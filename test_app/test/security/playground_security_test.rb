# frozen_string_literal: true

require "test_helper"
require "securerandom"

class PlaygroundSecurityTest < ActionDispatch::IntegrationTest
  DANGEROUS_SOURCES = {
    eval: 'eval("text(\\"owned\\")")',
    constant: 'File.read("/etc/passwd")',
    dynamic_send: 'text("Hello").send(:html_safe)',
    method_definition: 'def exploit; system("id"); end',
    assignment: "admin = true; text(admin)"
  }.freeze

  test "the interpreter rejects executable Ruby constructs without running them" do
    sentinel = Rails.root.join("tmp/playground-security-sentinel-#{SecureRandom.hex(8)}")

    sources = DANGEROUS_SOURCES.merge(
      system: "system(\"touch #{sentinel}\")",
      backticks: "`touch #{sentinel}`",
      file_write: "File.write(#{sentinel.to_s.inspect}, \"owned\")"
    )

    sources.each do |name, source|
      post showcase_playground_compile_path,
        params: { source: source, data_json: "{}", revision: name.to_s },
        as: :json

      assert_response :success, "Expected a bounded diagnostic for #{name}"
      payload = response.parsed_body
      assert_equal false, payload.fetch("ok"), "Expected #{name} to be rejected"
      assert_equal name.to_s, payload.fetch("revision")
      assert_operator payload.fetch("diagnostics").length, :>=, 1
      assert_empty payload.fetch("html").to_s
    end

    assert_not File.exist?(sentinel), "The playground executed File.write"
  ensure
    File.delete(sentinel) if sentinel && File.exist?(sentinel)
  end

  test "hostile fixture values remain escaped in rendered HTML" do
    post showcase_playground_compile_path,
      params: {
        source: "vstack { text(data[:title]); text(data[:body]) }",
        data_json: {
          title: '</div><script id="fixture-xss">alert(document.cookie)</script><div>',
          body: '<img id="fixture-onerror" src=x onerror="alert(1)">'
        }.to_json,
        revision: 3
      },
      as: :json

    assert_response :success
    html = response.parsed_body.fetch("html")
    refute_includes html, '<script id="fixture-xss">'
    refute_includes html, '<img id="fixture-onerror"'
    refute_includes html, "</div><script"
    assert_includes html, "&lt;script"
    assert_includes html, "&lt;img"
  end

  test "the HTML run and preview path remains escaped and script free" do
    hostile_value = '</main><script id="preview-xss">alert(document.cookie)</script><main>'
    post showcase_playground_run_path,
      params: {
        example: "product-catalog",
        source: "vstack { text(data[:message]) }",
        data_json: JSON.generate(message: hostile_value)
      }

    assert_response :see_other
    draft_token = Rack::Utils.parse_query(URI.parse(response.location).query).fetch("draft")
    get showcase_playground_preview_path(draft: draft_token)

    assert_response :success
    assert_select "#playground-render-root", text: /preview-xss/
    assert_select "script", count: 0
    refute_includes response.body, '<script id="preview-xss">'
    assert_includes response.body, "&lt;script"
    assert_includes response.headers.fetch("Content-Security-Policy"), "default-src 'none'"
  end

  test "preview draft tokens cannot cross Rails sessions" do
    author = open_session
    author.post showcase_playground_run_path,
      params: {
        example: "product-catalog",
        source: 'text("Private draft")',
        data_json: "{}"
      }
    assert_equal 303, author.response.status
    draft_token = Rack::Utils.parse_query(URI.parse(author.response.location).query).fetch("draft")

    other_session = open_session
    other_session.get showcase_playground_preview_path(draft: draft_token)

    assert_equal 404, other_session.response.status
    refute_includes other_session.response.body, "Private draft"
  end

  test "unsafe class and URL arguments cannot escape the allowlisted DSL" do
    {
      css_breakout: 'text("Owned").tw("safe; background: url(javascript:alert(1))")',
      attribute_breakout: 'text("Owned", class: %q[x\" onclick=\"alert(1)])',
      script_url: 'link("Owned", href: "javascript:alert(1)")'
    }.each do |name, source|
      post showcase_playground_compile_path,
        params: { source: source, data_json: "{}", revision: name.to_s },
        as: :json

      assert_response :success
      payload = response.parsed_body
      assert_equal false, payload.fetch("ok"), "Expected #{name} to be rejected"
      refute_includes payload.fetch("html").to_s, "javascript:"
      refute_includes payload.fetch("html").to_s, "onclick="
    end
  end

  test "semantic style roles cannot smuggle arbitrary utility classes" do
    {
      foreground: 'text("Owned").foreground_style("secondary bg-red-500")',
      background: 'text("Owned").background_style("surface hover:bg-red-500")',
      font: 'text("Owned").font("body motion-safe:animate-spin")',
      composite: 'text("Owned").text_style("supporting [&_*]:hidden")'
    }.each do |name, source|
      post showcase_playground_compile_path,
        params: { source: source, data_json: "{}", revision: "semantic-#{name}" },
        as: :json

      assert_response :success
      payload = response.parsed_body
      assert_equal false, payload.fetch("ok"), "Expected #{name} style injection to be rejected"
      assert_empty payload.fetch("html")
      assert_operator payload.fetch("diagnostics").length, :>=, 1
    end
  end

  test "oversized and deeply nested requests fail with bounded responses" do
    source_limit = playground_limit(:SOURCE_BYTES, 32.kilobytes)
    post showcase_playground_compile_path,
      params: {
        source: "x" * (source_limit + 1),
        data_json: "{}",
        revision: "oversized-source"
      },
      as: :json

    assert_response :success
    assert_equal false, response.parsed_body.fetch("ok")
    assert_operator response.body.bytesize, :<, 8.kilobytes

    nested_data = {}
    cursor = nested_data
    50.times { cursor["child"] = {}; cursor = cursor.fetch("child") }
    post showcase_playground_compile_path,
      params: {
        source: 'text("Nested")',
        data_json: nested_data.to_json,
        revision: "nested-data"
      },
      as: :json

    assert_response :success
    assert_equal false, response.parsed_body.fetch("ok")
    assert_operator response.body.bytesize, :<, 8.kilobytes
  end

  test "compile retains the Rails CSRF boundary" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    post showcase_playground_compile_path,
      params: { source: 'text("Hello")', data_json: "{}", revision: 1 },
      as: :json

    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  test "the HTML run endpoint retains the Rails CSRF boundary" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    post showcase_playground_run_path,
      params: { source: 'text("Hello")', data_json: "{}", example: "product-catalog" }

    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  test "diagnostics never leak server paths secrets or file contents" do
    post showcase_playground_compile_path,
      params: {
        source: 'text(File.read("/etc/passwd"))',
        data_json: "{}",
        revision: 5
      },
      as: :json

    assert_response :success
    body = response.body
    assert_equal false, response.parsed_body.fetch("ok")
    refute_includes body, Rails.root.to_s
    refute_includes body, "/etc/passwd:"
    refute_match(/root:x:\d+:/, body)
    refute_includes body, "BACKTRACE"
  end

  private

  def playground_limit(name, fallback)
    limits = Showcase::Playground::Limits
    limits.const_defined?(name, false) ? limits.const_get(name) : fallback
  end
end
