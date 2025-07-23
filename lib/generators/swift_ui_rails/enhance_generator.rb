# frozen_string_literal: true

require 'rails/generators'

module SwiftUiRails
  module Generators
    class EnhanceGenerator < Rails::Generators::Base
      desc "Enhance existing Rails 8 app with SwiftUI Rails - minimal changes"
      source_root File.expand_path("templates", __dir__)
      
      class_option :skip_npm, type: :boolean, default: false, desc: "Skip npm install step"
      class_option :skip_build, type: :boolean, default: false, desc: "Skip initial Tailwind build"

      def enhance_application_layout
        layout_file = "app/views/layouts/application.html.erb"
        
        if File.exist?(layout_file)
          say "Enhancing application layout with ToolbarComponent...", :green
          
          content = File.read(layout_file)
          
          # Update stylesheet to use Tailwind if not already done
          unless content.include?('stylesheet_link_tag "tailwind"')
            if content.include?('stylesheet_link_tag :app')
              content.gsub!(/<%=\s*stylesheet_link_tag\s+:app[^%]*%>/, 
                           '<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>')
              say "Updated stylesheet to use Tailwind", :green
            end
          end
          
          # Update title
          content.gsub!(/<title>.*?<\/title>/m, '<title>My Rails App</title>')
          
          # Remove the existing main container and replace body content with ToolbarComponent
          if content.include?('<main class="container mx-auto mt-28 px-5 flex">')
            # Replace the entire body content including the main container
            content.gsub!(
              /<body>.*?<\/body>/m,
              <<~BODY.strip
                <body>
                    <%= render SwiftUIRails::Component::Composed::Layout::ToolbarComponent.new(
                      brand_text: "Data Company",
                      brand_url: "/",
                      show_search: false,
                      show_notifications: false,
                      show_user_menu: true,
                      height: "16",
                      background: "white",
                      shadow: false,
                      center_content_block: proc do
                        nav do
                          link("Product", destination: "#").class("text-gray-700 hover:text-gray-900 font-medium px-3 py-2")
                          link("Features", destination: "#").class("text-gray-700 hover:text-gray-900 font-medium px-3 py-2")
                          link("Marketplace", destination: "#").class("text-gray-700 hover:text-gray-900 font-medium px-3 py-2")
                          link("Company", destination: "#").class("text-gray-700 hover:text-gray-900 font-medium px-3 py-2")
                        end.class("flex items-center space-x-8")
                      end,
                      right_actions_block: proc do
                        button("Log in →")
                          .data(
                            controller: "login-dialog-trigger",
                            action: "click->login-dialog-trigger#open"
                          )
                          .class("text-gray-700 hover:text-gray-900 font-medium bg-transparent border-none cursor-pointer")
                      end
                    ) %>
                    
                    <!-- Login Dialog Component -->
                    <%= render SwiftUIRails::Component::Composed::Auth::LoginDialogComponent.new(
                      open: false,
                      login_url: "/login",
                      register_url: "/register",
                      close_url: "/",
                      show_social: false
                    ) %>
                    
                    <%= yield %>
                  </body>
              BODY
            )
          else
            # For any other body structure, replace it
            content.gsub!(
              /<body>.*?<\/body>/m,
              <<~BODY.strip
                <body>
                    <%= render SwiftUIRails::Component::Composed::Layout::ToolbarComponent.new(
                      brand_text: "Data Company",
                      brand_url: "/",
                      show_search: false,
                      show_notifications: false,
                      show_user_menu: true,
                      height: "16",
                      background: "white",
                      shadow: false,
                      center_content_block: proc do
                        nav do
                          link("Product", destination: "#").class("text-gray-700 hover:text-gray-900 font-medium px-3 py-2")
                          link("Features", destination: "#").class("text-gray-700 hover:text-gray-900 font-medium px-3 py-2")
                          link("Marketplace", destination: "#").class("text-gray-700 hover:text-gray-900 font-medium px-3 py-2")
                          link("Company", destination: "#").class("text-gray-700 hover:text-gray-900 font-medium px-3 py-2")
                        end.class("flex items-center space-x-8")
                      end,
                      right_actions_block: proc do
                        button("Log in →")
                          .data(
                            controller: "login-dialog-trigger",
                            action: "click->login-dialog-trigger#open"
                          )
                          .class("text-gray-700 hover:text-gray-900 font-medium bg-transparent border-none cursor-pointer")
                      end
                    ) %>
                    
                    <!-- Login Dialog Component -->
                    <%= render SwiftUIRails::Component::Composed::Auth::LoginDialogComponent.new(
                      open: false,
                      login_url: "/login",
                      register_url: "/register",
                      close_url: "/",
                      show_social: false
                    ) %>
                    
                    <%= yield %>
                  </body>
              BODY
            )
          end
          
          File.write(layout_file, content)
        else
          say "Application layout not found - creating with ToolbarComponent...", :yellow
          create_layout_with_toolbar
        end
      end

      def setup_minimal_tailwind
        say "Setting up minimal Tailwind CSS...", :green
        
        # Create tailwind config
        unless File.exist?("config/tailwind.config.js")
          create_file "config/tailwind.config.js", <<~JS
            /** @type {import('tailwindcss').Config} */
            module.exports = {
              content: [
                './app/views/**/*.html.erb',
                './app/helpers/**/*.rb',
                './app/assets/stylesheets/**/*.css',
                './app/javascript/**/*.js',
                './app/components/**/*.rb'
              ],
              theme: {
                extend: {},
              },
              plugins: [],
            }
          JS
        end

        # Create Tailwind input file if needed
        unless File.exist?("app/assets/stylesheets/application.tailwind.css")
          empty_directory "app/assets/stylesheets"
          create_file "app/assets/stylesheets/application.tailwind.css", <<~CSS
            @tailwind base;
            @tailwind components;
            @tailwind utilities;
          CSS
        end

        # Create builds directory
        empty_directory "app/assets/builds"
      end

      def enhance_package_json
        unless File.exist?("package.json")
          say "Creating minimal package.json...", :green
          create_file "package.json", <<~JSON
            {
              "name": "#{File.basename(Rails.root)}",
              "private": true,
              "scripts": {
                "build": "tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/tailwind.css --build",
                "build:dev": "tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/tailwind.css --watch"
              },
              "devDependencies": {
                "tailwindcss": "^3.4.0"
              }
            }
          JSON
        end
      end

      def install_dependencies
        if !options[:skip_npm]
          say "Installing Tailwind CSS...", :green
          run "npm install"
        end
      end

      def build_initial_css
        if !options[:skip_build]
          say "Building Tailwind CSS...", :green
          run "npx tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/tailwind.css --build"
        end
      end

      def create_simple_initializer
        say "Creating SwiftUI Rails initializer...", :green
        create_file "config/initializers/swift_ui_rails.rb", <<~RUBY
          # SwiftUI Rails configuration

          # Disable debug logging for cleaner output
          Rails.logger.level = :info if Rails.env.development?

          # Load all gem composed components
          begin
            gem_root = Gem.loaded_specs['swift_ui_rails'].full_gem_path
            Dir[File.join(gem_root, 'lib/swift_ui_rails/components/**/*.rb')].each do |component_file|
              require component_file
            end
          rescue => e
            Rails.logger.warn "Could not load SwiftUI Rails components: \#{e.message}"
          end

          # Uncomment and configure as needed:
          # SwiftUIRails.configure do |config|
          #   config.development_mode = Rails.env.development?
          # end
        RUBY
      end

      def create_application_component
        say "Creating ApplicationComponent base class...", :green
        create_file "app/components/application_component.rb", <<~RUBY
          # frozen_string_literal: true

          class ApplicationComponent < SwiftUIRails::Component::Base
            # Include any application-wide component functionality here
          end
        RUBY
      end

      def enhance_home_controller
        # Check if we have a home controller already
        if File.exist?("app/controllers/home_controller.rb")
          say "Home controller already exists, skipping...", :yellow
          return
        end

        # Check if there's an active root route
        routes_content = File.read("config/routes.rb") if File.exist?("config/routes.rb")
        has_active_root = routes_content&.match(/^\s*root\s/)
        
        if has_active_root && !routes_content.include?('root "home#index"')
          say "Active root route exists but not pointing to home#index, skipping controller creation...", :yellow
          return
        end

        say "Creating simple home controller...", :green
        create_file "app/controllers/home_controller.rb", <<~RUBY
          class HomeController < ApplicationController
            def index
              # Simple home page with hero section
            end
          end
        RUBY
      end

      def create_simple_hero_view
        # Check if view already exists
        if File.exist?("app/views/home/index.html.erb")
          say "Home view already exists, skipping...", :yellow
          return
        end

        # Only create if we need it
        routes_content = File.read("config/routes.rb") if File.exist?("config/routes.rb")
        has_active_root = routes_content&.match(/^\s*root\s/)
        
        if has_active_root && !routes_content.include?('root "home#index"')
          say "Active root route exists but not pointing to home#index, skipping view creation...", :yellow
          return
        end

        say "Creating hero view using HeroLandingComponent...", :green
        empty_directory "app/views/home"
        create_file "app/views/home/index.html.erb", <<~ERB
          <%= render SwiftUIRails::Component::Composed::Layout::HeroLandingComponent.new(
            brand_name: "Data Company",
            headline: "Data to enrich your",
            headline_accent: "online business",
            description: "Anim qute id magna aliqua ad ad non deserunt sunt. Qui irure qui lorem cupidatat commodo. Elit sunt amet fugiat veniam occaecat.",
            announcement: "Announcing our next round of funding.",
            announcement_link_text: "Read more →",
            announcement_link_url: "#"
          ) %>
        ERB
      end

      def add_simple_route
        routes_content = File.read("config/routes.rb") if File.exist?("config/routes.rb")
        
        # Check for active root route (not commented out)
        has_active_root = routes_content&.match(/^\s*root\s/)
        
        unless has_active_root
          say "Adding root route...", :green
          route 'root "home#index"'
        else
          say "Active root route already exists, skipping...", :yellow
        end
      end

      def show_simple_completion_message
        say "\n✅ Rails app enhanced with SwiftUI Rails!", :green
        say "\n🎯 What was added:", :blue
        say "• Tailwind CSS integration"
        say "• SwiftUI Rails component base classes"
        say "• Simple hero home page"
        say "• Production-ready styling"
        say "\n🚀 Next steps:", :green
        say "1. Run 'bin/rails server' to start your app"
        say "2. Visit http://localhost:3000 to see your enhanced app"
        say "3. Start building with SwiftUI Rails components"
        say "\n💡 Key files modified/created:", :yellow
        say "• app/views/layouts/application.html.erb (enhanced)"
        say "• app/views/home/index.html.erb (new hero page)"
        say "• config/initializers/swift_ui_rails.rb (new)"
        say "• package.json & Tailwind config (new)"
      end

      private

      def create_layout_with_toolbar
        create_file "app/views/layouts/application.html.erb", <<~ERB
          <!DOCTYPE html>
          <html>
            <head>
              <title>My Rails App</title>
              <meta name="viewport" content="width=device-width,initial-scale=1">
              <meta name="apple-mobile-web-app-capable" content="yes">
              <meta name="mobile-web-app-capable" content="yes">
              <%= csrf_meta_tags %>
              <%= csp_meta_tag %>

              <%= yield :head %>

              <link rel="icon" href="/icon.png" type="image/png">
              <link rel="icon" href="/icon.svg" type="image/svg+xml">
              <link rel="apple-touch-icon" href="/icon.png">

              <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
              <%= javascript_importmap_tags %>
            </head>

            <body>
              <%= render SwiftUIRails::Component::Composed::Layout::ToolbarComponent.new(
                brand_text: "Data Company",
                brand_url: "/",
                show_search: false,
                show_notifications: false,
                show_user_menu: true,
                height: "16",
                background: "white",
                shadow: false,
                center_content_block: proc do
                  nav(class: "flex items-center space-x-8") do
                    [
                      link("Product", destination: "#", class: "text-gray-700 hover:text-gray-900 font-medium"),
                      link("Features", destination: "#", class: "text-gray-700 hover:text-gray-900 font-medium"),
                      link("Marketplace", destination: "#", class: "text-gray-700 hover:text-gray-900 font-medium"),
                      link("Company", destination: "#", class: "text-gray-700 hover:text-gray-900 font-medium")
                    ]
                  end
                end,
                right_actions_block: proc do
                  button("Log in →")
                    .data(
                      controller: "login-dialog-trigger",
                      action: "click->login-dialog-trigger#open"
                    )
                    .class("text-gray-700 hover:text-gray-900 font-medium bg-transparent border-none cursor-pointer")
                end
              ) %>
              
              <!-- Login Dialog Component -->
              <%= render SwiftUIRails::Component::Composed::Auth::LoginDialogComponent.new(
                open: false,
                login_url: "/login",
                register_url: "/register",
                close_url: "/",
                show_social: false
              ) %>
              
              <%= yield %>
            </body>
          </html>
        ERB
      end

      def gem_root
        File.expand_path("../../../..", __FILE__)
      end
    end
  end
end