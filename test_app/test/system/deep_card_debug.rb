# frozen_string_literal: true

# Copyright 2025

require "application_system_test_case"

class DeepCardDebug < ApplicationSystemTestCase
  test "deep debug of card background color issue" do
    puts "🔍 Deep debugging card background color..."

    visit "/storybook/show?story=card_component"
    sleep 3

    puts "✅ Page loaded"

    # Check the actual card HTML structure in detail
    puts "\n📋 CURRENT CARD HTML STRUCTURE:"
    card_html = page.evaluate_script("document.querySelector('#component-preview').innerHTML")
    puts card_html

    # Find all elements with background classes
    puts "\n🎨 ELEMENTS WITH BACKGROUND CLASSES:"
    bg_elements = page.evaluate_script("""
      Array.from(document.querySelectorAll('#component-preview *')).filter(el =>
        el.className && el.className.toString().includes('bg-')
      ).map(el => ({
        tag: el.tagName,
        classes: el.className,
        content: el.textContent.substring(0, 50) + '...'
      }))
    """)
    bg_elements.each_with_index do |elem, i|
      puts "  #{i+1}. #{elem['tag']}: #{elem['classes']} (#{elem['content']})"
    end

    # Test the background color control
    puts "\n🎛️ TESTING BACKGROUND COLOR CONTROL:"
    bg_select = find("select[name='background_color']")
    puts "Current value: #{bg_select.value}"

    # Change to blue-50
    puts "Changing to blue-50..."
    bg_select.select("Blue-50")
    sleep 2

    # Check if Stimulus fired
    puts "\n⚡ CHECKING STIMULUS CONTROLLER:"
    stimulus_debug = page.evaluate_script("""
      var element = document.querySelector('[data-controller=\"live-story\"]');
      return {
        found: !!element,
        connected: element && element.hasAttribute('data-live-story-connected'),
        hasController: element && !!element.controller,
        hasControlMethod: element && element.controller && typeof element.controller.controlChanged === 'function'
      }
    """)
    puts "Stimulus debug: #{stimulus_debug}"

    # Check what changed in the HTML
    puts "\n📋 HTML AFTER CHANGE:"
    new_card_html = page.evaluate_script("document.querySelector('#component-preview').innerHTML")

    if new_card_html == card_html
      puts "❌ HTML did not change at all!"
    else
      puts "✅ HTML changed"
      puts "New HTML: #{new_card_html[0..300]}..."
    end

    # Check new background elements
    puts "\n🎨 BACKGROUND ELEMENTS AFTER CHANGE:"
    new_bg_elements = page.evaluate_script("""
      Array.from(document.querySelectorAll('#component-preview *')).filter(el =>
        el.className && el.className.toString().includes('bg-')
      ).map(el => ({
        tag: el.tagName,
        classes: el.className,
        content: el.textContent.substring(0, 50) + '...'
      }))
    """)
    new_bg_elements.each_with_index do |elem, i|
      puts "  #{i+1}. #{elem['tag']}: #{elem['classes']} (#{elem['content']})"
    end

    # Check console logs for errors
    puts "\n🐛 CONSOLE LOGS:"
    logs = console_logs
    recent_logs = logs.last(5)
    recent_logs.each do |log|
      puts "  [#{log.level}] #{log.message}"
    end

    # Test color swatch button as well
    puts "\n🎨 TESTING COLOR SWATCH BUTTON:"
    blue_swatch = find("button[data-value='blue-50']")
    puts "Blue swatch classes: #{blue_swatch[:class]}"
    blue_swatch.click
    sleep 2

    final_html = page.evaluate_script("document.querySelector('#component-preview').innerHTML")
    if final_html != new_card_html
      puts "✅ Swatch button changed HTML"
    else
      puts "❌ Swatch button did not change HTML"
    end

    puts "\n📋 FINAL BACKGROUND ELEMENTS:"
    final_bg_elements = page.evaluate_script("""
      Array.from(document.querySelectorAll('#component-preview *')).filter(el =>
        el.className && el.className.toString().includes('bg-')
      ).map(el => ({
        tag: el.tagName,
        classes: el.className,
        content: el.textContent.substring(0, 50) + '...'
      }))
    """)
    final_bg_elements.each_with_index do |elem, i|
      puts "  #{i+1}. #{elem['tag']}: #{elem['classes']} (#{elem['content']})"
    end
  end
end
# Copyright 2025
