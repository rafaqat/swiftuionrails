# frozen_string_literal: true

module SwiftUIRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_initializer
        template "initializer.rb", "config/initializers/swift_ui_rails.rb"
      end

      def create_application_component
        template "application_component.rb", "app/components/application_component.rb"
      end

      def add_javascript
        append_to_file "app/javascript/application.js" do
          <<~JS
            
            // SwiftUI Rails
            import "./controllers/swift_ui_controller"
          JS
        end

        template "swift_ui_controller.js", "app/javascript/controllers/swift_ui_controller.js"
      end

      def add_styles
        if File.exist?("app/assets/stylesheets/application.tailwind.css")
          append_to_file "app/assets/stylesheets/application.tailwind.css" do
            <<~CSS
              
              /* SwiftUI Rails Components */
              @import "swift_ui_rails";
            CSS
          end
        end

        template "swift_ui_rails.css", "app/assets/stylesheets/swift_ui_rails.css"
      end

      def create_example_component
        template "example_component.rb", "app/components/example_component.rb"
      end

      def setup_storybook
        # Create storybook directories
        empty_directory "test/components/stories"
        
        # Add storybook routes if not already present
        route_content = <<~RUBY
          if defined?(ViewComponent::Storybook::Engine)
            mount ViewComponent::Storybook::Engine, at: "/swift_ui/storybook"
          end
        RUBY
        
        route route_content
        
        # Create storybook configuration
        template "storybook_config.rb", "config/initializers/view_component_storybook.rb"
        
        # Add storybook CSS
        template "storybook.css", "app/assets/stylesheets/storybook.css"
        
        # Create example story
        template "example_component_stories.rb", "test/components/stories/example_component_stories.rb"
        template "example_component_preview.html.erb", "test/components/stories/example_component_preview.html.erb"
      end

      def display_post_install_message
        say "\n✅ SwiftUI Rails has been successfully installed!", :green
        say "\nNext steps:", :yellow
        say "  1. Run 'bundle install' to install the gem dependencies"
        say "  2. Run 'rails generate swift_ui_rails:component MyComponent' to create new components"
        say "  3. Run 'rails generate swift_ui_rails:stories MyComponent' to create component stories"
        say "  4. Visit http://localhost:3000/swift_ui/storybook to see the component storybook"
        say "  5. Visit http://localhost:3000/swift_ui_rails/demo to see examples"
        say "\nHappy coding! 🚀\n", :blue
      end
    end
  end
end