# frozen_string_literal: true

require 'rails/generators'

module SwiftUIRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install SwiftUI Rails with all necessary infrastructure and proper showcase"
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
          end
          
          # Don't modify body - let the showcase handle navigation
          unless content.include?('SwiftUI Rails App')
            # Just update title if needed
            if content.include?('<title>')
              content.gsub!(/<title>.*?<\/title>/m, '<title>SwiftUI Rails App</title>')
            end
          end
          
          File.write(layout_file, content)
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
        if File.exist?("package.json") && !options[:skip_npm]
          say "Installing Tailwind CSS dependencies...", :green
          run "npm install"
        elsif options[:skip_npm]
          say "Skipping npm install (--skip-npm flag used)", :yellow
        end
      end

      def build_tailwind_css
        if File.exist?("config/tailwind.config.js") && !options[:skip_build]
          say "Building initial Tailwind CSS...", :green
          run "npx tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/tailwind.css --build"
        elsif options[:skip_build]
          say "Skipping Tailwind CSS build (--skip-build flag used)", :yellow
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

      def create_showcase_using_library_only
        say "Creating showcase using ONLY existing library components...", :green
        
        # NO NEW COMPONENTS - Only use existing library and DSL elements
        create_controller_only
        create_view_using_library_only
      end

      def create_controller_only
        say "Creating controller for library showcase...", :green
        create_file "app/controllers/home_controller.rb", <<~RUBY
          class HomeController < ApplicationController
            def index
              # Showcase page using ONLY existing SwiftUI Rails library components
              # Demonstrates ToolbarComponent and pure DSL composition
              @current_user = demo_user
            end
            
            private
            
            def demo_user
              OpenStruct.new(
                name: "Demo User",
                email: "demo@swiftuirails.com"
              )
            end
          end
        RUBY
      end

      def create_view_using_library_only
        say "Creating view using ONLY existing library components...", :green
        
        create_file "app/views/home/index.html.erb", <<~ERB
          <%# 
            SwiftUI Rails Library Showcase
            Uses ONLY existing gem components - NO new components created
            Demonstrates: ToolbarComponent + pure DSL composition
          %>
          
          <%# Use our EXISTING ToolbarComponent from the gem library %>
          <%= render SwiftUIRails::Component::Composed::Layout::ToolbarComponent.new(
            brand_text: "SwiftUI Rails",
            brand_url: "/",
            show_search: true,
            show_notifications: true,
            show_user_menu: true,
            current_user: @current_user,
            height: "16",
            background: "white",
            shadow: true
          ) do |toolbar|
            <%# Add center content using DSL %>
            <% toolbar.with_center_content do %>
              <span class="font-medium text-gray-700">Library Showcase</span>
            <% end %>
          <% end %>
          
          <%# Main content using pure DSL elements - NO custom components %>
          <main class="flex-1">
            <div class="max-w-7xl mx-auto px-4 py-12">
              
              <%# Hero section using DSL elements only %>
              <div class="text-center mb-16">
                <h1 class="text-5xl font-bold text-gray-900 mb-6">
                  SwiftUI Rails Library
                </h1>
                <p class="text-xl text-gray-600 mb-8 max-w-3xl mx-auto">
                  Showcasing our stable library of reusable components
                </p>
                
                <%# Buttons using DSL styling patterns %>
                <div class="flex justify-center space-x-4">
                  <button class="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition">
                    View Components
                  </button>
                  <button class="border border-gray-300 px-6 py-3 rounded-lg hover:bg-gray-50 transition">
                    Documentation
                  </button>
                </div>
              </div>
              
              <%# Features grid using existing layout patterns %>
              <div class="mb-16">
                <h2 class="text-3xl font-bold text-center mb-12">
                  Existing Library Components
                </h2>
                
                <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
                  <%# Feature cards using DSL patterns %>
                  <div class="bg-white rounded-lg shadow-md p-6 text-center">
                    <div class="text-3xl mb-3">🧩</div>
                    <h3 class="font-semibold mb-2">ToolbarComponent</h3>
                    <p class="text-gray-600 text-sm">Master navigation component with search, notifications, and user menu</p>
                  </div>
                  
                  <div class="bg-white rounded-lg shadow-md p-6 text-center">
                    <div class="text-3xl mb-3">🔐</div>
                    <h3 class="font-semibold mb-2">LoginDialogComponent</h3>
                    <p class="text-gray-600 text-sm">Authentication UI with progressive enhancement</p>
                  </div>
                  
                  <div class="bg-white rounded-lg shadow-md p-6 text-center">
                    <div class="text-3xl mb-3">🎨</div>
                    <h3 class="font-semibold mb-2">DSL Elements</h3>
                    <p class="text-gray-600 text-sm">Rich DSL with chainable modifiers for any UI pattern</p>
                  </div>
                </div>
              </div>
              
              <%# Code example showing library usage %>
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h3 class="text-2xl font-bold mb-6">
                  Using Existing Library Components
                </h3>
                
                <div class="bg-gray-900 rounded-lg p-4">
                  <pre class="text-green-400 text-sm"><code><%# Show how to use our existing components %>
