# frozen_string_literal: true

require_relative "component_showcase_base"

class MarketingComponentsShowcaseTest < ComponentShowcaseBase
  test "creates hero section with gradient" do
    test_component(
      name: "Hero Section - Gradient",
      category: "Marketing",
      code: <<~'RUBY',
        swift_ui do
          div(class: "relative bg-gradient-to-br from-indigo-600 to-purple-700 min-h-screen") do
            # Navigation
            nav(class: "relative z-10") do
              div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
                hstack(justify: :between, align: :center) do
                  # Logo
                  h1(class: "text-2xl font-bold text-white") { text("SwiftUI Rails") }
                  
                  # Nav links
                  hstack(spacing: 8) do
                    ["Features", "Pricing", "Docs", "Blog"].each do |item|
                      link(item, destination: "#", class: "text-white/80 hover:text-white transition")
                    end
                  end
                end
              end.py(6)
            end
            
            # Hero content
            div(class: "relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24 lg:py-32") do
              vstack(spacing: 8, alignment: :center) do
                # Badge
                span(class: "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-indigo-100 text-indigo-800") do
                  text("🎉 Version 2.0 is here")
                end
                
                # Headline
                h2(class: "text-5xl lg:text-7xl font-bold text-white text-center max-w-4xl") do
                  text("Build Beautiful Rails Apps with SwiftUI Syntax")
                end
                
                # Subheadline
                p(class: "text-xl lg:text-2xl text-indigo-200 text-center max-w-3xl") do
                  text("The perfect blend of SwiftUI's declarative syntax and Rails' powerful backend. Create stunning UIs with the framework you love.")
                end
                
                # CTA buttons
                hstack(spacing: 4) do
                  button { text("Get Started") }
                    .bg("white")
                    .text_color("indigo-600")
                    .px(8).py(4)
                    .rounded("lg")
                    .font_weight("semibold")
                    .text_size("lg")
                    .hover("shadow-xl")
                    
                  button { text("View Examples") }
                    .bg("indigo-500")
                    .text_color("white")
                    .px(8).py(4)
                    .rounded("lg")
                    .font_weight("semibold")
                    .text_size("lg")
                    .hover("bg-indigo-400")
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has hero headline" => -> { assert_text "Build Beautiful Rails Apps" },
        "has subheadline" => -> { assert_text "perfect blend" },
        "has CTA buttons" => -> { assert_selector "button", text: "Get Started" },
        "has navigation" => -> { assert_text "Features" }
      }
    )
  end

  test "creates feature section grid" do
    test_component(
      name: "Feature Section - Grid",
      category: "Marketing",
      code: <<~'RUBY',
        swift_ui do
          section(class: "py-24 bg-gray-50") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Everything you need") }
                p(class: "text-xl text-gray-600 max-w-3xl") do
                  text("SwiftUI Rails provides all the tools you need to build modern, reactive Rails applications with a delightful developer experience.")
                end
              end
              
              # Features grid
              grid(columns: 3, spacing: 8) do
                features = [
                  { icon: "⚡", title: "Lightning Fast", description: "Optimized for performance with minimal JavaScript overhead" },
                  { icon: "🎨", title: "Beautiful by Default", description: "Pre-styled components that look great out of the box" },
                  { icon: "🔧", title: "Fully Customizable", description: "Extend and customize every component to match your brand" },
                  { icon: "📱", title: "Responsive Design", description: "Mobile-first components that work on any screen size" },
                  { icon: "🚀", title: "Production Ready", description: "Battle-tested in production applications" },
                  { icon: "🛡️", title: "Type Safe", description: "Catch errors at development time, not runtime" }
                ]
                
                features.each do |feature|
                  card(elevation: 0) do
                    vstack(spacing: 4, alignment: :start) do
                      # Icon
                      div(class: "text-4xl") { text(feature[:icon]) }
                      
                      # Title
                      h3(class: "text-xl font-semibold text-gray-900") { text(feature[:title]) }
                      
                      # Description
                      p(class: "text-gray-600") { text(feature[:description]) }
                    end
                  end.p(6).bg("white").border.rounded("lg")
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has section title" => -> { assert_text "Everything you need" },
        "has feature cards" => -> { assert_text "Lightning Fast" ; assert_text "Beautiful by Default" },
        "has icons" => -> { assert_text "⚡" },
        "has descriptions" => -> { assert_text "Optimized for performance" }
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

  test "creates pricing section with tiers" do
    test_component(
      name: "Pricing Section - Tiers",
      category: "Marketing",
      code: <<~'RUBY',
        swift_ui do
          section(class: "py-24 bg-gray-50") do
            div(class: "max-w-7xl mx-auto px-6") do
              # Header
              vstack(spacing: 4, alignment: :center) do
                h2(class: "text-4xl font-bold text-gray-900") { text("Simple, transparent pricing") }
                p(class: "text-xl text-gray-600") { text("Choose the plan that's right for you") }
              end
              
              # Pricing cards
              grid(columns: 3, spacing: 8) do
                # Starter plan
                card(elevation: 1) do
                  vstack(spacing: 6) do
                    # Plan name
                    h3(class: "text-2xl font-bold text-gray-900") { text("Starter") }
                    
                    # Price
                    div do
                      span(class: "text-5xl font-bold text-gray-900") { text("$9") }
                      span(class: "text-gray-600") { text("/month") }
                    end
                    
                    # Features
                    vstack(spacing: 3) do
                      ["3 projects", "1GB storage", "Basic support", "SSL certificates"].each do |feature|
                        hstack(spacing: 3) do
                          span(class: "text-green-500") { text("✓") }
                          text(feature).text_color("gray-700")
                        end
                      end
                    end
                    
                    # CTA
                    button { text("Start free trial") }
                      .bg("gray-900")
                      .text_color("white")
                      .full_width
                      .py(3)
                      .rounded("lg")
                      .font_weight("medium")
                      .hover("bg-gray-800")
                  end
                end.p(8).bg("white")
                
                # Pro plan (featured)
                card(elevation: 3) do
                  div(class: "relative") do
                    # Badge
                    div(class: "absolute -top-4 left-1/2 transform -translate-x-1/2") do
                      span(class: "bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-1 rounded-full text-sm font-medium") do
                        text("Most Popular")
                      end
                    end
                    
                    vstack(spacing: 6) do
                      h3(class: "text-2xl font-bold text-gray-900 mt-4") { text("Pro") }
                      
                      div do
                        span(class: "text-5xl font-bold text-gray-900") { text("$29") }
                        span(class: "text-gray-600") { text("/month") }
                      end
                      
                      vstack(spacing: 3) do
                        ["Unlimited projects", "50GB storage", "Priority support", "Advanced analytics", "API access", "Custom domains"].each do |feature|
                          hstack(spacing: 3) do
                            span(class: "text-green-500") { text("✓") }
                            text(feature).text_color("gray-700")
                          end
                        end
                      end
                      
                      button { text("Start free trial") }
                        .bg("gradient-to-r from-blue-600 to-indigo-600")
                        .text_color("white")
                        .full_width
                        .py(3)
                        .rounded("lg")
                        .font_weight("medium")
                        .hover("shadow-lg")
                    end
                  end
                end.p(8).bg("white").border("2px solid").border_color("blue-600")
                
                # Enterprise plan
                card(elevation: 1) do
                  vstack(spacing: 6) do
                    h3(class: "text-2xl font-bold text-gray-900") { text("Enterprise") }
                    
                    div do
                      span(class: "text-5xl font-bold text-gray-900") { text("Custom") }
                    end
                    
                    vstack(spacing: 3) do
                      ["Everything in Pro", "Unlimited storage", "24/7 phone support", "SLA guarantee", "Custom contracts", "Dedicated manager"].each do |feature|
                        hstack(spacing: 3) do
                          span(class: "text-green-500") { text("✓") }
                          text(feature).text_color("gray-700")
                        end
                      end
                    end
                    
                    button { text("Contact sales") }
                      .bg("white")
                      .text_color("gray-900")
                      .border
                      .full_width
                      .py(3)
                      .rounded("lg")
                      .font_weight("medium")
                      .hover("bg-gray-50")
                  end
                end.p(8).bg("white")
              end
            end
          end
        end
      RUBY
      assertions: {
        "has pricing title" => -> { assert_text "Simple, transparent pricing" },
        "has plan names" => -> { assert_text "Starter" ; assert_text "Pro" ; assert_text "Enterprise" },
        "has prices" => -> { assert_text "$9" ; assert_text "$29" },
        "has popular badge" => -> { assert_text "Most Popular" },
        "has features" => -> { assert_text "Unlimited projects" }
      }
    )
  end

  test "creates newsletter signup section" do
    test_component(
      name: "Newsletter Signup",
      category: "Marketing",
      code: <<~'RUBY',
        swift_ui do
          section(class: "bg-indigo-700 py-16") do
            div(class: "max-w-7xl mx-auto px-6") do
              div(class: "bg-indigo-800 rounded-3xl px-6 py-10 md:px-12 md:py-16") do
                grid(columns: { base: 1, md: 2 }, spacing: 8, align: :center) do
                  # Content
                  div do
                    h2(class: "text-3xl md:text-4xl font-bold text-white") do
                      text("Stay up to date")
                    end
                    p(class: "mt-4 text-lg text-indigo-200") do
                      text("Get the latest updates on new features, tips & tricks, and exclusive content.")
                    end
                  end
                  
                  # Form
                  form do
                    hstack(spacing: 4) do
                      textfield(
                        type: "email",
                        name: "email",
                        placeholder: "Enter your email",
                        class: "flex-1 px-4 py-3 rounded-lg bg-white text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-white"
                      )
                      
                      button { text("Subscribe") }
                        .bg("white")
                        .text_color("indigo-700")
                        .px(6).py(3)
                        .rounded("lg")
                        .font_weight("semibold")
                        .hover("bg-gray-100")
                        .whitespace_nowrap
                    end
                    
                    p(class: "mt-3 text-sm text-indigo-200") do
                      text("We care about your privacy. Unsubscribe at any time.")
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
        "has description" => -> { assert_text "latest updates" },
        "has email input" => -> { assert_selector "input[type='email']" },
        "has subscribe button" => -> { assert_selector "button", text: "Subscribe" },
        "has privacy text" => -> { assert_text "privacy" }
      }
    )
  end

  test "creates footer section" do
    test_component(
      name: "Footer Section",
      category: "Marketing",
      code: <<~'RUBY',
        swift_ui do
          footer(class: "bg-gray-900") do
            div(class: "max-w-7xl mx-auto px-6 py-12") do
              grid(columns: { base: 1, md: 4 }, spacing: 8) do
                # Company info
                div do
                  h3(class: "text-white font-bold text-lg mb-4") { text("SwiftUI Rails") }
                  p(class: "text-gray-400 mb-4") do
                    text("Build beautiful Rails applications with SwiftUI-inspired syntax.")
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
                    
                    vstack(spacing: 3, alignment: :start) do
                      links = case section
                      when "Product"
                        ["Features", "Pricing", "Documentation", "Changelog"]
                      when "Resources"
                        ["Blog", "Tutorials", "API Reference", "Support"]
                      when "Company"
                        ["About", "Careers", "Contact", "Privacy"]
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
                  p(class: "text-gray-400") do
                    text("© 2024 SwiftUI Rails. All rights reserved.")
                  end
                  
                  hstack(spacing: 6) do
                    link("Terms", destination: "#", class: "text-gray-400 hover:text-white")
                    link("Privacy", destination: "#", class: "text-gray-400 hover:text-white")
                  end
                end
              end
            end
          end
        end
      RUBY
      assertions: {
        "has company name" => -> { assert_text "SwiftUI Rails" },
        "has footer sections" => -> { assert_text "Product" ; assert_text "Resources" ; assert_text "Company" },
        "has copyright" => -> { assert_text "© 2024" },
        "has footer links" => -> { assert_text "Features" ; assert_text "Blog" }
      }
    )
  end
end