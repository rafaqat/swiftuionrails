# frozen_string_literal: true

require 'rails/generators'

module SwiftUIRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install SwiftUI Rails with all necessary infrastructure"
      source_root File.expand_path("templates", __dir__)
      
      class_option :skip_npm, type: :boolean, default: false, desc: "Skip npm install step"
      class_option :skip_build, type: :boolean, default: false, desc: "Skip initial Tailwind build"

      def create_application_layout
        layout_file = "app/views/layouts/application.html.erb"
        
        if File.exist?(layout_file)
          say "Updating application layout for SwiftUI Rails...", :green
          
          # Read existing layout
          content = File.read(layout_file)
          
          # Check if it already has Tailwind CSS link
          unless content.include?('stylesheet_link_tag "tailwind"')
            # Replace stylesheet_link_tag :app with tailwind
            if content.include?('stylesheet_link_tag :app')
              content.gsub!(/<%=\s*stylesheet_link_tag\s+:app[^%]*%>/, 
                           '<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>')
              say "Updated existing stylesheet_link_tag to use Tailwind", :green
            elsif content.include?('</head>')
              # Add before closing head tag if no stylesheet_link_tag found
              content.gsub!('</head>', '    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
  </head>')
              say "Added Tailwind stylesheet_link_tag to existing layout", :green
            end
            
            File.write(layout_file, content)
          else
            say "Application layout already configured for Tailwind", :yellow
          end
        else
          say "Creating application layout file...", :green
          template "application.html.erb.tt", layout_file
        end
      end

      def configure_assets
        assets_file = "config/initializers/assets.rb"
        asset_path_line = 'Rails.application.config.assets.paths << Rails.root.join("app/assets/builds")'
        
        if File.exist?(assets_file)
          unless File.read(assets_file).include?("app/assets/builds")
            say "Configuring asset paths...", :green
            append_to_file assets_file, "\n# SwiftUI Rails asset configuration\n#{asset_path_line}\n"
          else
            say "Asset paths already configured, skipping...", :yellow
          end
        else
          say "Creating assets configuration...", :green
          create_file assets_file, <<~RUBY
            # Be sure to restart your server when you modify this file.

            # Version of your assets, change this if you want to expire all your assets.
            Rails.application.config.assets.version = "1.0"

            # Add additional assets to the asset load path.
            # Rails.application.config.assets.paths << Emoji.images_path

            # SwiftUI Rails asset configuration
            #{asset_path_line}

            # Precompile additional assets.
            # application.js, application.css, and all non-JS/CSS in the app/assets
            # folder are already added.
            # Rails.application.config.assets.precompile += %w( admin.js admin.css )
          RUBY
        end
      end

      def setup_tailwind
        say "Setting up Tailwind CSS...", :green
        
        # Create tailwind config if it doesn't exist
        unless File.exist?("config/tailwind.config.js")
          template "tailwind.config.js.tt", "config/tailwind.config.js"
        end

        # Create Tailwind input file
        unless File.exist?("app/assets/stylesheets/application.tailwind.css")
          directory "app/assets/stylesheets"
        end

        # Create builds directory
        empty_directory "app/assets/builds"
        
        # Add to gitignore
        gitignore_entry = "/app/assets/builds/*"
        gitignore_file = ".gitignore"
        
        if File.exist?(gitignore_file)
          unless File.read(gitignore_file).include?("app/assets/builds")
            append_to_file gitignore_file, "\n# SwiftUI Rails builds\n#{gitignore_entry}\n"
          end
        end
      end

      def create_procfile_dev
        unless File.exist?("Procfile.dev")
          say "Creating Procfile.dev...", :green
          template "Procfile.dev.tt", "Procfile.dev"
        else
          say "Procfile.dev already exists, skipping...", :yellow
        end
      end

      def create_package_json
        unless File.exist?("package.json")
          say "Creating package.json for Tailwind...", :green
          template "package.json.tt", "package.json"
        else
          say "package.json already exists, skipping...", :yellow
        end
      end

      def create_bin_dev
        unless File.exist?("bin/dev")
          say "Creating bin/dev script...", :green
          template "bin/dev.tt", "bin/dev"
          chmod "bin/dev", 0755
        else
          say "bin/dev already exists, skipping...", :yellow
        end
      end

      def install_npm_dependencies
        if File.exist?("package.json")
          say "Installing Tailwind CSS dependencies...", :green
          run "npm install"
        end
      end

      def build_tailwind_css
        if File.exist?("config/tailwind.config.js")
          say "Building initial Tailwind CSS...", :green
          run "npx tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/tailwind.css --build"
        end
      end

      def create_initializer
        say "Creating SwiftUI Rails initializer...", :green
        template "swift_ui_rails.rb.tt", "config/initializers/swift_ui_rails.rb"
      end

      def create_application_component
        say "Creating ApplicationComponent base class...", :green
        create_file "app/components/application_component.rb", <<~RUBY
          # frozen_string_literal: true

          class ApplicationComponent < SwiftUIRails::Component::Base
            # Include any application-wide component functionality here
            
            # Example: Add common helper methods
            # def current_user
            #   # Access current user from session/context
            # end
            
            # Example: Add common styling helpers
            # def primary_button_styles
            #   "bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            # end
          end
        RUBY
      end

      def create_business_components
        say "Creating high-level business components...", :green
        
        # Login CTA Component
        create_file "app/components/login_call_to_action_component.rb", <<~RUBY
          class LoginCallToActionComponent < ApplicationComponent
            # Business-level component that encapsulates the "Get Started" user journey
            # Uses ONLY SwiftUI Rails DSL methods - no HTML
            
            # Props for customization
            prop :button_text, type: String, default: "Get started"
            prop :button_style, type: Symbol, default: :primary # :primary, :secondary, :outline
            prop :button_size, type: Symbol, default: :lg # :sm, :md, :lg, :xl
            prop :show_modal, type: [TrueClass, FalseClass], default: false
            prop :login_url, type: String, default: "/login"
            prop :register_url, type: String, default: "/register"
            prop :close_url, type: String, default: "/"
            prop :enable_social_login, type: [TrueClass, FalseClass], default: true
            prop :social_providers, type: Array, default: ['google', 'github']
            prop :modal_size, type: Symbol, default: :md
            prop :return_url, type: String, default: nil
            
            swift_ui do
              vstack(spacing: 0) do
                # The CTA button using DSL
                cta_button
                
                # The login modal using DSL component (conditionally rendered)
                if show_modal
                  login_modal
                end
              end
            end
            
            private
            
            def cta_button
              button(button_text)
                .tap { |btn| apply_button_style(btn) }
                .tap { |btn| apply_button_size(btn) }
                .data(
                  controller: "login-cta",
                  action: "click->login-cta#showLogin",
                  "login-cta-modal-url-value": modal_url,
                  "login-cta-return-url-value": return_url
                )
            end
            
            def login_modal
              render SwiftUIRails::Component::Composed::Auth::LoginDialogComponent.new(
                open: true,
                login_url: login_url,
                register_url: register_url,
                close_url: close_url,
                show_social: enable_social_login,
                social_providers: social_providers,
                size: modal_size
              )
            end
            
            # Style application methods using DSL
            def apply_button_style(btn)
              case button_style
              when :primary
                btn.bg("blue-600")
                   .text_color("white")
                   .hover_bg("blue-700")
                   .shadow("lg")
              when :secondary
                btn.bg("gray-600")
                   .text_color("white")
                   .hover_bg("gray-700")
                   .shadow("md")
              when :outline
                btn.border
                   .border_color("blue-600")
                   .text_color("blue-600")
                   .hover_bg("blue-50")
                   .hover_border_color("blue-700")
              end
              
              btn.transition_colors
                 .font_semibold
                 .rounded("lg")
            end
            
            def apply_button_size(btn)
              case button_size
              when :sm
                btn.px(4).py(2).text_sm
              when :md
                btn.px(6).py(3).text_base
              when :lg
                btn.px(8).py(4).text_lg
              when :xl
                btn.px(10).py(5).text_xl
              end
            end
            
            def modal_url
              current_url = request&.url || close_url
              uri = URI.parse(current_url)
              params = URI.decode_www_form(uri.query || '') << ['show_login', 'true']
              uri.query = URI.encode_www_form(params)
              uri.to_s
            end
          end
        RUBY
        
        # Hero Section Component
        create_file "app/components/hero_section_component.rb", <<~RUBY
          class HeroSectionComponent < ApplicationComponent
            # Business-level component for landing page hero sections with navigation
            # Uses ONLY SwiftUI Rails DSL methods - no HTML
            
            # Props for content
            prop :headline, type: String, required: true
            prop :subheadline, type: String, default: nil
            prop :description, type: String, default: nil
            
            # Props for primary CTA
            prop :primary_cta_text, type: String, default: "Get started"
            prop :primary_cta_action, type: Symbol, default: :login # :login, :signup, :custom
            prop :primary_cta_url, type: String, default: nil
            
            # Props for secondary CTA
            prop :secondary_cta_text, type: String, default: nil
            prop :secondary_cta_url, type: String, default: "#"
            
            # Props for login modal (when primary_cta_action is :login)
            prop :show_login_modal, type: [TrueClass, FalseClass], default: false
            prop :login_url, type: String, default: "/login"
            prop :register_url, type: String, default: "/register"
            prop :close_url, type: String, default: "/"
            
            # Props for toolbar/navigation
            prop :brand_text, type: String, default: "Your App"
            prop :brand_logo, type: String, default: nil
            prop :navigation_items, type: Array, default: [
              { text: "Product", url: "#product" },
              { text: "Features", url: "#features" },
              { text: "Marketplace", url: "#marketplace" },
              { text: "Company", url: "#company" }
            ]
            prop :show_auth_buttons, type: [TrueClass, FalseClass], default: true
            
            # Layout props
            prop :text_alignment, type: Symbol, default: :center # :left, :center, :right
            prop :max_width, type: String, default: "4xl"
            prop :padding_y, type: Integer, default: 16
            
            swift_ui do
              # Main container using DSL
              div.min_h("screen").bg("gray-50") do
                # Navigation toolbar using DSL ToolbarComponent
                navigation_toolbar
                
                # Hero content section
                hero_section_content
              end
            end
            
            private
            
            # Navigation toolbar using DSL ToolbarComponent
            def navigation_toolbar
              render SwiftUIRails::Component::Composed::Layout::ToolbarComponent.new(
                brand_text: brand_text,
                brand_logo: brand_logo,
                background: "white",
                shadow: true,
                border: true,
                responsive: true
              ) do |toolbar|
                # Navigation links in center
                toolbar.with_center_content do
                  nav.hidden.md_flex.items_center.space_x(8) do
                    navigation_items.each do |item|
                      link(item[:text], destination: item[:url])
                        .text_color("gray-600")
                        .hover_text_color("gray-900")
                        .font_weight("medium")
                        .transition
                    end
                  end
                end
                
                # Auth buttons on right
                if show_auth_buttons
                  toolbar.with_right_action do
                    hstack(spacing: 3) do
                      link("Log in", destination: "/?modal=login")
                        .text_color("gray-700")
                        .px(4).py(2)
                        .rounded("md")
                        .hover_bg("gray-100")
                        .transition
                        .font_weight("medium")
                      
                      link("Sign up", destination: "/?modal=register")
                        .bg("blue-600")
                        .text_color("white")
                        .px(6).py(2)
                        .rounded("md")
                        .hover_bg("blue-700")
                        .transition
                        .font_weight("medium")
                    end
                  end
                end
              end
            end
            
            # Hero content section with proper spacing from toolbar
            def hero_section_content
              main.bg("white").py(padding_y) do
                div.container.mx("auto").px(4) do
                  div.tap { |container| apply_max_width(container) }
                     .mx("auto")
                     .tap { |container| apply_text_alignment(container) } do
                    
                    # Hero content using DSL
                    hero_content
                    
                    # CTA buttons using DSL
                    cta_buttons_section
                  end
                end
              end
            end
            
            def hero_content
              vstack(spacing: 6) do
                # Main headline using DSL
                headline_element
                
                # Subheadline using DSL (if present)
                if subheadline
                  subheadline_element
                end
                
                # Description using DSL (if present)
                if description
                  description_element
                end
              end.mb(12)
            end
            
            def headline_element
              h1.text_6xl.font_bold.text_color("gray-900").leading_tight do
                if headline.include?('\\n') || headline.include?('<br>')
                  # Handle multi-line headlines
                  lines = headline.split(/\\n|<br>/)
                  lines.each_with_index do |line, index|
                    text(line.strip)
                    # Note: br is not available in DSL, so we use multiple text elements
                    # The CSS will handle line breaks via white-space: pre-line if needed
                  end
                else
                  text(headline)
                end
              end
            end
            
            def subheadline_element
              h2.text_2xl.font_medium.text_color("gray-700").leading_relaxed do
                text(subheadline)
              end
            end
            
            def description_element
              p.text_xl.text_color("gray-600").leading_relaxed do
                text(description)
              end
            end
            
            def cta_buttons_section
              hstack(spacing: 8, justify: :center) do
                # Primary CTA using DSL
                primary_cta_button
                
                # Secondary CTA using DSL (if present)
                if secondary_cta_text
                  secondary_cta_button
                end
              end
            end
            
            def primary_cta_button
              case primary_cta_action
              when :login
                render LoginCallToActionComponent.new(
                  button_text: primary_cta_text,
                  button_style: :primary,
                  button_size: :lg,
                  show_modal: show_login_modal,
                  login_url: login_url,
                  register_url: register_url,
                  close_url: close_url
                )
              when :signup, :custom
                button(primary_cta_text)
                  .bg("blue-600")
                  .text_color("white")
                  .px(8).py(4)
                  .rounded("lg")
                  .text_lg.font_semibold
                  .hover_bg("blue-700")
                  .transition_colors
                  .shadow("lg")
                  .data(
                    action: "click->navigate#to",
                    "navigate-url-value": primary_cta_url || "#"
                  )
              end
            end
            
            def secondary_cta_button
              link(secondary_cta_text, destination: secondary_cta_url)
                .text_color("gray-700")
                .text_lg.font_medium
                .hover_text_color("gray-900")
                .transition_colors
            end
            
            # Layout helper methods using DSL
            def apply_max_width(container)
              container.max_w(max_width)
            end
            
            def apply_text_alignment(container)
              case text_alignment
              when :left
                container.text_left
              when :center
                container.text_center
              when :right
                container.text_right
              end
            end
          end
        RUBY
        
        # Feature Highlights Component
        create_file "app/components/feature_highlights_component.rb", <<~RUBY
          class FeatureHighlightsComponent < ApplicationComponent
            # Business-level component for feature highlight sections
            # Uses ONLY SwiftUI Rails DSL methods - no HTML
            
            # Props for layout
            prop :columns, type: Integer, default: 3
            prop :gap, type: Integer, default: 8
            prop :section_title, type: String, default: nil
            prop :section_description, type: String, default: nil
            prop :padding_top, type: Integer, default: 16
            
            # Props for features data
            prop :features, type: Array, default: []
            # features format: [{ icon: "lightning-bolt", title: "Fast", description: "...", color: "blue" }]
            
            swift_ui do
              section.pt(padding_top) do
                div.container.mx("auto").px(4) do
                  div.max_w("6xl").mx("auto") do
                    # Optional section header using DSL
                    if section_title
                      section_header
                    end
                    
                    # Features grid using DSL
                    features_grid
                  end
                end
              end
            end
            
            private
            
            def section_header
              div.text_center.mb(12) do
                h2.text_3xl.font_bold.text_color("gray-900").mb(4) do
                  text(section_title)
                end
                
                if section_description
                  p.text_xl.text_color("gray-600").max_w("3xl").mx("auto") do
                    text(section_description)
                  end
                end
              end
            end
            
            def features_grid
              grid(columns: responsive_columns, spacing: gap) do
                features.each do |feature|
                  feature_card(feature)
                end
              end
            end
            
            def feature_card(feature)
              div.text_center do
                # Icon container using DSL
                icon_container(feature)
                
                # Title using DSL
                feature_title(feature)
                
                # Description using DSL
                feature_description(feature)
              end
            end
            
            def icon_container(feature)
              div.tap { |container| apply_icon_style(container, feature) }
                 .rounded_full.w(16).h(16)
                 .flex.items_center.justify_center
                 .mx("auto").mb(4) do
                
                icon(feature[:icon] || "star")
                  .w(8).h(8)
                  .text_color("\#{(feature[:color] || 'blue')}-600")
              end
            end
            
            def feature_title(feature)
              h3.text_xl.font_semibold.mb(2) do
                text(feature[:title] || "Feature")
              end
            end
            
            def feature_description(feature)
              p.text_color("gray-600").leading_relaxed do
                text(feature[:description] || "Feature description")
              end
            end
            
            # Helper methods using DSL
            def responsive_columns
              case columns
              when 1
                { base: 1 }
              when 2
                { base: 1, md: 2 }
              when 3
                { base: 1, md: 2, lg: 3 }
              when 4
                { base: 1, md: 2, lg: 4 }
              else
                { base: 1, md: 2, lg: 3 }
              end
            end
            
            def apply_icon_style(container, feature)
              color = feature[:color] || "blue"
              container.bg("\#{color}-100")
            end
            
            # Class method for quick feature creation
            def self.create_feature(icon:, title:, description:, color: "blue")
              {
                icon: icon,
                title: title,
                description: description,
                color: color
              }
            end
          end
        RUBY
        
        # SwiftUI Showcase Landing Component  
        create_file "app/components/swiftui_showcase_landing_component.rb", <<~RUBY
          class SwiftuiShowcaseLandingComponent < ApplicationComponent
            # Showcase landing page that demonstrates the actual gem components
            # Uses the real LoginDialogComponent and RegisterDialogComponent from the gem
            
            prop :show_login_modal, type: [TrueClass, FalseClass], default: false
            prop :show_register_modal, type: [TrueClass, FalseClass], default: false
            
            swift_ui do
              div.min_h("screen").bg("gray-50") do
                # Navigation toolbar with auth buttons
                showcase_toolbar
                
                # Main content area
                main_content_area
                
                # Render the actual gem auth components
                auth_modals
              end
            end
            
            private
            
            def showcase_toolbar
              header.bg("white").shadow("sm").border_b.border_color("gray-200") do
                div.max_w("7xl").mx("auto").px(4).py(4) do
                  div.flex.items_center.justify_between do
                    # Brand/logo
                    toolbar_brand
                    
                    # Navigation links
                    toolbar_navigation
                    
                    # Auth buttons
                    toolbar_auth_buttons
                  end
                end
              end
            end
            
            def toolbar_brand
              div.flex.items_center.space_x(3) do
                # Logo icon
                div.w(8).h(8).tw("bg-gradient-to-br from-blue-600 to-purple-600").rounded("lg").flex.items_center.justify_center do
                  text("S").font_weight("bold").text_color("white")
                end
                text("SwiftUI Rails Demo").font_size("xl").font_weight("bold").text_color("gray-900")
              end
            end
            
            def toolbar_navigation
              nav.hidden.sm("flex").items_center.space_x(8) do
                link("Features", destination: "#features")
                  .text_color("gray-600")
                  .hover_text_color("gray-900")
                  .font_weight("medium")
                  .transition
                link("Components", destination: "/swiftui/components")
                  .text_color("gray-600")
                  .hover_text_color("gray-900")
                  .font_weight("medium")
                  .transition
                link("Documentation", destination: "#docs")
                  .text_color("gray-600")
                  .hover_text_color("gray-900")
                  .font_weight("medium")
                  .transition
              end
            end
            
            def toolbar_auth_buttons
              div.flex.items_center.space_x(3) do
                link("Log in", destination: "/?modal=login")
                  .text_color("gray-700")
                  .px(4).py(2)
                  .rounded("md")
                  .hover_bg("gray-100")
                  .transition
                  .font_weight("medium")
                
                link("Sign up", destination: "/?modal=register")
                  .bg("blue-600")
                  .text_color("white")
                  .px(6).py(2)
                  .rounded("md")
                  .hover_bg("blue-700")
                  .transition
                  .font_weight("medium")
              end
            end
            
            def main_content_area
              main.flex_1 do
                # Hero section
                hero_section
                
                # Features showcase
                features_section
                
                # Component examples
                component_examples_section
              end
            end
            
            def hero_section
              section.py(20).tw("bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50") do
                div.max_w("4xl").mx("auto").px(4).text_center do
                  div.space_y(8) do
                    # Announcement banner
                    div.inline_flex.items_center.space_x(3).bg("white").rounded("full").px(4).py(2).shadow("sm") do
                      text("NEW").bg("blue-600").text_color("white").text_xs.font_weight("medium").px(3).py(1).rounded("full")
                      text("LoginDialogComponent & RegisterDialogComponent Demo").text_sm.text_color("gray-600")
                    end
                    
                    # Main headline
                    div.space_y(6) do
                      h1.text_6xl.font_weight("bold").text_color("gray-900").leading_tight do
                        text("Experience SwiftUI-like ")
                        text("authentication").text_color("blue-600")
                        text(" in Rails")
                      end
                      
                      p.text_xl.text_color("gray-600").max_w("2xl").mx("auto").leading_relaxed do
                        text("Complete authentication components built with SwiftUI Rails DSL. Self-contained, secure, and beautiful.")
                      end
                    end
                    
                    # CTA buttons that trigger the actual gem components
                    div.flex.justify_center.items_center.space_x(4).mt(8) do
                      link("Try Register Modal", destination: "/?modal=register")
                        .tw("bg-gradient-to-r from-blue-600 to-purple-600")
                        .text_color("white")
                        .px(8).py(4)
                        .rounded("xl")
                        .font_weight("semibold")
                        .shadow("lg")
                        .hover_shadow("xl")
                        .transform
                        .hover_scale("105")
                        .transition
                        .text_lg
                      
                      link("Try Login Modal", destination: "/?modal=login")
                        .bg("white")
                        .text_color("gray-700")
                        .px(8).py(4)
                        .rounded("xl")
                        .font_weight("semibold")
                        .border.border_color("gray-200")
                        .hover_bg("gray-50")
                        .transition
                        .text_lg
                    end
                  end
                end
              end
            end
            
            def features_section
              section.py(16) do
                div.max_w("6xl").mx("auto").px(4) do
                  # Section header
                  div.text_center.mb(12) do
                    h2.text_3xl.font_bold.text_color("gray-900").mb(4) do
                      text("Authentication Components Features")
                    end
                    p.text_xl.text_color("gray-600").max_w("3xl").mx("auto") do
                      text("Everything you need for modern authentication, built with SwiftUI Rails DSL")
                    end
                  end
                  
                  # Features grid
                  div.grid.grid_cols(1).md_cols(2).lg_cols(3).gap(8) do
                    auth_feature_card(
                      "🔐", 
                      "LoginDialogComponent", 
                      "Complete login modal with password strength validation and social auth integration"
                    )
                    auth_feature_card(
                      "📝", 
                      "RegisterDialogComponent", 
                      "Registration form with password confirmation, email validation, and terms acceptance"
                    )
                    auth_feature_card(
                      "⚡", 
                      "Self-Contained", 
                      "All logic and Stimulus controllers embedded in the components - no external dependencies"
                    )
                    auth_feature_card(
                      "🎨", 
                      "Beautiful UI", 
                      "Modern design with smooth animations and responsive layout using Tailwind CSS"
                    )
                    auth_feature_card(
                      "🔧", 
                      "Customizable", 
                      "Configurable through props - colors, social providers, validation rules, and more"
                    )
                    auth_feature_card(
                      "🚀", 
                      "Rails 8 Ready", 
                      "Built for Rails 8 authentication, Turbo, and modern Rails development patterns"
                    )
                  end
                end
              end
            end
            
            def auth_feature_card(emoji, title, description)
              div.bg("white").p(6).rounded("xl").shadow("sm").border.border_color("gray-100").hover_shadow("md").transition do
                div.text_center do
                  text(emoji).text_4xl.mb(4)
                  h3.text_xl.font_semibold.text_color("gray-900").mb(2) do
                    text(title)
                  end
                  p.text_color("gray-600").leading_relaxed do
                    text(description)
                  end
                end
              end
            end
            
            def component_examples_section
              section.py(16).bg("white") do
                div.max_w("4xl").mx("auto").px(4).text_center do
                  h2.text_3xl.font_bold.text_color("gray-900").mb(8) do
                    text("Live Component Demo")
                  end
                  
                  p.text_xl.text_color("gray-600").mb(8) do
                    text("Click the buttons below to see the actual gem components in action")
                  end
                  
                  div.grid.grid_cols(1).md_cols(2).gap(8) do
                    # Login demo card
                    demo_card(
                      "Login Modal Demo",
                      "See the LoginDialogComponent with password validation, remember me, and social login options",
                      "Open Login Modal",
                      "/?modal=login",
                      "blue"
                    )
                    
                    # Register demo card  
                    demo_card(
                      "Register Modal Demo",
                      "Try the RegisterDialogComponent with password confirmation, email validation, and terms acceptance",
                      "Open Register Modal", 
                      "/?modal=register",
                      "green"
                    )
                  end
                end
              end
            end
            
            def demo_card(title, description, button_text, button_url, color)
              div.bg("gray-50").p(8).rounded("xl").border.border_color("gray-200") do
                h3.text_xl.font_semibold.text_color("gray-900").mb(4) do
                  text(title)
                end
                
                p.text_color("gray-600").mb(6) do
                  text(description)
                end
                
                link(button_text, destination: button_url)
                  .bg("\#{color}-600")
                  .text_color("white")
                  .px(6).py(3)
                  .rounded("lg")
                  .font_weight("semibold")
                  .hover_bg("\#{color}-700")
                  .transition
                  .shadow("md")
              end
            end
            
            def auth_modals
              # Render the actual gem LoginDialogComponent
              render SwiftUIRails::Component::Composed::Auth::LoginDialogComponent.new(
                open: show_login_modal,
                login_url: "/session",
                register_url: "/?modal=register", 
                close_url: "/",
                show_social: true
              )
              
              # Render the actual gem RegisterDialogComponent
              render SwiftUIRails::Component::Composed::Auth::RegisterDialogComponent.new(
                open: show_register_modal,
                register_url: "/register",
                login_url: "/?modal=login",
                close_url: "/", 
                show_social: true,
                require_terms: true
              )
            end
          end
        RUBY
        
        # Components Showcase Component
        create_file "app/components/components_showcase_component.rb", <<~RUBY
          class ComponentsShowcaseComponent < ApplicationComponent
            # Business-level component showcase page
            # Uses ONLY SwiftUI Rails DSL methods - no HTML
            
            swift_ui do
              div.min_h("screen").bg("gray-50") do
                div.container.mx("auto").px(4).py(8) do
                  div.max_w("4xl").mx("auto") do
                    # Page header using DSL
                    page_header
                    
                    # Component examples using DSL
                    component_examples
                    
                    # Back navigation using DSL
                    back_navigation
                  end
                end
              end
            end
            
            private
            
            def page_header
              h1.text_3xl.font_bold.mb(8).text_color("gray-800") do
                text("SwiftUI Rails Components")
              end
            end
            
            def component_examples
              vstack(spacing: 8) do
                # Available components showcase
                showcase_card
                
                # Login component demo
                login_component_demo
                
                # Hero component demo
                hero_component_demo
                
                # Feature highlights demo
                feature_highlights_demo
              end
            end
            
            def showcase_card
              div.bg("white").rounded("lg").shadow("lg").p(6) do
                h2.text_xl.font_semibold.mb(4) do
                  text("Available Components")
                end
                
                p.text_color("gray-600").mb(4) do
                  text("This page showcases all available gem components using pure SwiftUI Rails DSL.")
                end
                
                vstack(spacing: 2) do
                  component_item("ProductivityLandingComponent", "Complete landing page with hero and features")
                  component_item("HeroSectionComponent", "Customizable hero sections with CTAs")
                  component_item("FeatureHighlightsComponent", "Feature grids with icons and descriptions")
                  component_item("LoginCallToActionComponent", "Login buttons with modal integration")
                end
              end
            end
            
            def component_item(name, description)
              div.border_l(4).border_color("blue-500").pl(4).mb(3) do
                h3.font_semibold.text_color("blue-600") do
                  text(name)
                end
                p.text_sm.text_color("gray-600") do
                  text(description)
                end
              end
            end
            
            def login_component_demo
              div.bg("white").rounded("lg").shadow("lg").p(6) do
                h2.text_xl.font_semibold.mb(4) do
                  text("Login Component Demo")
                end
                
                p.text_color("gray-600").mb(4) do
                  text("Business-level login CTA with modal integration:")
                end
                
                # Demo login component
                render LoginCallToActionComponent.new(
                  button_text: "Try Login Demo",
                  button_style: :primary,
                  button_size: :md
                )
              end
            end
            
            def hero_component_demo
              div.bg("white").rounded("lg").shadow("lg").p(6) do
                h2.text_xl.font_semibold.mb(4) do
                  text("Hero Component Demo")
                end
                
                p.text_color("gray-600").mb(4) do
                  text("Customizable hero section with DSL:")
                end
                
                # Mini hero demo
                render HeroSectionComponent.new(
                  headline: "DSL Hero Demo",
                  description: "This hero section was created using pure SwiftUI Rails DSL.",
                  primary_cta_text: "View Source",
                  primary_cta_action: :custom,
                  primary_cta_url: "#",
                  padding_y: 8
                )
              end
            end
            
            def feature_highlights_demo
              div.bg("white").rounded("lg").shadow("lg").p(6) do
                h2.text_xl.font_semibold.mb(4) do
                  text("Feature Highlights Demo")
                end
                
                p.text_color("gray-600").mb(4) do
                  text("Responsive feature grid with DSL:")
                end
                
                # Demo features
                render FeatureHighlightsComponent.new(
                  features: demo_features,
                  columns: 2,
                  gap: 4,
                  padding_top: 4
                )
              end
            end
            
            def back_navigation
              div.mt(8).text_center do
                link("← Back to Showcase", destination: "/swiftui")
                  .bg("blue-600")
                  .text_color("white")
                  .px(6).py(3)
                  .rounded("lg")
                  .hover_bg("blue-700")
                  .transition_colors
              end
            end
            
            def demo_features
              [
                FeatureHighlightsComponent.create_feature(
                  icon: "code",
                  title: "Pure DSL",
                  description: "No HTML mixed in - all SwiftUI Rails DSL",
                  color: "green"
                ),
                FeatureHighlightsComponent.create_feature(
                  icon: "zap",
                  title: "High Performance",
                  description: "ViewComponent 2.0 optimized for speed",
                  color: "yellow"
                )
              ]
            end
          end
        RUBY
      end

      def create_stimulus_controllers
        say "Creating Stimulus controllers for DSL components...", :green
        
        create_file "app/javascript/controllers/login_cta_controller.js", <<~JS
          import { Controller } from "@hotwired/stimulus"

          export default class extends Controller {
            static values = { 
              modalUrl: String,
              returnUrl: String
            }

            showLogin() {
              // Navigate to show the login modal
              // Uses Turbo for smooth navigation
              window.location.href = this.modalUrlValue
            }
            
            // Optional: Handle successful login redirect
            handleLoginSuccess() {
              if (this.returnUrlValue) {
                window.location.href = this.returnUrlValue
              } else {
                // Default behavior - maybe redirect to dashboard
                window.location.href = "/dashboard"
              }
            }
          }
        JS
      end

      def create_swiftui_showcase_controller
        say "Creating SwiftUI showcase controller...", :green
        create_file "app/controllers/swiftui_controller.rb", <<~RUBY
          class SwiftuiController < ApplicationController
            def index
              # SwiftUI Rails component showcase
              # This demonstrates gem components in action
              @show_login_modal = params[:modal] == 'login'
              @show_register_modal = params[:modal] == 'register'
            end
            
            def components
              # Individual component demos
            end
            
            def login_demo
              # Login component demonstration
              @show_login_modal = true
            end
            
            def register_demo
              # Register component demonstration  
              @show_register_modal = true
            end
          end
        RUBY
      end

      def create_swiftui_showcase_views
        say "Creating SwiftUI showcase views...", :green
        
        # Main showcase index - uses the new auth demo component
        create_file "app/views/swiftui/index.html.erb", <<~ERB
          <%= render SwiftuiShowcaseLandingComponent.new(
            show_login_modal: @show_login_modal,
            show_register_modal: @show_register_modal
          ) %>
        ERB
        
        # Components showcase page - now uses DSL component
        create_file "app/views/swiftui/components.html.erb", <<~ERB
          <%= render ComponentsShowcaseComponent.new %>
        ERB
      end

      def add_swiftui_routes
        say "Adding SwiftUI showcase routes...", :green
        route <<~RUBY
          # SwiftUI Rails showcase routes
          get '/swiftui', to: 'swiftui#index', as: 'swiftui_index'
          get '/swiftui/components', to: 'swiftui#components', as: 'swiftui_components'
          get '/swiftui/login_demo', to: 'swiftui#login_demo', as: 'swiftui_login_demo'
          
          # Set SwiftUI showcase as root for demo
          root "swiftui#index"
        RUBY
      end

      def show_completion_message
        say "\n🎉 SwiftUI Rails installation complete!", :green
        say "\nNext steps:", :blue
        say "1. Run 'bin/dev' to start the development server with Tailwind watching"
        say "2. Visit http://localhost:3000 to see the authentication components showcase"
        say "3. Click 'Log in' or 'Sign up' in the toolbar to see the actual gem components!"
        say "4. Visit http://localhost:3000/swiftui/components to see all DSL components"
        say "5. All components use PURE SwiftUI Rails DSL - no HTML mixed in!"
        say "\n🔐 Authentication Components Showcase:", :green
        say "• SwiftuiShowcaseLandingComponent - Demo page with real auth modals"
        say "• LoginDialogComponent - Complete login modal (from gem)"
        say "• RegisterDialogComponent - Complete register modal (from gem)"
        say "• Toolbar with working login/register buttons"
        say "• Modal switching between login and register flows"
        say "\n✨ Additional Business Components:", :green
        say "• HeroSectionComponent - Customizable hero sections"
        say "• FeatureHighlightsComponent - Feature grids with icons"
        say "• LoginCallToActionComponent - Login buttons with modal integration"
        say "• ComponentsShowcaseComponent - Component demonstration page"
        say "\n🚀 SwiftUI Rails DSL Features Demonstrated:", :blue
        say "• Component-as-DSL-Context architecture"
        say "• Natural composition with helper methods"
        say "• Chainable modifiers for styling"
        say "• Self-contained components with embedded Stimulus"
        say "• Modal management and state handling"
        say "• Business-level abstractions"
        say "• Zero HTML in component code"
        say "\n🎯 Try the Auth Components:", :yellow
        say "• Click 'Log in' button → See LoginDialogComponent"
        say "• Click 'Sign up' button → See RegisterDialogComponent"
        say "• Switch between them using modal links"
        say "• All validation and interactions work out of the box!"
        say "\nFor more information, visit: https://github.com/your-repo/swift-ui-rails"
      end

      private

      def gem_root
        File.expand_path("../../../..", __FILE__)
      end
    end
  end
end