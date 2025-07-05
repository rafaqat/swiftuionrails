# Copyright 2025
require "test_helper"

class SwiftUIRails::SimpleSlotsTest < ViewComponent::TestCase
  # Most basic slot test - extend ApplicationComponent to see if that helps
  class BasicSlotComponent < ApplicationComponent
    renders_one :main_content
    
    def call
      content_tag(:div, class: "wrapper") do
        safe_join([
          main_content
        ].compact)
      end
    end
  end
  
  test "basic slot works" do
    component = BasicSlotComponent.new
    
    html = render_inline(component) do |c|
      c.with_main_content { "Hello World" }
    end
    
    puts "Rendered HTML: #{html.to_s}"
    
    assert_text "Hello World"
    assert_selector "div.wrapper"
  end
  
  # Test with SwiftUI DSL
  class DSLSlotComponent < SwiftUIRails::Component::Base
    renders_one :header
    
    def call
      content_tag(:div, class: "card p-4") do
        safe_join([
          header ? content_tag(:div, header, class: "header mb-4") : nil,
          content_tag(:div, "Body content", class: "body")
        ].compact)
      end
    end
  end
  
  test "dsl slot component works" do
    component = DSLSlotComponent.new
    
    render_inline(component) do |c|
      c.with_header { "Header Text" }
    end
    
    assert_text "Header Text"
    assert_text "Body content"
    assert_selector "div.header"
  end
end
# Copyright 2025
