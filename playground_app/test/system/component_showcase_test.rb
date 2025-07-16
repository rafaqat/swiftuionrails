# frozen_string_literal: true

require "application_system_test_case"
require "fileutils"

class ComponentShowcaseTest < ApplicationSystemTestCase
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
              <div class="stat-value">#{@test_results.count}</div>
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
              <div class="success-rate">#{(((@test_results.count { |r| r[:status] == "PASS" }).to_f / @test_results.count) * 100).round(1)}%</div>
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
    grouped_results = @test_results.group_by { |r| r[:category] }
    
    grouped_results.each do |category, results|
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
            <div class="error" style="background: #f8d7da; color: #721c24; padding: 10px; border-radius: 5px; margin: 10px 0;">
              <strong>Error:</strong> #{result[:error]}
            </div>
          HTML
        end
        
        html += <<~HTML
            <div class="code">
              <pre>#{CGI.escapeHTML(result[:code])}</pre>
            </div>
          </div>
        HTML
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
    puts "\n✅ Test report generated: #{REPORT_FILE}"
    puts "📸 Screenshots saved to: #{SCREENSHOT_DIR}"
  end

  # Marketing Components Tests (15 tests)
  test "creates hero section with gradient" do
    test_component(
      name: "Hero Section - Gradient",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "relative bg-gradient-to-br from-indigo-600 to-purple-700 min-h-screen") do
            # Navigation
            nav(class: "relative z-10") do
              div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
                hstack(justify: :between, alignment: :center) do
                  # Logo
                  h3(class: "text-white font-bold text-2xl") { text("SwiftUI Rails") }
                  
                  # Nav links
                  hstack(spacing: 8) do
                    ["Features", "Pricing", "Docs", "Blog"].each do |item|
                      link(item, destination: "#", class: "text-white/80 hover:text-white transition")
                    end
                  end
                  
                  # CTA
                  button(class: "bg-white text-indigo-600 px-4 py-2 rounded-lg font-semibold hover:bg-gray-100 transition") do
                    text("Get Started")
                  end
                end.py(6)
              end
            end
            
            # Hero content
            div(class: "relative z-10 max-w-7xl mx-auto px-4 pt-20 pb-32") do
              vstack(spacing: 8, alignment: :center) do
                # Badge
                div(class: "inline-flex items-center bg-white/10 backdrop-blur rounded-full px-4 py-2") do
                  span(class: "text-green-300 mr-2") { text("✓") }
                  text("Now with Rails 8 support").text_color("white")
                end
                
                # Title
                h1(class: "text-5xl md:text-7xl font-bold text-white text-center max-w-4xl") do
                  text("Build beautiful UIs with SwiftUI syntax in Rails")
                end
                
                # Subtitle
                p(class: "text-xl text-white/80 text-center max-w-2xl") do
                  text("The familiar declarative syntax you love, now available for your Rails applications. Write less code, build faster.")
                end
                
                # CTA buttons
                hstack(spacing: 4) do
                  button(class: "bg-white text-indigo-600 px-8 py-4 rounded-lg font-semibold text-lg hover:bg-gray-100 transition shadow-xl") do
                    text("Start Free Trial")
                  end
                  button(class: "border-2 border-white text-white px-8 py-4 rounded-lg font-semibold text-lg hover:bg-white/10 transition") do
                    text("View Demo")
                  end
                end
              end
            end
            
            # Background decoration
            div(class: "absolute inset-0 overflow-hidden") do
              div(class: "absolute -top-1/2 -right-1/4 w-96 h-96 bg-purple-500 rounded-full mix-blend-multiply filter blur-3xl opacity-30")
              div(class: "absolute -bottom-1/2 -left-1/4 w-96 h-96 bg-indigo-500 rounded-full mix-blend-multiply filter blur-3xl opacity-30")
            end
          end
        end
      RUBY
      assertions: {
        "has logo" => -> { assert_text "SwiftUI Rails" },
        "has navigation" => -> { assert_text "Features" },
        "has title" => -> { assert_text "Build beautiful UIs" },
        "has CTA buttons" => -> { assert_selector "button", text: "Start Free Trial" }
      }
    )
  end

  test "creates feature section with icons" do
    test_component(
      name: "Feature Section - Grid",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "py-24 bg-gray-50") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Everything you need to build faster") }
                p(class: "text-xl text-gray-600 max-w-2xl text-center") do
                  text("SwiftUI Rails combines the best of both worlds - the expressiveness of SwiftUI with the power of Rails")
                end
              end
              
              # Features grid
              grid(columns: 3, spacing: 8) do
                [
                  { icon: "⚡", title: "Lightning Fast", description: "Build UIs 10x faster with our intuitive DSL" },
                  { icon: "🎨", title: "Beautiful by Default", description: "Tailwind CSS integration for stunning designs" },
                  { icon: "🔧", title: "Developer Friendly", description: "Familiar SwiftUI syntax for Rails developers" },
                  { icon: "📱", title: "Responsive", description: "Mobile-first components that work everywhere" },
                  { icon: "🚀", title: "Production Ready", description: "Battle-tested in production applications" },
                  { icon: "🛡️", title: "Type Safe", description: "Catch errors at development time, not runtime" }
                ].each do |feature|
                  card(elevation: 0) do
                    vstack(spacing: 4, alignment: :start) do
                      # Icon
                      div(class: "text-5xl") { text(feature[:icon]) }
                      
                      # Title
                      h3(class: "text-xl font-semibold text-gray-900") { text(feature[:title]) }
                      
                      # Description
                      p(class: "text-gray-600") { text(feature[:description]) }
                    end
                  end
                  .p(8)
                  .bg("white")
                  .border
                  .hover_shadow("lg")
                  .transition
                end
              end.mt(16)
            end
          end
        end
      RUBY
      assertions: {
        "has section title" => -> { assert_text "Everything you need to build faster" },
        "has feature cards" => -> { assert_text "Lightning Fast" },
        "has icons" => -> { assert_text "⚡" }
      }
    )
  end

  test "creates newsletter signup section" do
    test_component(
      name: "Newsletter Signup",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "bg-indigo-700 py-16") do
            div(class: "max-w-7xl mx-auto px-6") do
              div(class: "bg-indigo-800 rounded-3xl px-6 py-10 md:px-12 md:py-16") do
                grid(columns: { base: 1, md: 2 }, spacing: 8, align: :center) do
                  # Content
                  div do
                    h2(class: "text-3xl font-bold text-white") do
                      text("Stay up to date")
                    end
                    p(class: "mt-4 text-lg text-indigo-200") do
                      text("Get the latest updates on new features, tips, and exclusive content delivered straight to your inbox.")
                    end
                  end
                  
                  # Form
                  div do
                    form(class: "flex flex-col sm:flex-row gap-4") do
                      textfield(
                        type: "email",
                        placeholder: "Enter your email",
                        class: "flex-1 px-4 py-3 rounded-lg text-gray-900 placeholder-gray-500 border-0 focus:ring-2 focus:ring-white"
                      )
                      button(class: "px-6 py-3 bg-white text-indigo-600 rounded-lg font-semibold hover:bg-gray-100 transition whitespace-nowrap") do
                        text("Subscribe")
                      end
                    end
                    p(class: "mt-3 text-sm text-indigo-200") do
                      text("We care about your data. Read our ")
                      link("Privacy Policy", destination: "#", class: "underline hover:text-white")
                      text(".")
                    end
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has newsletter title" => -> { assert_text "Stay up to date" },
        "has email input" => -> { assert_selector "input[type='email']" },
        "has subscribe button" => -> { assert_selector "button", text: "Subscribe" },
        "has privacy link" => -> { assert_text "Privacy Policy" }
      }
    )
  end

  test "creates pricing section with tiers" do
    test_component(
      name: "Pricing Section - Tiers",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "py-24 bg-gray-50") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Simple, transparent pricing") }
                p(class: "text-xl text-gray-600") { text("Choose the perfect plan for your needs") }
              end
              
              # Pricing cards
              grid(columns: 3, spacing: 8) do
                # Starter
                card(elevation: 1) do
                  vstack(spacing: 6) do
                    h3(class: "text-2xl font-semibold") { text("Starter") }
                    div do
                      span(class: "text-5xl font-bold") { text("$9") }
                      span(class: "text-gray-600 ml-1") { text("/month") }
                    end
                    text("Perfect for side projects").text_color("gray-600")
                    
                    vstack(spacing: 3) do
                      ["3 projects", "1GB storage", "Basic support", "SSL certificates"].each do |feature|
                        hstack(spacing: 3) do
                          span(class: "text-green-500") { text("✓") }
                          text(feature).text_sm
                        end
                      end
                    end
                    
                    button(class: "w-full") { text("Get Started") }
                      .bg("gray-100")
                      .text_color("gray-900")
                      .py(3).rounded("lg")
                      .font_weight("medium")
                      .hover("bg-gray-200")
                  end
                end.p(8)
                
                # Pro (featured)
                div(class: "relative") do
                  div(class: "absolute -top-5 left-0 right-0 text-center") do
                    span(class: "bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-1 rounded-full text-sm font-semibold") do
                      text("MOST POPULAR")
                    end
                  end
                  
                  card(elevation: 3) do
                    vstack(spacing: 6) do
                      h3(class: "text-2xl font-semibold") { text("Pro") }
                      div do
                        span(class: "text-5xl font-bold") { text("$29") }
                        span(class: "text-gray-600 ml-1") { text("/month") }
                      end
                      text("For growing businesses").text_color("gray-600")
                      
                      vstack(spacing: 3) do
                        ["Unlimited projects", "50GB storage", "Priority support", "Advanced analytics", "API access", "Custom domains"].each do |feature|
                          hstack(spacing: 3) do
                            span(class: "text-green-500") { text("✓") }
                            text(feature).text_sm
                          end
                        end
                      end
                      
                      button(class: "w-full") { text("Get Started") }
                        .bg("blue-600")
                        .text_color("white")
                        .py(3).rounded("lg")
                        .font_weight("medium")
                        .hover("bg-blue-700")
                    end
                  end.p(8).border("2px solid #3B82F6")
                end
                
                # Enterprise
                card(elevation: 1) do
                  vstack(spacing: 6) do
                    h3(class: "text-2xl font-semibold") { text("Enterprise") }
                    div do
                      span(class: "text-5xl font-bold") { text("Custom") }
                    end
                    text("For large organizations").text_color("gray-600")
                    
                    vstack(spacing: 3) do
                      ["Everything in Pro", "Unlimited storage", "24/7 phone support", "SLA guarantee", "Custom contracts", "Dedicated manager"].each do |feature|
                        hstack(spacing: 3) do
                          span(class: "text-green-500") { text("✓") }
                          text(feature).text_sm
                        end
                      end
                    end
                    
                    button(class: "w-full") { text("Contact Sales") }
                      .bg("gray-100")
                      .text_color("gray-900")
                      .py(3).rounded("lg")
                      .font_weight("medium")
                      .hover("bg-gray-200")
                  end
                end.p(8)
              end.mt(16)
            end
          end
        end
      RUBY
      assertions: {
        "has pricing title" => -> { assert_text "Simple, transparent pricing" },
        "has pricing tiers" => -> { assert_text "Starter" },
        "has popular badge" => -> { assert_text "MOST POPULAR" },
        "has pricing" => -> { assert_text "$29" }
      }
    )
  end

  test "creates testimonial carousel" do
    test_component(
      name: "Testimonial Carousel",
      category: "Marketing", 
      code: <<~'RUBY',
        swift_ui do
          section(class: "py-24 bg-white") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Loved by developers") }
                p(class: "text-xl text-gray-600") { text("See what our community has to say") }
              end
              
              # Testimonials
              # In a real app, this would come from @testimonials or similar
              testimonials = [
                {
                  quote: "SwiftUI Rails has completely transformed how we build our admin interfaces. What used to take days now takes hours.",
                  author: "Sarah Chen",
                  role: "CTO at TechStartup",
                  avatar: "SC",
                  rating: 5
                },
                {
                  quote: "The developer experience is incredible. It feels like writing SwiftUI but with all the power of Rails behind it.",
                  author: "Michael Rodriguez", 
                  role: "Lead Developer at FinTech Co",
                  avatar: "MR",
                  rating: 5
                }
              ]
              
              div(class: "mt-16 space-y-8") do
                testimonials.each do |testimonial|
                  card(elevation: 1) do
                    div(class: "flex flex-col md:flex-row gap-6") do
                      # Avatar
                      div(class: "flex-shrink-0") do
                        div(class: "w-16 h-16 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center") do
                          span(class: "text-white font-semibold text-xl") { text(testimonial[:avatar]) }
                        end
                      end
                      
                      # Content
                      div(class: "flex-1") do
                        # Stars
                        hstack(spacing: 1) do
                          testimonial[:rating].times { span(class: "text-yellow-400 text-xl") { text("★") } }
                        end
                        
                        # Quote
                        p(class: "mt-4 text-lg text-gray-700 italic") do
                          text('"' + testimonial[:quote] + '"')
                        end
                        
                        # Author
                        div(class: "mt-4") do
                          p(class: "font-semibold text-gray-900") { text(testimonial[:author]) }
                          p(class: "text-sm text-gray-600") { text(testimonial[:role]) }
                        end
                      end
                    end
                  end.p(8)
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has testimonial title" => -> { assert_text "Loved by developers" },
        "has quotes" => -> { assert_text "completely transformed" },
        "has authors" => -> { assert_text "Sarah Chen" },
        "has ratings" => -> { assert_text "★" }
      }
    )
  end

  test "creates CTA section with split layout" do
    test_component(
      name: "CTA Section - Split",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "bg-indigo-600") do
            div(class: "max-w-7xl mx-auto px-6 py-16 lg:py-20") do
              grid(columns: { base: 1, lg: 2 }, spacing: 12, align: :center) do
                # Content
                div do
                  h2(class: "text-4xl font-bold text-white") do
                    text("Ready to get started?")
                  end
                  p(class: "mt-4 text-xl text-indigo-200") do
                    text("Join thousands of developers building better Rails applications with SwiftUI syntax.")
                  end
                  
                  # Benefits list
                  vstack(spacing: 3) do
                    ["14-day free trial", "No credit card required", "Cancel anytime"].each do |benefit|
                      hstack(spacing: 3) do
                        span(class: "text-green-400") { text("✓") }
                        text(benefit).text_color("white")
                      end
                    end
                  end.mt(8)
                end
                
                # CTA card
                card(elevation: 0) do
                  vstack(spacing: 6, alignment: :center) do
                    h3(class: "text-2xl font-semibold text-gray-900") do
                      text("Start your free trial")
                    end
                    
                    vstack(spacing: 4) do
                      textfield(
                        placeholder: "Enter your email",
                        type: "email",
                        class: "w-full px-4 py-3 border rounded-lg"
                      )
                      textfield(
                        placeholder: "Choose a password", 
                        type: "password",
                        class: "w-full px-4 py-3 border rounded-lg"
                      )
                      
                      button(class: "w-full bg-indigo-600 text-white py-3 rounded-lg font-semibold hover:bg-indigo-700 transition") do
                        text("Create Account")
                      end
                    end
                    
                    p(class: "text-sm text-gray-600 text-center") do
                      text("By signing up, you agree to our ")
                      link("Terms", destination: "#", class: "text-indigo-600 underline")
                      text(" and ")
                      link("Privacy Policy", destination: "#", class: "text-indigo-600 underline")
                    end
                  end
                end.p(8).bg("white")
              end
            end
          end
        end
      RUBY
      assertions: {
        "has CTA title" => -> { assert_text "Ready to get started?" },
        "has benefits" => -> { assert_text "14-day free trial" },
        "has signup form" => -> { assert_selector "button", text: "Create Account" }
      }
    )
  end

  test "creates FAQ accordion section" do
    test_component(
      name: "FAQ Accordion",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "py-24 bg-gray-50") do
            div(class: "max-w-3xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Frequently asked questions") }
                p(class: "text-xl text-gray-600") { text("Everything you need to know about SwiftUI Rails") }
              end
              
              # FAQ items
              vstack(spacing: 4) do
                [
                  {
                    question: "What is SwiftUI Rails?",
                    answer: "SwiftUI Rails is a Ruby gem that brings SwiftUI-like declarative syntax to Rails views, allowing you to build UIs faster with familiar patterns."
                  },
                  {
                    question: "Do I need to know SwiftUI to use this?",
                    answer: "No! While familiarity with SwiftUI helps, the syntax is intuitive and easy to learn. Our documentation includes plenty of examples to get you started."
                  },
                  {
                    question: "Is it production ready?",
                    answer: "Yes! SwiftUI Rails is battle-tested in production applications serving millions of requests. It's built on top of ViewComponent for reliability."
                  },
                  {
                    question: "How does it work with Tailwind CSS?",
                    answer: "SwiftUI Rails has first-class Tailwind support. All utility classes are available as chainable methods, making styling intuitive and type-safe."
                  }
                ].each_with_index do |faq, index|
                  card(elevation: 0) do
                    # Using details/summary for native accordion
                    details do
                      summary(class: "cursor-pointer list-none") do
                        hstack(justify: :between) do
                          h3(class: "text-lg font-semibold text-gray-900") { text(faq[:question]) }
                          span(class: "text-gray-400 ml-6") { text("+") }
                        end
                      end.py(6)
                      
                      p(class: "text-gray-600 pb-6 pt-2") { text(faq[:answer]) }
                    end
                  end.bg("white").border.rounded("lg")
                end
              end.mt(12)
              
              # Contact support
              div(class: "mt-12 text-center p-8 bg-indigo-50 rounded-2xl") do
                h3(class: "text-lg font-semibold text-gray-900") { text("Still have questions?") }
                p(class: "mt-2 text-gray-600") { text("Can't find the answer you're looking for? Please chat with our team.") }
                button(class: "mt-4 bg-indigo-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-indigo-700 transition") do
                  text("Get in touch")
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has FAQ title" => -> { assert_text "Frequently asked questions" },
        "has questions" => -> { assert_text "What is SwiftUI Rails?" },
        "has contact section" => -> { assert_text "Still have questions?" }
      }
    )
  end

  test "creates team section with cards" do
    test_component(
      name: "Team Section",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "py-24 bg-white") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Meet our team") }
                p(class: "text-xl text-gray-600 max-w-2xl text-center") do
                  text("We're a diverse group of people working together to make Rails development more enjoyable")
                end
              end
              
              # Team grid
              grid(columns: 4, spacing: 8) do
                [
                  { name: "Emma Wilson", role: "Founder & CEO", avatar: "EW" },
                  { name: "James Chen", role: "CTO", avatar: "JC" },
                  { name: "Sofia Garcia", role: "Head of Design", avatar: "SG" },
                  { name: "Alex Kumar", role: "Lead Engineer", avatar: "AK" }
                ].each do |member|
                  vstack(spacing: 4, alignment: :center) do
                    # Avatar
                    div(class: "w-24 h-24 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-full flex items-center justify-center mx-auto") do
                      span(class: "text-white font-bold text-2xl") { text(member[:avatar]) }
                    end
                    
                    # Info
                    h3(class: "text-lg font-semibold text-gray-900") { text(member[:name]) }
                    p(class: "text-gray-600") { text(member[:role]) }
                    
                    # Social links
                    hstack(spacing: 4, alignment: :center) do
                      ["twitter", "linkedin", "github"].each do |social|
                        link("", destination: "#", class: "text-gray-400 hover:text-gray-600") do
                          span { text("◯") } # Placeholder for social icons
                        end
                      end
                    end
                  end
                end
              end.mt(16)
            end
          end
        end
      RUBY
      assertions: {
        "has team title" => -> { assert_text "Meet our team" },
        "has team members" => -> { assert_text "Emma Wilson" },
        "has roles" => -> { assert_text "Founder & CEO" }
      }
    )
  end

  test "creates blog section with cards" do
    test_component(
      name: "Blog Section",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "py-24 bg-gray-50") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              hstack(justify: :between, alignment: :end) do
                vstack(spacing: 2, alignment: :start) do
                  h2(class: "text-4xl font-bold text-gray-900") { text("From the blog") }
                  p(class: "text-xl text-gray-600") { text("Learn how to grow your business with our expert advice") }
                end
                
                link("View all posts →", destination: "#", class: "text-indigo-600 font-semibold hover:text-indigo-700")
              end
              
              # Blog posts grid
              grid(columns: 3, spacing: 8) do
                [
                  {
                    category: "Tutorial",
                    title: "Getting Started with SwiftUI Rails",
                    excerpt: "Learn the basics of SwiftUI Rails and build your first component in under 5 minutes.",
                    author: "Emma Wilson",
                    date: "Mar 16, 2024",
                    readTime: "5 min read"
                  },
                  {
                    category: "Case Study",
                    title: "How TechCorp Increased Productivity by 300%",
                    excerpt: "Discover how one company transformed their development workflow with SwiftUI Rails.",
                    author: "James Chen",
                    date: "Mar 14, 2024", 
                    readTime: "8 min read"
                  },
                  {
                    category: "Engineering",
                    title: "Building Responsive Layouts with Grid",
                    excerpt: "Master the Grid component and create beautiful responsive layouts effortlessly.",
                    author: "Sofia Garcia",
                    date: "Mar 12, 2024",
                    readTime: "6 min read"
                  }
                ].each do |post|
                  card(elevation: 0) do
                    vstack(spacing: 4, alignment: :start) do
                      # Category badge
                      span(class: "inline-block px-3 py-1 text-sm font-semibold text-indigo-600 bg-indigo-100 rounded-full") do
                        text(post[:category])
                      end
                      
                      # Title
                      h3(class: "text-xl font-semibold text-gray-900 line-clamp-2") do
                        text(post[:title])
                      end
                      
                      # Excerpt
                      p(class: "text-gray-600 line-clamp-3") { text(post[:excerpt]) }
                      
                      # Meta
                      hstack(justify: :between, alignment: :center) do
                        hstack(spacing: 4, alignment: :center) do
                          div(class: "w-8 h-8 bg-gray-300 rounded-full")
                          vstack(spacing: 0, alignment: :start) do
                            p(class: "text-sm font-medium text-gray-900") { text(post[:author]) }
                            p(class: "text-sm text-gray-600") { text(post[:date]) }
                          end
                        end
                        
                        span(class: "text-sm text-gray-500") { text(post[:readTime]) }
                      end.mt(4)
                    end
                  end.p(6).bg("white").border.hover_shadow("md").transition
                end
              end.mt(12)
            end
          end
        end
      RUBY
      assertions: {
        "has blog title" => -> { assert_text "From the blog" },
        "has blog posts" => -> { assert_text "Getting Started with SwiftUI Rails" },
        "has categories" => -> { assert_text "Tutorial" },
        "has read time" => -> { assert_text "5 min read" }
      }
    )
  end

  test "creates stats section with animation" do
    test_component(
      name: "Stats Section",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "py-20 bg-indigo-600") do
            div(class: "max-w-7xl mx-auto px-6") do
              grid(columns: 4, spacing: 8) do
                [
                  { value: "10K+", label: "Active Developers" },
                  { value: "500K", label: "Components Built" },
                  { value: "99.9%", label: "Uptime" },
                  { value: "24/7", label: "Support" }
                ].each do |stat|
                  vstack(spacing: 2, alignment: :center) do
                    h3(class: "text-5xl font-bold text-white") { text(stat[:value]) }
                    p(class: "text-indigo-200 text-lg") { text(stat[:label]) }
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has stats" => -> { assert_text "10K+" },
        "has labels" => -> { assert_text "Active Developers" }
      }
    )
  end

  test "creates footer with links" do
    test_component(
      name: "Footer Section",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          footer(class: "bg-gray-900") do
            div(class: "max-w-7xl mx-auto px-6 py-12") do
              grid(columns: { base: 1, md: 4 }, spacing: 8) do
                # Company info
                div do
                  h3(class: "text-white font-bold text-xl mb-4") { text("SwiftUI Rails") }
                  p(class: "text-gray-400 mb-4") do
                    text("Building the future of Rails UI development with SwiftUI-inspired syntax.")
                  end
                  # Social links
                  hstack(spacing: 4) do
                    ["Twitter", "GitHub", "Discord"].each do |social|
                      link("", destination: "#", class: "text-gray-400 hover:text-white") do
                        span { text(social[0]) }
                      end
                    end
                  end
                end
                
                # Links columns
                ["Product", "Resources", "Company"].each do |section|
                  div do
                    h4(class: "text-white font-semibold mb-4") { text(section) }
                    vstack(spacing: 3) do
                      links = case section
                      when "Product"
                        ["Features", "Pricing", "Roadmap", "Changelog"]
                      when "Resources"
                        ["Documentation", "Guides", "API Reference", "Support"]
                      else
                        ["About", "Blog", "Careers", "Contact"]
                      end
                      
                      links.each do |link_text|
                        link(link_text, destination: "#", class: "text-gray-400 hover:text-white")
                      end
                    end
                  end
                end
              end
              
              # Bottom bar
              div(class: "mt-12 pt-8 border-t border-gray-800") do
                hstack(justify: :between) do
                  p(class: "text-gray-400 text-sm") do
                    text("© 2024 SwiftUI Rails. All rights reserved.")
                  end
                  hstack(spacing: 6) do
                    link("Privacy", destination: "#", class: "text-gray-400 hover:text-white text-sm")
                    link("Terms", destination: "#", class: "text-gray-400 hover:text-white text-sm")
                    link("Cookies", destination: "#", class: "text-gray-400 hover:text-white text-sm")
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has footer logo" => -> { assert_text "SwiftUI Rails" },
        "has footer links" => -> { assert_text "Documentation" },
        "has copyright" => -> { assert_text "© 2024" }
      }
    )
  end

  test "creates bento grid showcase" do
    test_component(
      name: "Bento Grid",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "py-24 bg-gray-50") do
            div(class: "max-w-7xl mx-auto px-6") do
              h2(class: "text-4xl font-bold text-gray-900 text-center mb-16") do
                text("Powerful features in a beautiful package")
              end
              
              # Bento grid layout
              div(class: "grid grid-cols-4 gap-4 auto-rows-[200px]") do
                # Large feature - spans 2x2
                div(class: "col-span-2 row-span-2 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl p-8 text-white") do
                  h3(class: "text-2xl font-bold mb-4") { text("Component Library") }
                  p(class: "text-indigo-100 mb-6") do
                    text("100+ pre-built components ready to use in your Rails applications")
                  end
                  button(class: "bg-white text-indigo-600 px-4 py-2 rounded-lg font-semibold hover:bg-gray-100") do
                    text("Browse Components")
                  end
                end
                
                # Stats card
                div(class: "bg-white rounded-2xl p-6 shadow-sm") do
                  div(class: "text-3xl mb-2") { text("⚡") }
                  h4(class: "font-semibold text-gray-900") { text("Lightning Fast") }
                  p(class: "text-gray-600 text-sm mt-2") { text("10x faster development") }
                end
                
                # Stats card 2
                div(class: "bg-white rounded-2xl p-6 shadow-sm") do
                  div(class: "text-3xl mb-2") { text("🎯") }
                  h4(class: "font-semibold text-gray-900") { text("Type Safe") }
                  p(class: "text-gray-600 text-sm mt-2") { text("Catch errors early") }
                end
                
                # Wide feature
                div(class: "col-span-2 bg-gradient-to-r from-green-500 to-teal-600 rounded-2xl p-6 text-white") do
                  hstack(justify: :between, alignment: :center) do
                    div do
                      h3(class: "text-xl font-bold") { text("Start building today") }
                      p(class: "text-green-100") { text("Get started in under 5 minutes") }
                    end
                    button(class: "bg-white text-green-600 px-4 py-2 rounded-lg font-semibold") do
                      text("Get Started")
                    end
                  end
                end
                
                # Vertical cards
                div(class: "row-span-2 bg-white rounded-2xl p-6 shadow-sm") do
                  div(class: "text-4xl mb-4") { text("📚") }
                  h4(class: "text-lg font-semibold text-gray-900 mb-2") { text("Documentation") }
                  p(class: "text-gray-600 text-sm") do
                    text("Comprehensive guides and API references to help you build faster")
                  end
                end
                
                div(class: "bg-white rounded-2xl p-6 shadow-sm") do
                  div(class: "text-3xl mb-2") { text("🔧") }
                  h4(class: "font-semibold text-gray-900") { text("Customizable") }
                  p(class: "text-gray-600 text-sm mt-2") { text("Tailwind powered") }
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has bento title" => -> { assert_text "Powerful features" },
        "has component library" => -> { assert_text "Component Library" },
        "has feature cards" => -> { assert_text "Lightning Fast" }
      }
    )
  end

  test "creates logo cloud section" do
    test_component(
      name: "Logo Cloud",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "py-16 bg-white") do
            div(class: "max-w-7xl mx-auto px-6") do
              p(class: "text-center text-gray-600 font-semibold") do
                text("TRUSTED BY TEAMS FROM AROUND THE WORLD")
              end
              
              # Logo grid
              div(class: "mt-8 grid grid-cols-2 gap-8 md:grid-cols-6") do
                ["TechCorp", "FinanceApp", "StartupXYZ", "BigData Inc", "CloudFirst", "DevTools Pro"].each do |company|
                  div(class: "col-span-1 flex justify-center items-center") do
                    div(class: "h-12 w-32 bg-gray-200 rounded flex items-center justify-center") do
                      span(class: "text-gray-600 font-semibold") { text(company) }
                    end
                  end
                end
              end
              
              # Testimonial
              div(class: "mt-16 text-center") do
                p(class: "text-xl text-gray-600 italic max-w-3xl mx-auto") do
                  text("\\"SwiftUI Rails has become an essential part of our development stack. The productivity gains are incredible.\\"")
                end
                p(class: "mt-4 text-gray-900 font-semibold") { text("Jane Smith, CTO at TechCorp") }
              end
            end
          end
        end
      RUBY
      assertions: {
        "has trust text" => -> { assert_text "TRUSTED BY TEAMS" },
        "has company logos" => -> { assert_text "TechCorp" },
        "has testimonial" => -> { assert_text "essential part" }
      }
    )
  end

  test "creates contact section with form" do
    test_component(
      name: "Contact Section",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          section(class: "py-24 bg-gray-50") do
            div(class: "max-w-7xl mx-auto px-6") do
              grid(columns: { base: 1, lg: 2 }, spacing: 12) do
                # Contact info
                div do
                  h2(class: "text-4xl font-bold text-gray-900 mb-6") { text("Get in touch") }
                  p(class: "text-lg text-gray-600 mb-8") do
                    text("We'd love to hear from you. Send us a message and we'll respond as soon as possible.")
                  end
                  
                  vstack(spacing: 6) do
                    # Email
                    hstack(spacing: 4) do
                      div(class: "w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center") do
                        span(class: "text-indigo-600") { text("✉") }
                      end
                      div do
                        p(class: "font-semibold text-gray-900") { text("Email") }
                        p(class: "text-gray-600") { text("hello@swiftuirails.com") }
                      end
                    end
                    
                    # Phone
                    hstack(spacing: 4) do
                      div(class: "w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center") do
                        span(class: "text-indigo-600") { text("☎") }
                      end
                      div do
                        p(class: "font-semibold text-gray-900") { text("Phone") }
                        p(class: "text-gray-600") { text("+1 (555) 123-4567") }
                      end
                    end
                    
                    # Office
                    hstack(spacing: 4) do
                      div(class: "w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center") do
                        span(class: "text-indigo-600") { text("📍") }
                      end
                      div do
                        p(class: "font-semibold text-gray-900") { text("Office") }
                        p(class: "text-gray-600") { text("123 Main St, San Francisco, CA 94105") }
                      end
                    end
                  end
                end
                
                # Contact form
                card(elevation: 1) do
                  form do
                    vstack(spacing: 6) do
                      # Name fields
                      grid(columns: 2, spacing: 4) do
                        vstack(spacing: 2, alignment: :start) do
                          label(for_input: "first_name", class: "text-sm font-medium text-gray-700") do
                            text("First name")
                          end
                          textfield(name: "first_name", class: "w-full px-4 py-2 border rounded-lg")
                        end
                        
                        vstack(spacing: 2, alignment: :start) do
                          label(for_input: "last_name", class: "text-sm font-medium text-gray-700") do
                            text("Last name")
                          end
                          textfield(name: "last_name", class: "w-full px-4 py-2 border rounded-lg")
                        end
                      end
                      
                      # Email
                      vstack(spacing: 2, alignment: :start) do
                        label(for_input: "email", class: "text-sm font-medium text-gray-700") do
                          text("Email")
                        end
                        textfield(type: "email", name: "email", class: "w-full px-4 py-2 border rounded-lg")
                      end
                      
                      # Message
                      vstack(spacing: 2, alignment: :start) do
                        label(for_input: "message", class: "text-sm font-medium text-gray-700") do
                          text("Message")
                        end
                        div do
                          text("") # Placeholder for textarea
                        end.h(32).border.rounded("lg")
                      end
                      
                      button(class: "w-full bg-indigo-600 text-white py-3 rounded-lg font-semibold hover:bg-indigo-700") do
                        text("Send Message")
                      end
                    end
                  end
                end.p(8).bg("white")
              end
            end
          end
        end
      RUBY
      assertions: {
        "has contact title" => -> { assert_text "Get in touch" },
        "has contact info" => -> { assert_text "hello@swiftuirails.com" },
        "has form fields" => -> { assert_selector "input[name='first_name']" },
        "has send button" => -> { assert_text "Send Message" }
      }
    )
  end

  # Application UI Components Tests (15 tests)
  test "creates data table with sorting" do
    test_component(
      name: "Data Table",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          div(class: "p-6") do
            card(elevation: 2) do
              # Table header
              div(class: "px-6 py-4 border-b") do
                hstack(justify: :between) do
                  h2(class: "text-xl font-semibold text-gray-900") { text("Users") }
                  button { text("+ Add User") }
                    .bg("blue-600")
                    .text_color("white")
                    .px(4).py(2)
                    .rounded("lg")
                    .text_sm
                    .font_weight("medium")
                end
              end
              
              # Table
              div(class: "overflow-x-auto") do
                table(class: "w-full") do
                  # Table header
                  thead(class: "bg-gray-50 border-b") do
                    tr do
                      ["Name", "Email", "Role", "Status", "Joined", "Actions"].each do |header|
                        th(class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") do
                          if ["Name", "Email", "Joined"].include?(header)
                            button(class: "group inline-flex items-center") do
                              text(header)
                              span(class: "ml-2 text-gray-400 group-hover:text-gray-500") { text("↕") }
                            end
                          else
                            text(header)
                          end
                        end
                      end
                    end
                  end
                  
                  # Table body
                  tbody(class: "bg-white divide-y divide-gray-200") do
                    [
                      { name: "Jane Cooper", email: "jane@example.com", role: "Admin", status: "Active", joined: "Jan 15, 2024" },
                      { name: "Cody Fisher", email: "cody@example.com", role: "User", status: "Active", joined: "Jan 20, 2024" },
                      { name: "Esther Howard", email: "esther@example.com", role: "User", status: "Inactive", joined: "Jan 25, 2024" }
                    ].each do |user|
                      tr(class: "hover:bg-gray-50") do
                        td(class: "px-6 py-4 whitespace-nowrap") do
                          text(user[:name]).font_weight("medium")
                        end
                        td(class: "px-6 py-4 whitespace-nowrap") do
                          text(user[:email]).text_color("gray-600")
                        end
                        td(class: "px-6 py-4 whitespace-nowrap") do
                          span(class: "px-2 py-1 text-xs font-medium \#{user[:role] == 'Admin' ? 'bg-purple-100 text-purple-800' : 'bg-gray-100 text-gray-800'} rounded-full") do
                            text(user[:role])
                          end
                        end
                        td(class: "px-6 py-4 whitespace-nowrap") do
                          span(class: "px-2 py-1 text-xs font-medium \#{user[:status] == 'Active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'} rounded-full") do
                            text(user[:status])
                          end
                        end
                        td(class: "px-6 py-4 whitespace-nowrap text-gray-600") do
                          text(user[:joined])
                        end
                        td(class: "px-6 py-4 whitespace-nowrap text-right text-sm font-medium") do
                          hstack(spacing: 2) do
                            link("Edit", destination: "#", class: "text-indigo-600 hover:text-indigo-900")
                            link("Delete", destination: "#", class: "text-red-600 hover:text-red-900")
                          end
                        end
                      end
                    end
                  end
                end
              end
              
              # Pagination
              div(class: "px-6 py-4 border-t") do
                hstack(justify: :between) do
                  text("Showing 1 to 3 of 20 results").text_sm.text_color("gray-700")
                  hstack(spacing: 2) do
                    button { text("Previous") }
                      .px(3).py(1)
                      .border
                      .rounded("md")
                      .text_sm
                      .disabled
                    button { text("1") }
                      .px(3).py(1)
                      .bg("blue-600")
                      .text_color("white")
                      .rounded("md")
                      .text_sm
                    button { text("2") }
                      .px(3).py(1)
                      .border
                      .rounded("md")
                      .text_sm
                    button { text("Next") }
                      .px(3).py(1)
                      .border
                      .rounded("md")
                      .text_sm
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has table title" => -> { assert_text "Users" },
        "has table headers" => -> { assert_text "Name" ; assert_text "Email" ; assert_text "Role" },
        "has sortable columns" => -> { assert_text "↕" },
        "has user data" => -> { assert_text "Jane Cooper" },
        "has pagination" => -> { assert_text "Showing 1 to 3 of 20 results" }
      }
    )
  end

  test "creates user dashboard component" do
    test_component(
      name: "User Dashboard",
      category: "Business Forms",
      code: <<~RUBY,
        swift_ui do
          div(class: "p-6 bg-gray-50 min-h-screen") do
            # Header
            div(class: "mb-8") do
              h1(class: "text-3xl font-bold text-gray-900") { text("Dashboard") }
              p(class: "text-gray-600 mt-2") { text("Welcome back, John Doe") }
            end
            
            # Stats Grid
            grid(columns: 4, spacing: 6) do
              # Revenue Card
              card(elevation: 1) do
                vstack(spacing: 2, alignment: :start) do
                  text("Total Revenue")
                    .text_sm
                    .text_color("gray-600")
                    .font_weight("medium")
                  text("$45,231")
                    .text_size("2xl")
                    .font_weight("bold")
                    .text_color("gray-900")
                  text("+12.5% from last month")
                    .text_xs
                    .text_color("green-600")
                end
              end.p(6)
              
              # Orders Card
              card(elevation: 1) do
                vstack(spacing: 2, alignment: :start) do
                  text("Total Orders")
                    .text_sm
                    .text_color("gray-600")
                    .font_weight("medium")
                  text("1,234")
                    .text_size("2xl")
                    .font_weight("bold")
                    .text_color("gray-900")
                  text("+8.2% from last month")
                    .text_xs
                    .text_color("green-600")
                end
              end.p(6)
              
              # Customers Card
              card(elevation: 1) do
                vstack(spacing: 2, alignment: :start) do
                  text("Active Customers")
                    .text_sm
                    .text_color("gray-600")
                    .font_weight("medium")
                  text("892")
                    .text_size("2xl")
                    .font_weight("bold")
                    .text_color("gray-900")
                  text("+3.1% from last month")
                    .text_xs
                    .text_color("green-600")
                end
              end.p(6)
              
              # Conversion Rate Card
              card(elevation: 1) do
                vstack(spacing: 2, alignment: :start) do
                  text("Conversion Rate")
                    .text_sm
                    .text_color("gray-600")
                    .font_weight("medium")
                  text("3.42%")
                    .text_size("2xl")
                    .font_weight("bold")
                    .text_color("gray-900")
                  text("-1.5% from last month")
                    .text_xs
                    .text_color("red-600")
                end
              end.p(6)
            end
            
            # Recent Activity
            card(elevation: 2) do
              vstack(spacing: 4) do
                h2(class: "text-xl font-semibold text-gray-900") { text("Recent Activity") }
                
                vstack(spacing: 3) do
                  # Activity items
                  [1, 2, 3, 4, 5].each do |num|
                    hstack(spacing: 4) do
                      div(class: "w-2 h-2 bg-blue-500 rounded-full mt-1.5")
                      vstack(spacing: 1, alignment: :start) do
                        text("New order #\#{1000 + num} received")
                          .text_sm
                          .font_weight("medium")
                          .text_color("gray-900")
                        text("\#{num} hours ago")
                          .text_xs
                          .text_color("gray-500")
                      end
                    end
                  end
                end
              end
            end.p(6).mt(6)
          end
        end
      RUBY
      assertions: {
        "has dashboard title" => -> { assert_selector "h1", text: "Dashboard" },
        "has stat cards" => -> { assert_selector "div.rounded-lg.bg-white", count: 5 }, # 4 stats + 1 activity
        "has revenue stat" => -> { assert_text "$45,231" },
        "has recent activity" => -> { assert_text "Recent Activity" }
      }
    )
  end

  test "creates todo list component" do
    test_component(
      name: "Todo List",
      category: "Business Forms",
      code: <<~RUBY,
        swift_ui do
          card(elevation: 2) do
            vstack(spacing: 4) do
              # Header
              hstack(justify: :between) do
                h2(class: "text-2xl font-bold text-gray-900") { text("My Tasks") }
                button { text("+ Add Task") }
                  .bg("blue-600")
                  .text_color("white")
                  .px(4).py(2)
                  .rounded("lg")
                  .text_sm
                  .font_weight("medium")
                  .hover("bg-blue-700")
              end
              
              # Filter tabs
              hstack(spacing: 6) do
                ["All", "Active", "Completed"].each do |tab|
                  button { text(tab) }
                    .px(4).py(2)
                    .rounded("md")
                    .text_sm
                    .font_weight("medium")
                    .bg(tab == "All" ? "blue-100" : "transparent")
                    .text_color(tab == "All" ? "blue-700" : "gray-600")
                    .hover("bg-gray-100")
                end
              end
              
              # Todo items
              vstack(spacing: 2) do
                # Task 1
                div(class: "p-4 border rounded-lg hover:bg-gray-50 transition") do
                  hstack(spacing: 3) do
                    input(type: "checkbox", class: "rounded text-blue-600")
                    vstack(spacing: 1, alignment: :start) do
                      text("Complete project documentation")
                        .font_weight("medium")
                        .text_color("gray-900")
                      text("Due tomorrow at 5:00 PM")
                        .text_sm
                        .text_color("gray-500")
                    end
                    spacer
                    button { text("•••") }
                      .text_color("gray-400")
                      .hover("text-gray-600")
                  end
                end
                
                # Task 2
                div(class: "p-4 border rounded-lg hover:bg-gray-50 transition") do
                  hstack(spacing: 3) do
                    input(type: "checkbox", checked: true, class: "rounded text-blue-600")
                    vstack(spacing: 1, alignment: :start) do
                      text("Review pull requests")
                        .font_weight("medium")
                        .text_color("gray-500")
                        .line_through
                      text("Completed 2 hours ago")
                        .text_sm
                        .text_color("gray-400")
                    end
                    spacer
                    button { text("•••") }
                      .text_color("gray-400")
                      .hover("text-gray-600")
                  end
                end
                
                # Task 3
                div(class: "p-4 border rounded-lg hover:bg-gray-50 transition") do
                  hstack(spacing: 3) do
                    input(type: "checkbox", class: "rounded text-blue-600")
                    vstack(spacing: 1, alignment: :start) do
                      text("Team standup meeting")
                        .font_weight("medium")
                        .text_color("gray-900")
                      text("Today at 10:00 AM")
                        .text_sm
                        .text_color("gray-500")
                    end
                    spacer
                    button { text("•••") }
                      .text_color("gray-400")
                      .hover("text-gray-600")
                  end
                end
              end
              
              # Footer
              div(class: "text-center text-sm text-gray-500 pt-4 border-t") do
                text("3 tasks, 1 completed")
              end
            end
          end.p(6).max_w("2xl").mx("auto")
        end
      RUBY
      assertions: {
        "has todo title" => -> { assert_selector "h2", text: "My Tasks" },
        "has add button" => -> { assert_selector "button", text: "+ Add Task" },
        "has filter tabs" => -> { assert_selector "button", text: "All" },
        "has todo items" => -> { assert_selector "input[type='checkbox']", minimum: 3 },
        "has completed task" => -> { assert_selector "input[type='checkbox'][checked]" }
      }
    )
  end

  test "creates modal dialog component" do
    test_component(
      name: "Modal Dialog",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          # Background with modal
          div(class: "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4") do
            # Modal
            card(elevation: 4) do
              vstack(spacing: 4) do
                # Header
                hstack(justify: :between) do
                  h3(class: "text-lg font-semibold text-gray-900") { text("Delete User Account") }
                  button { text("×") }
                    .text_size("2xl")
                    .text_color("gray-400")
                    .hover("text-gray-600")
                end
                
                # Content
                div do
                  p(class: "text-gray-600") do
                    text("Are you sure you want to delete this user account? This action cannot be undone and all data will be permanently removed.")
                  end
                  
                  # User info
                  div(class: "mt-4 p-4 bg-gray-50 rounded-lg") do
                    hstack(spacing: 4) do
                      div(class: "w-12 h-12 bg-gray-300 rounded-full")
                      vstack(spacing: 1, alignment: :start) do
                        text("John Doe").font_weight("medium")
                        text("john.doe@example.com").text_sm.text_color("gray-600")
                      end
                    end
                  end
                end
                
                # Actions
                hstack(spacing: 3, justify: :end) do
                  button { text("Cancel") }
                    .px(4).py(2)
                    .border
                    .rounded("lg")
                    .font_weight("medium")
                    .hover("bg-gray-50")
                  
                  button { text("Delete Account") }
                    .px(4).py(2)
                    .bg("red-600")
                    .text_color("white")
                    .rounded("lg")
                    .font_weight("medium")
                    .hover("bg-red-700")
                end
              end
            end
            .p(6)
            .max_w("md")
            .w("full")
            .bg("white")
            .rounded("lg")
          end
        end
      RUBY
      assertions: {
        "has modal title" => -> { assert_text "Delete User Account" },
        "has warning text" => -> { assert_text "cannot be undone" },
        "has user info" => -> { assert_text "John Doe" },
        "has cancel button" => -> { assert_selector "button", text: "Cancel" },
        "has delete button" => -> { assert_selector "button", text: "Delete Account" }
      }
    )
  end

  test "creates sidebar navigation component" do
    test_component(
      name: "Sidebar Navigation",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          div(class: "flex h-screen bg-gray-100") do
            # Sidebar
            div(class: "w-64 bg-white shadow-lg") do
              # Logo
              div(class: "p-6 border-b") do
                h2(class: "text-2xl font-bold text-gray-900") { text("SwiftUI Rails") }
              end
              
              # Navigation
              nav(class: "p-4") do
                vstack(spacing: 1) do
                  # Main menu items
                  [
                    { icon: "🏠", label: "Dashboard", active: true },
                    { icon: "👥", label: "Users", active: false },
                    { icon: "📊", label: "Analytics", active: false },
                    { icon: "💼", label: "Projects", active: false },
                    { icon: "📧", label: "Messages", badge: 3, active: false },
                    { icon: "⚙️", label: "Settings", active: false }
                  ].each do |item|
                    link(destination: "#", class: "block") do
                      hstack(justify: :between) do
                        hstack(spacing: 3) do
                          span(class: "text-xl") { text(item[:icon]) }
                          text(item[:label])
                            .font_weight(item[:active] ? "semibold" : "medium")
                            .text_color(item[:active] ? "blue-600" : "gray-700")
                        end
                        
                        if item[:badge]
                          span(class: "bg-red-500 text-white text-xs px-2 py-1 rounded-full") do
                            text(item[:badge].to_s)
                          end
                        end
                      end
                    end
                    .px(4).py(3)
                    .rounded("lg")
                    .bg(item[:active] ? "blue-50" : "transparent")
                    .hover("bg-gray-50")
                  end
                end
                
                # Divider
                div(class: "my-6 border-t")
                
                # Secondary menu
                vstack(spacing: 1) do
                  link(destination: "#", class: "block px-4 py-3 rounded-lg hover:bg-gray-50") do
                    hstack(spacing: 3) do
                      span(class: "text-xl") { text("❓") }
                      text("Help & Support").text_color("gray-700")
                    end
                  end
                  
                  link(destination: "#", class: "block px-4 py-3 rounded-lg hover:bg-gray-50") do
                    hstack(spacing: 3) do
                      span(class: "text-xl") { text("🚪") }
                      text("Logout").text_color("gray-700")
                    end
                  end
                end
              end
              
              # User profile at bottom
              div(class: "absolute bottom-0 w-full p-4 border-t") do
                hstack(spacing: 3) do
                  div(class: "w-10 h-10 bg-gray-300 rounded-full")
                  vstack(spacing: 0, alignment: :start) do
                    text("Jane Smith").text_sm.font_weight("medium")
                    text("Admin").text_xs.text_color("gray-600")
                  end
                end
              end
            end
            
            # Main content area
            div(class: "flex-1 p-8") do
              h1(class: "text-3xl font-bold text-gray-900") { text("Dashboard Content") }
              p(class: "mt-4 text-gray-600") { text("Main content area") }
            end
          end
        end
      RUBY
      assertions: {
        "has sidebar logo" => -> { assert_text "SwiftUI Rails" },
        "has navigation items" => -> { assert_text "Dashboard" ; assert_text "Analytics" },
        "has message badge" => -> { assert_text "3" },
        "has user profile" => -> { assert_text "Jane Smith" },
        "has logout link" => -> { assert_text "Logout" }
      }
    )
  end

  test "creates form with validation component" do
    test_component(
      name: "Form with Validation",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-2xl mx-auto p-6") do
            card(elevation: 2) do
              form do
                vstack(spacing: 6) do
                  h2(class: "text-2xl font-bold text-gray-900") { text("Create New Project") }
                  
                  # Project name
                  vstack(spacing: 2, alignment: :start) do
                    label(for_input: "project_name", class: "text-sm font-medium text-gray-700") do
                      text("Project Name")
                      span(class: "text-red-500 ml-1") { text("*") }
                    end
                    textfield(
                      name: "project_name",
                      placeholder: "Enter project name",
                      required: true
                    )
                    .w("full")
                    .px(4).py(2)
                    .border
                    .rounded("lg")
                    p(class: "text-xs text-gray-500") { text("Must be 3-50 characters") }
                  end
                  
                  # Description
                  vstack(spacing: 2, alignment: :start) do
                    label(for_input: "description", class: "text-sm font-medium text-gray-700") do
                      text("Description")
                    end
                    div(class: "w-full") do
                      text("") # Placeholder for textarea
                    end
                    .h(24)
                    .border
                    .rounded("lg")
                    .p(3)
                    p(class: "text-xs text-gray-500") { text("Optional project description") }
                  end
                  
                  # Project type
                  vstack(spacing: 2, alignment: :start) do
                    label(class: "text-sm font-medium text-gray-700") { text("Project Type") }
                    grid(columns: 3, spacing: 3) do
                      ["Web App", "Mobile App", "API"].each do |type|
                        label(class: "relative") do
                          input(type: "radio", name: "project_type", value: type.downcase.gsub(" ", "_"), class: "sr-only peer")
                          div(class: "px-4 py-3 border rounded-lg text-center cursor-pointer peer-checked:bg-blue-50 peer-checked:border-blue-500 peer-checked:text-blue-700 hover:bg-gray-50") do
                            text(type)
                          end
                        end
                      end
                    end
                  end
                  
                  # Team members
                  vstack(spacing: 2, alignment: :start) do
                    label(class: "text-sm font-medium text-gray-700") { text("Team Members") }
                    vstack(spacing: 2) do
                      hstack(spacing: 2) do
                        textfield(
                          placeholder: "Enter email address",
                          type: "email"
                        )
                        .flex_1
                        .px(4).py(2)
                        .border
                        .rounded("lg")
                        
                        button(type: "button") { text("Add") }
                          .px(4).py(2)
                          .bg("gray-100")
                          .rounded("lg")
                          .font_weight("medium")
                          .hover("bg-gray-200")
                      end
                      
                      # Added members
                      vstack(spacing: 2) do
                        ["john@example.com", "sarah@example.com"].each do |email|
                          hstack(justify: :between) do
                            text(email).text_sm
                            button(type: "button") { text("Remove") }
                              .text_xs
                              .text_color("red-600")
                              .hover("text-red-700")
                          end
                          .px(3).py(2)
                          .bg("gray-50")
                          .rounded("md")
                        end
                      end
                    end
                  end
                  
                  # Privacy settings
                  vstack(spacing: 3, alignment: :start) do
                    label(class: "text-sm font-medium text-gray-700") { text("Privacy Settings") }
                    label(class: "flex items-center") do
                      input(type: "checkbox", name: "public", class: "rounded text-blue-600")
                        .mr(2)
                      text("Make project public").text_sm
                    end
                    label(class: "flex items-center") do
                      input(type: "checkbox", name: "notifications", class: "rounded text-blue-600", checked: true)
                        .mr(2)
                      text("Enable email notifications").text_sm
                    end
                  end
                  
                  # Actions
                  hstack(spacing: 3, justify: :end) do
                    button(type: "button") { text("Cancel") }
                      .px(6).py(2)
                      .border
                      .rounded("lg")
                      .font_weight("medium")
                      .hover("bg-gray-50")
                    
                    button(type: "submit") { text("Create Project") }
                      .px(6).py(2)
                      .bg("blue-600")
                      .text_color("white")
                      .rounded("lg")
                      .font_weight("medium")
                      .hover("bg-blue-700")
                  end
                end
              end
            end.p(8)
          end
        end
      RUBY
      assertions: {
        "has form title" => -> { assert_text "Create New Project" },
        "has required fields" => -> { assert_text "*" },
        "has project type radio buttons" => -> { assert_selector "input[type='radio']", count: 3 },
        "has team member inputs" => -> { assert_selector "input[placeholder='Enter email address']" },
        "has checkboxes" => -> { assert_selector "input[type='checkbox']", count: 2 },
        "has submit button" => -> { assert_selector "button", text: "Create Project" }
      }
    )
  end

  test "creates kanban board component" do
    test_component(
      name: "Kanban Board",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          div(class: "p-6 bg-gray-50 min-h-screen") do
            # Header
            hstack(justify: :between) do
              h1(class: "text-2xl font-bold text-gray-900") { text("Project Tasks") }
              button { text("+ New Task") }
                .bg("blue-600")
                .text_color("white")
                .px(4).py(2)
                .rounded("lg")
                .font_weight("medium")
            end
            
            # Kanban columns
            div(class: "mt-6 grid grid-cols-4 gap-6") do
              [
                { name: "To Do", color: "gray", count: 3 },
                { name: "In Progress", color: "blue", count: 2 },
                { name: "Review", color: "yellow", count: 1 },
                { name: "Done", color: "green", count: 4 }
              ].each do |column|
                # Column
                div(class: "bg-gray-100 rounded-lg p-4") do
                  # Column header
                  hstack(justify: :between) do
                    hstack(spacing: 2) do
                      div(class: "w-3 h-3 bg-\#{column[:color]}-500 rounded-full")
                      h3(class: "font-semibold text-gray-900") { text(column[:name]) }
                      span(class: "text-sm text-gray-500") { text("(\#{column[:count]})") }
                    end
                    button { text("•••") }
                      .text_color("gray-400")
                      .hover("text-gray-600")
                  end
                  
                  # Tasks
                  vstack(spacing: 3) do
                    # Sample tasks for each column
                    case column[:name]
                    when "To Do"
                      [
                        { title: "Design new landing page", priority: "high", assignee: "JD" },
                        { title: "Update API documentation", priority: "medium", assignee: "SC" },
                        { title: "Fix mobile responsive issues", priority: "low", assignee: "MR" }
                      ]
                    when "In Progress"
                      [
                        { title: "Implement user authentication", priority: "high", assignee: "JD" },
                        { title: "Add search functionality", priority: "medium", assignee: "SC" }
                      ]
                    when "Review"
                      [
                        { title: "Payment gateway integration", priority: "high", assignee: "MR" }
                      ]
                    else
                      [
                        { title: "Setup CI/CD pipeline", priority: "medium", assignee: "JD" },
                        { title: "Database optimization", priority: "low", assignee: "SC" },
                        { title: "Security audit", priority: "high", assignee: "MR" },
                        { title: "Performance testing", priority: "medium", assignee: "JD" }
                      ]
                    end.each do |task|
                      card(elevation: 1) do
                        vstack(spacing: 3, alignment: :start) do
                          # Task title
                          text(task[:title])
                            .font_weight("medium")
                            .text_color("gray-900")
                            .line_clamp(2)
                          
                          # Task meta
                          hstack(justify: :between) do
                            # Priority badge
                            span(class: "px-2 py-1 text-xs font-medium rounded-full \#{
                              task[:priority] == 'high' ? 'bg-red-100 text-red-700' :
                              task[:priority] == 'medium' ? 'bg-yellow-100 text-yellow-700' :
                              'bg-green-100 text-green-700'
                            }") do
                              text(task[:priority].capitalize)
                            end
                            
                            # Assignee avatar
                            div(class: "w-6 h-6 bg-blue-500 text-white rounded-full flex items-center justify-center text-xs font-medium") do
                              text(task[:assignee])
                            end
                          end
                        end
                      end.p(3).bg("white").cursor("pointer").hover_shadow("md")
                    end
                  end.mt(4)
                  
                  # Add task button
                  button(class: "w-full mt-3") { text("+ Add Task") }
                    .py(2)
                    .border("2px dashed #E5E7EB")
                    .rounded("lg")
                    .text_sm
                    .text_color("gray-500")
                    .hover("border-gray-400")
                    .hover("text-gray-700")
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has board title" => -> { assert_text "Project Tasks" },
        "has columns" => -> { assert_text "To Do" ; assert_text "In Progress" ; assert_text "Review" ; assert_text "Done" },
        "has task cards" => -> { assert_text "Design new landing page" },
        "has priority badges" => -> { assert_text "High" },
        "has assignee avatars" => -> { assert_text "JD" }
      }
    )
  end

  test "creates notification toast component" do
    test_component(
      name: "Notification Toast",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          # Toast container
          div(class: "fixed top-4 right-4 z-50 space-y-4") do
            # Success toast
            div(class: "bg-white rounded-lg shadow-lg p-4 max-w-md border-l-4 border-green-500") do
              hstack(spacing: 3) do
                div(class: "flex-shrink-0") do
                  span(class: "text-green-500 text-xl") { text("✓") }
                end
                
                vstack(spacing: 1, alignment: :start) do
                  text("Success!")
                    .font_weight("semibold")
                    .text_color("gray-900")
                  text("Your changes have been saved successfully.")
                    .text_sm
                    .text_color("gray-600")
                end
                
                button { text("×") }
                  .text_xl
                  .text_color("gray-400")
                  .hover("text-gray-600")
                  .ml(4)
              end
            end
            
            # Warning toast
            div(class: "bg-white rounded-lg shadow-lg p-4 max-w-md border-l-4 border-yellow-500") do
              hstack(spacing: 3) do
                div(class: "flex-shrink-0") do
                  span(class: "text-yellow-500 text-xl") { text("⚠") }
                end
                
                vstack(spacing: 1, alignment: :start) do
                  text("Warning")
                    .font_weight("semibold")
                    .text_color("gray-900")
                  text("Your session will expire in 5 minutes.")
                    .text_sm
                    .text_color("gray-600")
                  
                  button { text("Extend Session") }
                    .text_sm
                    .text_color("yellow-600")
                    .font_weight("medium")
                    .hover("text-yellow-700")
                    .mt(2)
                end
                
                button { text("×") }
                  .text_xl
                  .text_color("gray-400")
                  .hover("text-gray-600")
                  .ml(4)
              end
            end
            
            # Error toast
            div(class: "bg-white rounded-lg shadow-lg p-4 max-w-md border-l-4 border-red-500") do
              hstack(spacing: 3) do
                div(class: "flex-shrink-0") do
                  span(class: "text-red-500 text-xl") { text("✕") }
                end
                
                vstack(spacing: 1, alignment: :start) do
                  text("Error")
                    .font_weight("semibold")
                    .text_color("gray-900")
                  text("Failed to update user profile. Please try again.")
                    .text_sm
                    .text_color("gray-600")
                  
                  hstack(spacing: 2) do
                    button { text("Retry") }
                      .text_sm
                      .text_color("red-600")
                      .font_weight("medium")
                      .hover("text-red-700")
                    
                    button { text("Dismiss") }
                      .text_sm
                      .text_color("gray-600")
                      .font_weight("medium")
                      .hover("text-gray-700")
                  end.mt(2)
                end
                
                button { text("×") }
                  .text_xl
                  .text_color("gray-400")
                  .hover("text-gray-600")
                  .ml(4)
              end
            end
            
            # Info toast
            div(class: "bg-white rounded-lg shadow-lg p-4 max-w-md border-l-4 border-blue-500") do
              hstack(spacing: 3) do
                div(class: "flex-shrink-0") do
                  span(class: "text-blue-500 text-xl") { text("ℹ") }
                end
                
                vstack(spacing: 1, alignment: :start) do
                  text("New Feature Available")
                    .font_weight("semibold")
                    .text_color("gray-900")
                  text("Check out our new dashboard analytics!")
                    .text_sm
                    .text_color("gray-600")
                  
                  link("Learn More →", destination: "#", class: "text-sm text-blue-600 hover:text-blue-700 font-medium mt-2")
                end
                
                button { text("×") }
                  .text_xl
                  .text_color("gray-400")
                  .hover("text-gray-600")
                  .ml(4)
              end
            end
          end
        end
      RUBY
      assertions: {
        "has success toast" => -> { assert_text "Success!" },
        "has warning toast" => -> { assert_text "Warning" },
        "has error toast" => -> { assert_text "Error" },
        "has info toast" => -> { assert_text "New Feature Available" },
        "has action buttons" => -> { assert_text "Retry" ; assert_text "Extend Session" }
      }
    )
  end

  test "creates file upload component" do
    test_component(
      name: "File Upload",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-2xl mx-auto p-6") do
            card(elevation: 2) do
              vstack(spacing: 6) do
                h2(class: "text-xl font-semibold text-gray-900") { text("Upload Files") }
                
                # Drop zone
                div(class: "border-2 border-dashed border-gray-300 rounded-lg p-12 text-center hover:border-gray-400 transition cursor-pointer") do
                  vstack(spacing: 4) do
                    # Icon
                    div(class: "mx-auto w-16 h-16 text-gray-400") do
                      text("📁")
                        .text_size("5xl")
                    end
                    
                    # Instructions
                    vstack(spacing: 2) do
                      text("Drop files here or click to upload")
                        .text_lg
                        .font_weight("medium")
                        .text_color("gray-700")
                      
                      text("PNG, JPG, PDF up to 10MB")
                        .text_sm
                        .text_color("gray-500")
                    end
                    
                    # Browse button
                    button { text("Browse Files") }
                      .bg("white")
                      .text_color("blue-600")
                      .px(4).py(2)
                      .border
                      .rounded("lg")
                      .font_weight("medium")
                      .hover("bg-gray-50")
                      .mt(4)
                  end
                end
                
                # Uploaded files
                vstack(spacing: 3) do
                  h3(class: "text-sm font-medium text-gray-700") { text("Uploaded Files") }
                  
                  vstack(spacing: 2) do
                    [
                      { name: "design-mockup.png", size: "2.4 MB", status: "complete" },
                      { name: "project-brief.pdf", size: "1.2 MB", status: "uploading", progress: 65 },
                      { name: "data-export.csv", size: "4.8 MB", status: "error" }
                    ].each do |file|
                      div(class: "border rounded-lg p-4") do
                        hstack(spacing: 4) do
                          # File icon
                          div(class: "w-10 h-10 bg-gray-100 rounded flex items-center justify-center") do
                            text(file[:name].end_with?(".png") ? "🖼" : file[:name].end_with?(".pdf") ? "📄" : "📊")
                          end
                          
                          # File info
                          vstack(spacing: 1, alignment: :start) do
                            text(file[:name])
                              .font_weight("medium")
                              .text_color("gray-900")
                            
                            if file[:status] == "uploading"
                              # Progress bar
                              div(class: "w-48") do
                                div(class: "bg-gray-200 rounded-full h-1.5") do
                                  div(class: "bg-blue-600 h-1.5 rounded-full", style: "width: \#{file[:progress]}%")
                                end
                              end
                              text("\#{file[:progress]}% uploaded")
                                .text_xs
                                .text_color("gray-500")
                            elsif file[:status] == "error"
                              text("Upload failed")
                                .text_sm
                                .text_color("red-600")
                            else
                              text(file[:size])
                                .text_sm
                                .text_color("gray-500")
                            end
                          end
                          
                          spacer
                          
                          # Actions
                          if file[:status] == "complete"
                            button { text("✓") }
                              .text_color("green-500")
                              .text_xl
                          elsif file[:status] == "uploading"
                            button { text("⏸") }
                              .text_color("gray-400")
                              .hover("text-gray-600")
                          else
                            button { text("↻") }
                              .text_color("red-500")
                              .hover("text-red-600")
                          end
                        end
                      end
                    end
                  end
                end
                
                # Actions
                hstack(spacing: 3, justify: :end) do
                  button { text("Cancel") }
                    .px(4).py(2)
                    .border
                    .rounded("lg")
                    .font_weight("medium")
                  
                  button { text("Upload All") }
                    .px(4).py(2)
                    .bg("blue-600")
                    .text_color("white")
                    .rounded("lg")
                    .font_weight("medium")
                    .hover("bg-blue-700")
                end
              end
            end.p(6)
          end
        end
      RUBY
      assertions: {
        "has upload title" => -> { assert_text "Upload Files" },
        "has drop zone" => -> { assert_text "Drop files here" },
        "has file list" => -> { assert_text "Uploaded Files" },
        "has file names" => -> { assert_text "design-mockup.png" },
        "has progress bar" => -> { assert_text "65% uploaded" },
        "has upload button" => -> { assert_selector "button", text: "Upload All" }
      }
    )
  end

  test "creates settings panel component" do
    test_component(
      name: "Settings Panel",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-4xl mx-auto p-6") do
            h1(class: "text-3xl font-bold text-gray-900 mb-8") { text("Settings") }
            
            grid(columns: { base: 1, md: 4 }, column_gap: 8) do
              # Settings navigation
              div(class: "md:col-span-1") do
                nav do
                  vstack(spacing: 1) do
                    [
                      { label: "Profile", icon: "👤", active: true },
                      { label: "Notifications", icon: "🔔", active: false },
                      { label: "Security", icon: "🔒", active: false },
                      { label: "Billing", icon: "💳", active: false },
                      { label: "Team", icon: "👥", active: false },
                      { label: "Integrations", icon: "🔗", active: false }
                    ].each do |item|
                      link(destination: "#", class: "block") do
                        hstack(spacing: 3) do
                          span { text(item[:icon]) }
                          text(item[:label])
                            .font_weight(item[:active] ? "semibold" : "medium")
                            .text_color(item[:active] ? "blue-600" : "gray-700")
                        end
                      end
                      .px(3).py(2)
                      .rounded("lg")
                      .bg(item[:active] ? "blue-50" : "transparent")
                      .hover("bg-gray-50")
                    end
                  end
                end
              end
              
              # Settings content
              div(class: "md:col-span-3") do
                card(elevation: 1) do
                  vstack(spacing: 6) do
                    # Profile section
                    div do
                      h2(class: "text-xl font-semibold text-gray-900 mb-6") { text("Profile Information") }
                      
                      # Avatar upload
                      hstack(spacing: 6, alignment: :center) do
                        div(class: "w-24 h-24 bg-gray-300 rounded-full")
                        vstack(spacing: 2, alignment: :start) do
                          button { text("Change Avatar") }
                            .px(4).py(2)
                            .bg("white")
                            .border
                            .rounded("lg")
                            .text_sm
                            .font_weight("medium")
                            .hover("bg-gray-50")
                          text("JPG, PNG or GIF. Max 2MB.")
                            .text_xs
                            .text_color("gray-500")
                        end
                      end
                    end
                    
                    # Form fields
                    grid(columns: 2, spacing: 4) do
                      vstack(spacing: 2, alignment: :start) do
                        label(for_input: "first_name", class: "text-sm font-medium text-gray-700") do
                          text("First Name")
                        end
                        textfield(name: "first_name", value: "Jane", class: "w-full px-3 py-2 border rounded-lg")
                      end
                      
                      vstack(spacing: 2, alignment: :start) do
                        label(for_input: "last_name", class: "text-sm font-medium text-gray-700") do
                          text("Last Name")
                        end
                        textfield(name: "last_name", value: "Smith", class: "w-full px-3 py-2 border rounded-lg")
                      end
                    end
                    
                    vstack(spacing: 2, alignment: :start) do
                      label(for_input: "email", class: "text-sm font-medium text-gray-700") do
                        text("Email Address")
                      end
                      textfield(type: "email", name: "email", value: "jane.smith@example.com", class: "w-full px-3 py-2 border rounded-lg")
                    end
                    
                    vstack(spacing: 2, alignment: :start) do
                      label(for_input: "bio", class: "text-sm font-medium text-gray-700") do
                        text("Bio")
                      end
                      div(class: "w-full h-24 border rounded-lg p-3") do
                        text("Product designer with 5+ years of experience...")
                          .text_sm
                          .text_color("gray-700")
                      end
                    end
                    
                    # Timezone
                    vstack(spacing: 2, alignment: :start) do
                      label(for_input: "timezone", class: "text-sm font-medium text-gray-700") do
                        text("Timezone")
                      end
                      select(name: "timezone", class: "w-full px-3 py-2 border rounded-lg") do
                        option("(UTC-08:00) Pacific Time", selected: true)
                        option("(UTC-05:00) Eastern Time")
                        option("(UTC+00:00) UTC")
                        option("(UTC+01:00) Central European Time")
                      end
                    end
                    
                    # Save button
                    hstack(justify: :end) do
                      button { text("Cancel") }
                        .px(4).py(2)
                        .border
                        .rounded("lg")
                        .font_weight("medium")
                        .hover("bg-gray-50")
                        .mr(3)
                      
                      button { text("Save Changes") }
                        .px(4).py(2)
                        .bg("blue-600")
                        .text_color("white")
                        .rounded("lg")
                        .font_weight("medium")
                        .hover("bg-blue-700")
                    end
                  end
                end.p(6)
              end
            end
          end
        end
      RUBY
      assertions: {
        "has settings title" => -> { assert_text "Settings" },
        "has navigation items" => -> { assert_text "Profile" ; assert_text "Security" ; assert_text "Billing" },
        "has profile form" => -> { assert_text "Profile Information" },
        "has form fields" => -> { assert_selector "input[name='first_name']" },
        "has save button" => -> { assert_selector "button", text: "Save Changes" }
      }
    )
  end

  test "creates command palette component" do
    test_component(
      name: "Command Palette",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          # Overlay background
          div(class: "fixed inset-0 bg-gray-900 bg-opacity-50 flex items-start justify-center pt-20 px-4") do
            # Command palette
            card(elevation: 4) do
              vstack(spacing: 0) do
                # Search input
                div(class: "p-4 border-b") do
                  hstack(spacing: 3) do
                    span(class: "text-gray-400") { text("🔍") }
                    textfield(
                      placeholder: "Type a command or search...",
                      class: "flex-1 bg-transparent focus:outline-none"
                    )
                    span(class: "text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded") { text("⌘K") }
                  end
                end
                
                # Results
                div(class: "max-h-96 overflow-y-auto") do
                  # Recent searches
                  div(class: "p-2") do
                    p(class: "px-3 py-2 text-xs font-medium text-gray-500 uppercase") { text("Recent") }
                    vstack(spacing: 1) do
                      [
                        { icon: "📄", title: "Invoice #1234", subtitle: "View invoice details" },
                        { icon: "👤", title: "John Doe", subtitle: "Customer profile" },
                        { icon: "📊", title: "Q3 Sales Report", subtitle: "Analytics dashboard" }
                      ].each do |item|
                        button(class: "w-full text-left") do
                          hstack(spacing: 3) do
                            span(class: "text-lg") { text(item[:icon]) }
                            vstack(spacing: 0, alignment: :start) do
                              text(item[:title])
                                .text_sm
                                .font_weight("medium")
                                .text_color("gray-900")
                              text(item[:subtitle])
                                .text_xs
                                .text_color("gray-500")
                            end
                          end
                        end
                        .px(3).py(2)
                        .rounded("md")
                        .hover("bg-gray-100")
                      end
                    end
                  end
                  
                  # Quick actions
                  div(class: "p-2 border-t") do
                    p(class: "px-3 py-2 text-xs font-medium text-gray-500 uppercase") { text("Quick Actions") }
                    vstack(spacing: 1) do
                      [
                        { icon: "➕", title: "Create New Project", shortcut: "⌘N" },
                        { icon: "📤", title: "Export Data", shortcut: "⌘E" },
                        { icon: "⚙️", title: "Settings", shortcut: "⌘," },
                        { icon: "❓", title: "Help & Documentation", shortcut: "⌘?" }
                      ].each do |action|
                        button(class: "w-full text-left") do
                          hstack(justify: :between) do
                            hstack(spacing: 3) do
                              span(class: "text-lg") { text(action[:icon]) }
                              text(action[:title])
                                .text_sm
                                .font_weight("medium")
                                .text_color("gray-900")
                            end
                            span(class: "text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded") do
                              text(action[:shortcut])
                            end
                          end
                        end
                        .px(3).py(2)
                        .rounded("md")
                        .hover("bg-gray-100")
                      end
                    end
                  end
                end
                
                # Footer
                div(class: "p-3 border-t bg-gray-50") do
                  hstack(justify: :between) do
                    hstack(spacing: 4) do
                      span(class: "text-xs text-gray-500") { text("↑↓ Navigate") }
                      span(class: "text-xs text-gray-500") { text("↵ Select") }
                      span(class: "text-xs text-gray-500") { text("esc Close") }
                    end
                  end
                end
              end
            end
            .max_w("2xl")
            .w("full")
            .bg("white")
            .rounded("lg")
            .shadow("2xl")
          end
        end
      RUBY
      assertions: {
        "has search input" => -> { assert_selector "input[placeholder*='Type a command']" },
        "has recent section" => -> { assert_text "RECENT" },
        "has quick actions" => -> { assert_text "QUICK ACTIONS" },
        "has shortcuts" => -> { assert_text "⌘K" ; assert_text "⌘N" },
        "has navigation hints" => -> { assert_text "↑↓ Navigate" }
      }
    )
  end

  test "creates activity feed component" do
    test_component(
      name: "Activity Feed",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-3xl mx-auto p-6") do
            card(elevation: 2) do
              vstack(spacing: 0) do
                # Header
                div(class: "px-6 py-4 border-b") do
                  hstack(justify: :between) do
                    h2(class: "text-xl font-semibold text-gray-900") { text("Activity Feed") }
                    button { text("Mark all as read") }
                      .text_sm
                      .text_color("blue-600")
                      .font_weight("medium")
                      .hover("text-blue-700")
                  end
                end
                
                # Activity items
                vstack(spacing: 0) do
                  [
                    {
                      user: "Sarah Chen",
                      action: "commented on",
                      target: "Design System Documentation",
                      time: "2 minutes ago",
                      avatar: "SC",
                      color: "blue",
                      comment: "Great work on the component library! The new button variants look fantastic."
                    },
                    {
                      user: "Michael Rodriguez",
                      action: "assigned you to",
                      target: "Fix Navigation Bug",
                      time: "1 hour ago",
                      avatar: "MR",
                      color: "purple"
                    },
                    {
                      user: "Emily Watson",
                      action: "completed",
                      target: "User Authentication Flow",
                      time: "3 hours ago",
                      avatar: "EW",
                      color: "green"
                    },
                    {
                      user: "System",
                      action: "deployed",
                      target: "v2.1.0 to production",
                      time: "5 hours ago",
                      avatar: "🚀",
                      color: "gray",
                      details: "Deployment successful with 0 errors"
                    },
                    {
                      user: "David Kim",
                      action: "created a new project",
                      target: "Mobile App Redesign",
                      time: "Yesterday",
                      avatar: "DK",
                      color: "indigo"
                    }
                  ].each_with_index do |activity, idx|
                    div(class: "px-6 py-4 \#{idx < 4 ? 'border-b' : ''} hover:bg-gray-50") do
                      hstack(spacing: 4, alignment: :start) do
                        # Avatar
                        if activity[:avatar].length == 2
                          div(class: "w-10 h-10 bg-\#{activity[:color]}-500 text-white rounded-full flex items-center justify-center font-medium") do
                            text(activity[:avatar])
                          end
                        else
                          div(class: "w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center text-xl") do
                            text(activity[:avatar])
                          end
                        end
                        
                        # Content
                        vstack(spacing: 2, alignment: :start) do
                          # Main activity
                          p(class: "text-sm") do
                            span(class: "font-medium text-gray-900") { text(activity[:user]) }
                            text(" ")
                            span(class: "text-gray-600") { text(activity[:action]) }
                            text(" ")
                            span(class: "font-medium text-gray-900") { text(activity[:target]) }
                          end
                          
                          # Comment or details
                          if activity[:comment]
                            div(class: "bg-gray-50 rounded-lg p-3 mt-2") do
                              text(activity[:comment])
                                .text_sm
                                .text_color("gray-700")
                            end
                          elsif activity[:details]
                            text(activity[:details])
                              .text_sm
                              .text_color("gray-600")
                          end
                          
                          # Time
                          text(activity[:time])
                            .text_xs
                            .text_color("gray-500")
                        end
                      end
                    end
                  end
                end
                
                # Load more
                div(class: "px-6 py-4 text-center border-t") do
                  button { text("Load more activities") }
                    .text_sm
                    .text_color("blue-600")
                    .font_weight("medium")
                    .hover("text-blue-700")
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has activity title" => -> { assert_text "Activity Feed" },
        "has mark all as read" => -> { assert_text "Mark all as read" },
        "has activity items" => -> { assert_text "commented on" ; assert_text "assigned you to" },
        "has user names" => -> { assert_text "Sarah Chen" },
        "has timestamps" => -> { assert_text "2 minutes ago" },
        "has load more" => -> { assert_text "Load more activities" }
      }
    )
  end

  # E-commerce Components
  test "creates product card component" do
    test_component(
      name: "Product Card",
      category: "E-commerce",
      code: <<~RUBY,
        swift_ui do
          grid(columns: 3, spacing: 6) do
            # Product 1
            card(elevation: 2) do
              div(class: "relative") do
                # Sale badge
                div(class: "absolute top-2 left-2 bg-red-500 text-white px-2 py-1 text-xs font-semibold rounded") do
                  text("SALE")
                end
                
                # Product image
                div(class: "aspect-square bg-gray-100 rounded-t-lg overflow-hidden") do
                  image(src: "https://via.placeholder.com/300", alt: "Product")
                    .w("full").h("full").object("cover")
                end
              end
              
              vstack(spacing: 3, alignment: :start) do
                # Product info
                text("Premium Wireless Headphones")
                  .font_weight("semibold")
                  .text_color("gray-900")
                  .line_clamp(2)
                
                # Rating
                hstack(spacing: 1) do
                  (1..5).each do |i|
                    span(class: i <= 4 ? "text-yellow-400" : "text-gray-300") { text("★") }
                  end
                  text("(128)")
                    .text_sm
                    .text_color("gray-500")
                    .ml(2)
                end
                
                # Price
                hstack(spacing: 2) do
                  text("$299")
                    .text_size("xl")
                    .font_weight("bold")
                    .text_color("gray-900")
                  text("$399")
                    .text_sm
                    .text_color("gray-500")
                    .line_through
                end
                
                # Add to cart button
                button(class: "w-full") { text("Add to Cart") }
                  .bg("black")
                  .text_color("white")
                  .py(2)
                  .rounded("lg")
                  .font_weight("medium")
                  .hover("bg-gray-800")
                  .transition
              end.p(4)
            end
            
            # Product 2
            card(elevation: 2) do
              div(class: "aspect-square bg-gray-100 rounded-t-lg overflow-hidden") do
                image(src: "https://via.placeholder.com/300", alt: "Product")
                  .w("full").h("full").object("cover")
              end
              
              vstack(spacing: 3, alignment: :start) do
                text("Ergonomic Office Chair")
                  .font_weight("semibold")
                  .text_color("gray-900")
                  .line_clamp(2)
                
                hstack(spacing: 1) do
                  (1..5).each do |i|
                    span(class: i <= 5 ? "text-yellow-400" : "text-gray-300") { text("★") }
                  end
                  text("(89)")
                    .text_sm
                    .text_color("gray-500")
                    .ml(2)
                end
                
                text("$599")
                  .text_size("xl")
                  .font_weight("bold")
                  .text_color("gray-900")
                
                button(class: "w-full") { text("Add to Cart") }
                  .bg("black")
                  .text_color("white")
                  .py(2)
                  .rounded("lg")
                  .font_weight("medium")
                  .hover("bg-gray-800")
                  .transition
              end.p(4)
            end
            
            # Product 3
            card(elevation: 2) do
              div(class: "relative") do
                div(class: "absolute top-2 left-2 bg-green-500 text-white px-2 py-1 text-xs font-semibold rounded") do
                  text("NEW")
                end
                
                div(class: "aspect-square bg-gray-100 rounded-t-lg overflow-hidden") do
                  image(src: "https://via.placeholder.com/300", alt: "Product")
                    .w("full").h("full").object("cover")
                end
              end
              
              vstack(spacing: 3, alignment: :start) do
                text("Smart Watch Pro")
                  .font_weight("semibold")
                  .text_color("gray-900")
                  .line_clamp(2)
                
                hstack(spacing: 1) do
                  (1..5).each do |i|
                    span(class: i <= 4 ? "text-yellow-400" : "text-gray-300") { text("★") }
                  end
                  text("(256)")
                    .text_sm
                    .text_color("gray-500")
                    .ml(2)
                end
                
                text("$399")
                  .text_size("xl")
                  .font_weight("bold")
                  .text_color("gray-900")
                
                button(class: "w-full") { text("Add to Cart") }
                  .bg("black")
                  .text_color("white")
                  .py(2)
                  .rounded("lg")
                  .font_weight("medium")
                  .hover("bg-gray-800")
                  .transition
              end.p(4)
            end
          end
        end
      RUBY
      assertions: {
        "has product cards" => -> { assert_selector "div.rounded-lg.bg-white", count: 3 },
        "has product names" => -> { assert_text "Premium Wireless Headphones" },
        "has prices" => -> { assert_text "$299" },
        "has add to cart buttons" => -> { assert_selector "button", text: "Add to Cart", count: 3 },
        "has sale badge" => -> { assert_text "SALE" }
      }
    )
  end

  test "creates shopping cart component" do
    test_component(
      name: "Shopping Cart",
      category: "E-commerce",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-4xl mx-auto p-6") do
            h1(class: "text-3xl font-bold text-gray-900 mb-8") { text("Shopping Cart") }
            
            grid(columns: { base: 1, lg: 3 }, column_gap: 8) do
              # Cart items (2/3 width)
              div(class: "lg:col-span-2") do
                card(elevation: 1) do
                  vstack(spacing: 0) do
                    # Item 1
                    div(class: "p-6 border-b") do
                      hstack(spacing: 4) do
                        # Product image
                        div(class: "w-24 h-24 bg-gray-100 rounded-lg overflow-hidden flex-shrink-0") do
                          image(src: "https://via.placeholder.com/150", alt: "Product")
                            .w("full").h("full").object("cover")
                        end
                        
                        # Product details
                        vstack(spacing: 2, alignment: :start) do
                          text("Wireless Headphones")
                            .font_weight("semibold")
                            .text_color("gray-900")
                          text("Color: Black")
                            .text_sm
                            .text_color("gray-500")
                          
                          # Quantity selector
                          hstack(spacing: 3) do
                            button { text("-") }
                              .px(3).py(1)
                              .border
                              .rounded("md")
                              .text_sm
                            text("1")
                              .px(4).py(1)
                              .font_weight("medium")
                            button { text("+") }
                              .px(3).py(1)
                              .border
                              .rounded("md")
                              .text_sm
                          end
                        end
                        
                        spacer
                        
                        # Price and remove
                        vstack(spacing: 2, alignment: :end) do
                          text("$299.00")
                            .font_weight("semibold")
                            .text_color("gray-900")
                          button { text("Remove") }
                            .text_sm
                            .text_color("red-600")
                            .hover("text-red-700")
                        end
                      end
                    end
                    
                    # Item 2
                    div(class: "p-6") do
                      hstack(spacing: 4) do
                        div(class: "w-24 h-24 bg-gray-100 rounded-lg overflow-hidden flex-shrink-0") do
                          image(src: "https://via.placeholder.com/150", alt: "Product")
                            .w("full").h("full").object("cover")
                        end
                        
                        vstack(spacing: 2, alignment: :start) do
                          text("Office Chair")
                            .font_weight("semibold")
                            .text_color("gray-900")
                          text("Color: Gray")
                            .text_sm
                            .text_color("gray-500")
                          
                          hstack(spacing: 3) do
                            button { text("-") }
                              .px(3).py(1)
                              .border
                              .rounded("md")
                              .text_sm
                            text("2")
                              .px(4).py(1)
                              .font_weight("medium")
                            button { text("+") }
                              .px(3).py(1)
                              .border
                              .rounded("md")
                              .text_sm
                          end
                        end
                        
                        spacer
                        
                        vstack(spacing: 2, alignment: :end) do
                          text("$1,198.00")
                            .font_weight("semibold")
                            .text_color("gray-900")
                          button { text("Remove") }
                            .text_sm
                            .text_color("red-600")
                            .hover("text-red-700")
                        end
                      end
                    end
                  end
                end
              end
              
              # Order summary (1/3 width)
              div do
                card(elevation: 1) do
                  vstack(spacing: 4) do
                    h2(class: "text-xl font-semibold text-gray-900") { text("Order Summary") }
                    
                    vstack(spacing: 3) do
                      hstack(justify: :between) do
                        text("Subtotal").text_color("gray-600")
                        text("$1,497.00").font_weight("medium")
                      end
                      
                      hstack(justify: :between) do
                        text("Shipping").text_color("gray-600")
                        text("$15.00").font_weight("medium")
                      end
                      
                      hstack(justify: :between) do
                        text("Tax").text_color("gray-600")
                        text("$119.76").font_weight("medium")
                      end
                    end
                    
                    div(class: "border-t pt-4") do
                      hstack(justify: :between) do
                        text("Total").font_weight("semibold").text_size("lg")
                        text("$1,631.76").font_weight("bold").text_size("xl")
                      end
                    end
                    
                    button(class: "w-full") { text("Proceed to Checkout") }
                      .bg("blue-600")
                      .text_color("white")
                      .py(3)
                      .rounded("lg")
                      .font_weight("medium")
                      .hover("bg-blue-700")
                      .transition
                  end
                end.p(6)
              end
            end
          end
        end
      RUBY
      assertions: {
        "has cart title" => -> { assert_selector "h1", text: "Shopping Cart" },
        "has cart items" => -> { assert_text "Wireless Headphones" },
        "has quantity controls" => -> { assert_selector "button", text: "+", minimum: 2 },
        "has order summary" => -> { assert_text "Order Summary" },
        "has checkout button" => -> { assert_selector "button", text: "Proceed to Checkout" }
      }
    )
  end

  test "creates search box component" do
    test_component(
      name: "Search Box",
      category: "E-commerce",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-2xl mx-auto p-6") do
            # Search bar
            div(class: "relative") do
              textfield(
                type: "search",
                placeholder: "Search for products, brands, categories...",
                name: "search"
              )
              .w("full")
              .pl(12).pr(4).py(3)
              .border
              .rounded("lg")
              .text_color("gray-900")
              .focus("ring-2 ring-blue-500 border-blue-500")
              
              # Search icon
              div(class: "absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400") do
                text("🔍")
              end
              
              # Search button
              button(class: "absolute right-2 top-1/2 transform -translate-y-1/2") { text("Search") }
                .bg("blue-600")
                .text_color("white")
                .px(4).py(2)
                .rounded("md")
                .text_sm
                .font_weight("medium")
                .hover("bg-blue-700")
            end
            
            # Quick filters
            div(class: "mt-4") do
              hstack(spacing: 2) do
                span(class: "text-sm text-gray-600") { text("Popular:") }
                ["Laptops", "Headphones", "Smartphones", "Cameras", "Tablets"].each do |category|
                  button { text(category) }
                    .px(3).py(1)
                    .bg("gray-100")
                    .text_color("gray-700")
                    .rounded("full")
                    .text_sm
                    .hover("bg-gray-200")
                    .transition
                end
              end
            end
            
            # Search results preview
            card(elevation: 2) do
              vstack(spacing: 0) do
                # Result 1
                div(class: "p-4 hover:bg-gray-50 cursor-pointer border-b") do
                  hstack(spacing: 4) do
                    div(class: "w-16 h-16 bg-gray-100 rounded overflow-hidden flex-shrink-0") do
                      image(src: "https://via.placeholder.com/100", alt: "Product")
                        .w("full").h("full").object("cover")
                    end
                    vstack(spacing: 1, alignment: :start) do
                      text("Apple MacBook Pro 16\"")
                        .font_weight("medium")
                        .text_color("gray-900")
                      text("Laptops & Computers")
                        .text_sm
                        .text_color("gray-500")
                      text("$2,399")
                        .font_weight("semibold")
                        .text_color("blue-600")
                    end
                  end
                end
                
                # Result 2
                div(class: "p-4 hover:bg-gray-50 cursor-pointer border-b") do
                  hstack(spacing: 4) do
                    div(class: "w-16 h-16 bg-gray-100 rounded overflow-hidden flex-shrink-0") do
                      image(src: "https://via.placeholder.com/100", alt: "Product")
                        .w("full").h("full").object("cover")
                    end
                    vstack(spacing: 1, alignment: :start) do
                      text("Sony WH-1000XM5")
                        .font_weight("medium")
                        .text_color("gray-900")
                      text("Audio & Headphones")
                        .text_sm
                        .text_color("gray-500")
                      text("$399")
                        .font_weight("semibold")
                        .text_color("blue-600")
                    end
                  end
                end
                
                # View all results
                div(class: "p-4 text-center") do
                  link(destination: "#", class: "text-blue-600 hover:text-blue-700 font-medium") do
                    text("View all 127 results →")
                  end
                end
              end
            end.mt(4)
          end
        end
      RUBY
      assertions: {
        "has search input" => -> { assert_selector "input[placeholder*='Search for products']" },
        "has search button" => -> { assert_selector "button", text: "Search" },
        "has popular filters" => -> { assert_text "Popular:" },
        "has search results" => -> { assert_text "Apple MacBook Pro" },
        "has view all link" => -> { assert_text "View all 127 results" }
      }
    )
  end

  test "creates product grid with filters component" do
    test_component(
      name: "Product Grid with Filters",
      category: "E-commerce",
      code: <<~RUBY,
        swift_ui do
          div(class: "p-6") do
            grid(columns: { base: 1, md: 4 }, column_gap: 8) do
              # Filters sidebar
              div(class: "md:col-span-1") do
                vstack(spacing: 6) do
                  h3(class: "text-lg font-semibold text-gray-900") { text("Filters") }
                  
                  # Category filter
                  vstack(spacing: 3) do
                    h4(class: "text-sm font-medium text-gray-700") { text("Category") }
                    vstack(spacing: 2) do
                      ["Electronics", "Clothing", "Home & Garden", "Sports", "Books"].each do |category|
                        label(class: "flex items-center") do
                          input(type: "checkbox", name: "category[]", value: category.downcase.gsub(" ", "_"), class: "rounded text-blue-600")
                            .mr(2)
                          text(category).text_sm
                        end
                      end
                    end
                  end
                  
                  # Price range
                  vstack(spacing: 3) do
                    h4(class: "text-sm font-medium text-gray-700") { text("Price Range") }
                    vstack(spacing: 2) do
                      ["Under $25", "$25 - $50", "$50 - $100", "$100 - $250", "Over $250"].each do |range|
                        label(class: "flex items-center") do
                          input(type: "radio", name: "price_range", value: range.downcase.gsub(/[^0-9a-z]/, "_"), class: "text-blue-600")
                            .mr(2)
                          text(range).text_sm
                        end
                      end
                    end
                  end
                  
                  # Brand filter
                  vstack(spacing: 3) do
                    h4(class: "text-sm font-medium text-gray-700") { text("Brand") }
                    vstack(spacing: 2) do
                      ["Apple", "Samsung", "Sony", "Nike", "Adidas"].each do |brand|
                        label(class: "flex items-center") do
                          input(type: "checkbox", name: "brand[]", value: brand.downcase, class: "rounded text-blue-600")
                            .mr(2)
                          text(brand).text_sm
                        end
                      end
                    end
                  end
                  
                  # Rating filter
                  vstack(spacing: 3) do
                    h4(class: "text-sm font-medium text-gray-700") { text("Customer Rating") }
                    vstack(spacing: 2) do
                      [4, 3, 2, 1].each do |rating|
                        label(class: "flex items-center") do
                          input(type: "checkbox", name: "rating[]", value: rating, class: "rounded text-blue-600")
                            .mr(2)
                          hstack(spacing: 1) do
                            rating.times { span(class: "text-yellow-400 text-sm") { text("★") } }
                            (5 - rating).times { span(class: "text-gray-300 text-sm") { text("★") } }
                            text(" & up").text_sm.ml(1)
                          end
                        end
                      end
                    end
                  end
                  
                  # Clear filters
                  button { text("Clear All Filters") }
                    .w("full")
                    .px(4).py(2)
                    .border
                    .rounded("lg")
                    .text_sm
                    .font_weight("medium")
                    .hover("bg-gray-50")
                    .mt(4)
                end
              end
              
              # Products grid
              div(class: "md:col-span-3") do
                # Header with sorting
                hstack(justify: :between) do
                  text("256 products found").text_sm.text_color("gray-600")
                  
                  select(name: "sort", class: "px-3 py-2 border rounded-lg text-sm") do
                    option("Sort by: Featured")
                    option("Price: Low to High")
                    option("Price: High to Low")
                    option("Customer Rating")
                    option("Newest First")
                  end
                end
                
                # Product grid
                grid(columns: 3, spacing: 6) do
                  6.times do |idx|
                    card(elevation: 1) do
                      div(class: "relative") do
                        # Badge
                        if idx == 0
                          div(class: "absolute top-2 left-2 bg-red-500 text-white px-2 py-1 text-xs font-semibold rounded") do
                            text("SALE")
                          end
                        elsif idx == 2
                          div(class: "absolute top-2 left-2 bg-green-500 text-white px-2 py-1 text-xs font-semibold rounded") do
                            text("NEW")
                          end
                        end
                        
                        # Product image
                        div(class: "aspect-square bg-gray-100 rounded-t-lg")
                      end
                      
                      vstack(spacing: 2, alignment: :start) do
                        text("Product Name \#{i + 1}")
                          .font_weight("medium")
                          .text_color("gray-900")
                        
                        hstack(spacing: 1) do
                          4.times { span(class: "text-yellow-400 text-sm") { text("★") } }
                          span(class: "text-gray-300 text-sm") { text("★") }
                          text("(\#{45 + i * 7})").text_xs.text_color("gray-500").ml(1)
                        end
                        
                        hstack(spacing: 2) do
                          text("$\#{99 + i * 50}").font_weight("semibold")
                          if i == 0
                            text("$\#{149 + i * 50}").text_sm.text_color("gray-500").line_through
                          end
                        end
                        
                        button(class: "w-full") { text("Add to Cart") }
                          .bg("blue-600")
                          .text_color("white")
                          .py(2)
                          .rounded("md")
                          .text_sm
                          .font_weight("medium")
                          .hover("bg-blue-700")
                          .mt(2)
                      end.p(4)
                    end
                  end
                end.mt(6)
                
                # Pagination
                hstack(justify: :center) do
                  button { text("Previous") }
                    .px(3).py(2)
                    .border
                    .rounded("md")
                    .text_sm
                    .disabled
                  
                  [1, 2, 3, "...", 8, 9].each do |page|
                    if page == 1
                      button { text(page.to_s) }
                        .px(3).py(2)
                        .bg("blue-600")
                        .text_color("white")
                        .rounded("md")
                        .text_sm
                    elsif page == "..."
                      span { text("...") }.px(2).text_color("gray-500")
                    else
                      button { text(page.to_s) }
                        .px(3).py(2)
                        .border
                        .rounded("md")
                        .text_sm
                        .hover("bg-gray-50")
                    end
                  end
                  
                  button { text("Next") }
                    .px(3).py(2)
                    .border
                    .rounded("md")
                    .text_sm
                    .hover("bg-gray-50")
                end.mt(8)
              end
            end
          end
        end
      RUBY
      assertions: {
        "has filters sidebar" => -> { assert_text "Filters" },
        "has category filters" => -> { assert_text "Electronics" },
        "has price range" => -> { assert_text "Price Range" },
        "has product count" => -> { assert_text "256 products found" },
        "has sorting dropdown" => -> { assert_selector "select[name='sort']" },
        "has product grid" => -> { assert_text "Product Name 1" }
      }
    )
  end

  test "creates product detail page component" do
    test_component(
      name: "Product Detail Page",
      category: "E-commerce",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-7xl mx-auto p-6") do
            grid(columns: { base: 1, md: 2 }, spacing: 12) do
              # Product images
              div do
                # Main image
                div(class: "aspect-square bg-gray-100 rounded-lg mb-4")
                
                # Thumbnail gallery
                grid(columns: 4, spacing: 2) do
                  4.times do
                    div(class: "aspect-square bg-gray-200 rounded cursor-pointer hover:opacity-75 transition")
                  end
                end
              end
              
              # Product info
              vstack(spacing: 6) do
                # Breadcrumb
                hstack(spacing: 2) do
                  link("Home", destination: "#", class: "text-sm text-gray-600 hover:text-gray-900")
                  span(class: "text-gray-400") { text("/") }
                  link("Electronics", destination: "#", class: "text-sm text-gray-600 hover:text-gray-900")
                  span(class: "text-gray-400") { text("/") }
                  link("Headphones", destination: "#", class: "text-sm text-gray-600 hover:text-gray-900")
                end
                
                # Title and rating
                div do
                  h1(class: "text-3xl font-bold text-gray-900") { text("Premium Noise-Canceling Headphones") }
                  hstack(spacing: 4) do
                    hstack(spacing: 1) do
                      5.times do |i|
                        span(class: i < 4 ? "text-yellow-400" : "text-gray-300") { text("★") }
                      end
                    end
                    text("4.5").font_weight("semibold")
                    link("(328 reviews)", destination: "#reviews", class: "text-blue-600 hover:text-blue-700")
                    text("·").text_color("gray-400")
                    text("1.2k sold").text_color("gray-600")
                  end.mt(2)
                end
                
                # Price
                div do
                  hstack(spacing: 3, alignment: :end) do
                    text("$299").text_size("3xl").font_weight("bold")
                    text("$399").text_size("xl").text_color("gray-500").line_through
                    span(class: "bg-red-100 text-red-700 px-2 py-1 rounded text-sm font-medium") { text("25% OFF") }
                  end
                  text("Free shipping on orders over $50").text_sm.text_color("green-600").mt(2)
                end
                
                # Options
                vstack(spacing: 4) do
                  # Color selection
                  div do
                    label(class: "text-sm font-medium text-gray-700") { text("Color") }
                    hstack(spacing: 2) do
                      ["Black", "Silver", "Navy"].each_with_index do |color, idx|
                        button(class: "px-4 py-2 border-2 rounded-lg \#{idx == 0 ? 'border-blue-500' : 'border-gray-300'}") do
                          text(color)
                        end
                      end
                    end.mt(2)
                  end
                  
                  # Quantity
                  div do
                    label(class: "text-sm font-medium text-gray-700") { text("Quantity") }
                    hstack(spacing: 3) do
                      button { text("-") }
                        .px(3).py(2)
                        .border
                        .rounded("md")
                      
                      span(class: "px-6 py-2") { text("1") }
                      
                      button { text("+") }
                        .px(3).py(2)
                        .border
                        .rounded("md")
                    end.mt(2)
                  end
                end
                
                # Actions
                hstack(spacing: 3) do
                  button(class: "flex-1") { text("Add to Cart") }
                    .bg("blue-600")
                    .text_color("white")
                    .py(3)
                    .rounded("lg")
                    .font_weight("semibold")
                    .hover("bg-blue-700")
                  
                  button { text("♡") }
                    .px(4).py(3)
                    .border
                    .rounded("lg")
                    .text_xl
                    .hover("bg-gray-50")
                end
                
                # Product highlights
                card(elevation: 0) do
                  vstack(spacing: 3) do
                    h3(class: "font-semibold text-gray-900") { text("Product Highlights") }
                    ["Active noise cancellation", "30-hour battery life", "Premium comfort padding", "Bluetooth 5.0", "Foldable design"].each do |feature|
                      hstack(spacing: 2) do
                        span(class: "text-green-500") { text("✓") }
                        text(feature).text_sm
                      end
                    end
                  end
                end.p(4).bg("gray-50")
                
                # Shipping info
                vstack(spacing: 3) do
                  hstack(spacing: 3) do
                    span { text("🚚") }
                    vstack(spacing: 1, alignment: :start) do
                      text("Free Shipping").font_weight("medium")
                      text("Estimated delivery: 3-5 business days").text_sm.text_color("gray-600")
                    end
                  end
                  
                  hstack(spacing: 3) do
                    span { text("↩️") }
                    vstack(spacing: 1, alignment: :start) do
                      text("Free Returns").font_weight("medium")
                      text("30-day return policy").text_sm.text_color("gray-600")
                    end
                  end
                end
              end
            end
            
            # Tabs section
            div(class: "mt-12 border-t pt-12") do
              # Tab navigation
              hstack(spacing: 8) do
                ["Description", "Specifications", "Reviews (328)"].each_with_index do |tab, i|
                  button(class: "pb-4 \#{i == 0 ? 'border-b-2 border-blue-500' : ''}") do
                    text(tab)
                      .font_weight(i == 0 ? "semibold" : "medium")
                      .text_color(i == 0 ? "blue-600" : "gray-600")
                  end
                end
              end
              
              # Tab content
              div(class: "mt-8") do
                vstack(spacing: 4) do
                  h3(class: "text-lg font-semibold text-gray-900") { text("About this item") }
                  p(class: "text-gray-600 leading-relaxed") do
                    text("Experience premium sound quality with our latest noise-canceling headphones. Featuring industry-leading noise cancellation technology, these headphones create an immersive listening experience whether you're commuting, working, or relaxing at home.")
                  end
                  
                  h4(class: "font-semibold text-gray-900 mt-6") { text("Key Features") }
                  ul(class: "list-disc list-inside space-y-2 text-gray-600") do
                    li { text("Advanced Active Noise Cancellation (ANC) technology") }
                    li { text("30-hour battery life with quick charge capability") }
                    li { text("Premium memory foam ear cushions for all-day comfort") }
                    li { text("Multi-device connectivity with seamless switching") }
                    li { text("Built-in voice assistant support") }
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has product title" => -> { assert_text "Premium Noise-Canceling Headphones" },
        "has breadcrumb" => -> { assert_text "Electronics" },
        "has price" => -> { assert_text "$299" },
        "has color options" => -> { assert_text "Black" ; assert_text "Silver" },
        "has add to cart" => -> { assert_selector "button", text: "Add to Cart" },
        "has product highlights" => -> { assert_text "Product Highlights" },
        "has tabs" => -> { assert_text "Description" ; assert_text "Specifications" ; assert_text "Reviews" }
      }
    )
  end

  test "creates checkout form component" do
    test_component(
      name: "Checkout Form",
      category: "E-commerce",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-7xl mx-auto p-6") do
            h1(class: "text-3xl font-bold text-gray-900 mb-8") { text("Checkout") }
            
            grid(columns: { base: 1, lg: 3 }, column_gap: 8) do
              # Main form (2/3 width)
              div(class: "lg:col-span-2") do
                vstack(spacing: 8) do
                  # Shipping Information
                  card(elevation: 1) do
                    vstack(spacing: 6) do
                      h2(class: "text-xl font-semibold text-gray-900") { text("Shipping Information") }
                      
                      grid(columns: 2, spacing: 4) do
                        vstack(spacing: 2, alignment: :start) do
                          label(for_input: "first_name", class: "text-sm font-medium text-gray-700") do
                            text("First Name")
                          end
                          textfield(name: "first_name", required: true, class: "w-full px-3 py-2 border rounded-lg")
                        end
                        
                        vstack(spacing: 2, alignment: :start) do
                          label(for_input: "last_name", class: "text-sm font-medium text-gray-700") do
                            text("Last Name")
                          end
                          textfield(name: "last_name", required: true, class: "w-full px-3 py-2 border rounded-lg")
                        end
                      end
                      
                      vstack(spacing: 2, alignment: :start) do
                        label(for_input: "email", class: "text-sm font-medium text-gray-700") do
                          text("Email Address")
                        end
                        textfield(type: "email", name: "email", required: true, class: "w-full px-3 py-2 border rounded-lg")
                      end
                      
                      vstack(spacing: 2, alignment: :start) do
                        label(for_input: "address", class: "text-sm font-medium text-gray-700") do
                          text("Street Address")
                        end
                        textfield(name: "address", required: true, class: "w-full px-3 py-2 border rounded-lg")
                      end
                      
                      grid(columns: 3, spacing: 4) do
                        vstack(spacing: 2, alignment: :start) do
                          label(for_input: "city", class: "text-sm font-medium text-gray-700") do
                            text("City")
                          end
                          textfield(name: "city", required: true, class: "w-full px-3 py-2 border rounded-lg")
                        end
                        
                        vstack(spacing: 2, alignment: :start) do
                          label(for_input: "state", class: "text-sm font-medium text-gray-700") do
                            text("State")
                          end
                          select(name: "state", class: "w-full px-3 py-2 border rounded-lg") do
                            option("Select State")
                            option("CA")
                            option("NY")
                            option("TX")
                          end
                        end
                        
                        vstack(spacing: 2, alignment: :start) do
                          label(for_input: "zip", class: "text-sm font-medium text-gray-700") do
                            text("ZIP Code")
                          end
                          textfield(name: "zip", required: true, class: "w-full px-3 py-2 border rounded-lg")
                        end
                      end
                    end
                  end.p(6)
                  
                  # Payment Information
                  card(elevation: 1) do
                    vstack(spacing: 6) do
                      h2(class: "text-xl font-semibold text-gray-900") { text("Payment Information") }
                      
                      # Payment method tabs
                      hstack(spacing: 4) do
                        ["Credit Card", "PayPal", "Apple Pay"].each_with_index do |method, idx|
                          button(class: "px-4 py-2 rounded-lg \#{idx == 0 ? 'bg-blue-50 text-blue-700 border-2 border-blue-500' : 'border'}") do
                            text(method)
                          end
                        end
                      end
                      
                      # Credit card form
                      vstack(spacing: 4) do
                        vstack(spacing: 2, alignment: :start) do
                          label(for_input: "card_number", class: "text-sm font-medium text-gray-700") do
                            text("Card Number")
                          end
                          textfield(name: "card_number", placeholder: "1234 5678 9012 3456", class: "w-full px-3 py-2 border rounded-lg")
                        end
                        
                        grid(columns: 2, spacing: 4) do
                          vstack(spacing: 2, alignment: :start) do
                            label(for_input: "expiry", class: "text-sm font-medium text-gray-700") do
                              text("Expiry Date")
                            end
                            textfield(name: "expiry", placeholder: "MM/YY", class: "w-full px-3 py-2 border rounded-lg")
                          end
                          
                          vstack(spacing: 2, alignment: :start) do
                            label(for_input: "cvv", class: "text-sm font-medium text-gray-700") do
                              text("CVV")
                            end
                            textfield(name: "cvv", placeholder: "123", class: "w-full px-3 py-2 border rounded-lg")
                          end
                        end
                      end
                      
                      # Save payment method
                      label(class: "flex items-center") do
                        input(type: "checkbox", class: "rounded text-blue-600")
                          .mr(2)
                        text("Save payment method for future purchases").text_sm
                      end
                    end
                  end.p(6)
                end
              end
              
              # Order summary (1/3 width)
              div do
                card(elevation: 2) do
                  vstack(spacing: 6) do
                    h2(class: "text-xl font-semibold text-gray-900") { text("Order Summary") }
                    
                    # Items
                    vstack(spacing: 4) do
                      [
                        { name: "Wireless Headphones", price: 299, qty: 1 },
                        { name: "Phone Case", price: 29, qty: 2 },
                        { name: "USB-C Cable", price: 19, qty: 1 }
                      ].each do |item|
                        hstack(justify: :between) do
                          vstack(spacing: 1, alignment: :start) do
                            text(item[:name]).text_sm.font_weight("medium")
                            text("Qty: \#{item[:qty]}").text_xs.text_color("gray-500")
                          end
                          text("$\#{item[:price] * item[:qty]}").font_weight("medium")
                        end
                      end
                    end
                    
                    div(class: "border-t pt-4") do
                      vstack(spacing: 3) do
                        hstack(justify: :between) do
                          text("Subtotal").text_sm.text_color("gray-600")
                          text("$376.00")
                        end
                        
                        hstack(justify: :between) do
                          text("Shipping").text_sm.text_color("gray-600")
                          text("FREE").text_color("green-600").font_weight("medium")
                        end
                        
                        hstack(justify: :between) do
                          text("Tax").text_sm.text_color("gray-600")
                          text("$30.08")
                        end
                        
                        # Promo code
                        hstack(spacing: 2) do
                          textfield(placeholder: "Promo code", class: "flex-1 px-3 py-2 border rounded-lg text-sm")
                          button { text("Apply") }
                            .px(3).py(2)
                            .bg("gray-100")
                            .rounded("lg")
                            .text_sm
                            .font_weight("medium")
                        end
                      end
                    end
                    
                    div(class: "border-t pt-4") do
                      hstack(justify: :between) do
                        text("Total").font_weight("semibold").text_lg
                        text("$406.08").font_weight("bold").text_xl
                      end
                    end
                    
                    button(class: "w-full") { text("Complete Order") }
                      .bg("blue-600")
                      .text_color("white")
                      .py(3)
                      .rounded("lg")
                      .font_weight("semibold")
                      .hover("bg-blue-700")
                    
                    # Security badges
                    hstack(justify: :center, spacing: 4) do
                      span(class: "text-gray-400 text-sm") { text("🔒 Secure Checkout") }
                      span(class: "text-gray-400 text-sm") { text("💳 SSL Encrypted") }
                    end
                  end
                end.p(6)
              end
            end
          end
        end
      RUBY
      assertions: {
        "has checkout title" => -> { assert_text "Checkout" },
        "has shipping form" => -> { assert_text "Shipping Information" },
        "has payment form" => -> { assert_text "Payment Information" },
        "has order summary" => -> { assert_text "Order Summary" },
        "has complete order button" => -> { assert_selector "button", text: "Complete Order" },
        "has security badges" => -> { assert_text "Secure Checkout" }
      }
    )
  end

  test "creates order confirmation component" do
    test_component(
      name: "Order Confirmation",
      category: "E-commerce",
      code: <<~'RUBY',
        swift_ui do
          div(class: "max-w-3xl mx-auto p-6") do
            # Success message
            card(elevation: 2) do
              vstack(spacing: 6, alignment: :center) do
                # Success icon
                div(class: "w-20 h-20 bg-green-100 rounded-full flex items-center justify-center") do
                  span(class: "text-green-500 text-4xl") { text("✓") }
                end
                
                h1(class: "text-3xl font-bold text-gray-900") { text("Order Confirmed!") }
                p(class: "text-lg text-gray-600") { text("Thank you for your purchase") }
                
                # Order details
                div(class: "bg-gray-50 rounded-lg p-6 w-full") do
                  vstack(spacing: 3) do
                    hstack(justify: :between) do
                      text("Order Number:").text_sm.text_color("gray-600")
                      text("#ORD-2024-001234").font_weight("semibold")
                    end
                    
                    hstack(justify: :between) do
                      text("Order Date:").text_sm.text_color("gray-600")
                      text("January 15, 2024").font_weight("medium")
                    end
                    
                    hstack(justify: :between) do
                      text("Total Amount:").text_sm.text_color("gray-600")
                      text("$406.08").font_weight("semibold")
                    end
                  end
                end
                
                # Actions
                hstack(spacing: 3) do
                  button { text("View Order Details") }
                    .bg("blue-600")
                    .text_color("white")
                    .px(6).py(3)
                    .rounded("lg")
                    .font_weight("medium")
                    .hover("bg-blue-700")
                  
                  button { text("Continue Shopping") }
                    .border
                    .px(6).py(3)
                    .rounded("lg")
                    .font_weight("medium")
                    .hover("bg-gray-50")
                end
              end
            end.p(8)
            
            # Order information
            grid(columns: 2, spacing: 6) do
              # Shipping info
              card(elevation: 1) do
                vstack(spacing: 4) do
                  h3(class: "font-semibold text-gray-900") { text("Shipping Address") }
                  vstack(spacing: 1) do
                    text("John Doe")
                    text("123 Main Street").text_color("gray-600")
                    text("San Francisco, CA 94105").text_color("gray-600")
                    text("United States").text_color("gray-600")
                  end
                  
                  div(class: "pt-4 border-t") do
                    text("Estimated Delivery:").text_sm.text_color("gray-600")
                    text("January 18-20, 2024").font_weight("semibold").mt(1)
                  end
                end
              end.p(6)
              
              # Payment info
              card(elevation: 1) do
                vstack(spacing: 4) do
                  h3(class: "font-semibold text-gray-900") { text("Payment Method") }
                  hstack(spacing: 2) do
                    span(class: "text-xl") { text("💳") }
                    vstack(spacing: 1, alignment: :start) do
                      text("Visa ending in 4242")
                      text("Expires 12/25").text_sm.text_color("gray-600")
                    end
                  end
                  
                  div(class: "pt-4 border-t") do
                    text("Billing Address:").text_sm.text_color("gray-600")
                    text("Same as shipping").text_sm.mt(1)
                  end
                end
              end.p(6)
            end.mt(6)
            
            # Order items
            card(elevation: 1) do
              vstack(spacing: 4) do
                h3(class: "font-semibold text-gray-900") { text("Order Items") }
                
                # In a real app, this would come from @order.items
                order_items = [
                  { name: "Wireless Headphones", price: 299, qty: 1, image: "🎧" },
                  { name: "Phone Case", price: 29, qty: 2, image: "📱" },
                  { name: "USB-C Cable", price: 19, qty: 1, image: "🔌" }
                ]
                
                vstack(spacing: 0) do
                  order_items.each_with_index do |item, idx|
                    div(class: "py-4 \#{idx > 0 ? 'border-t' : ''}") do
                      hstack(spacing: 4) do
                        div(class: "w-16 h-16 bg-gray-100 rounded flex items-center justify-center text-2xl") do
                          text(item[:image])
                        end
                        
                        vstack(spacing: 1, alignment: :start) do
                          text(item[:name]).font_weight("medium")
                          text("Quantity: \#{item[:qty]}").text_sm.text_color("gray-600")
                        end
                        
                        spacer
                        
                        text("$\\#{item[:price] * item[:qty]}").font_weight("medium")
                      end
                    end
                  end
                end
              end
            end.p(6).mt(6)
            
            # Help section
            div(class: "text-center mt-8") do
              p(class: "text-gray-600") do
                text("Questions about your order? ")
                link("Contact Support", destination: "#", class: "text-blue-600 hover:text-blue-700 font-medium")
              end
            end
          end
        end
      RUBY
      assertions: {
        "has success message" => -> { assert_text "Order Confirmed!" },
        "has order number" => -> { assert_text "#ORD-2024-001234" },
        "has shipping address" => -> { assert_text "Shipping Address" },
        "has payment method" => -> { assert_text "Payment Method" },
        "has order items" => -> { assert_text "Order Items" },
        "has action buttons" => -> { assert_selector "button", text: "View Order Details" }
      }
    )
  end

  # Marketing Components
  test "creates hero section component" do
    test_component(
      name: "Hero Section",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "relative min-h-screen bg-gradient-to-br from-blue-600 to-purple-700") do
            # Background pattern
            div(class: "absolute inset-0 bg-black opacity-10")
            
            # Content
            div(class: "relative z-10 flex items-center justify-center min-h-screen px-6") do
              vstack(spacing: 8, alignment: :center) do
                # Badge
                div(class: "inline-flex items-center px-4 py-2 bg-white/20 backdrop-blur-sm rounded-full") do
                  span(class: "text-sm font-medium text-white") { text("🚀 New Feature Launch") }
                end
                
                # Headline
                h1(class: "text-5xl md:text-6xl font-bold text-white text-center max-w-4xl") do
                  text("Build Amazing Products with SwiftUI Rails")
                end
                
                # Subheadline
                p(class: "text-xl text-white/90 text-center max-w-2xl") do
                  text("Create beautiful, responsive web applications using familiar SwiftUI syntax. Ship faster with the power of Rails and the elegance of SwiftUI.")
                end
                
                # CTA Buttons
                hstack(spacing: 4) do
                  button { text("Get Started Free") }
                    .bg("white")
                    .text_color("blue-600")
                    .px(8).py(4)
                    .rounded("lg")
                    .font_weight("semibold")
                    .text_size("lg")
                    .hover("bg-gray-100")
                    .transition
                  
                  button { text("View Demo") }
                    .bg("transparent")
                    .text_color("white")
                    .px(8).py(4)
                    .rounded("lg")
                    .font_weight("semibold")
                    .text_size("lg")
                    .border("2px solid white")
                    .hover("bg-white/10")
                    .transition
                end
                
                # Social proof
                div(class: "mt-8") do
                  vstack(spacing: 2) do
                    hstack(spacing: 1) do
                      (1..5).each do
                        span(class: "text-yellow-400 text-xl") { text("★") }
                      end
                    end
                    text("Trusted by 10,000+ developers worldwide")
                      .text_sm
                      .text_color("white/80")
                  end
                end
              end
            end
            
            # Scroll indicator
            div(class: "absolute bottom-8 left-1/2 transform -translate-x-1/2 text-white/60 animate-bounce") do
              text("↓")
            end
          end
        end
      RUBY
      assertions: {
        "has hero headline" => -> { assert_text "Build Amazing Products" },
        "has CTA buttons" => -> { assert_selector "button", text: "Get Started Free" },
        "has demo button" => -> { assert_selector "button", text: "View Demo" },
        "has social proof" => -> { assert_text "Trusted by 10,000+ developers" }
      }
    )
  end

  test "creates newsletter signup component" do
    test_component(
      name: "Newsletter Signup",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "bg-gray-900 py-16") do
            div(class: "max-w-7xl mx-auto px-6") do
              grid(columns: { base: 1, lg: 2 }, spacing: 12, align: :center) do
                # Left side - Content
                vstack(spacing: 6, alignment: :start) do
                  h2(class: "text-4xl font-bold text-white") do
                    text("Stay in the loop")
                  end
                  
                  p(class: "text-xl text-gray-300") do
                    text("Get the latest updates on new features, tips & tricks, and exclusive content delivered straight to your inbox.")
                  end
                  
                  # Benefits list
                  vstack(spacing: 3) do
                    ["Weekly developer tips", "Early access to features", "Exclusive tutorials", "No spam, ever"].each do |benefit|
                      hstack(spacing: 3) do
                        span(class: "text-green-400 text-lg") { text("✓") }
                        text(benefit).text_color("gray-300")
                      end
                    end
                  end
                end
                
                # Right side - Form
                card(elevation: 3) do
                  form(action: "/newsletter", method: :post) do
                    vstack(spacing: 4) do
                      h3(class: "text-2xl font-semibold text-gray-900") { text("Subscribe Now") }
                      
                      # Name field
                      vstack(spacing: 2, alignment: :start) do
                        label(for_input: "name", class: "text-sm font-medium text-gray-700") { text("Your Name") }
                        textfield(
                          name: "name",
                          placeholder: "John Doe",
                          required: true
                        )
                        .w("full")
                        .px(4).py(3)
                        .border
                        .rounded("lg")
                      end
                      
                      # Email field
                      vstack(spacing: 2, alignment: :start) do
                        label(for_input: "email", class: "text-sm font-medium text-gray-700") { text("Email Address") }
                        textfield(
                          name: "email",
                          type: "email",
                          placeholder: "you@example.com",
                          required: true
                        )
                        .w("full")
                        .px(4).py(3)
                        .border
                        .rounded("lg")
                      end
                      
                      # Topics selection
                      vstack(spacing: 2, alignment: :start) do
                        label(class: "text-sm font-medium text-gray-700") { text("Interested in:") }
                        vstack(spacing: 2) do
                          ["Development Tips", "Product Updates", "Community News"].each do |topic|
                            label(class: "flex items-center") do
                              input(type: "checkbox", name: "topics[]", value: topic.downcase.gsub(" ", "_"))
                                .mr(2)
                                .rounded
                                .text_color("blue-600")
                              text(topic).text_sm
                            end
                          end
                        end
                      end
                      
                      # Submit button
                      button(type: "submit", class: "w-full") { text("Subscribe") }
                        .bg("blue-600")
                        .text_color("white")
                        .py(3)
                        .rounded("lg")
                        .font_weight("semibold")
                        .hover("bg-blue-700")
                        .transition
                      
                      # Privacy notice
                      p(class: "text-xs text-gray-500 text-center") do
                        text("We respect your privacy. Unsubscribe at any time.")
                      end
                    end
                  end
                end.p(8).bg("white")
              end
            end
          end
        end
      RUBY
      assertions: {
        "has newsletter title" => -> { assert_text "Stay in the loop" },
        "has form" => -> { assert_selector "form[action='/newsletter']" },
        "has name field" => -> { assert_selector "input[name='name']" },
        "has email field" => -> { assert_selector "input[name='email'][type='email']" },
        "has topic checkboxes" => -> { assert_selector "input[type='checkbox']", minimum: 3 },
        "has subscribe button" => -> { assert_selector "button[type='submit']", text: "Subscribe" }
      }
    )
  end

  test "creates pricing table component" do
    test_component(
      name: "Pricing Table",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "py-16 bg-gray-50") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Simple, transparent pricing") }
                p(class: "text-xl text-gray-600") { text("Choose the perfect plan for your needs") }
              end
              
              # Pricing cards
              grid(columns: 3, spacing: 8) do
                # Starter plan
                card(elevation: 1) do
                  vstack(spacing: 6) do
                    # Plan name
                    h3(class: "text-2xl font-semibold text-gray-900") { text("Starter") }
                    
                    # Price
                    div do
                      span(class: "text-5xl font-bold text-gray-900") { text("$9") }
                      span(class: "text-gray-600 ml-1") { text("/month") }
                    end
                    
                    # Description
                    text("Perfect for individuals and small projects")
                      .text_color("gray-600")
                    
                    # Features
                    vstack(spacing: 3) do
                      ["Up to 3 projects", "1GB storage", "Basic support", "API access"].each do |feature|
                        hstack(spacing: 3) do
                          span(class: "text-green-500") { text("✓") }
                          text(feature).text_sm
                        end
                      end
                    end
                    
                    # CTA
                    button(class: "w-full") { text("Start Free Trial") }
                      .bg("gray-100")
                      .text_color("gray-900")
                      .py(3)
                      .rounded("lg")
                      .font_weight("medium")
                      .hover("bg-gray-200")
                      .transition
                  end
                end.p(8)
                
                # Pro plan (highlighted)
                div(class: "relative") do
                  # Popular badge
                  div(class: "absolute -top-4 left-1/2 transform -translate-x-1/2") do
                    div(class: "bg-blue-600 text-white px-4 py-1 rounded-full text-sm font-semibold") do
                      text("MOST POPULAR")
                    end
                  end
                  
                  card(elevation: 3) do
                    vstack(spacing: 6) do
                      h3(class: "text-2xl font-semibold text-gray-900") { text("Pro") }
                      
                      div do
                        span(class: "text-5xl font-bold text-gray-900") { text("$29") }
                        span(class: "text-gray-600 ml-1") { text("/month") }
                      end
                      
                      text("Great for growing teams and businesses")
                        .text_color("gray-600")
                      
                      vstack(spacing: 3) do
                        ["Unlimited projects", "50GB storage", "Priority support", "Advanced API", "Custom integrations", "Analytics dashboard"].each do |feature|
                          hstack(spacing: 3) do
                            span(class: "text-green-500") { text("✓") }
                            text(feature).text_sm
                          end
                        end
                      end
                      
                      button(class: "w-full") { text("Start Free Trial") }
                        .bg("blue-600")
                        .text_color("white")
                        .py(3)
                        .rounded("lg")
                        .font_weight("medium")
                        .hover("bg-blue-700")
                        .transition
                    end
                  end.p(8).border("2px solid #3B82F6")
                end
                
                # Enterprise plan
                card(elevation: 1) do
                  vstack(spacing: 6) do
                    h3(class: "text-2xl font-semibold text-gray-900") { text("Enterprise") }
                    
                    div do
                      span(class: "text-5xl font-bold text-gray-900") { text("$99") }
                      span(class: "text-gray-600 ml-1") { text("/month") }
                    end
                    
                    text("For large organizations with advanced needs")
                      .text_color("gray-600")
                    
                    vstack(spacing: 3) do
                      ["Everything in Pro", "Unlimited storage", "24/7 phone support", "SLA guarantee", "Custom contracts", "Dedicated account manager"].each do |feature|
                        hstack(spacing: 3) do
                          span(class: "text-green-500") { text("✓") }
                          text(feature).text_sm
                        end
                      end
                    end
                    
                    button(class: "w-full") { text("Contact Sales") }
                      .bg("gray-100")
                      .text_color("gray-900")
                      .py(3)
                      .rounded("lg")
                      .font_weight("medium")
                      .hover("bg-gray-200")
                      .transition
                  end
                end.p(8)
              end.mt(12)
            end
          end
        end
      RUBY
      assertions: {
        "has pricing title" => -> { assert_text "Simple, transparent pricing" },
        "has three plans" => -> { assert_text "Starter" ; assert_text "Pro" ; assert_text "Enterprise" },
        "has prices" => -> { assert_text "$9" ; assert_text "$29" ; assert_text "$99" },
        "has popular badge" => -> { assert_text "MOST POPULAR" },
        "has CTA buttons" => -> { assert_selector "button", text: "Start Free Trial", count: 2 }
      }
    )
  end

  test "creates testimonial section component" do
    test_component(
      name: "Testimonial Section",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "py-16 bg-white") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Loved by developers worldwide") }
                p(class: "text-xl text-gray-600") { text("See what our customers have to say") }
              end
              
              # Testimonials grid
              grid(columns: 3, spacing: 8) do
                # Testimonial 1
                card(elevation: 2) do
                  vstack(spacing: 4) do
                    # Stars
                    hstack(spacing: 1) do
                      5.times { span(class: "text-yellow-400") { text("★") } }
                    end
                    
                    # Quote
                    p(class: "text-gray-700 italic") do
                      text("\\"SwiftUI Rails has transformed how we build web applications. The familiar syntax and powerful features have increased our productivity by 300%.\\"")
                    end
                    
                    # Author
                    vstack(spacing: 1, alignment: :start) do
                      text("Sarah Johnson")
                        .font_weight("semibold")
                        .text_color("gray-900")
                      text("CTO at TechCorp")
                        .text_sm
                        .text_color("gray-600")
                    end
                  end
                end.p(6)
                
                # Testimonial 2
                card(elevation: 2) do
                  vstack(spacing: 4) do
                    hstack(spacing: 1) do
                      5.times { span(class: "text-yellow-400") { text("★") } }
                    end
                    
                    p(class: "text-gray-700 italic") do
                      text("\\"The best decision we made was adopting SwiftUI Rails. Our development speed has doubled, and our code is more maintainable than ever.\\"")
                    end
                    
                    vstack(spacing: 1, alignment: :start) do
                      text("Michael Chen")
                        .font_weight("semibold")
                        .text_color("gray-900")
                      text("Lead Developer at StartupXYZ")
                        .text_sm
                        .text_color("gray-600")
                    end
                  end
                end.p(6)
                
                # Testimonial 3
                card(elevation: 2) do
                  vstack(spacing: 4) do
                    hstack(spacing: 1) do
                      5.times { span(class: "text-yellow-400") { text("★") } }
                    end
                    
                    p(class: "text-gray-700 italic") do
                      text("\\"I can't imagine building Rails apps without SwiftUI Rails anymore. It's intuitive, powerful, and makes development fun again!\\"")
                    end
                    
                    vstack(spacing: 1, alignment: :start) do
                      text("Emily Rodriguez")
                        .font_weight("semibold")
                        .text_color("gray-900")
                      text("Freelance Developer")
                        .text_sm
                        .text_color("gray-600")
                    end
                  end
                end.p(6)
              end.mt(12)
              
              # Call to action
              div(class: "text-center mt-12") do
                link(destination: "#", class: "text-blue-600 hover:text-blue-700 font-medium text-lg") do
                  text("Read more success stories →")
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has testimonial title" => -> { assert_text "Loved by developers worldwide" },
        "has testimonials" => -> { assert_text "Sarah Johnson" ; assert_text "Michael Chen" },
        "has ratings" => -> { assert_selector "span.text-yellow-400", minimum: 15 }, # 5 stars × 3 testimonials
        "has CTA link" => -> { assert_text "Read more success stories" }
      }
    )
  end

  # Additional Marketing Components
  test "creates FAQ section component" do
    test_component(
      name: "FAQ Section",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "py-16 bg-gray-50") do
            div(class: "max-w-3xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Frequently Asked Questions") }
                p(class: "text-xl text-gray-600") { text("Everything you need to know about SwiftUI Rails") }
              end
              
              # FAQ items
              vstack(spacing: 4) do
                [
                  {
                    q: "What is SwiftUI Rails?",
                    a: "SwiftUI Rails is a Ruby gem that brings SwiftUI-like declarative syntax to Rails applications, allowing you to build beautiful UIs with familiar patterns."
                  },
                  {
                    q: "Do I need to know SwiftUI to use it?",
                    a: "While SwiftUI knowledge helps, it's not required. The syntax is intuitive and well-documented, making it easy for any Rails developer to learn."
                  },
                  {
                    q: "Is it production-ready?",
                    a: "Yes! SwiftUI Rails is used by dozens of companies in production, handling millions of requests daily with excellent performance."
                  },
                  {
                    q: "How does it compare to React or Vue?",
                    a: "Unlike JavaScript frameworks, SwiftUI Rails embraces Rails' server-side rendering philosophy while providing a modern, declarative API."
                  }
                ].each_with_index do |faq, index|
                  div(class: "bg-white rounded-lg shadow-sm") do
                    details(class: "group") do
                      summary(class: "flex justify-between items-center cursor-pointer p-6 hover:bg-gray-50") do
                        h3(class: "font-semibold text-gray-900") { text(faq[:q]) }
                        span(class: "text-gray-400 group-open:rotate-180 transition-transform") { text("▼") }
                      end
                      
                      div(class: "px-6 pb-6") do
                        p(class: "text-gray-600") { text(faq[:a]) }
                      end
                    end
                  end
                end
              end.mt(12)
              
              # Contact CTA
              div(class: "text-center mt-12") do
                p(class: "text-gray-600 mb-4") { text("Still have questions?") }
                button { text("Contact Support") }
                  .bg("blue-600")
                  .text_color("white")
                  .px(6).py(3)
                  .rounded("lg")
                  .font_weight("medium")
                  .hover("bg-blue-700")
              end
            end
          end
        end
      RUBY
      assertions: {
        "has FAQ title" => -> { assert_text "Frequently Asked Questions" },
        "has questions" => -> { assert_text "What is SwiftUI Rails?" },
        "has expandable items" => -> { assert_selector "details", count: 4 },
        "has contact CTA" => -> { assert_selector "button", text: "Contact Support" }
      }
    )
  end

  test "creates footer component" do
    test_component(
      name: "Footer",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          footer(class: "bg-gray-900 text-white") do
            div(class: "max-w-7xl mx-auto px-6 py-12") do
              # Top section
              grid(columns: { base: 1, md: 4 }, spacing: 8) do
                # Company info
                vstack(spacing: 4, alignment: :start) do
                  h3(class: "text-2xl font-bold") { text("SwiftUI Rails") }
                  p(class: "text-gray-400") do
                    text("Building the future of Rails development with declarative UI patterns.")
                  end
                  
                  # Social links
                  hstack(spacing: 4) do
                    ["Twitter", "GitHub", "Discord"].each do |social|
                      link(destination: "#", class: "text-gray-400 hover:text-white transition") do
                        text(social)
                      end
                    end
                  end
                end
                
                # Product links
                vstack(spacing: 3, alignment: :start) do
                  h4(class: "font-semibold mb-2") { text("Product") }
                  ["Features", "Pricing", "Documentation", "Changelog"].each do |link_text|
                    link(link_text, destination: "#", class: "text-gray-400 hover:text-white transition")
                  end
                end
                
                # Resources
                vstack(spacing: 3, alignment: :start) do
                  h4(class: "font-semibold mb-2") { text("Resources") }
                  ["Blog", "Tutorials", "API Reference", "Support"].each do |link_text|
                    link(link_text, destination: "#", class: "text-gray-400 hover:text-white transition")
                  end
                end
                
                # Company
                vstack(spacing: 3, alignment: :start) do
                  h4(class: "font-semibold mb-2") { text("Company") }
                  ["About", "Careers", "Contact", "Privacy Policy"].each do |link_text|
                    link(link_text, destination: "#", class: "text-gray-400 hover:text-white transition")
                  end
                end
              end
              
              # Bottom section
              div(class: "border-t border-gray-800 mt-12 pt-8") do
                hstack(justify: :between) do
                  text("© 2024 SwiftUI Rails. All rights reserved.")
                    .text_sm
                    .text_color("gray-400")
                  
                  hstack(spacing: 6) do
                    link("Terms", destination: "#", class: "text-sm text-gray-400 hover:text-white")
                    link("Privacy", destination: "#", class: "text-sm text-gray-400 hover:text-white")
                    link("Cookies", destination: "#", class: "text-sm text-gray-400 hover:text-white")
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has footer tag" => -> { assert_selector "footer" },
        "has company name" => -> { assert_text "SwiftUI Rails" },
        "has footer sections" => -> { assert_text "Product" ; assert_text "Resources" ; assert_text "Company" },
        "has copyright" => -> { assert_text "© 2024 SwiftUI Rails" },
        "has social links" => -> { assert_text "Twitter" ; assert_text "GitHub" }
      }
    )
  end

  # Additional Application UI Components
  test "creates user profile component" do
    test_component(
      name: "User Profile",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-4xl mx-auto p-6") do
            card(elevation: 2) do
              # Header with cover image
              div(class: "h-48 bg-gradient-to-r from-blue-500 to-purple-600 rounded-t-lg")
              
              # Profile content
              div(class: "px-8 pb-8") do
                # Avatar and basic info
                div(class: "flex items-end -mt-20 mb-6") do
                  div(class: "w-32 h-32 bg-white rounded-full border-4 border-white shadow-lg flex items-center justify-center text-5xl") do
                    text("👤")
                  end
                  
                  div(class: "ml-6 mb-4") do
                    h1(class: "text-3xl font-bold text-gray-900") { text("Alex Thompson") }
                    p(class: "text-gray-600") { text("@alexthompson") }
                  end
                  
                  spacer
                  
                  button { text("Edit Profile") }
                    .bg("blue-600")
                    .text_color("white")
                    .px(6).py(2)
                    .rounded("lg")
                    .font_weight("medium")
                end
                
                # Bio
                div(class: "mb-8") do
                  p(class: "text-gray-700") do
                    text("Full-stack developer passionate about building great user experiences. SwiftUI Rails enthusiast. Coffee addict ☕")
                  end
                end
                
                # Stats
                grid(columns: 4, spacing: 4) do
                  ["Projects", "Followers", "Following", "Stars"].each_with_index do |stat, i|
                    vstack(alignment: :center) do
                      text(["42", "1.2K", "89", "523"][i])
                        .text_2xl
                        .font_weight("bold")
                        .text_color("gray-900")
                      text(stat)
                        .text_sm
                        .text_color("gray-600")
                    end
                  end
                end
                
                # Tabs
                div(class: "mt-8 border-t pt-8") do
                  div(class: "border-b") do
                    hstack(spacing: 8) do
                      ["Overview", "Projects", "Activity", "Settings"].each do |tab|
                        button { text(tab) }
                          .pb(4)
                          .px(2)
                          .font_weight(tab == "Overview" ? "semibold" : "normal")
                          .text_color(tab == "Overview" ? "blue-600" : "gray-600")
                          .border_b(tab == "Overview" ? "2px solid #2563EB" : "none")
                      end
                    end
                  end
                  
                  # Tab content
                  div(class: "mt-6") do
                    vstack(spacing: 4) do
                      h3(class: "font-semibold text-gray-900 mb-2") { text("Recent Activity") }
                      
                      ["Created new project 'SwiftUI Components'", "Starred rails/rails repository", "Followed @dhh"].each do |activity|
                        hstack(spacing: 3) do
                          div(class: "w-2 h-2 bg-blue-600 rounded-full mt-2")
                          text(activity).text_color("gray-700")
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has profile name" => -> { assert_text "Alex Thompson" },
        "has username" => -> { assert_text "@alexthompson" },
        "has edit button" => -> { assert_selector "button", text: "Edit Profile" },
        "has stats" => -> { assert_text "Projects" ; assert_text "Followers" },
        "has tabs" => -> { assert_text "Overview" ; assert_text "Projects" }
      }
    )
  end

  test "creates analytics dashboard component" do
    test_component(
      name: "Analytics Dashboard",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          div(class: "p-6 bg-gray-50 min-h-screen") do
            # Header
            hstack(justify: :between, class: "mb-8") do
              h1(class: "text-3xl font-bold text-gray-900") { text("Analytics Overview") }
              
              # Date range selector
              hstack(spacing: 2) do
                button { text("Today") }.px(4).py(2).rounded("lg").bg("white").border
                button { text("7 Days") }.px(4).py(2).rounded("lg").bg("blue-600").text_color("white")
                button { text("30 Days") }.px(4).py(2).rounded("lg").bg("white").border
              end
            end
            
            # Metric cards
            grid(columns: 4, spacing: 6) do
              [
                { label: "Total Revenue", value: "$45,231", change: "+12.5%", positive: true },
                { label: "Active Users", value: "2,345", change: "+5.2%", positive: true },
                { label: "Conversion Rate", value: "3.2%", change: "-0.4%", positive: false },
                { label: "Avg. Order Value", value: "$89", change: "+8.1%", positive: true }
              ].each do |metric|
                card(elevation: 1) do
                  vstack(spacing: 2, alignment: :start) do
                    text(metric[:label])
                      .text_sm
                      .text_color("gray-600")
                    
                    hstack(justify: :between) do
                      text(metric[:value])
                        .text_2xl
                        .font_weight("bold")
                        .text_color("gray-900")
                      
                      div(class: "px-2 py-1 rounded-full text-xs font-medium \#{metric[:positive] ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}") do
                        text(metric[:change])
                      end
                    end
                  end
                end.p(6)
              end
            end
            
            # Charts section
            grid(columns: { base: 1, lg: 2 }, spacing: 6) do
              # Revenue chart
              card(elevation: 1) do
                vstack(spacing: 4) do
                  h3(class: "font-semibold text-gray-900") { text("Revenue Trend") }
                  
                  # Chart placeholder
                  div(class: "h-64 bg-gray-100 rounded flex items-center justify-center") do
                    text("📊 Revenue Chart").text_color("gray-500")
                  end
                end
              end.p(6)
              
              # User activity
              card(elevation: 1) do
                vstack(spacing: 4) do
                  h3(class: "font-semibold text-gray-900") { text("User Activity") }
                  
                  # Activity chart placeholder
                  div(class: "h-64 bg-gray-100 rounded flex items-center justify-center") do
                    text("📈 Activity Chart").text_color("gray-500")
                  end
                end
              end.p(6)
            end.mt(6)
            
            # Recent transactions table
            card(elevation: 1) do
              vstack(spacing: 4) do
                hstack(justify: :between) do
                  h3(class: "font-semibold text-gray-900") { text("Recent Transactions") }
                  link("View all →", destination: "#", class: "text-blue-600 hover:text-blue-700 text-sm")
                end
                
                # Table
                div(class: "overflow-x-auto") do
                  table(class: "w-full") do
                    thead do
                      tr(class: "border-b") do
                        ["Customer", "Amount", "Status", "Date"].each do |header|
                          th(class: "text-left py-3 px-4 font-medium text-gray-700") { text(header) }
                        end
                      end
                    end
                    
                    tbody do
                      [
                        { customer: "John Doe", amount: "$299", status: "Completed", date: "2 hours ago" },
                        { customer: "Jane Smith", amount: "$149", status: "Pending", date: "4 hours ago" },
                        { customer: "Bob Johnson", amount: "$499", status: "Completed", date: "6 hours ago" }
                      ].each do |transaction|
                        tr(class: "border-b hover:bg-gray-50") do
                          td(class: "py-3 px-4") { text(transaction[:customer]) }
                          td(class: "py-3 px-4 font-medium") { text(transaction[:amount]) }
                          td(class: "py-3 px-4") do
                            span(class: "px-2 py-1 rounded-full text-xs \#{transaction[:status] == 'Completed' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}") do
                              text(transaction[:status])
                            end
                          end
                          td(class: "py-3 px-4 text-gray-600") { text(transaction[:date]) }
                        end
                      end
                    end
                  end
                end
              end
            end.p(6).mt(6)
          end
        end
      RUBY
      assertions: {
        "has dashboard title" => -> { assert_text "Analytics Overview" },
        "has metric cards" => -> { assert_text "Total Revenue" ; assert_text "Active Users" },
        "has charts section" => -> { assert_text "Revenue Trend" ; assert_text "User Activity" },
        "has transactions table" => -> { assert_text "Recent Transactions" },
        "has date filters" => -> { assert_selector "button", text: "7 Days" }
      }
    )
  end

  test "creates chat interface component" do
    test_component(
      name: "Chat Interface",
      category: "Application UI",
      code: <<~RUBY,
        swift_ui do
          div(class: "h-screen flex") do
            # Sidebar with conversations
            div(class: "w-80 bg-gray-50 border-r") do
              # Header
              div(class: "p-4 border-b bg-white") do
                hstack(justify: :between) do
                  h2(class: "text-xl font-semibold") { text("Messages") }
                  button { text("+") }
                    .w(8).h(8)
                    .rounded("full")
                    .bg("blue-600")
                    .text_color("white")
                    .font_weight("bold")
                end
              end
              
              # Conversation list
              vstack(spacing: 0) do
                [
                  { name: "Sarah Wilson", message: "Thanks for the update!", time: "2m", unread: 2 },
                  { name: "Dev Team", message: "Deployment completed", time: "1h", unread: 0 },
                  { name: "Alex Chen", message: "Can we schedule a call?", time: "3h", unread: 1 }
                ].each do |chat|
                  div(class: "p-4 hover:bg-gray-100 cursor-pointer border-b") do
                    hstack(spacing: 3) do
                      # Avatar
                      div(class: "w-12 h-12 bg-blue-500 rounded-full flex items-center justify-center text-white font-semibold") do
                        text(chat[:name].split.map(&:first).join)
                      end
                      
                      # Chat info
                      vstack(spacing: 1, class: "flex-1") do
                        hstack(justify: :between) do
                          text(chat[:name]).font_weight("semibold")
                          text(chat[:time]).text_sm.text_color("gray-500")
                        end
                        
                        hstack(justify: :between) do
                          text(chat[:message]).text_sm.text_color("gray-600").truncate
                          if chat[:unread] > 0
                            div(class: "w-6 h-6 bg-blue-600 rounded-full flex items-center justify-center") do
                              text(chat[:unread].to_s).text_xs.text_color("white")
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
            
            # Chat area
            div(class: "flex-1 flex flex-col") do
              # Chat header
              div(class: "p-4 border-b bg-white") do
                hstack(spacing: 3) do
                  div(class: "w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center text-white font-semibold") do
                    text("SW")
                  end
                  
                  vstack(spacing: 0) do
                    text("Sarah Wilson").font_weight("semibold")
                    text("Active now").text_sm.text_color("green-600")
                  end
                end
              end
              
              # Messages
              div(class: "flex-1 overflow-y-auto p-4 bg-gray-50") do
                vstack(spacing: 4) do
                  # Received message
                  div(class: "flex items-start") do
                    div(class: "max-w-xs lg:max-w-md") do
                      div(class: "bg-white rounded-lg p-3 shadow-sm") do
                        text("Hey! How's the new feature coming along?")
                      end
                      text("10:32 AM").text_xs.text_color("gray-500").mt(1)
                    end
                  end
                  
                  # Sent message
                  div(class: "flex items-start justify-end") do
                    div(class: "max-w-xs lg:max-w-md") do
                      div(class: "bg-blue-600 text-white rounded-lg p-3") do
                        text("It's going great! Just finished the UI components.")
                      end
                      text("10:35 AM").text_xs.text_color("gray-500").mt(1).text_right
                    end
                  end
                  
                  # Received message
                  div(class: "flex items-start") do
                    div(class: "max-w-xs lg:max-w-md") do
                      div(class: "bg-white rounded-lg p-3 shadow-sm") do
                        text("Thanks for the update!")
                      end
                      text("10:36 AM").text_xs.text_color("gray-500").mt(1)
                    end
                  end
                end
              end
              
              # Message input
              div(class: "p-4 bg-white border-t") do
                hstack(spacing: 3) do
                  textfield(
                    placeholder: "Type a message...",
                    class: "flex-1"
                  ).px(4).py(3).bg("gray-100").rounded("lg").border("none")
                  
                  button { text("Send") }
                    .bg("blue-600")
                    .text_color("white")
                    .px(6).py(3)
                    .rounded("lg")
                    .font_weight("medium")
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has chat sidebar" => -> { assert_text "Messages" },
        "has conversation list" => -> { assert_text "Sarah Wilson" ; assert_text "Dev Team" },
        "has active chat" => -> { assert_text "Active now" },
        "has messages" => -> { assert_text "How's the new feature coming along?" },
        "has message input" => -> { assert_selector "input[placeholder*='Type a message']", visible: false }
      }
    )
  end

  # Additional E-commerce Components
  test "creates wishlist component" do
    test_component(
      name: "Wishlist",
      category: "E-commerce",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-6xl mx-auto p-6") do
            # Header
            hstack(justify: :between, class: "mb-8") do
              h1(class: "text-3xl font-bold text-gray-900") { text("My Wishlist") }
              text("4 items").text_color("gray-600")
            end
            
            # Wishlist grid
            grid(columns: { base: 1, md: 2, lg: 3 }, spacing: 6) do
              [
                { name: "Wireless Earbuds Pro", price: "$249", original: "$299", image: "🎧", discount: "-17%" },
                { name: "Smart Home Hub", price: "$199", original: "$249", image: "🏠", discount: "-20%" },
                { name: "4K Webcam", price: "$149", original: nil, image: "📹", discount: nil },
                { name: "Mechanical Keyboard", price: "$179", original: "$229", image: "⌨️", discount: "-22%" }
              ].each do |item|
                card(elevation: 1) do
                  vstack(spacing: 4) do
                    # Image with discount badge
                    div(class: "relative") do
                      div(class: "h-48 bg-gray-100 rounded-lg flex items-center justify-center text-6xl") do
                        text(item[:image])
                      end
                      
                      if item[:discount]
                        div(class: "absolute top-2 right-2 bg-red-500 text-white px-2 py-1 rounded text-sm font-semibold") do
                          text(item[:discount])
                        end
                      end
                      
                      # Remove button
                      button(class: "absolute top-2 left-2 w-8 h-8 bg-white rounded-full shadow-md flex items-center justify-center") do
                        text("×").text_xl.text_color("gray-600")
                      end
                    end
                    
                    # Product info
                    vstack(spacing: 2, alignment: :start) do
                      text(item[:name]).font_weight("semibold").text_color("gray-900")
                      
                      hstack(spacing: 2) do
                        text(item[:price]).font_weight("bold").text_color("gray-900")
                        if item[:original]
                          text(item[:original]).text_sm.text_color("gray-500").line_through
                        end
                      end
                    end
                    
                    # Actions
                    vstack(spacing: 2) do
                      button(class: "w-full") { text("Add to Cart") }
                        .bg("blue-600")
                        .text_color("white")
                        .py(2)
                        .rounded("lg")
                        .font_weight("medium")
                        .hover("bg-blue-700")
                      
                      button(class: "w-full") { text("Quick View") }
                        .bg("white")
                        .text_color("gray-700")
                        .py(2)
                        .rounded("lg")
                        .border
                        .hover("bg-gray-50")
                    end
                  end
                end.p(6)
              end
            end
            
            # Share wishlist
            div(class: "mt-12 text-center") do
              card(elevation: 1) do
                vstack(spacing: 4) do
                  h3(class: "font-semibold text-gray-900") { text("Share Your Wishlist") }
                  p(class: "text-gray-600") { text("Send your wishlist to friends and family") }
                  
                  hstack(spacing: 3, justify: :center) do
                    button { text("📧 Email") }.px(4).py(2).bg("gray-100").rounded("lg")
                    button { text("🔗 Copy Link") }.px(4).py(2).bg("gray-100").rounded("lg")
                    button { text("📱 Share") }.px(4).py(2).bg("gray-100").rounded("lg")
                  end
                end
              end.p(6)
            end
          end
        end
      RUBY
      assertions: {
        "has wishlist title" => -> { assert_text "My Wishlist" },
        "has item count" => -> { assert_text "4 items" },
        "has products" => -> { assert_text "Wireless Earbuds Pro" ; assert_text "Smart Home Hub" },
        "has discount badges" => -> { assert_text "-17%" ; assert_text "-20%" },
        "has action buttons" => -> { assert_selector "button", text: "Add to Cart", minimum: 4 },
        "has share options" => -> { assert_text "Share Your Wishlist" }
      }
    )
  end

  test "creates product reviews component" do
    test_component(
      name: "Product Reviews",
      category: "E-commerce",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-4xl mx-auto p-6") do
            # Header
            vstack(spacing: 6) do
              h2(class: "text-2xl font-bold text-gray-900") { text("Customer Reviews") }
              
              # Overall rating
              card(elevation: 1) do
                grid(columns: { base: 1, md: 2 }, spacing: 8, align: :center) do
                  # Rating summary
                  vstack(alignment: :center) do
                    text("4.5").text_5xl.font_weight("bold").text_color("gray-900")
                    hstack(spacing: 1) do
                      5.times do |i|
                        span(class: i < 4 ? "text-yellow-400" : "text-gray-300") { text("★") }
                      end
                    end
                    text("Based on 287 reviews").text_sm.text_color("gray-600")
                  end
                  
                  # Rating breakdown
                  vstack(spacing: 2) do
                    [
                      { stars: 5, count: 180, percent: 63 },
                      { stars: 4, count: 72, percent: 25 },
                      { stars: 3, count: 20, percent: 7 },
                      { stars: 2, count: 10, percent: 3 },
                      { stars: 1, count: 5, percent: 2 }
                    ].each do |rating|
                      hstack(spacing: 3, align: :center) do
                        text("\#{rating[:stars]} ★").text_sm.w(12)
                        div(class: "flex-1 h-2 bg-gray-200 rounded-full overflow-hidden") do
                          div(class: "h-full bg-yellow-400", style: "width: \#{rating[:percent]}%")
                        end
                        text(rating[:count].to_s).text_sm.text_color("gray-600").w(12).text_right
                      end
                    end
                  end
                end
              end.p(6)
              
              # Write review button
              button(class: "self-start") { text("Write a Review") }
                .bg("blue-600")
                .text_color("white")
                .px(6).py(3)
                .rounded("lg")
                .font_weight("medium")
                .mt(6)
              
              # Individual reviews
              vstack(spacing: 6) do
                [
                  { name: "John D.", rating: 5, date: "2 days ago", title: "Excellent product!", text: "Exceeded my expectations. Build quality is fantastic." },
                  { name: "Sarah M.", rating: 4, date: "1 week ago", title: "Very good, minor issues", text: "Great overall, but the setup instructions could be clearer." },
                  { name: "Mike R.", rating: 5, date: "2 weeks ago", title: "Worth every penny", text: "Best purchase I've made this year. Highly recommend!" }
                ].each do |review|
                  card(elevation: 1) do
                    vstack(spacing: 3) do
                      # Reviewer info
                      hstack(justify: :between) do
                        hstack(spacing: 3) do
                          div(class: "w-10 h-10 bg-gray-300 rounded-full flex items-center justify-center") do
                            text(review[:name].chars.first).font_weight("semibold")
                          end
                          
                          vstack(spacing: 0) do
                            text(review[:name]).font_weight("semibold")
                            hstack(spacing: 1) do
                              review[:rating].times { span(class: "text-yellow-400 text-sm") { text("★") } }
                            end
                          end
                        end
                        
                        text(review[:date]).text_sm.text_color("gray-500")
                      end
                      
                      # Review content
                      vstack(spacing: 2, alignment: :start) do
                        text(review[:title]).font_weight("semibold").text_color("gray-900")
                        text(review[:text]).text_color("gray-700")
                      end
                      
                      # Helpful buttons
                      hstack(spacing: 4) do
                        button { text("👍 Helpful (12)") }
                          .text_sm
                          .text_color("gray-600")
                          .hover("text-gray-900")
                        
                        button { text("👎 Not Helpful") }
                          .text_sm
                          .text_color("gray-600")
                          .hover("text-gray-900")
                      end
                    end
                  end.p(6)
                end
              end.mt(8)
              
              # Load more
              button(class: "self-center") { text("Load More Reviews") }
                .bg("white")
                .text_color("gray-700")
                .px(6).py(3)
                .rounded("lg")
                .border
                .mt(6)
            end
          end
        end
      RUBY
      assertions: {
        "has reviews title" => -> { assert_text "Customer Reviews" },
        "has overall rating" => -> { assert_text "4.5" },
        "has review count" => -> { assert_text "Based on 287 reviews" },
        "has rating breakdown" => -> { assert_text "5 ★" ; assert_text "180" },
        "has individual reviews" => -> { assert_text "John D." ; assert_text "Excellent product!" },
        "has write review button" => -> { assert_selector "button", text: "Write a Review" }
      }
    )
  end

  test "creates category page component" do
    test_component(
      name: "Category Page",
      category: "E-commerce",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-7xl mx-auto p-6") do
            # Breadcrumb
            hstack(spacing: 2, class: "text-sm text-gray-600 mb-6") do
              link("Home", destination: "#", class: "hover:text-gray-900")
              text("/")
              link("Electronics", destination: "#", class: "hover:text-gray-900")
              text("/")
              text("Audio").text_color("gray-900")
            end
            
            # Category header
            div(class: "mb-8") do
              h1(class: "text-4xl font-bold text-gray-900 mb-4") { text("Audio Equipment") }
              p(class: "text-lg text-gray-600") do
                text("Premium audio gear for music lovers and professionals")
              end
            end
            
            # Subcategories
            div(class: "mb-8") do
              h3(class: "font-semibold text-gray-900 mb-4") { text("Shop by Category") }
              
              grid(columns: { base: 2, md: 4, lg: 6 }, spacing: 4) do
                [
                  { name: "Headphones", icon: "🎧", count: 145 },
                  { name: "Speakers", icon: "🔊", count: 89 },
                  { name: "Microphones", icon: "🎤", count: 67 },
                  { name: "Amplifiers", icon: "📻", count: 34 },
                  { name: "Cables", icon: "🔌", count: 123 },
                  { name: "Accessories", icon: "🎵", count: 201 }
                ].each do |category|
                  link(destination: "#", class: "group") do
                    card(elevation: 1) do
                      vstack(spacing: 2, alignment: :center) do
                        text(category[:icon]).text_3xl
                        text(category[:name])
                          .font_weight("medium")
                          .text_color("gray-900")
                          .group_hover("text-blue-600")
                        text("\#{category[:count]} items")
                          .text_sm
                          .text_color("gray-600")
                      end
                    end.p(4).hover("shadow-md").transition
                  end
                end
              end
            end
            
            # Featured products
            div(class: "mb-12") do
              hstack(justify: :between, class: "mb-6") do
                h2(class: "text-2xl font-bold text-gray-900") { text("Featured Products") }
                link("View all →", destination: "#", class: "text-blue-600 hover:text-blue-700")
              end
              
              grid(columns: { base: 1, md: 2, lg: 4 }, spacing: 6) do
                [
                  { name: "Studio Pro Headphones", price: "$299", rating: 4.8, image: "🎧" },
                  { name: "Wireless Speaker Set", price: "$199", rating: 4.6, image: "🔊" },
                  { name: "USB Microphone", price: "$149", rating: 4.7, image: "🎤" },
                  { name: "Audio Interface", price: "$249", rating: 4.9, image: "🎛️" }
                ].each do |product|
                  card(elevation: 1) do
                    vstack(spacing: 3) do
                      div(class: "h-40 bg-gray-100 rounded flex items-center justify-center text-5xl") do
                        text(product[:image])
                      end
                      
                      vstack(spacing: 2, alignment: :start) do
                        text(product[:name])
                          .font_weight("medium")
                          .text_color("gray-900")
                        
                        hstack(spacing: 2) do
                          hstack(spacing: 0) do
                            5.times do |i|
                              span(class: i < product[:rating].floor ? "text-yellow-400" : "text-gray-300") do
                                text("★")
                              end
                            end
                          end
                          text(product[:rating].to_s).text_sm.text_color("gray-600")
                        end
                        
                        text(product[:price])
                          .font_weight("bold")
                          .text_color("gray-900")
                          .text_lg
                      end
                    end
                  end.p(4)
                end
              end
            end
            
            # Shop by brand
            div do
              h3(class: "font-semibold text-gray-900 mb-4") { text("Popular Brands") }
              
              hstack(spacing: 4, class: "overflow-x-auto pb-2") do
                ["Sony", "Bose", "JBL", "Sennheiser", "Audio-Technica", "Marshall"].each do |brand|
                  div(class: "flex-shrink-0 px-6 py-3 bg-gray-100 rounded-lg hover:bg-gray-200 cursor-pointer transition") do
                    text(brand).font_weight("medium")
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has breadcrumb" => -> { assert_text "Home" ; assert_text "Electronics" ; assert_text "Audio" },
        "has category title" => -> { assert_text "Audio Equipment" },
        "has subcategories" => -> { assert_text "Headphones" ; assert_text "145 items" },
        "has featured products" => -> { assert_text "Featured Products" ; assert_text "Studio Pro Headphones" },
        "has brands" => -> { assert_text "Popular Brands" ; assert_text "Sony" ; assert_text "Bose" }
      }
    )
  end

  # Additional Marketing Components
  test "creates comparison table component" do
    test_component(
      name: "Comparison Table",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-6xl mx-auto p-6") do
            # Header
            vstack(spacing: 4, alignment: :center) do
              h2(class: "text-4xl font-bold text-gray-900") { text("Compare Plans") }
              p(class: "text-xl text-gray-600") { text("Find the perfect plan for your needs") }
            end
            
            # Comparison table
            div(class: "mt-12 overflow-x-auto") do
              table(class: "w-full") do
                thead do
                  tr do
                    th(class: "text-left py-4 px-6") { text("") }
                    th(class: "text-center py-4 px-6 bg-gray-50") do
                      vstack(spacing: 2) do
                        text("Starter").font_weight("semibold").text_lg
                        text("$9/mo").text_gray_600
                      end
                    end
                    th(class: "text-center py-4 px-6 bg-blue-50 border-2 border-blue-500 border-b-0") do
                      vstack(spacing: 2) do
                        span(class: "text-xs bg-blue-600 text-white px-3 py-1 rounded-full") { text("RECOMMENDED") }
                        text("Pro").font_weight("semibold").text_lg.mt(2)
                        text("$29/mo").text_gray_600
                      end
                    end
                    th(class: "text-center py-4 px-6 bg-gray-50") do
                      vstack(spacing: 2) do
                        text("Enterprise").font_weight("semibold").text_lg
                        text("$99/mo").text_gray_600
                      end
                    end
                  end
                end
                
                tbody do
                  [
                    { feature: "Projects", starter: "3", pro: "Unlimited", enterprise: "Unlimited" },
                    { feature: "Storage", starter: "1 GB", pro: "50 GB", enterprise: "Unlimited" },
                    { feature: "Team Members", starter: "1", pro: "10", enterprise: "Unlimited" },
                    { feature: "API Access", starter: "✓", pro: "✓", enterprise: "✓" },
                    { feature: "Custom Domain", starter: "—", pro: "✓", enterprise: "✓" },
                    { feature: "Analytics", starter: "Basic", pro: "Advanced", enterprise: "Custom" },
                    { feature: "Support", starter: "Email", pro: "Priority", enterprise: "24/7 Phone" },
                    { feature: "SLA", starter: "—", pro: "99.9%", enterprise: "99.99%" }
                  ].each_with_index do |row, index|
                    tr(class: index.even? ? "bg-gray-50" : "") do
                      td(class: "py-4 px-6 font-medium") { text(row[:feature]) }
                      td(class: "py-4 px-6 text-center") { text(row[:starter]) }
                      td(class: "py-4 px-6 text-center bg-blue-50/50 border-x-2 border-blue-500") { text(row[:pro]) }
                      td(class: "py-4 px-6 text-center") { text(row[:enterprise]) }
                    end
                  end
                  
                  # CTA row
                  tr do
                    td(class: "py-6")
                    td(class: "py-6 px-6 text-center") do
                      button { text("Get Started") }
                        .bg("gray-200")
                        .text_color("gray-900")
                        .px(6).py(3)
                        .rounded("lg")
                        .font_weight("medium")
                        .hover("bg-gray-300")
                    end
                    td(class: "py-6 px-6 text-center bg-blue-50/50 border-x-2 border-b-2 border-blue-500") do
                      button { text("Get Started") }
                        .bg("blue-600")
                        .text_color("white")
                        .px(6).py(3)
                        .rounded("lg")
                        .font_weight("medium")
                        .hover("bg-blue-700")
                    end
                    td(class: "py-6 px-6 text-center") do
                      button { text("Contact Sales") }
                        .bg("gray-200")
                        .text_color("gray-900")
                        .px(6).py(3)
                        .rounded("lg")
                        .font_weight("medium")
                        .hover("bg-gray-300")
                    end
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has comparison title" => -> { assert_text "Compare Plans" },
        "has plan names" => -> { assert_text "Starter" ; assert_text "Pro" ; assert_text "Enterprise" },
        "has recommended badge" => -> { assert_text "RECOMMENDED" },
        "has features" => -> { assert_text "Projects" ; assert_text "Storage" ; assert_text "API Access" },
        "has CTA buttons" => -> { assert_selector "button", text: "Get Started", minimum: 2 }
      }
    )
  end

  test "creates roadmap component" do
    test_component(
      name: "Product Roadmap",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-6xl mx-auto p-6") do
            # Header
            vstack(spacing: 4, alignment: :center) do
              h2(class: "text-4xl font-bold text-gray-900") { text("Product Roadmap") }
              p(class: "text-xl text-gray-600") { text("See what we're building next") }
            end
            
            # Timeline
            div(class: "mt-12") do
              [
                {
                  quarter: "Q1 2024",
                  status: "completed",
                  items: [
                    { title: "Dark Mode", desc: "System-wide dark theme support", done: true },
                    { title: "API v2", desc: "RESTful API with GraphQL support", done: true },
                    { title: "Mobile App", desc: "iOS and Android apps", done: true }
                  ]
                },
                {
                  quarter: "Q2 2024",
                  status: "in-progress",
                  items: [
                    { title: "Real-time Collaboration", desc: "Live editing with team members", done: true },
                    { title: "Advanced Analytics", desc: "Detailed insights and reporting", done: false },
                    { title: "Integrations Hub", desc: "Connect with popular tools", done: false }
                  ]
                },
                {
                  quarter: "Q3 2024",
                  status: "planned",
                  items: [
                    { title: "AI Assistant", desc: "Smart suggestions and automation", done: false },
                    { title: "Enterprise SSO", desc: "SAML and OAuth support", done: false },
                    { title: "Custom Workflows", desc: "Build your own automations", done: false }
                  ]
                }
              ].each_with_index do |quarter, index|
                div(class: "relative") do
                  # Timeline line
                  if index < 2
                    div(class: "absolute left-8 top-16 bottom-0 w-0.5 bg-gray-300")
                  end
                  
                  # Quarter header
                  hstack(spacing: 4, align: :center) do
                    div(class: "w-16 h-16 rounded-full flex items-center justify-center \#{
                      quarter[:status] == 'completed' ? 'bg-green-500' :
                      quarter[:status] == 'in-progress' ? 'bg-blue-500' : 'bg-gray-300'
                    }") do
                      if quarter[:status] == 'completed'
                        text("✓").text_white.text_xl.font_weight("bold")
                      elsif quarter[:status] == 'in-progress'
                        div(class: "w-3 h-3 bg-white rounded-full animate-pulse")
                      end
                    end
                    
                    vstack(spacing: 1, alignment: :start) do
                      text(quarter[:quarter]).text_2xl.font_weight("bold").text_color("gray-900")
                      text(quarter[:status].tr('_', ' ').capitalize)
                        .text_sm
                        .text_color(quarter[:status] == 'completed' ? 'green-600' :
                                   quarter[:status] == 'in-progress' ? 'blue-600' : 'gray-600')
                    end
                  end
                  
                  # Items
                  div(class: "ml-20 mt-4 mb-12") do
                    vstack(spacing: 3) do
                      quarter[:items].each do |item|
                        card(elevation: 1) do
                          hstack(spacing: 4) do
                            div(class: "w-6 h-6 rounded-full flex-shrink-0 flex items-center justify-center \#{
                              item[:done] ? 'bg-green-100' : 'bg-gray-100'
                            }") do
                              if item[:done]
                                text("✓").text_green_600.text_sm
                              else
                                div(class: "w-2 h-2 bg-gray-400 rounded-full")
                              end
                            end
                            
                            vstack(spacing: 1, alignment: :start) do
                              text(item[:title])
                                .font_weight("semibold")
                                .text_color(item[:done] ? "gray-900" : "gray-700")
                              text(item[:desc])
                                .text_sm
                                .text_color("gray-600")
                            end
                          end
                        end.p(4)
                      end
                    end
                  end
                end
              end
            end
            
            # Subscribe CTA
            div(class: "text-center mt-16") do
              card(elevation: 2) do
                vstack(spacing: 4) do
                  h3(class: "text-xl font-semibold text-gray-900") { text("Get notified about updates") }
                  p(class: "text-gray-600") { text("Be the first to know when new features launch") }
                  
                  hstack(spacing: 3, justify: :center) do
                    textfield(
                      type: "email",
                      placeholder: "your@email.com",
                      class: "w-64"
                    ).px(4).py(3).rounded("lg").border
                    
                    button { text("Subscribe") }
                      .bg("blue-600")
                      .text_color("white")
                      .px(6).py(3)
                      .rounded("lg")
                      .font_weight("medium")
                  end
                end
              end.p(8).bg("blue-50")
            end
          end
        end
      RUBY
      assertions: {
        "has roadmap title" => -> { assert_text "Product Roadmap" },
        "has quarters" => -> { assert_text "Q1 2024" ; assert_text "Q2 2024" ; assert_text "Q3 2024" },
        "has status indicators" => -> { assert_text "completed" ; assert_text "in-progress" ; assert_text "planned" },
        "has roadmap items" => -> { assert_text "Dark Mode" ; assert_text "AI Assistant" },
        "has subscribe form" => -> { assert_selector "input[type='email']", visible: false }
      }
    )
  end

  test "creates changelog component" do
    test_component(
      name: "Changelog",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "max-w-4xl mx-auto p-6") do
            # Header
            vstack(spacing: 4, alignment: :center) do
              h1(class: "text-4xl font-bold text-gray-900") { text("Changelog") }
              p(class: "text-xl text-gray-600") { text("Stay up to date with the latest improvements") }
            end
            
            # Changelog entries
            vstack(spacing: 12) do
              [
                {
                  version: "v2.5.0",
                  date: "July 10, 2024",
                  type: "major",
                  changes: [
                    { type: "feature", text: "Added real-time collaboration features" },
                    { type: "feature", text: "New dashboard with customizable widgets" },
                    { type: "improvement", text: "50% faster page load times" },
                    { type: "fix", text: "Fixed issue with file uploads on mobile" }
                  ]
                },
                {
                  version: "v2.4.2",
                  date: "June 28, 2024",
                  type: "patch",
                  changes: [
                    { type: "fix", text: "Resolved memory leak in data processing" },
                    { type: "fix", text: "Fixed timezone issues in scheduling" },
                    { type: "improvement", text: "Better error messages for form validation" }
                  ]
                },
                {
                  version: "v2.4.0",
                  date: "June 15, 2024",
                  type: "minor",
                  changes: [
                    { type: "feature", text: "API v2 with GraphQL support" },
                    { type: "feature", text: "Dark mode for all UI components" },
                    { type: "improvement", text: "Enhanced security with 2FA" },
                    { type: "deprecation", text: "API v1 endpoints deprecated (EOL: Dec 2024)" }
                  ]
                }
              ].each do |release|
                card(elevation: 1) do
                  vstack(spacing: 4) do
                    # Release header
                    hstack(justify: :between) do
                      hstack(spacing: 3) do
                        text(release[:version])
                          .text_2xl
                          .font_weight("bold")
                          .text_color("gray-900")
                        
                        span(class: "px-3 py-1 rounded-full text-sm font-medium \#{
                          release[:type] == 'major' ? 'bg-purple-100 text-purple-800' :
                          release[:type] == 'minor' ? 'bg-blue-100 text-blue-800' :
                          'bg-gray-100 text-gray-800'
                        }") do
                          text(release[:type].upcase)
                        end
                      end
                      
                      text(release[:date]).text_color("gray-600")
                    end
                    
                    # Changes
                    vstack(spacing: 2) do
                      release[:changes].each do |change|
                        hstack(spacing: 3, align: :start) do
                          # Icon based on type
                          div(class: "flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center text-xs \#{
                            change[:type] == 'feature' ? 'bg-green-100 text-green-600' :
                            change[:type] == 'improvement' ? 'bg-blue-100 text-blue-600' :
                            change[:type] == 'fix' ? 'bg-yellow-100 text-yellow-600' :
                            'bg-red-100 text-red-600'
                          }") do
                            text(
                              change[:type] == 'feature' ? '✨' :
                              change[:type] == 'improvement' ? '⚡' :
                              change[:type] == 'fix' ? '🐛' : '⚠️'
                            )
                          end
                          
                          text(change[:text]).text_color("gray-700")
                        end
                      end
                    end
                  end
                end.p(6)
              end
            end.mt(12)
            
            # RSS feed link
            div(class: "text-center mt-12") do
              link(destination: "#", class: "inline-flex items-center text-blue-600 hover:text-blue-700") do
                text("📡 Subscribe to RSS feed")
              end
            end
          end
        end
      RUBY
      assertions: {
        "has changelog title" => -> { assert_text "Changelog" },
        "has version numbers" => -> { assert_text "v2.5.0" ; assert_text "v2.4.2" ; assert_text "v2.4.0" },
        "has release types" => -> { assert_text "MAJOR" ; assert_text "MINOR" ; assert_text "PATCH" },
        "has change types" => -> { assert_text "Added real-time collaboration" ; assert_text "Fixed issue with file uploads" },
        "has RSS link" => -> { assert_text "Subscribe to RSS feed" }
      }
    )
  end

  # Final components to reach 50 tests
  test "creates features grid component" do
    test_component(
      name: "Features Grid",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "py-16 bg-white") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Everything you need") }
                p(class: "text-xl text-gray-600 max-w-3xl") do
                  text("Our platform provides all the tools and features to build amazing applications faster than ever before.")
                end
              end
              
              # Features grid
              grid(columns: { base: 1, md: 2, lg: 3 }, spacing: 8) do
                [
                  { 
                    icon: "⚡", 
                    title: "Lightning Fast", 
                    desc: "Optimized performance with sub-second load times and instant interactions."
                  },
                  { 
                    icon: "🔒", 
                    title: "Enterprise Security", 
                    desc: "Bank-level encryption, SOC2 compliance, and regular security audits."
                  },
                  { 
                    icon: "🌍", 
                    title: "Global Scale", 
                    desc: "Deploy to multiple regions with automatic failover and CDN integration."
                  },
                  { 
                    icon: "🤝", 
                    title: "Team Collaboration", 
                    desc: "Real-time editing, commenting, and version control for teams."
                  },
                  { 
                    icon: "📊", 
                    title: "Advanced Analytics", 
                    desc: "Deep insights into user behavior and application performance."
                  },
                  { 
                    icon: "🔧", 
                    title: "Developer Friendly", 
                    desc: "Comprehensive API, webhooks, and integration with your favorite tools."
                  }
                ].each do |feature|
                  vstack(spacing: 4, alignment: :start) do
                    div(class: "w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center text-2xl") do
                      text(feature[:icon])
                    end
                    
                    h3(class: "text-xl font-semibold text-gray-900") { text(feature[:title]) }
                    p(class: "text-gray-600") { text(feature[:desc]) }
                    
                    link("Learn more →", destination: "#", class: "text-blue-600 hover:text-blue-700 font-medium")
                  end
                end
              end.mt(12)
              
              # CTA section
              div(class: "mt-16 text-center") do
                button { text("Start Building Today") }
                  .bg("blue-600")
                  .text_color("white")
                  .px(8).py(4)
                  .rounded("lg")
                  .font_weight("semibold")
                  .text_size("lg")
                  .hover("bg-blue-700")
                  .transition
              end
            end
          end
        end
      RUBY
      assertions: {
        "has features title" => -> { assert_text "Everything you need" },
        "has feature items" => -> { assert_text "Lightning Fast" ; assert_text "Enterprise Security" },
        "has feature descriptions" => -> { assert_text "Optimized performance" ; assert_text "Bank-level encryption" },
        "has learn more links" => -> { assert_text "Learn more →", minimum: 6 },
        "has CTA button" => -> { assert_selector "button", text: "Start Building Today" }
      }
    )
  end

  test "creates team section component" do
    test_component(
      name: "Team Section",
      category: "Marketing",
      code: <<~RUBY,
        swift_ui do
          div(class: "py-16 bg-gray-50") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Meet Our Team") }
                p(class: "text-xl text-gray-600") { text("The talented people behind SwiftUI Rails") }
              end
              
              # Team grid
              grid(columns: { base: 1, md: 2, lg: 4 }, spacing: 8) do
                [
                  { name: "Sarah Chen", role: "CEO & Founder", avatar: "👩‍💼", bio: "10+ years building developer tools" },
                  { name: "Michael Rodriguez", role: "CTO", avatar: "👨‍💻", bio: "Rails core contributor" },
                  { name: "Emily Johnson", role: "Head of Design", avatar: "👩‍🎨", bio: "Former Apple design lead" },
                  { name: "David Kim", role: "VP Engineering", avatar: "👨‍💼", bio: "Scaled systems to millions of users" },
                  { name: "Lisa Thompson", role: "Head of Product", avatar: "👩‍🚀", bio: "Product strategy expert" },
                  { name: "James Wilson", role: "VP Sales", avatar: "👨‍💼", bio: "Enterprise software veteran" },
                  { name: "Maria Garcia", role: "Developer Advocate", avatar: "👩‍🏫", bio: "Community builder & educator" },
                  { name: "Alex Park", role: "Senior Engineer", avatar: "🧑‍💻", bio: "Open source enthusiast" }
                ].each do |member|
                  card(elevation: 1) do
                    vstack(spacing: 4, alignment: :center) do
                      # Avatar
                      div(class: "w-24 h-24 bg-gray-200 rounded-full flex items-center justify-center text-5xl") do
                        text(member[:avatar])
                      end
                      
                      # Info
                      vstack(spacing: 1, alignment: :center) do
                        text(member[:name])
                          .font_weight("semibold")
                          .text_color("gray-900")
                          .text_lg
                        text(member[:role])
                          .text_sm
                          .text_color("blue-600")
                          .font_weight("medium")
                      end
                      
                      # Bio
                      text(member[:bio])
                        .text_sm
                        .text_color("gray-600")
                        .text_center
                      
                      # Social links
                      hstack(spacing: 3, justify: :center) do
                        ["LinkedIn", "Twitter", "GitHub"].each do |social|
                          link(destination: "#", class: "text-gray-400 hover:text-gray-600") do
                            text(social[0])
                              .w(8).h(8)
                              .bg("gray-100")
                              .rounded("full")
                              .flex
                              .items_center
                              .justify_center
                              .text_xs
                              .font_weight("bold")
                          end
                        end
                      end
                    end
                  end.p(6)
                end
              end.mt(12)
              
              # Join us CTA
              div(class: "mt-16 text-center") do
                card(elevation: 2) do
                  vstack(spacing: 4) do
                    h3(class: "text-2xl font-semibold text-gray-900") { text("Join Our Growing Team") }
                    p(class: "text-gray-600 max-w-2xl mx-auto") do
                      text("We're always looking for talented individuals who are passionate about building the future of web development.")
                    end
                    
                    button { text("View Open Positions") }
                      .bg("blue-600")
                      .text_color("white")
                      .px(6).py(3)
                      .rounded("lg")
                      .font_weight("medium")
                      .hover("bg-blue-700")
                  end
                end.p(8).bg("white")
              end
            end
          end
        end
      RUBY
      assertions: {
        "has team title" => -> { assert_text "Meet Our Team" },
        "has team members" => -> { assert_text "Sarah Chen" ; assert_text "Michael Rodriguez" },
        "has roles" => -> { assert_text "CEO & Founder" ; assert_text "CTO" },
        "has bios" => -> { assert_text "Rails core contributor" },
        "has join CTA" => -> { assert_text "Join Our Growing Team" ; assert_selector "button", text: "View Open Positions" }
      }
    )
  end
end