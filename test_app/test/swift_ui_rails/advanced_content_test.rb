# frozen_string_literal: true

require "test_helper"

class SwiftUIRails::AdvancedContentTest < ActiveSupport::TestCase
  setup do
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  test "AsyncImage keeps a neutral native fallback until JavaScript enables phases" do
    html = render_dsl do
      async_image(
        "/icon.png",
        alt: "SwiftUI Rails mark",
        loading_label: "Loading the mark",
        error_label: "The mark could not load",
        loading: :eager,
        fetch_priority: :high
      )
    end
    fragment = Nokogiri::HTML.fragment(html)
    figure = fragment.at_css("figure[data-sui-async-image]")
    image = figure.at_css("img")

    assert_equal({ "cache" => "browser" }, JSON.parse(figure["data-sui-async-image"]))
    assert_nil figure["aria-busy"]
    assert_equal "/icon.png", image["src"]
    assert_equal "SwiftUI Rails mark", image["alt"]
    assert_equal "eager", image["loading"]
    assert_equal "high", image["fetchpriority"]
    assert_equal "image", image["data-sui-async-image-role"]
    assert_nil image["data-action"]
    loading_status = figure.at_css("[role='status']")
    assert_equal "Loading the mark", loading_status.text
    assert loading_status.key?("hidden")
    refute image.key?("hidden")
    assert_equal "The mark could not load", figure.at_css("[role='alert']").text
    assert figure.at_css("[role='alert']").key?("hidden")
  end

  test "AsyncImage rejects unsafe sources and invented cache policies" do
    assert_raises(SwiftUIRails::SecurityError) do
      render_dsl { async_image("https://attacker.example/pixel", alt: "tracking pixel") }
    end
    assert_raises(SwiftUIRails::SecurityError) do
      render_dsl { async_image("javascript:alert(1)", alt: "bad") }
    end
    assert_raises(ArgumentError) do
      render_dsl { async_image("/icon.png", alt: "mark", cache_policy: :ignore_cache) }
    end
    assert_raises(ArgumentError) do
      render_dsl { async_image("/icon.png", alt: "mark", loading: :sometimes) }
    end
  end

  test "advanced content rejects caller controllers and protects required metadata" do
    async_html = render_dsl do
      async_image(
        "/icon.png",
        alt: "mark",
        data: { sui_async_image: JSON.generate(cache: "bypass") }
      )
    end
    async_figure = Nokogiri::HTML.fragment(async_html).at_css("figure")
    assert_equal "browser", JSON.parse(async_figure["data-sui-async-image"]).fetch("cache")
    assert_raises(SwiftUIRails::RenderIR::InvalidStructure) do
      render_dsl { async_image("/icon.png", alt: "mark", data: { controller: "analytics" }) }
    end

    map_html = render_dsl do
      map(
        center: [0, 0],
        span: [1, 1],
        markers: [],
        label: "Coordinates",
        data: { map_provider: "street-tiles" }
      )
    end
    assert_equal "schematic", Nokogiri::HTML.fragment(map_html).at_css("figure")["data-map-provider"]
  end

  test "rich text preserves editorial structure while removing active content" do
    html = render_dsl do
      rich_text(<<~HTML)
        <h2 style="color:red">Release <em>notes</em></h2>
        <p onclick="steal()">Read <strong>carefully</strong>.</p>
        <script id="payload">alert(1)</script>
        <img id="tracker" src="https://attacker.example/pixel" onerror="steal()">
        <a id="bad" href="javascript:alert(1)" target="_blank">bad</a>
        <a id="good" href="/releases" target="_blank">details</a>
      HTML
    end
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css(".swift-ui-rich-text[data-rich-text='sanitized']")
    assert_equal "Release notes", fragment.at_css("h2").text
    assert_equal "carefully", fragment.at_css("strong").text
    assert_nil fragment.at_css("script")
    assert_nil fragment.at_css("img")
    assert_nil fragment.at_css("[onclick]")
    bad_link = fragment.css("a").find { |anchor| anchor.text == "bad" }
    good_link = fragment.css("a").find { |anchor| anchor.text == "details" }
    assert_nil bad_link["href"]
    assert_equal "/releases", good_link["href"]
    assert_equal "noopener noreferrer", good_link["rel"]
    assert_nil fragment.at_css("h2")["style"]
  end

  test "WebView renders only sandboxed same-origin or allowlisted documents" do
    local_html = render_dsl do
      web_view("/up", title: "Application health", allow: [:fullscreen])
    end
    local = Nokogiri::HTML.fragment(local_html).at_css("iframe")
    assert_equal "/up", local["src"]
    assert_equal "", local["sandbox"]
    assert_equal "fullscreen", local["allow"]
    assert local.key?("allowfullscreen")
    assert_equal "same-origin", local["data-web-view"]

    external_html = render_dsl do
      web_view(
        "https://www.youtube-nocookie.com/embed/aqz-KE-bpKQ",
        title: "Demo video",
        allow: %i[fullscreen picture-in-picture]
      )
    end
    external = Nokogiri::HTML.fragment(external_html).at_css("iframe")
    assert_equal "allow-presentation allow-scripts", external["sandbox"]
    assert_equal "allowlisted-external", external["data-web-view"]
    assert_equal "strict-origin-when-cross-origin", external["referrerpolicy"]

    overridden_html = render_dsl do
      web_view("/up", title: "Health", referrerpolicy: "unsafe-url")
    end
    overridden = Nokogiri::HTML.fragment(overridden_html).at_css("iframe")
    assert_equal "strict-origin-when-cross-origin", overridden["referrerpolicy"]

    blank_html = render_dsl do
      web_view(
        :blank,
        title: "Generated preview",
        sandbox: [ "allow-same-origin" ],
        loading: :eager
      )
    end
    blank = Nokogiri::HTML.fragment(blank_html).at_css("iframe")
    assert_equal "about:blank", blank["src"]
    assert_equal "allow-same-origin", blank["sandbox"]
    assert_equal "no-referrer", blank["referrerpolicy"]
    assert_equal "blank", blank["data-web-view"]
  end

  test "WebView rejects srcdoc even when the external source is allowlisted" do
    assert_raises(SwiftUIRails::SecurityError) do
      render_dsl do
        web_view(
          "https://www.youtube-nocookie.com/embed/aqz-KE-bpKQ",
          title: "Unsafe inline document",
          srcdoc: "<script>parent.document.body.textContent = 'owned'</script>"
        )
      end
    end
  end

  test "WebView rejects script and same-origin sandbox escalation for external frames" do
    assert_raises(SwiftUIRails::SecurityError) do
      render_dsl do
        web_view(
          "https://www.youtube-nocookie.com/embed/aqz-KE-bpKQ",
          title: "Unsafe sandbox pair",
          sandbox: %i[allow-scripts allow-same-origin]
        )
      end
    end
  end

  test "charts expose an accessible SVG and exact values table" do
    html = render_dsl do
      chart(
        { "North" => 18, "South" => -4.5, "West" => 11 },
        type: :bar,
        title: "Regional change",
        description: "Quarterly change by region",
        color: :teal
      )
    end
    fragment = Nokogiri::HTML.fragment(html)
    svg = fragment.at_css("figure[data-chart-type='bar'] svg[role='img']")

    assert svg
    assert_equal "Regional change", svg.at_css("title").text
    assert_equal "Quarterly change by region", svg.at_css("desc").text
    assert_equal 3, svg.css("rect:not(:first-child)").length
    assert_equal "Regional change data", fragment.at_css("table caption").text
    assert_equal ["North", "South", "West"], fragment.css("tbody th").map(&:text)
    assert_equal ["18", "-4.5", "11"], fragment.css("tbody td").map(&:text)
  end

  test "line charts validate their type data and color" do
    html = render_dsl { chart([["A", 1], ["B", 2]], type: :line, title: "Trend") }
    fragment = Nokogiri::HTML.fragment(html)
    assert_equal 1, fragment.css("polyline").length
    assert_equal 2, fragment.css("circle").length

    assert_raises(ArgumentError) { render_dsl { chart([], title: "Empty") } }
    assert_raises(ArgumentError) { render_dsl { chart([["A", Float::INFINITY]], title: "Infinite") } }
    assert_raises(ArgumentError) { render_dsl { chart([["A", 1]], type: :pie, title: "Pie") } }
    assert_raises(ArgumentError) { render_dsl { chart([["A", 1]], color: :url, title: "Bad") } }
  end

  test "Canvas serializes a bounded drawing vocabulary and accessible fallback" do
    html = render_dsl do
      canvas(
        width: 320,
        height: 180,
        label: "Deployment trend illustration",
        commands: [
          { type: :clear, color: :white },
          { type: :fill_rect, x: 10, y: 20, width: 80, height: 40, color: "#2563eb" },
          { type: :line, x1: 0, y1: 170, x2: 320, y2: 10, color: :purple, line_width: 3 },
          { type: :circle, x: 150, y: 80, radius: 12, color: :orange, fill: false },
          { type: :text, x: 160, y: 160, text: "Healthy", align: :center, size: 18, color: :green }
        ]
      )
    end
    fragment = Nokogiri::HTML.fragment(html)
    figure = fragment.at_css("figure[data-sui-canvas]")
    surface = figure.at_css("canvas[role='img']")
    commands = JSON.parse(figure["data-sui-canvas"]).fetch("commands")

    assert_equal "Deployment trend illustration", surface["aria-label"]
    assert_equal "320", surface["width"]
    assert_equal "180", surface["height"]
    assert_equal %w[clear fill_rect line circle text], commands.map { |command| command.fetch("type") }
    assert_equal "#7c3aed", commands[2]["color"]
    assert_equal "Deployment trend illustration", figure.at_css("figcaption").text
    assert_includes surface.text, "requires Canvas support"
  end

  test "Canvas rejects executable or unbounded commands" do
    assert_raises(ArgumentError) do
      render_dsl { canvas(label: "Bad", commands: [{ type: :eval, code: "alert(1)" }]) }
    end
    assert_raises(ArgumentError) do
      render_dsl { canvas(label: "Bad", commands: [{ type: :clear, color: "url(javascript:alert(1))" }]) }
    end
    assert_raises(ArgumentError) do
      render_dsl { canvas(width: 100, label: "Bad", commands: [{ type: :line, x1: -1, y1: 0, x2: 2, y2: 2 }]) }
    end
    assert_raises(ArgumentError) do
      render_dsl { canvas(label: "Bad", commands: Array.new(501) { { type: :clear } }) }
    end
  end

  test "schematic map renders visible markers and an exact coordinate list" do
    html = render_dsl do
      map(
        center: { latitude: 51.5074, longitude: -0.1278 },
        span: [0.2, 0.4],
        label: "London offices",
        markers: [
          map_marker(latitude: 51.5074, longitude: -0.1278, label: "Head office", detail: "Open weekdays"),
          { latitude: 40.7128, longitude: -74.0060, label: "Outside viewport" }
        ]
      )
    end
    fragment = Nokogiri::HTML.fragment(html)
    figure = fragment.at_css("figure[data-map-provider='schematic']")

    assert_equal "London offices", figure.at_css("svg title").text
    assert_equal 1, figure.css(".swift-ui-map__marker").length
    assert_equal 2, figure.css(".swift-ui-map__markers li").length
    assert_includes figure.at_css("figcaption").text, "no street tiles; not for navigation"
    assert_includes figure.at_css("figcaption").text, "1 of 2 markers are in view"
    assert_includes figure.at_css(".swift-ui-map__markers").text, "51.50740, -0.12780"
  end

  test "map rejects misleading providers and invalid geography" do
    assert_raises(ArgumentError) do
      render_dsl { map(center: [0, 0], span: [1, 1], markers: [], label: "Map", provider: :streets) }
    end
    assert_raises(ArgumentError) do
      render_dsl { map_marker(latitude: 91, longitude: 0, label: "Invalid") }
    end
    assert_raises(ArgumentError) do
      render_dsl { map(center: [0, 0], span: [0, 1], markers: [], label: "Map") }
    end

    marker = SwiftUIRails::DSL::AdvancedContent::MapMarker.new(
      latitude: 1,
      longitude: 1,
      label: "Initially valid"
    )
    marker.latitude = 1000
    assert_raises(ArgumentError) do
      render_dsl { map(center: [0, 0], span: [1, 1], markers: [marker], label: "Map") }
    end
  end

  private

  def render_dsl(&block)
    @view.swift_ui(&block)
  end
end
