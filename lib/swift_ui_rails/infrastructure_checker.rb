# frozen_string_literal: true

module SwiftUIRails
  class InfrastructureChecker
    class << self
      def check_infrastructure!
        return if Rails.env.test? # Skip in test environment
        return unless Rails.root # Skip if Rails hasn't fully initialized
        
        missing_items = []
        
        missing_items << "application layout" unless layout_exists?
        missing_items << "asset configuration" unless assets_configured?
        missing_items << "CSS build file" unless css_build_exists?
        
        if missing_items.any?
          raise ConfigurationError, build_error_message(missing_items)
        end
      end

      def layout_exists?
        return false unless Rails.root
        File.exist?(Rails.root.join("app/views/layouts/application.html.erb"))
      end

      def assets_configured?
        return false unless Rails.root
        return false unless File.exist?(Rails.root.join("config/initializers/assets.rb"))
        
        assets_content = File.read(Rails.root.join("config/initializers/assets.rb"))
        assets_content.include?("app/assets/builds") ||
          Rails.application.config.assets.paths.any? { |path| path.to_s.include?("app/assets/builds") }
      end

      def css_build_exists?
        return false unless Rails.root
        File.exist?(Rails.root.join("app/assets/builds/tailwind.css"))
      end

      def check_status
        {
          layout: layout_exists?,
          assets: assets_configured?,
          css_build: css_build_exists?,
          all_good: layout_exists? && assets_configured? && css_build_exists?
        }
      end

      private

      def build_error_message(missing_items)
        <<~ERROR
          🚨 SwiftUI Rails Infrastructure Missing!
          
          The following required infrastructure is missing:
          #{missing_items.map { |item| "  ❌ #{item}" }.join("\n")}
          
          🔧 Quick Fix:
          Run: rails generate swift_ui_rails:install
          
          📋 Manual Setup (if preferred):
          #{missing_items.include?("application layout") ? "  • Create app/views/layouts/application.html.erb with CSS loading\n" : ""}#{missing_items.include?("asset configuration") ? "  • Add app/assets/builds to Rails asset paths\n" : ""}#{missing_items.include?("CSS build file") ? "  • Build Tailwind CSS to app/assets/builds/tailwind.css\n" : ""}
          📖 Documentation: https://github.com/rafaqat/swiftuionrails#installation
        ERROR
      end
    end

    class ConfigurationError < StandardError; end
  end
end