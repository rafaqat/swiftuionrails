# frozen_string_literal: true

require "test_helper"

# The linter is the agent-facing generate→validate→repair harness; these
# tests pin its diagnostic contract: domain-phrased messages, line/column
# locations, did-you-mean hints, and zero findings on healthy files.
class SwiftUiLintTest < ActiveSupport::TestCase
  # Per-process fixture dir — the suite runs with parallel workers and a
  # shared directory would let one worker's teardown delete another's file.
  def fixture_dir
    @fixture_dir ||= Rails.root.join("tmp/lint_fixtures_#{Process.pid}").tap { |dir| FileUtils.mkdir_p(dir) }
  end

  teardown do
    FileUtils.rm_rf(@fixture_dir) if @fixture_dir
  end

  def write_fixture(name, source)
    path = fixture_dir.join(name)
    File.write(path, source)
    path.relative_path_from(Rails.root).to_s
  end

  test "flags misspelled modifiers statically with a did-you-mean hint" do
    path = write_fixture("misspelled_component.rb", <<~RUBY)
      class LintMisspelledComponent < ApplicationComponent
        swift_ui do
          text("hi").font_wieght("bold")
        end
      end
    RUBY

    diagnostics = SwiftUi::Lint.call(path)
    finding = diagnostics.find { |d| d.code == "unknown_modifier" }

    assert finding, "expected an unknown_modifier diagnostic"
    assert_equal 3, finding.line
    assert_match(/font_wieght/, finding.message)
    assert_match(/font_weight/, finding.hint)
  end

  test "flags hallucinated literal values with enumerated domain errors" do
    path = write_fixture("bad_values_component.rb", <<~RUBY)
      class LintBadValuesComponent < ApplicationComponent
        swift_ui do
          div("x").bg("cerulean-500").rounded("blob")
        end
      end
    RUBY

    diagnostics = SwiftUi::Lint.call(path)
    codes = diagnostics.map(&:code)

    assert_includes codes, "invalid_value"
    color_finding = diagnostics.find { |d| d.message.include?("cerulean-500") }
    assert color_finding
    assert_match(/blue/, color_finding.message, "error should enumerate the valid vocabulary")
    assert diagnostics.any? { |d| d.message.include?('"blob"') }
  end

  test "reports syntax errors with locations" do
    path = write_fixture("syntax_component.rb", <<~RUBY)
      class LintSyntaxComponent < ApplicationComponent
        swift_ui do
          text("hi"
        end
      end
    RUBY

    diagnostics = SwiftUi::Lint.call(path)

    assert diagnostics.any? { |d| d.code == "syntax" && d.line }
  end

  test "healthy DSL passes clean" do
    path = write_fixture("healthy_component.rb", <<~RUBY)
      class LintHealthyComponent < ApplicationComponent
        prop :label, type: String, default: "Hi"

        swift_ui do
          vstack(spacing: 8) do
            text(label).font_weight("bold").text_color("slate-900")
          end.bg("white").rounded("2xl").p(4)
        end
      end
    RUBY

    diagnostics = SwiftUi::Lint.call(path)
    errors = diagnostics.select { |d| d.severity == "error" }

    assert_empty errors, "healthy file produced: #{errors.map(&:message)}"
  end

  test "accepts semantic classes from the framework stylesheet" do
    path = write_fixture("framework_styles_component.rb", <<~RUBY)
      class LintFrameworkStylesComponent < ApplicationComponent
        swift_ui do
          text("status").foreground_style(:secondary)
        end
      end
    RUBY

    diagnostics = SwiftUi::Lint.call(path)
    missing_classes = diagnostics.select { |diagnostic| diagnostic.code == "missing_tailwind_class" }

    assert_empty diagnostics.select { |diagnostic| diagnostic.severity == "error" }
    assert_empty missing_classes.select { |diagnostic| diagnostic.message.include?("swift-ui-foreground-secondary") }
  ensure
    Object.send(:remove_const, :LintFrameworkStylesComponent) if Object.const_defined?(:LintFrameworkStylesComponent, false)
  end

  test "exempts only registered structural hooks from compiled CSS checks" do
    path = write_fixture("structural_hooks_component.rb", <<~RUBY)
      class LintStructuralHooksComponent < ApplicationComponent
        swift_ui do
          vstack do
            div("chart").tw("swift-ui-chart")
            div("unknown").tw("swift-ui-unregistered-hook")
          end
        end
      end
    RUBY

    missing = SwiftUi::Lint.call(path).select { |diagnostic| diagnostic.code == "missing_tailwind_class" }

    refute missing.any? { |diagnostic| diagnostic.message.include?("swift-ui-chart`") }
    assert missing.any? { |diagnostic| diagnostic.message.include?("swift-ui-unregistered-hook") }
  ensure
    Object.send(:remove_const, :LintStructuralHooksComponent) if Object.const_defined?(:LintStructuralHooksComponent, false)
  end

  test "checks arbitrary-value utilities instead of skipping bracket tokens" do
    path = write_fixture("arbitrary_utilities_component.rb", <<~RUBY)
      class LintArbitraryUtilitiesComponent < ApplicationComponent
        swift_ui do
          vstack do
            div("compiled").tw("h-[300px]")
            div("missing").tw("lint-arbitrary-[missing]")
          end
        end
      end
    RUBY

    missing = SwiftUi::Lint.call(path).select { |diagnostic| diagnostic.code == "missing_tailwind_class" }

    refute missing.any? { |diagnostic| diagnostic.message.include?("h-[300px]") }
    assert missing.any? { |diagnostic| diagnostic.message.include?("lint-arbitrary-[missing]") }
  ensure
    Object.send(:remove_const, :LintArbitraryUtilitiesComponent) if Object.const_defined?(:LintArbitraryUtilitiesComponent, false)
  end

  test "reports each genuinely missing CSS class once across fixture renders" do
    path = write_fixture("missing_css_component.rb", <<~RUBY)
      class LintMissingCssComponent < ApplicationComponent
        swift_ui do
          vstack do
            text("first").tw("lint-class-without-css")
            text("second").tw("lint-class-without-css")
          end
        end
      end
    RUBY

    diagnostics = SwiftUi::Lint.call(path)
    missing_classes = diagnostics.select do |diagnostic|
      diagnostic.code == "missing_tailwind_class" && diagnostic.message.include?("lint-class-without-css")
    end

    assert_equal 1, missing_classes.length
  ensure
    Object.send(:remove_const, :LintMissingCssComponent) if Object.const_defined?(:LintMissingCssComponent, false)
  end

  test "does not flag plain-Ruby chain methods or helper-rooted chains" do
    path = write_fixture("ruby_chains_component.rb", <<~RUBY)
      class LintRubyChainsComponent < ApplicationComponent
        swift_ui do
          text("hi").tw("x").then { |el| el }
          helper_built_thing.some_app_method("y")
        end
      end
    RUBY

    diagnostics = SwiftUi::Lint.call(path)

    assert_empty diagnostics.select { |d| d.code == "unknown_modifier" }
  end

  test "missing files yield a single diagnostic instead of an exception" do
    diagnostics = SwiftUi::Lint.call("tmp/lint_fixtures/nope.rb")

    assert_equal 1, diagnostics.length
    assert_equal "file_missing", diagnostics.first.code
  end

  test "required props without a deterministic fixture are a hard error" do
    path = write_fixture("uncovered_component.rb", <<~RUBY)
      class LintUncoveredComponent < ApplicationComponent
        prop :records, type: Array, required: true

        swift_ui do
          text(records.length.to_s)
        end
      end
    RUBY

    diagnostics = SwiftUi::Lint.call(path)
    finding = diagnostics.find { |diagnostic| diagnostic.code == "fixture_missing" }

    assert finding
    assert_equal "error", finding.severity
    assert_match(/records/, finding.hint)
  ensure
    Object.send(:remove_const, :LintUncoveredComponent) if Object.const_defined?(:LintUncoveredComponent, false)
  end

  test "a component DSL block executes once while lint validates and renders its IR" do
    path = write_fixture("single_execution_component.rb", <<~RUBY)
      class LintSingleExecutionComponent < ApplicationComponent
        class << self
          attr_accessor :executions
        end
        self.executions = 0

        swift_ui do
          @component.class.executions += 1
          text("one pass")
        end
      end
    RUBY

    diagnostics = SwiftUi::Lint.call(path)

    assert_empty diagnostics.select { |diagnostic| diagnostic.severity == "error" }
    assert_equal 1, LintSingleExecutionComponent.executions
  ensure
    Object.send(:remove_const, :LintSingleExecutionComponent) if Object.const_defined?(:LintSingleExecutionComponent, false)
  end

  test "story lint executes every public variant rather than only default" do
    path = write_fixture("all_variants_stories.rb", <<~RUBY)
      class LintStoryProbeComponent < ApplicationComponent
        prop :label, type: String, default: "story"

        swift_ui do
          text(label)
        end
      end

      class LintAllVariantsStories < ViewComponent::Storybook::Stories
        class << self
          attr_accessor :executions
        end
        self.executions = []

        def first_variant
          self.class.executions << :first_variant
          LintStoryProbeComponent.new(label: "first")
        end

        def second_variant
          self.class.executions << :second_variant
          LintStoryProbeComponent.new(label: "second")
        end
      end
    RUBY

    diagnostics = SwiftUi::Lint.call(path)

    assert_empty diagnostics.select { |diagnostic| diagnostic.severity == "error" }
    assert_equal %i[first_variant second_variant], LintAllVariantsStories.executions
  ensure
    Object.send(:remove_const, :LintAllVariantsStories) if Object.const_defined?(:LintAllVariantsStories, false)
    Object.send(:remove_const, :LintStoryProbeComponent) if Object.const_defined?(:LintStoryProbeComponent, false)
  end
end
