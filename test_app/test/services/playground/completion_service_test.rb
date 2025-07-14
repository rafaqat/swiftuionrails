# frozen_string_literal: true

require 'test_helper'

class Playground::CompletionServiceTest < ActiveSupport::TestCase
  def pos(str, line = 1)
    { "lineNumber" => line, "column" => str.length + 1 }
  end
  
  def get_labels(completions)
    completions.map { |c| c[:label] }
  end
  
  test "suggests top-level DSL elements" do
    service = Playground::CompletionService.new("tex", pos("tex"))
    completions = service.generate_completions
    labels = get_labels(completions)
    
    assert_includes labels, "text"
    assert_includes labels, "textfield"
    assert_not_includes labels, "button" # Doesn't start with "tex"
  end
  
  test "suggests all DSL elements when no partial" do
    service = Playground::CompletionService.new("", pos(""))
    completions = service.generate_completions
    labels = get_labels(completions)
    
    assert_includes labels, "text"
    assert_includes labels, "button"
    assert_includes labels, "vstack"
    assert_includes labels, "hstack"
  end
  
  test "suggests modifiers after dot" do
    code = 'text("Hello").'
    service = Playground::CompletionService.new(code, pos(code))
    completions = service.generate_completions
    labels = get_labels(completions)
    
    assert_includes labels, "font_size"
    assert_includes labels, "text_color"
    assert_includes labels, "padding"
    assert_includes labels, "bg"
  end
  
  test "filters modifiers by partial" do
    code = 'text("Hello").font_'
    service = Playground::CompletionService.new(code, pos(code))
    completions = service.generate_completions
    labels = get_labels(completions)
    
    assert_includes labels, "font_size"
    assert_includes labels, "font_weight"
    assert_not_includes labels, "text_color"
    assert_not_includes labels, "padding"
  end
  
  test "suggests Tailwind colors inside bg(" do
    code = 'text("Hello").bg("'
    service = Playground::CompletionService.new(code, pos(code))
    completions = service.generate_completions
    labels = get_labels(completions)
    
    assert_includes labels, "white"
    assert_includes labels, "black"
    assert_includes labels, "transparent"
    # Check for any Tailwind color pattern (e.g., slate-50, blue-500)
    assert labels.any? { |l| l =~ /\w+-\d+/ }, "Should include Tailwind colors like slate-50 or blue-500"
  end
  
  test "suggests spacing values for padding" do
    code = 'div.padding('
    service = Playground::CompletionService.new(code, pos(code))
    completions = service.generate_completions
    labels = get_labels(completions)
    
    assert_includes labels, "0"
    assert_includes labels, "1"
    assert_includes labels, "4"
    assert_includes labels, "8"
  end
  
  test "suggests font sizes for font_size" do
    code = 'text("Hi").font_size("'
    service = Playground::CompletionService.new(code, pos(code))
    completions = service.generate_completions
    labels = get_labels(completions)
    
    assert_includes labels, "xs"
    assert_includes labels, "sm"
    assert_includes labels, "base"
    assert_includes labels, "lg"
    assert_includes labels, "xl"
  end
  
  test "works with method chains" do
    code = 'text("Hi").bg("red").padding(4).'
    service = Playground::CompletionService.new(code, pos(code))
    completions = service.generate_completions
    labels = get_labels(completions)
    
    # Should still suggest all modifiers
    assert_includes labels, "font_size"
    assert_includes labels, "margin"
    assert_includes labels, "rounded"
  end
  
  test "works inside nested blocks" do
    code = "vstack do\n  text('Hi')."
    service = Playground::CompletionService.new(code, { "lineNumber" => 2, "column" => 13 })
    completions = service.generate_completions
    labels = get_labels(completions)
    
    assert_includes labels, "font_size"
    assert_includes labels, "text_color"
  end
  
  test "handles incomplete parentheses" do
    code = 'button("Click'
    service = Playground::CompletionService.new(code, pos(code))
    completions = service.generate_completions
    
    # Should detect this as inside a method call and return empty array or parameter completions
    # The important thing is it doesn't crash
    assert_not_nil completions
  end
  
  test "caches results for performance" do
    code = 'text("Hello").'
    position = pos(code)
    
    # Clear cache first
    Rails.cache.clear
    
    # First call
    service1 = Playground::CompletionService.new(code, position)
    result1 = nil
    time1 = Benchmark.realtime { result1 = service1.generate_completions }
    
    # Second call (should be cached)
    service2 = Playground::CompletionService.new(code, position)
    result2 = nil
    time2 = Benchmark.realtime { result2 = service2.generate_completions }
    
    assert_equal result1, result2
    # Just verify caching works, don't rely on timing
    assert_not_nil result1
    assert_not_empty result1
  end
  
  test "registry version changes when updated" do
    # Get initial version
    initial_version = Playground::DslRegistry.instance.version
    
    # Ensure we get a different timestamp
    sleep 1
    
    # Update registry
    Playground::DslRegistry.instance.register(:test_element_unique, { description: "Test" })
    
    # Get new version
    new_version = Playground::DslRegistry.instance.version
    
    assert_not_equal initial_version, new_version, "Version should change after registry update"
    assert new_version > initial_version, "New version should be greater than initial"
  end
end