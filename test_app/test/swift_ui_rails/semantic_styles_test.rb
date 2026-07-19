require "test_helper"

class SwiftUIRails::SemanticStylesTest < ActiveSupport::TestCase
  def setup
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  test "foreground styles emit stable framework classes for every allowed role" do
    roles = %i[
      primary secondary tertiary quaternary accent success warning danger
      on_accent
    ]

    roles.each do |role|
      result = render_text { |element| element.foreground_style(role) }

      assert_includes result, "swift-ui-foreground-#{role.to_s.tr('_', '-')}"
    end
  end

  test "background styles emit stable framework classes for every allowed role" do
    roles = %i[canvas surface elevated muted accent success warning danger]

    roles.each do |role|
      result = render_text { |element| element.background_style(role) }

      assert_includes result, "swift-ui-background-#{role}"
    end
  end

  test "font accepts the SwiftUI semantic font vocabulary" do
    roles = %i[
      large_title title title2 title3 headline subheadline body callout footnote
      caption caption2
    ]

    roles.each do |role|
      result = render_text { |element| element.font(role) }

      assert_includes result, "swift-ui-font-#{role.to_s.tr('_', '-')}"
    end

    assert_includes render_text { |element| element.font("large-title") },
                    "swift-ui-font-large-title"
  end

  test "text styles compose a stable marker with font and foreground facets" do
    expected = {
      title: %w[swift-ui-font-title swift-ui-foreground-primary],
      headline: %w[swift-ui-font-headline swift-ui-foreground-primary],
      body: %w[swift-ui-font-body swift-ui-foreground-primary],
      supporting: %w[swift-ui-font-subheadline swift-ui-foreground-secondary],
      metadata: %w[swift-ui-font-footnote swift-ui-foreground-tertiary],
      caption: %w[swift-ui-font-caption swift-ui-foreground-secondary]
    }

    expected.each do |role, facets|
      result = render_text { |element| element.text_style(role) }

      assert_includes result, "swift-ui-text-style-#{role}"
      facets.each { |facet| assert_includes result, facet }
    end
  end

  test "repeated semantic modifiers use the last role" do
    result = render_text do |element|
      element
        .foreground_style(:secondary)
        .foreground_style(:danger)
        .background_style(:surface)
        .background_style(:elevated)
        .font(:caption)
        .font(:headline)
    end

    assert_includes result, "swift-ui-foreground-danger"
    assert_includes result, "swift-ui-background-elevated"
    assert_includes result, "swift-ui-font-headline"
    refute_includes result, "swift-ui-foreground-secondary"
    refute_includes result, "swift-ui-background-surface"
    refute_includes result, "swift-ui-font-caption"
  end

  test "explicit facets override a text style and a later text style resets both" do
    overridden = render_text do |element|
      element
        .text_style(:supporting)
        .font(:headline)
        .foreground_style(:danger)
    end

    assert_includes overridden, "swift-ui-text-style-supporting"
    assert_includes overridden, "swift-ui-font-headline"
    assert_includes overridden, "swift-ui-foreground-danger"
    refute_includes overridden, "swift-ui-font-subheadline"
    refute_includes overridden, "swift-ui-foreground-secondary"

    reset = render_text do |element|
      element
        .text_style(:supporting)
        .font(:headline)
        .foreground_style(:danger)
        .text_style(:metadata)
    end

    assert_includes reset, "swift-ui-text-style-metadata"
    assert_includes reset, "swift-ui-font-footnote"
    assert_includes reset, "swift-ui-foreground-tertiary"
    refute_includes reset, "swift-ui-text-style-supporting"
    refute_includes reset, "swift-ui-font-headline"
    refute_includes reset, "swift-ui-foreground-danger"
  end

  test "unknown roles and non scalar roles are rejected" do
    assertions = [
      -> { render_text { |element| element.foreground_style(:brand) } },
      -> { render_text { |element| element.background_style(:primary) } },
      -> { render_text { |element| element.font(:tiny) } },
      -> { render_text { |element| element.text_style(:hero) } },
      -> { render_text { |element| element.foreground_style("secondary bg-red-500") } },
      -> { render_text { |element| element.font(Object.new) } }
    ]

    assertions.each { |assertion| assert_raises(ArgumentError, &assertion) }
  end

  test "raw color escape hatches and semantic roles follow chain order" do
    raw_foreground = render_text do |element|
      element.foreground_style(:secondary).text_color("red-600")
    end
    semantic_foreground = render_text do |element|
      element.text_color("red-600").foreground_style(:secondary)
    end
    raw_background = render_text do |element|
      element.background_style(:surface).bg("red-600")
    end
    semantic_background = render_text do |element|
      element.bg("red-600").background_style(:surface)
    end

    assert_includes raw_foreground, "text-red-600"
    refute_includes raw_foreground, "swift-ui-foreground-secondary"

    assert_includes semantic_foreground, "swift-ui-foreground-secondary"
    refute_includes semantic_foreground, "text-red-600"

    assert_includes raw_background, "bg-red-600"
    refute_includes raw_background, "swift-ui-background-surface"

    assert_includes semantic_background, "swift-ui-background-surface"
    refute_includes semantic_background, "bg-red-600"
  end

  test "semantic style modifiers preserve trailing content blocks" do
    result = @view.swift_ui do
      div.background_style(:surface).text_style(:body) do
        text("Semantic child")
      end
    end

    assert_includes result, "swift-ui-background-surface"
    assert_includes result, "swift-ui-text-style-body"
    assert_includes result, "Semantic child"
  end

  test "appearance exposes a safe application-defined view style hook" do
    result = render_text { |element| element.appearance(:code_editor_gutter) }

    assert_includes result, 'data-swift-ui-appearance="code-editor-gutter"'
    refute_includes result, "code_editor_gutter"

    assert_raises(ArgumentError) { render_text { |element| element.appearance("surface bg-red-500") } }
    assert_raises(ArgumentError) { render_text { |element| element.appearance("[onclick]") } }
    assert_raises(ArgumentError) { render_text { |element| element.appearance(Object.new) } }
  end

  test "visually hidden preserves accessible content without raw utility calls" do
    hidden = render_text { |element| element.visually_hidden }
    visible = render_text { |element| element.visually_hidden.visually_hidden(false) }

    assert_includes hidden, "swift-ui-visually-hidden"
    refute_includes hidden, "aria-hidden"
    refute_includes visible, "swift-ui-visually-hidden"
    assert_raises(ArgumentError) { render_text { |element| element.visually_hidden(nil) } }
  end

  test "generated styles use overridable variables and support dark themes" do
    stylesheet = File.read(
      Rails.root.join("..", "lib/generators/swift_ui_rails/install/templates/swift_ui_rails.css")
    )

    assert_includes stylesheet, "--swift-ui-foreground-secondary:"
    assert_includes stylesheet, "--swift-ui-background-surface:"
    assert_includes stylesheet, "--swift-ui-font-body-size:"
    assert_includes stylesheet, '[data-swift-ui-theme="dark"]'
    assert_includes stylesheet, "@media (prefers-color-scheme: dark)"
    assert_includes stylesheet,
                    ".swift-ui-foreground-secondary { color: var(--swift-ui-foreground-secondary); }"
    assert_includes stylesheet,
                    ".swift-ui-font-body { font-size: var(--swift-ui-font-body-size);"
    assert_includes stylesheet, ".swift-ui-visually-hidden {"
  end

  test "packaged and showcase stylesheets cover every public semantic role" do
    stylesheets = [
      Rails.root.join("..", "lib/generators/swift_ui_rails/install/templates/swift_ui_rails.css"),
      Rails.root.join("app/assets/stylesheets/application.css")
    ].to_h { |path| [ path, File.read(path) ] }
    modifiers = SwiftUIRails::DSL::SemanticStyleModifiers

    stylesheets.each do |path, stylesheet|
      assert_includes stylesheet, ".swift-ui-visually-hidden", path.to_s

      modifiers::FOREGROUND_STYLES.each do |role|
        kebab_role = role.to_s.tr("_", "-")
        assert_includes stylesheet, ".swift-ui-foreground-#{kebab_role}", path.to_s
        assert_includes stylesheet, "--swift-ui-foreground-#{kebab_role}", path.to_s
      end

      modifiers::BACKGROUND_STYLES.each do |role|
        kebab_role = role.to_s.tr("_", "-")
        assert_includes stylesheet, ".swift-ui-background-#{kebab_role}", path.to_s
        assert_includes stylesheet, "--swift-ui-background-#{kebab_role}", path.to_s
      end

      modifiers::FONT_STYLES.each do |role|
        kebab_role = role.to_s.tr("_", "-")
        assert_includes stylesheet, ".swift-ui-font-#{kebab_role}", path.to_s
        assert_includes stylesheet, "--swift-ui-font-#{kebab_role}-size", path.to_s
      end
    end
  end

  private

  def render_text
    @view.swift_ui do
      element = text("Semantic")
      yield(element)
    end
  end
end
