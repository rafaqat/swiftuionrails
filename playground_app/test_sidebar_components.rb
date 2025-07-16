#!/usr/bin/env ruby

# Test script to validate all sidebar components
require 'net/http'
require 'uri'
require 'json'

class SidebarComponentTester
  def initialize
    @base_url = "http://localhost:3000"
    @preview_endpoint = "/playground/preview"
    @results = []
  end
  
  def test_all_components
    puts "🔍 Testing all sidebar components..."
    puts "=" * 60
    
    # Test each component
    test_text_component
    test_button_component
    test_image_component
    test_vstack_component
    test_hstack_component
    test_card_component
    test_list_component
    test_grid_component
    test_form_component
    test_textfield_component
    test_table_components
    
    # Print summary
    print_summary
  end
  
  private
  
  def test_text_component
    code = 'text("Your text here")
  .font_size("xl")
  .font_weight("semibold")
  .text_color("gray-800")
  .text_align("left")
  .leading("relaxed")'
    
    test_component("Text", code)
  end
  
  def test_button_component
    code = 'button("Click Me")
  .bg("blue-500")
  .text_color("white")
  .px(4).py(2)
  .rounded("lg")
  .data(action: "click->controller#method")'
    
    test_component("Button", code)
  end
  
  def test_image_component
    code = 'image(src: "https://images.unsplash.com/photo-1470509037663-253afd7f0f51?w=400&h=300&fit=crop", alt: "Beautiful sunflower")'
    
    test_component("Image", code)
  end
  
  def test_vstack_component
    code = 'vstack(spacing: 16) do
  text("Item 1")
  text("Item 2")
  text("Item 3")
end'
    
    test_component("VStack", code)
  end
  
  def test_hstack_component
    code = 'hstack(justify: :between) do
  text("Left")
  text("Right")
end'
    
    test_component("HStack", code)
  end
  
  def test_card_component
    code = 'card(elevation: 2) do
  text("Card content")
  text("More content")
end'
    
    test_component("Card", code)
  end
  
  def test_list_component
    code = 'list do
  (1..5).each do |i|
    list_item { text("Item #{i}") }
  end
end'
    
    test_component("List", code)
  end
  
  def test_grid_component
    # Test the WRONG syntax first
    wrong_code = 'grid(cols: 3, gap: 16) do
  text("Grid item")
end'
    
    puts "Testing WRONG grid syntax..."
    test_component_expect_error("Grid (Wrong)", wrong_code)
    
    # Now test the CORRECT syntax
    correct_code = 'grid(columns: 3, spacing: 16) do
  (1..6).each do |i|
    card(elevation: 1) do
      text("Grid Item #{i}")
    end
  end
end'
    
    puts "Testing CORRECT grid syntax..."
    test_component("Grid (Correct)", correct_code)
  end
  
  def test_form_component
    code = 'form(action: "#", method: :post) do
  textfield(name: "email", placeholder: "Enter email")
  button("Submit", type: "submit")
end'
    
    test_component("Form", code)
  end
  
  def test_textfield_component
    code = 'textfield(name: "email", placeholder: "Enter email")'
    
    test_component("TextField", code)
  end
  
  def test_table_components
    simple_table_code = 'simple_table(
  headers: ["Name", "Role", "Status"],
  rows: [
    ["John Doe", "Admin", "Active"],
    ["Jane Smith", "User", "Inactive"]
  ]
)'
    
    test_component("Simple Table", simple_table_code)
    
    data_table_code = 'data_table(
  title: "Users",
  data: [
    { name: "John", role: "Admin", status: "Active" },
    { name: "Jane", role: "User", status: "Inactive" }
  ],
  columns: [
    { key: :name, label: "Name" },
    { key: :role, label: "Role", format: :badge },
    { key: :status, label: "Status", format: :badge }
  ]
)'
    
    test_component("Data Table", data_table_code)
  end
  
  def test_component(component_name, code)
    print "Testing #{component_name.ljust(20)} "
    
    uri = URI("#{@base_url}#{@preview_endpoint}")
    
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request.body = "code=#{URI.encode_www_form_component(code)}"
      
      response = http.request(request)
      
      if response.code == '200'
        body = response.body
        
        # Check for error indicators
        if body.include?("error") || body.include?("Error") || body.include?("undefined method") || body.include?("NoMethodError")
          puts "❌ FAILED - Error in response"
          puts "   Error: #{extract_error(body)}"
          @results << { component: component_name, status: :failed, error: extract_error(body) }
        else
          puts "✅ SUCCESS"
          @results << { component: component_name, status: :success }
        end
      else
        puts "❌ FAILED - HTTP #{response.code}"
        @results << { component: component_name, status: :failed, error: "HTTP #{response.code}" }
      end
    end
  end
  
  def test_component_expect_error(component_name, code)
    print "Testing #{component_name.ljust(20)} (expecting error) "
    
    uri = URI("#{@base_url}#{@preview_endpoint}")
    
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request.body = "code=#{URI.encode_www_form_component(code)}"
      
      response = http.request(request)
      
      if response.code == '200'
        body = response.body
        
        # Check for error indicators - we EXPECT an error
        if body.include?("error") || body.include?("Error") || body.include?("undefined method") || body.include?("NoMethodError")
          puts "✅ CORRECTLY FAILED as expected"
          @results << { component: component_name, status: :expected_failure, error: extract_error(body) }
        else
          puts "⚠️ UNEXPECTEDLY SUCCEEDED"
          @results << { component: component_name, status: :unexpected_success }
        end
      else
        puts "✅ CORRECTLY FAILED with HTTP #{response.code}"
        @results << { component: component_name, status: :expected_failure, error: "HTTP #{response.code}" }
      end
    end
  end
  
  def extract_error(body)
    # Extract error message from response
    if body.include?("undefined method")
      body.match(/undefined method `([^']+)'/)[0] rescue "undefined method"
    elsif body.include?("NoMethodError")
      body.match(/NoMethodError: ([^<]+)/)[1] rescue "NoMethodError"
    elsif body.include?("Error:")
      body.match(/Error: ([^<]+)/)[1] rescue "Error"
    else
      "Unknown error"
    end
  end
  
  def print_summary
    puts "\n" + "=" * 60
    puts "🎯 SUMMARY"
    puts "=" * 60
    
    success_count = @results.count { |r| r[:status] == :success }
    failure_count = @results.count { |r| r[:status] == :failed }
    expected_failure_count = @results.count { |r| r[:status] == :expected_failure }
    unexpected_success_count = @results.count { |r| r[:status] == :unexpected_success }
    
    puts "✅ Successful: #{success_count}"
    puts "❌ Failed: #{failure_count}"
    puts "⚠️ Expected failures: #{expected_failure_count}"
    puts "🔄 Unexpected successes: #{unexpected_success_count}"
    
    puts "\n🚨 ISSUES FOUND:"
    @results.each do |result|
      if result[:status] == :failed
        puts "  - #{result[:component]}: #{result[:error]}"
      end
    end
    
    puts "\n💡 RECOMMENDATIONS:"
    @results.each do |result|
      if result[:status] == :failed && result[:error].include?("undefined method")
        puts "  - Fix #{result[:component]} component syntax"
      end
    end
  end
end

# Run the test
tester = SidebarComponentTester.new
tester.test_all_components