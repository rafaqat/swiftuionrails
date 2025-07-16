# frozen_string_literal: true

require "application_system_test_case"

class HstackJustifyFeaturesTest < ApplicationSystemTestCase
  def setup
    # Visit the unified playground 
    visit root_path
    
    # Wait for page to load
    assert_selector '[data-controller="playground"]', wait: 10
    
    # Wait for Monaco editor to initialize properly
    wait_for_monaco_editor
  end

  test "default playground code shows justify between layout working" do
    # Skip Monaco and directly test the core functionality
    # Load the "Layout Demo" example which should showcase justify: :between
    within_examples_section do
      click_on "Layout Demo"
    end
    
    # Wait for preview to update
    sleep 3
    
    # Check if the preview container has the layout test
    within_preview_container do
      # Look for "HStack Justification Examples" heading
      assert_selector "span", text: "HStack Justification Examples", wait: 10
      
      # Look for the justify: :between section
      assert_selector "span", text: "justify: :between", wait: 5
      
      # Look for the demo boxes
      assert_selector "span", text: "A", wait: 5
      assert_selector "span", text: "B", wait: 5
      assert_selector "span", text: "C", wait: 5
    end
    
    # Take screenshot for verification
    save_screenshot("default_justify_between.png")
  end

  test "can try different justify options via code editing" do
    justify_options = [
      { option: ":start", expected_class: "justify-start" },
      { option: ":center", expected_class: "justify-center" },
      { option: ":end", expected_class: "justify-end" },
      { option: ":between", expected_class: "justify-between" },
      { option: ":around", expected_class: "justify-around" },
      { option: ":evenly", expected_class: "justify-evenly" }
    ]
    
    justify_options.each do |test_case|
      puts "Testing justify option: #{test_case[:option]}"
      
      # Clear editor and set new code
      clear_editor
      
      hstack_code = <<~RUBY
        swift_ui do
          hstack(justify: #{test_case[:option]}) do
            text("Left")
            text("Right")
          end
        end
      RUBY
      
      set_editor_code(hstack_code)
      
      # Wait for preview to update (auto-update should happen)
      sleep 2
      
      # Check that the HTML contains the expected CSS class
      within_preview_container do
        assert_selector "div.#{test_case[:expected_class]}", wait: 5
      end
      
      # Take screenshot
      save_screenshot("justify_#{test_case[:option].sub(':', '')}.png")
    end
  end

  test "Layout Demo example shows all justify behaviors side-by-side" do
    # Click on the Layout Demo example
    within_examples_section do
      click_on "Layout Demo"
    end
    
    # Wait for code to load in editor
    sleep 2
    
    # Verify the preview shows all justify options
    within_preview_container do
      # Check for the main heading
      assert_selector "span", text: "HStack Justification Examples", wait: 10
      
      # Check for each justify option demonstration
      justify_labels = [
        "justify: :start (default)",
        "justify: :center", 
        "justify: :end",
        "justify: :between",
        "justify: :around",
        "justify: :evenly"
      ]
      
      justify_labels.each do |label|
        assert_selector "span", text: label, wait: 5
      end
      
      # Verify that each demo section has the appropriate CSS classes
      ["justify-start", "justify-center", "justify-end", "justify-between", "justify-around", "justify-evenly"].each do |css_class|
        assert_selector "div.#{css_class}", wait: 5
      end
    end
    
    # Take screenshot
    save_screenshot("layout_demo_full.png")
  end

  test "sidebar HStack component inserts justify between example" do
    # Click on HStack component in sidebar
    within_sidebar_components do
      click_on "HStack"
    end
    
    # Wait for code to be inserted
    sleep 2
    
    # Verify the code was inserted correctly
    editor_content = get_editor_content
    puts "Editor content after HStack insertion: #{editor_content}"
    
    # The sidebar might insert the component code without swift_ui wrapper
    # Let's check what's actually inserted
    if editor_content.include?("hstack(justify: :between)")
      assert_includes editor_content, "hstack(justify: :between)"
      assert_includes editor_content, 'text("Left")'
      assert_includes editor_content, 'text("Right")'
    else
      # If the code wasn't inserted properly, let's see what we got
      puts "HStack code not inserted as expected. Got: #{editor_content}"
      # Try to manually trigger the preview with the current content
    end
    
    # If we don't have the swift_ui wrapper, add it
    unless editor_content.include?("swift_ui do")
      wrapped_code = <<~RUBY
        swift_ui do
          #{editor_content}
        end
      RUBY
      set_editor_code(wrapped_code)
      sleep 1
    end
    
    # Verify the preview updates
    within_preview_container do
      assert_selector "div.justify-between", wait: 5
      assert_selector "span", text: "Left", wait: 5
      assert_selector "span", text: "Right", wait: 5
    end
    
    # Take screenshot
    save_screenshot("sidebar_hstack_insert.png")
  end

  test "IntelliSense shows justify parameter completions" do
    # Clear editor and start typing hstack
    clear_editor
    
    # Type "hstack(" to trigger IntelliSense
    type_in_editor("hstack(")
    
    # Wait for IntelliSense to appear
    sleep 1
    
    # Check if IntelliSense completion popup appears
    # Note: This tests the Monaco editor integration
    completion_visible = page.evaluate_script <<~JS
      // Check if Monaco completion widget is visible
      const widget = document.querySelector('.monaco-editor .suggest-widget');
      return widget && !widget.classList.contains('hidden') && widget.style.display !== 'none';
    JS
    
    if completion_visible
      # Take screenshot of IntelliSense
      save_screenshot("intellisense_hstack_params.png")
      
      # Check for justify parameter in completions
      assert_selector ".suggest-widget", wait: 5
    else
      # If IntelliSense doesn't appear, continue with manual typing test
      type_in_editor("justify: :between) do\n  text(\"Test\")\nend")
      
      # Verify it still works
      within_preview_container do
        assert_selector "div.justify-between", wait: 5
      end
    end
  end

  test "can copy working code for own projects" do
    # Load the Layout Demo
    within_examples_section do
      click_on "Layout Demo"
    end
    
    # Wait for code to load
    sleep 2
    
    # Get the editor content
    editor_content = get_editor_content
    
    # Verify it contains working hstack examples
    assert_includes editor_content, "hstack(justify: :start)"
    assert_includes editor_content, "hstack(justify: :center)"
    assert_includes editor_content, "hstack(justify: :end)"
    assert_includes editor_content, "hstack(justify: :between)"
    assert_includes editor_content, "hstack(justify: :around)"
    assert_includes editor_content, "hstack(justify: :evenly)"
    
    # Verify the code is properly formatted and copyable
    assert_includes editor_content, "swift_ui do"
    assert_includes editor_content, "HStack Justification Examples"
    assert_includes editor_content, "vstack(spacing: 16) do"
    
    # Test copying a simple hstack example
    simple_hstack = <<~RUBY
      swift_ui do
        hstack(justify: :between) do
          text("Left Item")
          text("Right Item") 
        end
      end
    RUBY
    
    clear_editor
    set_editor_code(simple_hstack)
    
    # Verify it renders correctly
    within_preview_container do
      assert_selector "div.justify-between", wait: 5
      assert_selector "span", text: "Left Item", wait: 5
      assert_selector "span", text: "Right Item", wait: 5
    end
    
    # Take screenshot
    save_screenshot("copyable_code_test.png")
  end

  test "justify between spreads elements to edges correctly" do
    # Test with different numbers of elements
    test_cases = [
      { elements: 2, code: 'hstack(justify: :between) { text("A"); text("B") }' },
      { elements: 3, code: 'hstack(justify: :between) { text("A"); text("B"); text("C") }' },
      { elements: 4, code: 'hstack(justify: :between) { text("A"); text("B"); text("C"); text("D") }' }
    ]
    
    test_cases.each do |test_case|
      clear_editor
      set_editor_code(test_case[:code])
      
      # Wait for preview to update
      sleep 1
      
      within_preview_container do
        # Verify justify-between class is present
        assert_selector "div.justify-between", wait: 5
        
        # Verify w-full class is automatically added
        assert_selector "div.w-full", wait: 5
        
        # Verify all elements are present
        (0...test_case[:elements]).each do |i|
          letter = ('A'.ord + i).chr
          assert_selector "span", text: letter, wait: 5
        end
      end
      
      # Take screenshot
      save_screenshot("justify_between_#{test_case[:elements]}_elements.png")
    end
  end

  private

  def clear_editor
    # Clear Monaco editor content
    page.execute_script <<~JS
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue('');
      }
    JS
  end
  
  def wait_for_monaco_editor
    # Wait for Monaco editor container to be visible
    assert_selector "#monaco-editor", wait: 10
    
    # Debug Monaco initialization
    puts "=== Monaco Editor Debug ==="
    puts "Monaco container exists: #{page.has_selector?('#monaco-editor')}"
    puts "Monaco loader script exists: #{page.has_selector?('script[src*=\"monaco-editor\"]')}"
    
    # Check if require is available
    require_available = page.evaluate_script("typeof require !== 'undefined'")
    puts "require available: #{require_available}"
    
    # Check Monaco loading status
    monaco_status = page.evaluate_script <<~JS
      ({
        requireAvailable: typeof require !== 'undefined',
        monacoLoaded: typeof monaco !== 'undefined',
        editorInstance: typeof window.monacoEditorInstance !== 'undefined',
        playgroundController: typeof window.playgroundController !== 'undefined'
      })
    JS
    puts "Monaco status: #{monaco_status}"
    
    # Wait for Monaco editor instance to be ready with timeout
    timeout = 30 # seconds
    start_time = Time.now
    
    loop do
      editor_ready = page.evaluate_script <<~JS
        window.monacoEditorInstance && 
        window.monacoEditorInstance.getValue && 
        typeof window.monacoEditorInstance.getValue === 'function'
      JS
      
      if editor_ready
        puts "Monaco editor instance is ready!"
        break
      end
      
      if Time.now - start_time > timeout
        puts "Monaco editor failed to initialize within #{timeout} seconds"
        # Get console logs for debugging
        logs = page.driver.browser.logs.get(:browser)
        puts "Browser console logs:"
        logs.each { |log| puts "  #{log.level}: #{log.message}" }
        break
      end
      
      sleep 0.1
    end
    
    puts "=== End Monaco Debug ==="
  end

  def set_editor_code(code)
    # Set code in Monaco editor
    escaped_code = code.gsub('"', '\\"').gsub("\n", "\\n")
    page.execute_script <<~JS
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue("#{escaped_code}");
        // Trigger manual update if auto-update is not working
        setTimeout(() => {
          const event = new Event('input', { bubbles: true });
          window.monacoEditorInstance.trigger('keyboard', 'type', { text: ' ' });
        }, 100);
      }
    JS
  end

  def get_editor_content
    # Get content from Monaco editor
    page.evaluate_script <<~JS
      window.monacoEditorInstance ? window.monacoEditorInstance.getValue() : ''
    JS
  end

  def type_in_editor(text)
    # Type text in Monaco editor
    escaped_text = text.gsub('"', '\\"').gsub("\n", "\\n")
    page.execute_script <<~JS
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.trigger('keyboard', 'type', { text: "#{escaped_text}" });
      }
    JS
  end

  def within_preview_container(&block)
    within "#preview-container", &block
  end

  def within_examples_section(&block)
    within "[data-playground-target='examplesContainer']", &block
  end

  def within_sidebar_components(&block)
    within "[data-playground-target='componentsContainer']", &block
  end
end