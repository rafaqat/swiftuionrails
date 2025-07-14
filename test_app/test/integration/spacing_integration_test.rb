require "test_helper"

class SpacingIntegrationTest < ActionDispatch::IntegrationTest
  test "button DSL converts pixel values to Tailwind spacing" do
    # Create a test component
    test_component = Class.new(ApplicationComponent) do
      include SwiftUIRails::DSL
      include SwiftUIRails::Helpers

      def call
        swift_ui do
          button("Test Button")
            .px(16)
            .py(8)
            .bg("blue-500")
        end
      end
    end

    # Render the component
    html = test_component.new.call.to_s

    puts "\n=== Component HTML Output ==="
    puts html
    puts "=== End HTML ===\n"

    # Check the output
    assert_match /<button/, html, "Should contain a button element"
    assert_match /Test Button/, html, "Should contain the button text"

    # These should be converted
    assert_match /px-4/, html, "px(16) should convert to px-4"
    assert_match /py-2/, html, "py(8) should convert to py-2"

    # These should NOT appear
    assert_no_match /px-16/, html, "Should not contain px-16"
    assert_no_match /py-8/, html, "Should not contain py-8"
  end
end
