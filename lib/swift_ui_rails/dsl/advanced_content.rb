# frozen_string_literal: true

require "json"
require "nokogiri"
require "securerandom"
require "uri"

module SwiftUIRails
  module DSL
    # Web-native equivalents for SwiftUI's richer content families. These
    # helpers deliberately expose honest browser semantics: charts and maps are
    # server-rendered SVG, Canvas accepts a small command language rather than
    # JavaScript, WebView is a sandboxed iframe, and AsyncImage delegates bytes
    # and HTTP caching to the browser's native image loader.
    module AdvancedContent
      RICH_TEXT_TAGS = %w[
        p br strong em u s code pre blockquote ul ol li h2 h3 h4 h5 h6 a
      ].freeze
      RICH_TEXT_ATTRIBUTES = %w[href title target].freeze

      CHART_TYPES = %i[bar line].freeze
      CHART_COLORS = {
        blue: "#2563eb",
        green: "#16a34a",
        purple: "#7c3aed",
        orange: "#ea580c",
        red: "#dc2626",
        teal: "#0d9488"
      }.freeze

      CANVAS_COMMANDS = %i[clear fill_rect stroke_rect line circle text].freeze
      CANVAS_NAMED_COLORS = {
        black: "#000000",
        white: "#ffffff",
        red: "#dc2626",
        green: "#16a34a",
        blue: "#2563eb",
        orange: "#ea580c",
        purple: "#7c3aed",
        gray: "#6b7280",
        transparent: "transparent"
      }.freeze

      WEB_VIEW_SANDBOX_TOKENS = %w[
        allow-downloads
        allow-forms
        allow-modals
        allow-popups
        allow-popups-to-escape-sandbox
        allow-presentation
        allow-same-origin
        allow-scripts
      ].freeze
      WEB_VIEW_PERMISSIONS = %w[
        autoplay
        clipboard-write
        encrypted-media
        fullscreen
        picture-in-picture
      ].freeze

      MapMarker = Struct.new(:latitude, :longitude, :label, :detail, keyword_init: true) do
        def to_h
          { latitude: latitude, longitude: longitude, label: label, detail: detail }
        end
      end

      # Renders a native img with observable loading, success, and failure
      # phases. No fetch/blob indirection is used, so normal browser HTTP cache
      # headers, decoding, responsive image behavior, and assistive technology
      # all continue to work.
      def async_image(
        source,
        alt:,
        loading_label: "Loading image…",
        error_label: "Image unavailable",
        loading: :lazy,
        fetch_priority: :auto,
        cache_policy: :browser,
        image_class: nil,
        **attrs
      )
        safe_src = Security::URLValidator.validate_image_src(source.to_s, fallback: nil)
        raise SwiftUIRails::SecurityError, "AsyncImage source is not allowed" unless safe_src

        loading_value = loading.to_sym
        unless %i[lazy eager].include?(loading_value)
          raise ArgumentError, "loading must be :lazy or :eager"
        end

        priority_value = fetch_priority.to_sym
        unless %i[auto high low].include?(priority_value)
          raise ArgumentError, "fetch_priority must be :auto, :high, or :low"
        end
        unless cache_policy.to_sym == :browser
          raise ArgumentError, "AsyncImage supports only :browser cache_policy"
        end

        attrs[:class] = class_names("swift-ui-async-image relative", attrs[:class])
        attrs[:data] = advanced_merge_data(attrs[:data], {
          sui_async_image: JSON.generate(cache: "browser")
        })

        create_element(:figure, nil, **attrs) do
          div(
            loading_label.to_s,
            class: "swift-ui-async-image__loading",
            role: "status",
            hidden: true,
            data: { sui_async_image_role: "loading" }
          )
          create_element(
            :img,
            nil,
            src: safe_src,
            alt: alt.to_s,
            loading: loading_value.to_s,
            decoding: "async",
            fetchpriority: priority_value.to_s,
            class: class_names("swift-ui-async-image__image", image_class),
            data: { sui_async_image_role: "image" }
          )
          div(
            error_label.to_s,
            class: "swift-ui-async-image__error",
            role: "alert",
            hidden: true,
            data: { sui_async_image_role: "failure" }
          )
        end
      end

      # Sanitizes untrusted formatted text to a deliberately small editorial
      # vocabulary. Styling, media, forms, embeds, event handlers, and arbitrary
      # data attributes are never accepted.
      def rich_text(content, **attrs)
        sanitized = ActionController::Base.helpers.sanitize(
          content.to_s,
          tags: RICH_TEXT_TAGS,
          attributes: RICH_TEXT_ATTRIBUTES
        )
        fragment = Nokogiri::HTML5.fragment(sanitized)

        fragment.css("a").each do |anchor|
          href = anchor["href"]
          if href.present?
            safe_href = Security::URLValidator.validate_url(
              href,
              allow_relative: true,
              require_approved_domains: false,
              fallback: nil
            )
            safe_href ? anchor["href"] = safe_href : anchor.remove_attribute("href")
          end

          if anchor["target"] == "_blank"
            anchor["rel"] = "noopener noreferrer"
          elsif anchor["target"].present? && anchor["target"] != "_self"
            anchor.remove_attribute("target")
          end
        end

        attrs[:class] = class_names("swift-ui-rich-text", attrs[:class])
        attrs[:data] = advanced_merge_data(attrs[:data], { rich_text: "sanitized" })
        create_element(:div, fragment.to_html.html_safe, **attrs)
      end

      # A sandboxed iframe with a dedicated external-host allowlist. Relative
      # application URLs are supported, but can never combine allow-scripts and
      # allow-same-origin because that pair lets a same-origin frame remove its
      # own sandbox.
      def web_view(
        source,
        title:,
        sandbox: nil,
        allow: [],
        loading: :lazy,
        **attrs
      )
        raise ArgumentError, "WebView title is required" if title.to_s.strip.empty?
        if attrs.key?(:srcdoc) || attrs.key?("srcdoc")
          raise SwiftUIRails::SecurityError, "WebView srcdoc is not supported"
        end

        blank_document = source == :blank
        safe_src = if blank_document
          "about:blank"
        else
          Security::URLValidator.validate_embed_src(source.to_s)
        end
        raise SwiftUIRails::SecurityError, "WebView source is not allowed" unless safe_src

        loading_value = loading.to_sym
        unless %i[lazy eager].include?(loading_value)
          raise ArgumentError, "loading must be :lazy or :eager"
        end

        external = !blank_document && URI.parse(safe_src).host.present?
        default_sandbox = external ? %w[allow-presentation allow-scripts] : []
        sandbox_tokens = advanced_enum_list(sandbox.nil? ? default_sandbox : sandbox, WEB_VIEW_SANDBOX_TOKENS, "sandbox")
        if sandbox_tokens.include?("allow-scripts") && sandbox_tokens.include?("allow-same-origin")
          raise SwiftUIRails::SecurityError,
                "WebView cannot combine allow-scripts and allow-same-origin"
        end

        permissions = advanced_enum_list(allow, WEB_VIEW_PERMISSIONS, "WebView permission")
        attrs[:src] = safe_src
        attrs[:title] = title.to_s
        attrs[:sandbox] = sandbox_tokens.join(" ")
        attrs[:allow] = permissions.join("; ") if permissions.any?
        attrs[:allowfullscreen] = true if permissions.include?("fullscreen")
        attrs[:loading] = loading_value.to_s
        attrs[:referrerpolicy] = blank_document ? "no-referrer" : "strict-origin-when-cross-origin"
        attrs[:class] = class_names("swift-ui-web-view", attrs[:class])
        web_view_kind = if blank_document
          "blank"
        elsif external
          "allowlisted-external"
        else
          "same-origin"
        end
        attrs[:data] = advanced_merge_data(attrs[:data], { web_view: web_view_kind })

        create_element(:iframe, "".html_safe, **attrs)
      end

      # An accessible, dependency-free SVG chart. Exact values are repeated in
      # a visually hidden table, so the result remains useful without color,
      # JavaScript, pointer input, or visual SVG interpretation.
      def chart(data, type: :bar, title:, description: nil, color: :blue, **attrs)
        chart_type = type.to_sym
        raise ArgumentError, "chart type must be :bar or :line" unless CHART_TYPES.include?(chart_type)
        chart_title = advanced_bounded_text(title, "chart title", 160)
        chart_description = description.nil? ? nil : advanced_bounded_text(description, "chart description", 500)

        points = advanced_chart_points(data)
        color_value = CHART_COLORS.fetch(color.to_sym) do
          raise ArgumentError, "unknown chart color: #{color.inspect}"
        end
        chart_id = "swift-ui-chart-#{SecureRandom.hex(6)}"
        svg = advanced_chart_svg(
          points,
          type: chart_type,
          title: chart_title,
          description: chart_description.presence || "#{chart_type.to_s.capitalize} chart with #{points.length} values.",
          color: color_value,
          id: chart_id
        )
        table = advanced_data_table(points, caption: "#{chart_title} data")
        caption = "<figcaption>#{advanced_escape(chart_title)}</figcaption>"

        attrs[:class] = class_names("swift-ui-chart", attrs[:class])
        attrs[:data] = advanced_merge_data(attrs[:data], { chart_type: chart_type })
        create_element(:figure, "#{svg}#{caption}#{table}".html_safe, **attrs)
      end

      # Executes a fixed, data-only drawing language in a real HTML canvas.
      # Arbitrary JavaScript, CSS, path strings, composite operations, and image
      # URLs are intentionally outside the contract.
      def canvas(commands:, width: 640, height: 360, label:, fallback: nil, **attrs)
        canvas_width = advanced_dimension(width, "canvas width")
        canvas_height = advanced_dimension(height, "canvas height")
        raise ArgumentError, "canvas label is required" if label.to_s.strip.empty?

        normalized_commands = advanced_canvas_commands(commands, canvas_width, canvas_height)
        fallback_text = fallback.presence || "#{label}. This drawing requires Canvas support."
        canvas_tag = content_tag(
          :canvas,
          fallback_text,
          width: canvas_width,
          height: canvas_height,
          role: "img",
          aria: { label: label.to_s },
          class: "swift-ui-canvas__surface",
          data: { sui_canvas_role: "surface" }
        )
        caption = content_tag(:figcaption, label.to_s)

        attrs[:class] = class_names("swift-ui-canvas", attrs[:class])
        attrs[:data] = advanced_merge_data(attrs[:data], {
          sui_canvas: JSON.generate(
            commands: normalized_commands,
            width: canvas_width,
            height: canvas_height
          )
        })
        create_element(:figure, safe_join([canvas_tag, caption]), **attrs)
      end

      def map_marker(latitude:, longitude:, label:, detail: nil)
        MapMarker.new(
          latitude: advanced_coordinate(latitude, -90.0, 90.0, "marker latitude"),
          longitude: advanced_coordinate(longitude, -180.0, 180.0, "marker longitude"),
          label: advanced_bounded_text(label, "marker label", 120),
          detail: detail.nil? ? nil : advanced_bounded_text(detail, "marker detail", 240)
        )
      end

      # A deterministic schematic coordinate view, not a tile/street map. That
      # distinction is visible in markup and the caption so callers never
      # mistake it for a navigation product or silently send location data to a
      # third-party map provider.
      def map(center:, span:, markers:, label:, provider: :schematic, **attrs)
        raise ArgumentError, "map provider must be :schematic" unless provider.to_sym == :schematic
        map_label = advanced_bounded_text(label, "map label", 160)

        center_latitude, center_longitude = advanced_map_point(center, "map center")
        latitude_span, longitude_span = advanced_map_span(span)
        marker_values = Array(markers)
        raise ArgumentError, "map supports at most 100 markers" if marker_values.length > 100

        normalized_markers = marker_values.map do |marker|
          map_marker(**marker.to_h.transform_keys(&:to_sym))
        rescue NoMethodError, TypeError
          raise ArgumentError, "each map marker must be a marker or hash"
        end

        map_id = "swift-ui-map-#{SecureRandom.hex(6)}"
        svg, visible_count = advanced_map_svg(
          center_latitude,
          center_longitude,
          latitude_span,
          longitude_span,
          normalized_markers,
          map_label,
          map_id
        )
        list = advanced_marker_list(normalized_markers)
        note = "Schematic coordinate map — no street tiles; not for navigation. #{visible_count} of #{normalized_markers.length} markers are in view."
        caption = "<figcaption><strong>#{advanced_escape(map_label)}</strong> <span>#{advanced_escape(note)}</span></figcaption>"

        attrs[:class] = class_names("swift-ui-map", attrs[:class])
        attrs[:data] = advanced_merge_data(attrs[:data], { map_provider: "schematic" })
        create_element(:figure, "#{svg}#{caption}#{list}".html_safe, **attrs)
      end

      private

      def advanced_merge_data(existing, additions)
        merged = (existing || {}).dup

        additions.each do |key, value|
          # Internal metadata describes an enforced semantic/security contract,
          # so caller-supplied duplicate spellings may not spoof it.
          merged.delete(key.to_s)
          merged.delete(key.to_sym)
          merged[key] = value
        end
        merged
      end

      def advanced_enum_list(values, allowed, name)
        Array(values).map(&:to_s).uniq.tap do |list|
          invalid = list - allowed
          raise ArgumentError, "unknown #{name}: #{invalid.join(', ')}" if invalid.any?
        end
      end

      def advanced_chart_points(data)
        pairs = data.is_a?(Hash) ? data.to_a : Array(data)
        raise ArgumentError, "chart data must contain between 1 and 100 values" unless pairs.length.between?(1, 100)

        pairs.map do |entry|
          unless entry.respond_to?(:to_a) && entry.to_a.length == 2
            raise ArgumentError, "chart data entries must be [label, value] pairs"
          end

          label, raw_value = entry.to_a
          value = Float(raw_value)
          raise ArgumentError, "chart values must be finite" unless value.finite?

          [advanced_bounded_text(label, "chart label", 80), value]
        rescue ArgumentError, TypeError
          raise ArgumentError, "chart values must be finite numbers" unless defined?(value) && value&.finite?

          raise
        end
      end

      def advanced_chart_svg(points, type:, title:, description:, color:, id:)
        width = 640.0
        height = 360.0
        left = 58.0
        right = 20.0
        top = 38.0
        bottom = 58.0
        plot_width = width - left - right
        plot_height = height - top - bottom
        values = points.map(&:last)
        minimum = [values.min, 0.0].min
        maximum = [values.max, 0.0].max
        maximum = minimum + 1.0 if maximum == minimum
        y_for = ->(value) { top + ((maximum - value) / (maximum - minimum)) * plot_height }
        baseline = y_for.call(0.0)
        slot = plot_width / points.length

        marks = if type == :bar
          points.each_with_index.map do |(label, value), index|
            center_x = left + (slot * index) + (slot / 2.0)
            value_y = y_for.call(value)
            bar_y = [value_y, baseline].min
            bar_height = [(value_y - baseline).abs, 1.0].max
            bar_width = [slot * 0.62, 4.0].max
            <<~SVG
              <rect x="#{advanced_number(center_x - (bar_width / 2.0))}" y="#{advanced_number(bar_y)}" width="#{advanced_number(bar_width)}" height="#{advanced_number(bar_height)}" fill="#{color}" rx="3">
                <title>#{advanced_escape(label)}: #{advanced_escape(advanced_display_number(value))}</title>
              </rect>
            SVG
          end.join
        else
          coordinates = points.each_with_index.map do |(_label, value), index|
            [left + (slot * index) + (slot / 2.0), y_for.call(value)]
          end
          polyline = "<polyline points=\"#{coordinates.map { |x, y| "#{advanced_number(x)},#{advanced_number(y)}" }.join(' ')}\" fill=\"none\" stroke=\"#{color}\" stroke-width=\"4\" stroke-linejoin=\"round\" stroke-linecap=\"round\" />"
          circles = points.each_with_index.map do |(label, value), index|
            x, y = coordinates[index]
            <<~SVG
              <circle cx="#{advanced_number(x)}" cy="#{advanced_number(y)}" r="5" fill="#{color}">
                <title>#{advanced_escape(label)}: #{advanced_escape(advanced_display_number(value))}</title>
              </circle>
            SVG
          end.join
          "#{polyline}#{circles}"
        end

        labels = points.each_with_index.map do |(label, _value), index|
          x = left + (slot * index) + (slot / 2.0)
          short_label = label.length > 14 ? "#{label[0, 13]}…" : label
          "<text x=\"#{advanced_number(x)}\" y=\"#{advanced_number(height - 24)}\" text-anchor=\"middle\" font-size=\"12\" fill=\"#475569\">#{advanced_escape(short_label)}</text>"
        end.join

        <<~SVG
          <svg viewBox="0 0 640 360" role="img" aria-labelledby="#{id}-title #{id}-description" class="swift-ui-chart__plot" xmlns="http://www.w3.org/2000/svg">
            <title id="#{id}-title">#{advanced_escape(title)}</title>
            <desc id="#{id}-description">#{advanced_escape(description)}</desc>
            <line x1="#{advanced_number(left)}" y1="#{advanced_number(baseline)}" x2="#{advanced_number(width - right)}" y2="#{advanced_number(baseline)}" stroke="#94a3b8" stroke-width="1" />
            #{marks}
            #{labels}
          </svg>
        SVG
      end

      def advanced_data_table(points, caption:)
        rows = points.map do |label, value|
          "<tr><th scope=\"row\">#{advanced_escape(label)}</th><td>#{advanced_escape(advanced_display_number(value))}</td></tr>"
        end.join
        <<~HTML
          <table class="sr-only swift-ui-chart__data">
            <caption>#{advanced_escape(caption)}</caption>
            <thead><tr><th scope="col">Label</th><th scope="col">Value</th></tr></thead>
            <tbody>#{rows}</tbody>
          </table>
        HTML
      end

      def advanced_canvas_commands(commands, width, height)
        command_values = Array(commands)
        raise ArgumentError, "canvas supports at most 500 commands" if command_values.length > 500

        command_values.map do |command|
          raise ArgumentError, "each canvas command must be a hash" unless command.is_a?(Hash)

          value = command.to_h.transform_keys(&:to_sym)
          type = value.fetch(:type).to_sym
          raise ArgumentError, "unknown canvas command: #{type.inspect}" unless CANVAS_COMMANDS.include?(type)

          case type
          when :clear
            { type: "clear", color: advanced_canvas_color(value.fetch(:color, :transparent)) }
          when :fill_rect, :stroke_rect
            normalized = {
              type: type.to_s,
              x: advanced_canvas_coordinate(value.fetch(:x), width, "rectangle x"),
              y: advanced_canvas_coordinate(value.fetch(:y), height, "rectangle y"),
              width: advanced_positive_number(value.fetch(:width), width, "rectangle width"),
              height: advanced_positive_number(value.fetch(:height), height, "rectangle height"),
              color: advanced_canvas_color(value.fetch(:color, :black))
            }
            normalized[:line_width] = advanced_line_width(value.fetch(:line_width, 1)) if type == :stroke_rect
            normalized
          when :line
            {
              type: "line",
              x1: advanced_canvas_coordinate(value.fetch(:x1), width, "line x1"),
              y1: advanced_canvas_coordinate(value.fetch(:y1), height, "line y1"),
              x2: advanced_canvas_coordinate(value.fetch(:x2), width, "line x2"),
              y2: advanced_canvas_coordinate(value.fetch(:y2), height, "line y2"),
              color: advanced_canvas_color(value.fetch(:color, :black)),
              line_width: advanced_line_width(value.fetch(:line_width, 1))
            }
          when :circle
            {
              type: "circle",
              x: advanced_canvas_coordinate(value.fetch(:x), width, "circle x"),
              y: advanced_canvas_coordinate(value.fetch(:y), height, "circle y"),
              radius: advanced_positive_number(value.fetch(:radius), [width, height].max, "circle radius"),
              color: advanced_canvas_color(value.fetch(:color, :black)),
              fill: value.fetch(:fill, true) == true,
              line_width: advanced_line_width(value.fetch(:line_width, 1))
            }
          when :text
            align = value.fetch(:align, :start).to_s
            raise ArgumentError, "text align must be start, center, or end" unless %w[start center end].include?(align)

            {
              type: "text",
              x: advanced_canvas_coordinate(value.fetch(:x), width, "text x"),
              y: advanced_canvas_coordinate(value.fetch(:y), height, "text y"),
              text: advanced_bounded_text(value.fetch(:text), "canvas text", 200),
              color: advanced_canvas_color(value.fetch(:color, :black)),
              size: advanced_integer(value.fetch(:size, 16), 8, 96, "text size"),
              align: align
            }
          end
        rescue KeyError => error
          raise ArgumentError, "canvas command is missing #{error.key}"
        end
      end

      def advanced_canvas_color(value)
        string = value.to_s.downcase
        return CANVAS_NAMED_COLORS.fetch(string.to_sym) if CANVAS_NAMED_COLORS.key?(string.to_sym)
        return string if string.match?(/\A#[0-9a-f]{6}\z/i)

        raise ArgumentError, "canvas color must be a named palette color or six-digit hex"
      end

      def advanced_dimension(value, name)
        advanced_integer(value, 1, 4096, name)
      end

      def advanced_integer(value, minimum, maximum, name)
        number = Integer(value)
        raise ArgumentError, "#{name} must be between #{minimum} and #{maximum}" unless number.between?(minimum, maximum)

        number
      rescue TypeError, ArgumentError
        raise ArgumentError, "#{name} must be between #{minimum} and #{maximum}"
      end

      def advanced_canvas_coordinate(value, maximum, name)
        number = Float(value)
        raise ArgumentError, "#{name} must be finite and within the canvas" unless number.finite? && number.between?(0.0, maximum.to_f)

        number
      rescue TypeError, ArgumentError
        raise ArgumentError, "#{name} must be finite and within the canvas"
      end

      def advanced_positive_number(value, maximum, name)
        number = Float(value)
        raise ArgumentError, "#{name} must be positive and finite" unless number.finite? && number.positive? && number <= maximum

        number
      rescue TypeError, ArgumentError
        raise ArgumentError, "#{name} must be positive and finite"
      end

      def advanced_line_width(value)
        advanced_positive_number(value, 64, "line width")
      end

      def advanced_coordinate(value, minimum, maximum, name)
        number = Float(value)
        raise ArgumentError, "#{name} is outside its valid range" unless number.finite? && number.between?(minimum, maximum)

        number
      rescue TypeError, ArgumentError
        raise ArgumentError, "#{name} is outside its valid range"
      end

      def advanced_map_point(value, name)
        if value.is_a?(Hash)
          hash = value.to_h.transform_keys(&:to_sym)
          latitude = hash.fetch(:latitude)
          longitude = hash.fetch(:longitude)
        else
          latitude, longitude = Array(value)
        end

        [
          advanced_coordinate(latitude, -90.0, 90.0, "#{name} latitude"),
          advanced_coordinate(longitude, -180.0, 180.0, "#{name} longitude")
        ]
      rescue KeyError
        raise ArgumentError, "#{name} requires latitude and longitude"
      end

      def advanced_map_span(value)
        latitude, longitude = Array(value)
        latitude = Float(latitude)
        longitude = Float(longitude)
        unless latitude.finite? && longitude.finite? && latitude.positive? && longitude.positive? && latitude <= 180 && longitude <= 360
          raise ArgumentError, "map span must contain positive latitude and longitude deltas"
        end

        [latitude, longitude]
      rescue TypeError, ArgumentError
        raise ArgumentError, "map span must contain positive latitude and longitude deltas"
      end

      def advanced_map_svg(center_latitude, center_longitude, latitude_span, longitude_span, markers, label, id)
        width = 640.0
        height = 360.0
        padding = 28.0
        plot_width = width - (padding * 2)
        plot_height = height - (padding * 2)
        north = center_latitude + (latitude_span / 2.0)
        west = center_longitude - (longitude_span / 2.0)

        visible = markers.filter_map do |marker|
          x_ratio = (marker.longitude - west) / longitude_span
          y_ratio = (north - marker.latitude) / latitude_span
          next unless x_ratio.between?(0.0, 1.0) && y_ratio.between?(0.0, 1.0)

          [marker, padding + (x_ratio * plot_width), padding + (y_ratio * plot_height)]
        end

        grid = (1..3).map do |index|
          x = padding + (plot_width * index / 4.0)
          y = padding + (plot_height * index / 4.0)
          "<line x1=\"#{advanced_number(x)}\" y1=\"#{advanced_number(padding)}\" x2=\"#{advanced_number(x)}\" y2=\"#{advanced_number(height - padding)}\" stroke=\"#cbd5e1\" /><line x1=\"#{advanced_number(padding)}\" y1=\"#{advanced_number(y)}\" x2=\"#{advanced_number(width - padding)}\" y2=\"#{advanced_number(y)}\" stroke=\"#cbd5e1\" />"
        end.join
        pins = visible.each_with_index.map do |(marker, x, y), index|
          <<~SVG
            <g class="swift-ui-map__marker" data-marker-index="#{index}">
              <circle cx="#{advanced_number(x)}" cy="#{advanced_number(y)}" r="9" fill="#dc2626" stroke="#ffffff" stroke-width="3">
                <title>#{advanced_escape(marker.label)} — #{advanced_escape(advanced_coordinate_text(marker))}</title>
              </circle>
            </g>
          SVG
        end.join

        svg = <<~SVG
          <svg viewBox="0 0 640 360" role="img" aria-labelledby="#{id}-title #{id}-description" class="swift-ui-map__plot" xmlns="http://www.w3.org/2000/svg">
            <title id="#{id}-title">#{advanced_escape(label)}</title>
            <desc id="#{id}-description">Schematic coordinate plot with #{visible.length} visible markers. No street or terrain data is shown.</desc>
            <rect x="#{advanced_number(padding)}" y="#{advanced_number(padding)}" width="#{advanced_number(plot_width)}" height="#{advanced_number(plot_height)}" fill="#f8fafc" stroke="#64748b" />
            #{grid}
            <path d="M 314 180 H 326 M 320 174 V 186" stroke="#334155" stroke-width="2" aria-hidden="true" />
            #{pins}
          </svg>
        SVG
        [svg, visible.length]
      end

      def advanced_marker_list(markers)
        items = markers.map do |marker|
          detail = marker.detail.present? ? " #{marker.detail}" : ""
          "<li><strong>#{advanced_escape(marker.label)}</strong> — #{advanced_escape(advanced_coordinate_text(marker))}.#{advanced_escape(detail)}</li>"
        end.join
        "<ul class=\"sr-only swift-ui-map__markers\">#{items}</ul>"
      end

      def advanced_coordinate_text(marker)
        format("%.5f, %.5f", marker.latitude, marker.longitude)
      end

      def advanced_bounded_text(value, name, maximum)
        text = value.to_s
        raise ArgumentError, "#{name} is required" if text.strip.empty?
        raise ArgumentError, "#{name} is too long" if text.length > maximum

        text
      end

      def advanced_number(value)
        format("%.2f", value)
      end

      def advanced_display_number(value)
        value == value.to_i ? value.to_i.to_s : format("%.2f", value).sub(/0+\z/, "").sub(/\.\z/, "")
      end

      def advanced_escape(value)
        ERB::Util.html_escape(value.to_s)
      end
    end

    include AdvancedContent
  end
end
