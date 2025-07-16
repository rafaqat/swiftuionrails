# frozen_string_literal: true

require "application_system_test_case"

class PlaygroundMonacoDiagnosisTest < ApplicationSystemTestCase
  def setup
    @test_start_time = Time.current
    puts "\n" + "="*80
    puts "🔍 MONACO EDITOR DIAGNOSIS TEST - #{@test_start_time}"
    puts "="*80
  end

  test "comprehensive Monaco editor loading diagnosis with probes and screenshots" do
    puts "\n📋 Starting comprehensive Monaco editor diagnosis..."
    
    # Visit the playground
    visit "/playground"
    
    # Take initial screenshot
    save_screenshot("01_initial_page_load.png")
    puts "✅ Initial page loaded - screenshot saved"
    
    # Check page title and basic structure
    assert_selector "h1", text: "SwiftUI Rails Playground"
    puts "✅ Page title confirmed"
    
    # Probe 1: Check if the editor loading div exists
    probe_loading_ui_existence
    
    # Probe 2: Check Monaco editor container
    probe_monaco_container
    
    # Probe 3: Check dimensions and CSS
    probe_editor_dimensions
    
    # Probe 4: Check JavaScript loading
    probe_javascript_status
    
    # Probe 5: Wait for Monaco to load with detailed monitoring
    monitor_monaco_loading_with_probes
    
    # Final verification
    final_verification
    
    puts "\n🎯 Diagnosis complete!"
  end

  private

  def probe_loading_ui_existence
    puts "\n🔍 PROBE 1: Loading UI Existence Check"
    
    # Check if loading container exists
    loading_container = find("#editor-loading", visible: false)
    
    if loading_container
      puts "✅ Loading container found: #editor-loading"
      
      # Check visibility
      visible = loading_container.visible?
      puts "📊 Loading container visible: #{visible}"
      
      # Check computed styles
      display_style = page.evaluate_script("window.getComputedStyle(document.getElementById('editor-loading')).display")
      opacity_style = page.evaluate_script("window.getComputedStyle(document.getElementById('editor-loading')).opacity")
      z_index_style = page.evaluate_script("window.getComputedStyle(document.getElementById('editor-loading')).zIndex")
      
      puts "📊 Display style: #{display_style}"
      puts "📊 Opacity style: #{opacity_style}"
      puts "📊 Z-index style: #{z_index_style}"
      
      # Check inner content
      inner_html = page.evaluate_script("document.getElementById('editor-loading').innerHTML")
      puts "📊 Loading UI inner HTML length: #{inner_html.length} chars"
      puts "📊 Contains gradient: #{inner_html.include?('gradient')}"
      puts "📊 Contains spinner: #{inner_html.include?('spinner')}"
      puts "📊 Contains Monaco text: #{inner_html.include?('Monaco')}"
      
      save_screenshot("02_loading_ui_probe.png")
    else
      puts "❌ Loading container NOT found!"
    end
  end

  def probe_monaco_container
    puts "\n🔍 PROBE 2: Monaco Container Check"
    
    # Check if Monaco container exists
    monaco_container = find("#monaco-editor", visible: false)
    
    if monaco_container
      puts "✅ Monaco container found: #monaco-editor"
      
      # Check dimensions
      width = page.evaluate_script("document.getElementById('monaco-editor').offsetWidth")
      height = page.evaluate_script("document.getElementById('monaco-editor').offsetHeight")
      
      puts "📊 Monaco container width: #{width}px"
      puts "📊 Monaco container height: #{height}px"
      
      # Check CSS styles
      display_style = page.evaluate_script("window.getComputedStyle(document.getElementById('monaco-editor')).display")
      position_style = page.evaluate_script("window.getComputedStyle(document.getElementById('monaco-editor')).position")
      
      puts "📊 Display style: #{display_style}"
      puts "📊 Position style: #{position_style}"
      
      # Check parent container
      parent_width = page.evaluate_script("document.getElementById('monaco-editor').parentElement.offsetWidth")
      parent_height = page.evaluate_script("document.getElementById('monaco-editor').parentElement.offsetHeight")
      
      puts "📊 Parent container width: #{parent_width}px"
      puts "📊 Parent container height: #{parent_height}px"
      
      save_screenshot("03_monaco_container_probe.png")
    else
      puts "❌ Monaco container NOT found!"
    end
  end

  def probe_editor_dimensions
    puts "\n🔍 PROBE 3: Editor Dimensions Deep Dive"
    
    # Get all relevant containers
    containers = [
      "#monaco-editor",
      ".editor-content",
      "[data-playground-target='monacoContainer']"
    ]
    
    containers.each do |selector|
      begin
        element = find(selector, visible: false)
        if element
          width = page.evaluate_script("document.querySelector('#{selector}').offsetWidth")
          height = page.evaluate_script("document.querySelector('#{selector}').offsetHeight")
          client_width = page.evaluate_script("document.querySelector('#{selector}').clientWidth")
          client_height = page.evaluate_script("document.querySelector('#{selector}').clientHeight")
          
          puts "📊 #{selector}:"
          puts "   - Offset: #{width}x#{height}"
          puts "   - Client: #{client_width}x#{client_height}"
        end
      rescue Capybara::ElementNotFound
        puts "❌ #{selector} not found"
      end
    end
    
    save_screenshot("04_dimensions_probe.png")
  end

  def probe_javascript_status
    puts "\n🔍 PROBE 4: JavaScript Loading Status"
    
    # Check if Monaco global is available
    monaco_available = page.evaluate_script("typeof monaco !== 'undefined'")
    puts "📊 Monaco global available: #{monaco_available}"
    
    # Check if require is available
    require_available = page.evaluate_script("typeof require !== 'undefined'")
    puts "📊 Require.js available: #{require_available}"
    
    # Check playground controller
    playground_controller = page.evaluate_script("document.querySelector('[data-controller=\"playground\"]') !== null")
    puts "📊 Playground controller element exists: #{playground_controller}"
    
    # Check if playground controller is connected
    begin
      controller_connected = page.evaluate_script("
        const element = document.querySelector('[data-controller=\"playground\"]');
        element && element.application && element.application.controllers.length > 0
      ")
      puts "📊 Playground controller connected: #{controller_connected}"
    rescue => e
      puts "❌ Error checking controller: #{e.message}"
    end
    
    # Check console errors
    logs = page.driver.browser.logs.get(:browser)
    error_logs = logs.select { |log| log.level == "SEVERE" }
    puts "📊 Console errors: #{error_logs.length}"
    error_logs.each { |log| puts "   - #{log.message}" }
    
    save_screenshot("05_javascript_probe.png")
  end

  def monitor_monaco_loading_with_probes
    puts "\n🔍 PROBE 5: Monaco Loading Monitor with Continuous Probes"
    
    max_wait_time = 15.seconds
    check_interval = 1.second
    start_time = Time.current
    
    puts "⏰ Starting Monaco loading monitor (#{max_wait_time}s max)"
    
    while Time.current - start_time < max_wait_time
      elapsed = Time.current - start_time
      puts "\n⏱️  Check at #{elapsed.round(1)}s:"
      
      # Check if Monaco is loaded
      monaco_loaded = page.evaluate_script("typeof monaco !== 'undefined' && monaco.editor")
      puts "📊 Monaco loaded: #{monaco_loaded}"
      
      # Check if editor instance exists
      editor_instance = page.evaluate_script("
        const element = document.querySelector('[data-controller=\"playground\"]');
        const controller = element && element.application && element.application.getControllerForElementAndIdentifier(element, 'playground');
        controller && controller.editor ? 'exists' : 'missing'
      ")
      puts "📊 Editor instance: #{editor_instance}"
      
      # Check loading UI visibility
      loading_visible = page.evaluate_script("
        const loading = document.getElementById('editor-loading');
        loading && window.getComputedStyle(loading).display !== 'none'
      ")
      puts "📊 Loading UI visible: #{loading_visible}"
      
      # Check Monaco container dimensions
      monaco_width = page.evaluate_script("
        const monaco = document.getElementById('monaco-editor');
        monaco ? monaco.offsetWidth : 0
      ")
      monaco_height = page.evaluate_script("
        const monaco = document.getElementById('monaco-editor');
        monaco ? monaco.offsetHeight : 0
      ")
      puts "📊 Monaco dimensions: #{monaco_width}x#{monaco_height}"
      
      # Take screenshot every few seconds
      if elapsed.to_i % 3 == 0
        save_screenshot("06_monaco_loading_#{elapsed.to_i}s.png")
      end
      
      # Break if Monaco is loaded and has valid dimensions
      if monaco_loaded && monaco_width > 0 && monaco_height > 0
        puts "✅ Monaco successfully loaded with valid dimensions!"
        break
      end
      
      sleep check_interval
    end
    
    # Final check
    final_elapsed = Time.current - start_time
    puts "\n🏁 Final status after #{final_elapsed.round(1)}s:"
    
    final_monaco_loaded = page.evaluate_script("typeof monaco !== 'undefined' && monaco.editor")
    final_width = page.evaluate_script("document.getElementById('monaco-editor')?.offsetWidth || 0")
    final_height = page.evaluate_script("document.getElementById('monaco-editor')?.offsetHeight || 0")
    
    puts "📊 Final Monaco loaded: #{final_monaco_loaded}"
    puts "📊 Final dimensions: #{final_width}x#{final_height}"
    
    save_screenshot("07_final_monaco_state.png")
  end

  def final_verification
    puts "\n🔍 FINAL VERIFICATION"
    
    # Check if we can interact with Monaco
    begin
      # Try to get Monaco editor value
      editor_value = page.evaluate_script("
        const element = document.querySelector('[data-controller=\"playground\"]');
        const controller = element && element.application && element.application.getControllerForElementAndIdentifier(element, 'playground');
        controller && controller.editor ? controller.editor.getValue() : 'NO_EDITOR'
      ")
      puts "📊 Editor value length: #{editor_value.length} chars"
      puts "📊 Editor content preview: #{editor_value[0..100]}..."
      
      # Try to set value
      page.evaluate_script("
        const element = document.querySelector('[data-controller=\"playground\"]');
        const controller = element && element.application && element.application.getControllerForElementAndIdentifier(element, 'playground');
        if (controller && controller.editor) {
          controller.editor.setValue('# Test from diagnosis\\ntext(\"Hello Monaco!\")');
        }
      ")
      
      sleep 1
      save_screenshot("08_final_interaction_test.png")
      
      puts "✅ Successfully interacted with Monaco editor"
    rescue => e
      puts "❌ Failed to interact with Monaco: #{e.message}"
    end
    
    # Summary
    puts "\n" + "="*80
    puts "🎯 DIAGNOSIS SUMMARY"
    puts "="*80
    puts "Test completed at: #{Time.current}"
    puts "Total runtime: #{Time.current - @test_start_time} seconds"
    puts "Screenshots saved in: tmp/capybara/"
    puts "="*80
  end
end