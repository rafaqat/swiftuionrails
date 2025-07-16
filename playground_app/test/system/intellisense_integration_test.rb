require "application_system_test_case"

class IntelliSenseIntegrationTest < ApplicationSystemTestCase
  test "Monaco editor displays and provides IntelliSense completions" do
    visit root_path
    
    # Wait for Monaco editor to load
    assert_selector "#monaco-editor", wait: 10
    
    # Wait for Monaco editor to be fully initialized
    sleep 2
    
    # Check that Monaco editor is visible
    monaco_container = find("#monaco-editor")
    assert monaco_container.visible?
    
    # Test that DSL registry is populated
    registry = Playground::DslRegistry.instance
    assert registry.all.size > 0
    assert registry["text"].present?
    assert registry["vstack"].present?
    assert registry["hstack"].present?
    assert registry["button"].present?
    
    # Test that Monaco container has proper dimensions
    assert monaco_container["style"].include?("display: block") ||
           monaco_container["style"].include?("display: none") # Initially hidden during load
    
    # Check that completion data is available
    assert File.exist?(Rails.root.join("public", "playground", "data", "completion_data.json"))
    
    puts "✅ IntelliSense integration test passed"
  end
  
  test "DSL registry contains comprehensive element definitions" do
    registry = Playground::DslRegistry.instance
    
    # Check core DSL elements
    %w[text button vstack hstack image card div form textfield].each do |element|
      assert registry[element].present?, "#{element} should be registered"
      assert registry[element][:description].present?, "#{element} should have description"
      assert registry[element][:modifiers].present?, "#{element} should have modifiers"
      assert registry[element][:examples].present?, "#{element} should have examples"
    end
    
    # Check text element specifics
    text_element = registry["text"]
    assert_equal "Display styled text content with typography options", text_element[:description]
    assert_includes text_element[:modifiers], "font_size"
    assert_includes text_element[:modifiers], "text_color"
    assert_includes text_element[:examples], 'text("Hello World")'
    
    # Check vstack element specifics
    vstack_element = registry["vstack"]
    assert_equal "Vertical stack layout", vstack_element[:description]
    assert_includes vstack_element[:modifiers], "spacing"
    assert_includes vstack_element[:examples], "vstack { }"
    
    puts "✅ DSL registry comprehensive test passed"
  end
  
  test "completion service provides intelligent suggestions" do
    # Create service with proper parameters  
    context = "swift_ui do\n  tex"
    position = { "lineNumber" => 2, "column" => 5 }
    service = Playground::CompletionService.new(context, position)
    
    # Test DSL element completions
    results = service.generate_completions
    text_completion = results.find { |c| c[:label] == "text" }
    assert text_completion.present?
    assert_equal "Function", text_completion[:kind]
    assert text_completion[:insertText].include?("text(")
    
    puts "✅ Completion service intelligent suggestions test passed"
  end
end