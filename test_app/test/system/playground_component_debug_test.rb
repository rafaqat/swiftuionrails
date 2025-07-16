# frozen_string_literal: true

require "application_system_test_case"

class PlaygroundComponentDebugTest < ApplicationSystemTestCase
  def setup
    @test_start_time = Time.current
    puts "\n" + "="*80
    puts "🔍 PLAYGROUND COMPONENT DEBUG TEST - #{@test_start_time}"
    puts "="*80
  end

  test "debug playground component rendering step by step" do
    puts "\n📋 Starting playground component debug..."
    
    # Visit the playground
    visit "/playground"
    
    # Take initial screenshot
    save_screenshot("01_debug_initial_load.png")
    puts "✅ Initial page loaded"
    
    # Debug step 1: Check if main container exists
    debug_main_container
    
    # Debug step 2: Check if controller is attached
    debug_stimulus_controller
    
    # Debug step 3: Check if component data exists
    debug_component_data
    
    # Debug step 4: Check server-side rendering
    debug_server_rendering
    
    puts "\n🎯 Debug complete!"
  end

  private

  def debug_main_container
    puts "\n🔍 DEBUG 1: Main Container Check"
    
    # Check if the main playground container exists
    if has_selector?("[data-controller='playground']")
      puts "✅ Main playground container found"
      
      # Check its classes
      container_classes = page.evaluate_script("document.querySelector('[data-controller=\"playground\"]').className")
      puts "📊 Container classes: #{container_classes}"
      
      # Check its HTML content
      container_html = page.evaluate_script("document.querySelector('[data-controller=\"playground\"]').innerHTML")
      puts "📊 Container HTML length: #{container_html.length} chars"
      puts "📊 Container HTML preview: #{container_html[0..200]}..."
      
      # Check if it's empty
      if container_html.strip.empty?
        puts "❌ Container is EMPTY!"
      else
        puts "✅ Container has content"
      end
    else
      puts "❌ Main playground container NOT found!"
    end
    
    save_screenshot("02_debug_main_container.png")
  end

  def debug_stimulus_controller
    puts "\n🔍 DEBUG 2: Stimulus Controller Check"
    
    # Check if Stimulus has loaded
    stimulus_loaded = page.evaluate_script("typeof Stimulus !== 'undefined'")
    puts "📊 Stimulus loaded: #{stimulus_loaded}"
    
    # Check if playground controller exists
    playground_controller_exists = page.evaluate_script("
      const app = window.Stimulus || window.Application;
      if (app && app.router && app.router.modulesByIdentifier) {
        return app.router.modulesByIdentifier.has('playground');
      }
      return false;
    ")
    puts "📊 Playground controller registered: #{playground_controller_exists}"
    
    # Check if controller is connected
    controller_connected = page.evaluate_script("
      const element = document.querySelector('[data-controller=\"playground\"]');
      return element && element.classList.contains('stimulus-connected');
    ")
    puts "📊 Controller connected: #{controller_connected}"
    
    save_screenshot("03_debug_stimulus_controller.png")
  end

  def debug_component_data
    puts "\n🔍 DEBUG 3: Component Data Check"
    
    # Check if we can access Rails controller data
    begin
      # Try to make a simple request to the controller
      page.evaluate_script("
        fetch('/playground/preview', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name=\"csrf-token\"]').content
          },
          body: JSON.stringify({code: 'text(\"test\")'})
        }).then(response => {
          console.log('Controller response:', response.status);
          return response.text();
        }).then(text => {
          console.log('Controller response text:', text);
        }).catch(error => {
          console.error('Controller error:', error);
        });
      ")
      
      puts "✅ Made test request to controller"
    rescue => e
      puts "❌ Failed to make request: #{e.message}"
    end
    
    save_screenshot("04_debug_component_data.png")
  end

  def debug_server_rendering
    puts "\n🔍 DEBUG 4: Server-Side Rendering Check"
    
    # Get the full HTML source
    full_html = page.html
    puts "📊 Full HTML length: #{full_html.length} chars"
    
    # Check if our component classes are in the HTML
    has_playground_component = full_html.include?("PlaygroundV2Component")
    has_header_component = full_html.include?("HeaderComponent")
    has_sidebar_component = full_html.include?("SidebarComponent")
    has_editor_component = full_html.include?("EditorPanelComponent")
    has_preview_component = full_html.include?("PreviewPanelComponent")
    
    puts "📊 Contains PlaygroundV2Component: #{has_playground_component}"
    puts "📊 Contains HeaderComponent: #{has_header_component}"
    puts "📊 Contains SidebarComponent: #{has_sidebar_component}"
    puts "📊 Contains EditorPanelComponent: #{has_editor_component}"
    puts "📊 Contains PreviewPanelComponent: #{has_preview_component}"
    
    # Check for any error messages
    has_error = full_html.include?("error") || full_html.include?("Error") || full_html.include?("exception")
    puts "📊 Contains error messages: #{has_error}"
    
    # Search for specific content we expect
    has_header_text = full_html.include?("SwiftUI Rails Playground")
    has_monaco_editor = full_html.include?("monaco-editor")
    has_editor_loading = full_html.include?("editor-loading")
    
    puts "📊 Contains header text: #{has_header_text}"
    puts "📊 Contains Monaco editor: #{has_monaco_editor}"
    puts "📊 Contains editor loading: #{has_editor_loading}"
    
    # Save a portion of the HTML for inspection
    body_start = full_html.index("<body>")
    body_end = full_html.index("</body>")
    if body_start && body_end
      body_content = full_html[body_start..body_end]
      puts "📊 Body content length: #{body_content.length} chars"
      puts "📊 Body content preview: #{body_content[0..500]}..."
    end
    
    save_screenshot("05_debug_server_rendering.png")
  end
end