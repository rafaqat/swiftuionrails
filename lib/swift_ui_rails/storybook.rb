# frozen_string_literal: true

module SwiftUIRails
  module Storybook
    extend ActiveSupport::Concern

    included do
      if defined?(ViewComponent::Storybook::Stories)
        include ViewComponent::Storybook::Stories
      end
    end

    class_methods do
      # Helper method to define stories with SwiftUI DSL
      def swift_story(name, component: nil, &block)
        story(name) do
          controls do
            instance_eval(&block) if block_given?
          end
          
          component ||= self.name.gsub("Stories", "").constantize
        end
      end

      # Define common control types for SwiftUI components
      def swift_text(name, default: "", **options)
        text(name, default: default, **options)
      end

      def swift_select(name, options:, default: nil, **opts)
        select(name, options, default: default, **opts)
      end

      def swift_boolean(name, default: false, **options)
        boolean(name, default: default, **options)
      end

      def swift_number(name, default: 0, min: nil, max: nil, step: 1, **options)
        number(name, default: default, min: min, max: max, step: step, **options)
      end

      def swift_color(name, default: "#000000", **options)
        color(name, default: default, **options)
      end

      def swift_object(name, default: {}, **options)
        object(name, default: default, **options)
      end

      def swift_array(name, default: [], **options)
        array(name, default: default, **options)
      end
    end

    # Story layout helpers
    module Layouts
      def swift_story_layout(title:, description: nil, dark_mode: false, &block)
        content_tag :div, class: "swift-story-layout #{dark_mode ? 'dark' : ''}" do
          content = []
          
          if title || description
            content << content_tag(:div, class: "swift-story-header") do
              header_content = []
              header_content << content_tag(:h2, title, class: "swift-story-title") if title
              header_content << content_tag(:p, description, class: "swift-story-description") if description
              safe_join(header_content)
            end
          end
          
          content << content_tag(:div, class: "swift-story-content", &block)
          
          safe_join(content)
        end
      end

      def swift_story_grid(columns: 2, gap: 4, &block)
        content_tag :div, 
          class: "grid grid-cols-#{columns} gap-#{gap}",
          &block
      end

      def swift_story_section(title:, &block)
        content_tag :div, class: "swift-story-section" do
          content = []
          content << content_tag(:h3, title, class: "text-lg font-semibold mb-4")
          content << content_tag(:div, &block)
          safe_join(content)
        end
      end
    end

    # Preview helpers for demonstrating components
    module Previews
      def swift_preview_container(**options, &block)
        options[:class] = [
          "p-8 bg-gray-50 rounded-lg",
          options[:class]
        ].compact.join(" ")
        
        content_tag(:div, options, &block)
      end

      def swift_device_preview(device: :iphone, &block)
        device_classes = {
          iphone: "max-w-sm mx-auto bg-white rounded-3xl shadow-xl p-4",
          ipad: "max-w-4xl mx-auto bg-white rounded-2xl shadow-xl p-6",
          desktop: "w-full bg-white rounded-lg shadow-lg p-8"
        }
        
        content_tag :div, class: device_classes[device] || device_classes[:iphone] do
          content_tag :div, class: "device-screen", &block
        end
      end

      def swift_theme_preview(themes: [:light, :dark], &block)
        content_tag :div, class: "grid grid-cols-#{themes.size} gap-8" do
          themes.map do |theme|
            content_tag :div, class: "theme-preview #{theme}" do
              content = []
              content << content_tag(:h4, theme.to_s.capitalize, class: "text-sm font-medium mb-4")
              content << content_tag(:div, class: theme == :dark ? "bg-gray-900 p-6 rounded" : "bg-white p-6 rounded border", &block)
              safe_join(content)
            end
          end.join.html_safe
        end
      end
    end

    # Documentation helpers
    module Documentation
      def swift_props_table(component_class)
        props = component_class.swift_props
        
        return content_tag(:p, "No props defined", class: "text-gray-500") if props.empty?
        
        content_tag :table, class: "min-w-full divide-y divide-gray-200" do
          content = []
          
          # Header
          content << content_tag(:thead, class: "bg-gray-50") do
            content_tag :tr do
              %w[Name Type Required Default Description].map do |header|
                content_tag :th, header, 
                  class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              end.join.html_safe
            end
          end
          
          # Body
          content << content_tag(:tbody, class: "bg-white divide-y divide-gray-200") do
            props.map do |name, config|
              content_tag :tr do
                cells = []
                cells << content_tag(:td, name, class: "px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900")
                cells << content_tag(:td, config[:type]&.to_s || "Any", class: "px-6 py-4 whitespace-nowrap text-sm text-gray-500")
                cells << content_tag(:td, config[:required] ? "Yes" : "No", class: "px-6 py-4 whitespace-nowrap text-sm text-gray-500")
                cells << content_tag(:td, config[:default]&.inspect || "-", class: "px-6 py-4 whitespace-nowrap text-sm text-gray-500")
                cells << content_tag(:td, config[:description] || "-", class: "px-6 py-4 text-sm text-gray-500")
                safe_join(cells)
              end
            end.join.html_safe
          end
          
          safe_join(content)
        end
      end

      def swift_code_example(language: :ruby, &block)
        code = capture(&block).strip
        
        content_tag :div, class: "swift-code-example" do
          content = []
          content << content_tag(:div, class: "flex items-center justify-between px-4 py-2 bg-gray-800 rounded-t-lg") do
            inner = []
            inner << content_tag(:span, language.to_s.capitalize, class: "text-xs text-gray-400")
            inner << content_tag(:button, "Copy", class: "text-xs text-gray-400 hover:text-white", data: { action: "click->clipboard#copy" })
            safe_join(inner)
          end
          content << content_tag(:pre, class: "overflow-x-auto p-4 bg-gray-900 rounded-b-lg") do
            content_tag(:code, code, class: "text-sm text-gray-300 language-#{language}")
          end
          safe_join(content)
        end
      end
    end
  end
end