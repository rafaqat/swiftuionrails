# frozen_string_literal: true

require "test_helper"
require "open3"

class SwiftUIRails::OptionalStorybookTest < ActiveSupport::TestCase
  test "loads the Storybook integration when its optional provider is present" do
    assert SwiftUIRails.storybook_available?
    assert_operator SwiftUIRails::Storybook::Stories, :<, ViewComponent::Storybook::Stories
    assert_operator SwiftUIRails::Storybook::Stories, :<, SwiftUIRails::Storybook::Helpers
  end

  test "loads the core gem when the optional Storybook provider is absent" do
    library_path = Rails.root.join("..", "lib").expand_path
    script = <<~RUBY
      require "rails"
      require "action_view"
      require "view_component"
      require "active_support/all"

      module RejectOptionalStorybook
        def require(feature)
          if feature == "view_component/storybook"
            error = LoadError.new("cannot load such file -- \#{feature}")
            error.define_singleton_method(:path) { feature }
            raise error
          end

          super
        end
      end

      Kernel.prepend(RejectOptionalStorybook)
      $LOAD_PATH.unshift(#{library_path.to_s.inspect})
      require "swift_ui_rails"

      abort "Storybook integration leaked into core" if SwiftUIRails.const_defined?(:Storybook, false)
      abort "Storybook reported available" if SwiftUIRails.storybook_available?
      puts "core-loaded-without-storybook"
    RUBY

    stdout, stderr, status = Open3.capture3(
      { "DISABLE_BOOTSNAP" => "1", "RAILS_ENV" => "production" },
      Gem.ruby,
      "-e",
      script,
      chdir: Rails.root.to_s
    )

    assert status.success?, stderr
    assert_equal "core-loaded-without-storybook\n", stdout
  end
end
