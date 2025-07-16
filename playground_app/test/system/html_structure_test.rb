# frozen_string_literal: true

require "application_system_test_case"

class HtmlStructureTest < ApplicationSystemTestCase
  test "examine HTML structure of loading indicator" do
    puts "\n🔍 Examining HTML structure..."
    
    # Visit the playground
    visit "/playground"
    
    # Wait for page to load
    sleep 2
    
    # Find the loading indicator and print its HTML
    loading_element = find("#editor-loading", visible: false)
    if loading_element
      puts "✅ Loading element found"
      puts "Loading element HTML:"
      puts loading_element.native.attribute('outerHTML')
      puts "\nLoading element inner HTML:"
      puts loading_element.native.attribute('innerHTML')
    else
      puts "❌ Loading element not found"
    end
    
    # Check if there's a span inside
    span_elements = all("#editor-loading span", visible: false)
    puts "\nSpan elements found: #{span_elements.count}"
    span_elements.each_with_index do |span, index|
      puts "Span #{index + 1}:"
      puts "  HTML: #{span.native.attribute('outerHTML')}"
      puts "  Text: '#{span.text}'"
      puts "  Class: #{span.native.attribute('class')}"
    end
    
    # Check the container div
    container_div = find(".flex-1.flex.relative", visible: false)
    if container_div
      puts "\nContainer div found"
      puts "Container HTML (first 500 chars):"
      puts container_div.native.attribute('innerHTML')[0..500]
    end
    
    puts "\n✅ HTML structure examination complete"
  end
end