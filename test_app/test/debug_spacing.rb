require "test_helper"

class DebugSpacingTest < ActiveSupport::TestCase
  test "debug spacing conversion" do
    puts "\n=== DEBUG SPACING CONVERSION ==="

    # Check if SpacingConverter is loaded
    puts "SpacingConverter defined? #{defined?(SwiftUIRails::Tailwind::SpacingConverter)}"

    if defined?(SwiftUIRails::Tailwind::SpacingConverter)
      converter = SwiftUIRails::Tailwind::SpacingConverter
      puts "pixel_value?(16): #{converter.pixel_value?(16)}"
      puts "convert(16): #{converter.convert(16)}"
    end

    # Check if the method is using SpacingConverter
    test_obj = Object.new
    test_obj.extend(SwiftUIRails::Tailwind::Modifiers)
    test_obj.instance_eval { @css_classes = [] }

    # Call px method
    test_obj.px(16)

    # Check what classes were added
    puts "CSS classes after px(16): #{test_obj.instance_variable_get(:@css_classes).inspect}"

    puts "=== END DEBUG ===\n"
  end
end