&lt;%= render SwiftUIRails::Component::Composed::Layout::ToolbarComponent.new(
  brand_text: "My App",
  show_search: true,
  current_user: @user
) %&gt;</code></pre>
                </div>
                
                <p class="mt-4 text-gray-600">
                  This demonstrates using our stable, tested library components instead of creating new ones.
                  The generator focuses on showcasing existing components, not building new ones.
                </p>
              </div>
              
            </div>
          </main>
          
          <%# Footer using standard HTML - no new components %>
          <footer class="bg-gray-900 text-white py-8 mt-16">
            <div class="max-w-7xl mx-auto px-4 text-center">
              <p class="text-gray-400">
                Built with existing SwiftUI Rails library components - no new components created
              </p>
            </div>
          </footer>
        ERB
      end

      def add_routes
        say "Adding routes...", :green
        route <<~RUBY
          # SwiftUI Rails Demo
          root "home#index"
        RUBY
      end

      def show_completion_message
        say "\n🎉 SwiftUI Rails Library Showcase Complete!", :green
        say "\n✨ What was created:", :blue
        say "• Home controller - Showcases existing library components"
        say "• Library showcase view - Uses ONLY existing components"
        say "• ToolbarComponent demo - Master navigation component"
        say "• Tailwind CSS integration - Modern styling system"
        say "\n🧩 Library Components Demonstrated:", :yellow
        say "• SwiftUIRails::Component::Composed::Layout::ToolbarComponent"
        say "• Pure DSL elements (text, button, div, etc.)"
        say "• Chainable modifiers (.bg(), .text_color(), .px(), .py())"
        say "• Component composition patterns"
        say "\n🚀 Next steps:", :green
        say "1. Run 'bin/dev' to start the development server"
        say "2. Visit http://localhost:3000 to see the library showcase"
        say "3. Notice: Uses EXISTING components, no new ones created"
        say "4. Study the view to see library component usage"
        say "\n💡 Library-First Philosophy:", :yellow
        say "• NO new components created by generator"
        say "• Showcases stable, reusable library components"
        say "• Composition over creation"
        say "• Focus on building a component LIBRARY"
        say "\n🎯 Architecture Pattern:", :blue
        say "• Use existing SwiftUIRails::Component classes"
        say "• Compose with pure DSL elements"
        say "• Build on proven, tested components"
        say "• Avoid component proliferation"
        say "\n📚 Key Files:", :green
        say "• Controller: app/controllers/home_controller.rb"
        say "• Library showcase: app/views/home/index.html.erb"
        say "• Existing components: lib/swift_ui_rails/components/"
        say "\n🌊 This showcases our stable component LIBRARY!"
      end

      private

      def gem_root
        File.expand_path("../../../..", __FILE__)
      end
    end
  end
end