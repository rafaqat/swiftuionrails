require "test_helper"

class SpacingConverterTest < ActiveSupport::TestCase
  test "converts pixel values to Tailwind spacing" do
    converter = SwiftUIRails::Tailwind::SpacingConverter

    # Test pixel_value? method
    assert converter.pixel_value?(16), "16 should be considered a pixel value"
    assert converter.pixel_value?(8), "8 should be considered a pixel value"
    assert_not converter.pixel_value?(4), "4 should not be considered a pixel value"
    assert_not converter.pixel_value?(2), "2 should not be considered a pixel value"

    # Test convert method
    assert_equal "4", converter.convert(16), "16px should convert to 4"
    assert_equal "2", converter.convert(8), "8px should convert to 2"
    assert_equal "1", converter.convert(4), "4px should convert to 1"
    assert_equal "px", converter.convert(1), "1px should convert to px"
  end

  test "button renders with correct spacing classes" do
    class TestButton < ApplicationComponent
      include SwiftUIRails::DSL

      def call
        swift_ui do
          button("Test").px(16).py(8)
        end
      end
    end

    html = TestButton.new.call.to_s
    puts "\nRendered HTML: #{html}"

    # Check that the HTML contains the correct classes
    assert_match /px-4/, html, "Should have px-4 (not px-16)"
    assert_match /py-2/, html, "Should have py-2 (not py-8)"
  end
end
