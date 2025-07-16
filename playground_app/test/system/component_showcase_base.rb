# frozen_string_literal: true

require "application_system_test_case"
require "fileutils"

# Base class for component showcase tests
class ComponentShowcaseBase < ApplicationSystemTestCase
  # Create a timestamped directory for this test run
  SCREENSHOT_DIR = Rails.root.join("tmp", "component_showcase", Time.now.strftime("%Y%m%d_%H%M%S"))
  REPORT_FILE = SCREENSHOT_DIR.join("test_report.html")
  
  def setup
    super
    FileUtils.mkdir_p(SCREENSHOT_DIR)
    @test_results = []
    @start_time = Time.now
  end
  
  def teardown
    super
    generate_html_report if @test_results.any?
  end

  private

  def test_component(name:, category:, code:, assertions: {})
    visit root_path
    
    # Wait for Monaco editor
    assert_selector "#monaco-editor", visible: true, wait: 10
    sleep 1 # Give Monaco time to fully initialize
    
    # Clear and set code
    find('[data-action="click->playground#clearCode"]').click
    
    page.execute_script <<~JS
      if (window.monacoEditorInstance) {
        window.monacoEditorInstance.setValue(`#{code.gsub("\n", "\\n").gsub('"', '\"').gsub('#', '\\#')}`);
      }
    JS
    
    # Run the code
    find('[data-action="click->playground#runCode"]').click
    
    # Wait for preview to update
    sleep 1
    
    # Check if there's an error
    if page.has_selector?(".playground-error", wait: 0.5)
      # Still take screenshot for documentation
      screenshot_path = SCREENSHOT_DIR.join("#{category}_#{name.downcase.gsub(/\s+/, '_')}.png")
      save_screenshot(screenshot_path)
      
      @test_results << {
        name: name,
        category: category,
        status: "FAIL",
        error: "Syntax error in component code",
        screenshot: screenshot_path.basename.to_s,
        code: code
      }
      return false
    end
    
    within "#preview-container" do
      # Run custom assertions
      assertions.each do |description, assertion_proc|
        assertion_proc.call
      end
    end
    
    # Take screenshot
    screenshot_path = SCREENSHOT_DIR.join("#{category}_#{name.downcase.gsub(/\s+/, '_')}.png")
    save_screenshot(screenshot_path)
    
    @test_results << {
      name: name,
      category: category,
      status: "PASS",
      screenshot: screenshot_path.basename.to_s,
      code: code
    }
    
    true
  rescue => e
    @test_results << {
      name: name,
      category: category,
      status: "FAIL",
      error: e.message,
      code: code
    }
    false
  end

  def generate_html_report
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>SwiftUI Rails Component Showcase Report</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
          .header { background: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
          h1 { margin: 0; color: #333; }
          .summary { margin-top: 20px; display: flex; gap: 30px; }
          .stat { text-align: center; }
          .stat-value { font-size: 36px; font-weight: bold; color: #007AFF; }
          .stat-label { color: #666; margin-top: 5px; }
          .category { background: white; margin-bottom: 20px; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
          .category-header { background: #f8f9fa; padding: 15px 20px; border-bottom: 1px solid #e9ecef; }
          h2 { margin: 0; color: #495057; font-size: 20px; }
          .component { padding: 20px; border-bottom: 1px solid #e9ecef; }
          .component:last-child { border-bottom: none; }
          .component-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
          h3 { margin: 0; color: #212529; }
          .status { padding: 5px 15px; border-radius: 20px; font-size: 14px; font-weight: 600; }
          .status.pass { background: #d4edda; color: #155724; }
          .status.fail { background: #f8d7da; color: #721c24; }
          .screenshot { margin: 15px 0; text-align: center; }
          .screenshot img { max-width: 100%; border: 1px solid #dee2e6; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
          .code { background: #f8f9fa; padding: 15px; border-radius: 8px; overflow-x: auto; margin-top: 15px; }
          .code pre { margin: 0; font-family: 'SF Mono', Monaco, monospace; font-size: 13px; color: #212529; }
          .footer { text-align: center; color: #6c757d; margin-top: 40px; padding: 20px; }
          .success-rate { font-size: 48px; font-weight: bold; color: #28a745; }
          .execution-time { color: #6c757d; margin-top: 10px; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>SwiftUI Rails Component Showcase Report</h1>
          <div class="summary">
            <div class="stat">
              <div class="stat-value">#{@test_results.length}</div>
              <div class="stat-label">Total Components</div>
            </div>
            <div class="stat">
              <div class="stat-value">#{@test_results.count { |r| r[:status] == "PASS" }}</div>
              <div class="stat-label">Passed</div>
            </div>
            <div class="stat">
              <div class="stat-value">#{@test_results.count { |r| r[:status] == "FAIL" }}</div>
              <div class="stat-label">Failed</div>
            </div>
            <div class="stat">
              <div class="success-rate">#{((@test_results.count { |r| r[:status] == "PASS" }.to_f / @test_results.length) * 100).round(1)}%</div>
              <div class="stat-label">Success Rate</div>
            </div>
          </div>
          <div class="execution-time">
            Generated on: #{Time.now.strftime("%B %d, %Y at %I:%M %p")}<br>
            Execution time: #{(Time.now - @start_time).round(2)} seconds
          </div>
        </div>
    HTML
    
    # Group results by category
    @test_results.group_by { |r| r[:category] }.each do |category, results|
      html += <<~HTML
        <div class="category">
          <div class="category-header">
            <h2>#{category}</h2>
          </div>
      HTML
      
      results.each do |result|
        status_class = result[:status].downcase
        html += <<~HTML
          <div class="component">
            <div class="component-header">
              <h3>#{result[:name]}</h3>
              <span class="status #{status_class}">#{result[:status]}</span>
            </div>
        HTML
        
        if result[:screenshot]
          html += <<~HTML
            <div class="screenshot">
              <img src="#{result[:screenshot]}" alt="#{result[:name]} screenshot">
            </div>
          HTML
        end
        
        if result[:error]
          html += <<~HTML
            <div class="error">
              <strong>Error:</strong> #{result[:error]}
            </div>
          HTML
        end
        
        if result[:code]
          html += <<~HTML
            <div class="code">
              <pre>#{CGI.escapeHTML(result[:code])}</pre>
            </div>
          HTML
        end
        
        html += "</div>"
      end
      
      html += "</div>"
    end
    
    html += <<~HTML
        <div class="footer">
          <p>Generated by SwiftUI Rails Component Showcase Test Suite</p>
        </div>
      </body>
      </html>
    HTML
    
    File.write(REPORT_FILE, html)
    puts "\n\n✅ Test report generated: #{REPORT_FILE}"
  end
end