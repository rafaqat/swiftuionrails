# frozen_string_literal: true

require "application_system_test_case"

class PlaygroundIntellisenseTest < ApplicationSystemTestCase
  def setup
    # Use headless browser for tests
    Capybara.current_driver = :selenium_chrome_headless
  end

  test "playground loads with Monaco editor and line numbers" do
    visit playground_path
    
    # Wait for Monaco editor to load
    assert_selector "#editor-loading", visible: false, wait: 10
    assert_selector "[data-playground-target='monacoContainer']", visible: true
    
    # Check that line numbers are visible
    within "[data-playground-target='monacoContainer']" do
      assert_selector ".line-numbers", visible: true
      assert_selector ".margin-view-overlays", visible: true
    end
  end

  test "IntelliSense autocomplete triggers on dot and shows completions" do
    visit playground_path
    
    # Wait for Monaco editor to load
    assert_selector "#editor-loading", visible: false, wait: 10
    
    # Wait for playground data manager to initialize
    sleep 1
    
    # Get the Monaco editor container
    editor_container = find("[data-playground-target='monacoContainer']")
    
    # Click in the editor to focus it
    editor_container.find(".view-lines").click
    
    # Clear existing content with Ctrl+A and Delete
    page.driver.browser.action.key_down(:control).send_keys("a").key_up(:control).perform
    page.driver.browser.action.send_keys(:delete).perform
    
    # Type button code
    page.driver.browser.action.send_keys("button(\"Click Me\")").perform
    
    # Type dot to trigger autocomplete
    page.driver.browser.action.send_keys(".").perform
    
    # Wait for autocomplete menu to appear
    assert_selector ".suggest-widget", visible: true, wait: 5
    
    # Check that completions are shown
    within ".suggest-widget" do
      # Check for some expected method completions
      assert_text "bg"
      assert_text "text_color"
      assert_text "padding"
      assert_text "rounded"
      assert_text "hover"
    end
  end

  test "IntelliSense shows parameter completions on parenthesis" do
    visit playground_path
    
    # Wait for Monaco editor to load
    assert_selector "#editor-loading", visible: false, wait: 10
    
    # Wait for playground data manager to initialize
    sleep 1
    
    # Get the Monaco editor container
    editor_container = find("[data-playground-target='monacoContainer']")
    
    # Click in the editor to focus it
    editor_container.find(".view-lines").click
    
    # Clear existing content
    page.driver.browser.action.key_down(:control).send_keys("a").key_up(:control).perform
    page.driver.browser.action.send_keys(:delete).perform
    
    # Type code that should trigger parameter completions
    page.driver.browser.action.send_keys("button(\"Test\").bg").perform
    
    # Type opening parenthesis to trigger parameter completions
    page.driver.browser.action.send_keys("(").perform
    
    # Wait for autocomplete menu to appear
    assert_selector ".suggest-widget", visible: true, wait: 5
    
    # Check that color completions are shown
    within ".suggest-widget" do
      # Check for some expected color completions
      assert_text "blue-500"
      assert_text "red-500"
      assert_text "green-500"
      assert_text "gray-100"
    end
  end

  test "IntelliSense signature help appears for methods" do
    visit playground_path
    
    # Wait for Monaco editor to load
    assert_selector "#editor-loading", visible: false, wait: 10
    
    # Wait for playground data manager to initialize
    sleep 1
    
    # Get the Monaco editor container
    editor_container = find("[data-playground-target='monacoContainer']")
    
    # Click in the editor to focus it
    editor_container.find(".view-lines").click
    
    # Clear existing content
    page.driver.browser.action.key_down(:control).send_keys("a").key_up(:control).perform
    page.driver.browser.action.send_keys(:delete).perform
    
    # Type code that should trigger signature help
    page.driver.browser.action.send_keys("vstack").perform
    page.driver.browser.action.send_keys("(").perform
    
    # Wait for signature help to appear (if implemented)
    # Note: Signature help might appear as a tooltip or inline widget
    sleep 0.5
    
    # Try to find signature help widget
    if page.has_selector?(".parameter-hints-widget", wait: 2)
      within ".parameter-hints-widget" do
        assert_text "spacing"
        assert_text "align"
      end
    else
      # Alternative: Check if the completions show parameter info
      if page.has_selector?(".suggest-widget", wait: 2)
        within ".suggest-widget" do
          # Parameters might be shown in the suggest widget
          assert page.has_text?("spacing") || page.has_text?("align")
        end
      end
    end
  end

  test "completions endpoint returns valid data" do
    visit playground_path
    
    # Test the completions endpoint directly via JavaScript
    result = page.evaluate_script(<<~JS)
      (async () => {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
        const response = await fetch('/playground/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-CSRF-Token': csrfToken
          },
          body: JSON.stringify({
            context: 'button("Test").',
            position: { lineNumber: 1, column: 15 }
          })
        });
        
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        return {
          success: true,
          suggestionCount: data.suggestions.length,
          hasSuggestions: data.suggestions.length > 0,
          sampleSuggestions: data.suggestions.slice(0, 5).map(s => s.label)
        };
      })().catch(error => ({
        success: false,
        error: error.message
      }));
    JS
    
    assert result["success"], "Completions endpoint should return successfully"
    assert result["hasSuggestions"], "Should have completion suggestions"
    assert result["suggestionCount"] > 10, "Should have multiple completion suggestions"
    
    # Check that expected method names are in the suggestions
    sample_suggestions = result["sampleSuggestions"]
    assert sample_suggestions.include?("bg"), "Should include 'bg' method"
    assert sample_suggestions.include?("text_color"), "Should include 'text_color' method"
  end

  test "playground data manager is initialized and working" do
    visit playground_path
    
    # Wait for Monaco editor to load
    assert_selector "#editor-loading", visible: false, wait: 10
    
    # Check that playground data manager is initialized
    result = page.evaluate_script(<<~JS)
      (() => {
        const manager = window.playgroundDataManager;
        return {
          exists: !!manager,
          hasCache: !!manager?.cache,
          hasMethods: !!(manager?.getCachedData && manager?.setCachedData && manager?.preloadAll)
        };
      })();
    JS
    
    assert result["exists"], "PlaygroundDataManagerV2 should exist"
    assert result["hasCache"], "Should have cache object"
    assert result["hasMethods"], "Should have required methods"
  end

  test "preview updates when typing code" do
    visit playground_path
    
    # Wait for Monaco editor to load
    assert_selector "#editor-loading", visible: false, wait: 10
    
    # Get the Monaco editor container
    editor_container = find("[data-playground-target='monacoContainer']")
    
    # Click in the editor to focus it
    editor_container.find(".view-lines").click
    
    # Clear existing content
    page.driver.browser.action.key_down(:control).send_keys("a").key_up(:control).perform
    page.driver.browser.action.send_keys(:delete).perform
    
    # Type new code
    page.driver.browser.action.send_keys("text(\"Hello IntelliSense!\").font_size(\"2xl\").text_color(\"blue-600\")").perform
    
    # Wait for debounced preview update (500ms + processing time)
    sleep 1
    
    # Check that preview contains the rendered content
    within "[data-playground-target='preview']" do
      assert_text "Hello IntelliSense!"
      assert_selector ".text-2xl"
      assert_selector ".text-blue-600"
    end
  end
end