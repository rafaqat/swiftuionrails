# frozen_string_literal: true

require "application_system_test_case"

class MonacoConsoleDiagnosisTest < ApplicationSystemTestCase
  def setup
    @test_start_time = Time.current
    puts "\n" + "="*80
    puts "🔍 MONACO CONSOLE DIAGNOSIS TEST - #{@test_start_time}"
    puts "="*80
  end

  test "comprehensive Monaco editor loading diagnosis with console errors" do
    puts "\n🚨 CHECKING CONSOLE ERRORS AND MONACO LOADING..."
    
    # Visit the playground
    visit "/playground"
    
    # Wait a moment for initial load
    sleep 2
    
    # Capture console logs and errors
    logs = page.driver.browser.logs.get(:browser)
    
    puts "\n📋 BROWSER CONSOLE LOGS:"
    puts "="*50
    logs.each do |log|
      level_emoji = case log.level
      when "SEVERE", "ERROR" then "🚨"
      when "WARNING" then "⚠️"
      when "INFO" then "ℹ️"
      else "📝"
      end
      puts "#{level_emoji} [#{log.level}] #{log.message}"
    end
    puts "="*50
    
    # Check for specific JavaScript errors
    has_js_errors = logs.any? { |log| log.level == "SEVERE" || log.level == "ERROR" }
    puts has_js_errors ? "🚨 JavaScript errors found!" : "✅ No JavaScript errors"
    
    # Check Monaco-specific variables and functions
    puts "\n🔍 CHECKING MONACO-SPECIFIC DIAGNOSTICS:"
    
    # Check if require.js is loaded
    require_loaded = page.evaluate_script("typeof require !== 'undefined'")
    puts "require.js loaded: #{require_loaded ? '✅' : '🚨'}"
    
    # Check if Monaco is defined
    monaco_defined = page.evaluate_script("typeof monaco !== 'undefined'")
    puts "Monaco defined: #{monaco_defined ? '✅' : '🚨'}"
    
    # Check if Monaco editor is defined
    monaco_editor_defined = page.evaluate_script("typeof monaco !== 'undefined' && typeof monaco.editor !== 'undefined'")
    puts "Monaco editor defined: #{monaco_editor_defined ? '✅' : '🚨'}"
    
    # Check Stimulus controller
    stimulus_controller = page.evaluate_script("
      const element = document.querySelector('[data-controller=\"playground\"]');
      element && element.application && element.application.getControllerForElementAndIdentifier
    ")
    puts "Stimulus playground controller: #{stimulus_controller ? '✅' : '🚨'}"
    
    # Check Monaco container dimensions
    monaco_container = page.evaluate_script("
      const container = document.getElementById('monaco-editor');
      if (container) {
        return {
          width: container.offsetWidth,
          height: container.offsetHeight,
          clientWidth: container.clientWidth,
          clientHeight: container.clientHeight,
          scrollWidth: container.scrollWidth,
          scrollHeight: container.scrollHeight,
          display: window.getComputedStyle(container).display,
          position: window.getComputedStyle(container).position
        };
      }
      return null;
    ")
    
    puts "\n📊 MONACO CONTAINER DIAGNOSTICS:"
    if monaco_container
      puts "Width: #{monaco_container['width']}px"
      puts "Height: #{monaco_container['height']}px"
      puts "Client Width: #{monaco_container['clientWidth']}px"
      puts "Client Height: #{monaco_container['clientHeight']}px"
      puts "Scroll Width: #{monaco_container['scrollWidth']}px"
      puts "Scroll Height: #{monaco_container['scrollHeight']}px"
      puts "Display: #{monaco_container['display']}"
      puts "Position: #{monaco_container['position']}"
      
      # Check if dimensions are zero
      if monaco_container['width'] == 0 || monaco_container['height'] == 0
        puts "🚨 CRITICAL: Monaco container has zero dimensions!"
      else
        puts "✅ Monaco container has valid dimensions"
      end
    else
      puts "🚨 Monaco container not found!"
    end
    
    # Check parent container dimensions
    editor_content = page.evaluate_script("
      const container = document.querySelector('.editor-content, [data-playground-target=\"monacoContainer\"]')?.parentElement;
      if (container) {
        return {
          width: container.offsetWidth,
          height: container.offsetHeight,
          display: window.getComputedStyle(container).display
        };
      }
      return null;
    ")
    
    puts "\n📊 PARENT CONTAINER DIAGNOSTICS:"
    if editor_content
      puts "Parent Width: #{editor_content['width']}px"
      puts "Parent Height: #{editor_content['height']}px"
      puts "Parent Display: #{editor_content['display']}"
    else
      puts "🚨 Parent container not found!"
    end
    
    # Check loading UI visibility
    loading_ui = page.evaluate_script("
      const loading = document.getElementById('editor-loading');
      if (loading) {
        const style = window.getComputedStyle(loading);
        return {
          display: style.display,
          opacity: style.opacity,
          zIndex: style.zIndex,
          position: style.position
        };
      }
      return null;
    ")
    
    puts "\n📊 LOADING UI DIAGNOSTICS:"
    if loading_ui
      puts "Loading Display: #{loading_ui['display']}"
      puts "Loading Opacity: #{loading_ui['opacity']}"
      puts "Loading Z-Index: #{loading_ui['zIndex']}"
      puts "Loading Position: #{loading_ui['position']}"
    else
      puts "🚨 Loading UI not found!"
    end
    
    # Check if Monaco scripts are in the page
    monaco_scripts = page.evaluate_script("
      const scripts = Array.from(document.querySelectorAll('script[src*=\"monaco\"]'));
      return scripts.map(s => s.src);
    ")
    
    puts "\n📊 MONACO SCRIPT TAGS:"
    if monaco_scripts.any?
      monaco_scripts.each { |src| puts "✅ #{src}" }
    else
      puts "🚨 No Monaco script tags found!"
    end
    
    # Check network requests for Monaco
    puts "\n📊 CHECKING NETWORK REQUESTS..."
    
    # Wait longer for potential Monaco loading
    puts "⏳ Waiting 10 seconds for Monaco to load..."
    sleep 10
    
    # Re-check Monaco after wait
    monaco_defined_after = page.evaluate_script("typeof monaco !== 'undefined'")
    puts "Monaco defined after wait: #{monaco_defined_after ? '✅' : '🚨'}"
    
    # Check if any Monaco editor instances exist
    monaco_instances = page.evaluate_script("
      if (typeof monaco !== 'undefined' && monaco.editor) {
        return monaco.editor.getModels().length;
      }
      return 0;
    ")
    puts "Monaco editor instances: #{monaco_instances}"
    
    # Take screenshots at different stages
    save_screenshot("01_monaco_diagnosis_initial.png")
    
    # Try to manually trigger Monaco loading if Stimulus is available
    puts "\n🔧 ATTEMPTING MANUAL MONACO INITIALIZATION..."
    
    manual_init_result = page.evaluate_script("
      try {
        const container = document.getElementById('monaco-editor');
        if (container && typeof monaco !== 'undefined') {
          const editor = monaco.editor.create(container, {
            value: 'swift_ui do\\n  text(\"Hello World\")\\nend',
            language: 'ruby',
            theme: 'vs-light'
          });
          return 'SUCCESS: Monaco editor manually created';
        } else if (!container) {
          return 'ERROR: Monaco container not found';
        } else {
          return 'ERROR: Monaco not defined';
        }
      } catch (error) {
        return 'ERROR: ' + error.message;
      }
    ")
    
    puts "Manual initialization result: #{manual_init_result}"
    
    # Final screenshot
    save_screenshot("02_monaco_diagnosis_final.png")
    
    # Get final console logs
    final_logs = page.driver.browser.logs.get(:browser)
    new_logs = final_logs - logs
    
    if new_logs.any?
      puts "\n📋 NEW CONSOLE LOGS DURING TEST:"
      puts "="*50
      new_logs.each do |log|
        level_emoji = case log.level
        when "SEVERE", "ERROR" then "🚨"
        when "WARNING" then "⚠️"
        when "INFO" then "ℹ️"
        else "📝"
        end
        puts "#{level_emoji} [#{log.level}] #{log.message}"
      end
      puts "="*50
    end
    
    # Summary
    puts "\n🎯 DIAGNOSIS SUMMARY:"
    puts "="*50
    puts "JavaScript Errors: #{has_js_errors ? '🚨 YES' : '✅ NO'}"
    puts "require.js: #{require_loaded ? '✅ LOADED' : '🚨 MISSING'}"
    puts "Monaco: #{monaco_defined_after ? '✅ LOADED' : '🚨 MISSING'}"
    puts "Container Dimensions: #{monaco_container && monaco_container['width'] > 0 ? '✅ VALID' : '🚨 INVALID'}"
    puts "Loading UI: #{loading_ui ? '✅ PRESENT' : '🚨 MISSING'}"
    puts "="*50
    
    puts "\n🎯 Test completed at: #{Time.current}"
    puts "⏱️  Total runtime: #{Time.current - @test_start_time} seconds"
    puts "="*80
  end
end