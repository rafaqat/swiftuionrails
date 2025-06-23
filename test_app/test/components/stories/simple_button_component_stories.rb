# frozen_string_literal: true

class SimpleButtonComponentStories < ViewComponent::Storybook::Stories
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Context
  
  # Basic properties
  control :title, as: :text, default: "Click Me"
  control :variant, as: :select, options: [:primary, :secondary, :danger, :success, :warning], default: :primary
  control :size, as: :select, options: [:sm, :md, :lg, :xl], default: :md
  control :disabled, as: :boolean, default: false
  
  # SwiftUI-style appearance properties  
  control :background_color, as: :select, options: [
    "", # Default/empty
    "white", "black", 
    "gray-50", "gray-100", "gray-200", "gray-300", "gray-400", "gray-500", "gray-600", "gray-700", "gray-800", "gray-900",
    "red-50", "red-100", "red-200", "red-300", "red-400", "red-500", "red-600", "red-700", "red-800", "red-900",
    "orange-50", "orange-100", "orange-200", "orange-300", "orange-400", "orange-500", "orange-600", "orange-700", "orange-800", "orange-900",
    "yellow-50", "yellow-100", "yellow-200", "yellow-300", "yellow-400", "yellow-500", "yellow-600", "yellow-700", "yellow-800", "yellow-900",
    "green-50", "green-100", "green-200", "green-300", "green-400", "green-500", "green-600", "green-700", "green-800", "green-900",
    "blue-50", "blue-100", "blue-200", "blue-300", "blue-400", "blue-500", "blue-600", "blue-700", "blue-800", "blue-900",
    "indigo-50", "indigo-100", "indigo-200", "indigo-300", "indigo-400", "indigo-500", "indigo-600", "indigo-700", "indigo-800", "indigo-900",
    "purple-50", "purple-100", "purple-200", "purple-300", "purple-400", "purple-500", "purple-600", "purple-700", "purple-800", "purple-900",
    "pink-50", "pink-100", "pink-200", "pink-300", "pink-400", "pink-500", "pink-600", "pink-700", "pink-800", "pink-900"
  ], default: ""
  control :text_color, as: :select, options: [
    "", # Default/empty
    "white", "black", 
    "gray-50", "gray-100", "gray-200", "gray-300", "gray-400", "gray-500", "gray-600", "gray-700", "gray-800", "gray-900",
    "red-50", "red-100", "red-200", "red-300", "red-400", "red-500", "red-600", "red-700", "red-800", "red-900",
    "orange-50", "orange-100", "orange-200", "orange-300", "orange-400", "orange-500", "orange-600", "orange-700", "orange-800", "orange-900",
    "yellow-50", "yellow-100", "yellow-200", "yellow-300", "yellow-400", "yellow-500", "yellow-600", "yellow-700", "yellow-800", "yellow-900",
    "green-50", "green-100", "green-200", "green-300", "green-400", "green-500", "green-600", "green-700", "green-800", "green-900",
    "blue-50", "blue-100", "blue-200", "blue-300", "blue-400", "blue-500", "blue-600", "blue-700", "blue-800", "blue-900",
    "indigo-50", "indigo-100", "indigo-200", "indigo-300", "indigo-400", "indigo-500", "indigo-600", "indigo-700", "indigo-800", "indigo-900",
    "purple-50", "purple-100", "purple-200", "purple-300", "purple-400", "purple-500", "purple-600", "purple-700", "purple-800", "purple-900",
    "pink-50", "pink-100", "pink-200", "pink-300", "pink-400", "pink-500", "pink-600", "pink-700", "pink-800", "pink-900"
  ], default: ""
  control :corner_radius, as: :select, options: ["none", "sm", "md", "lg", "xl", "full"], default: "md"
  control :padding_x, as: :select, options: ["", "1", "2", "3", "4", "5", "6", "8"], default: ""
  control :padding_y, as: :select, options: ["", "1", "2", "3", "4", "5", "6", "8"], default: ""
  control :font_weight, as: :select, options: ["light", "normal", "medium", "semibold", "bold"], default: "medium"
  control :font_size, as: :select, options: ["", "xs", "sm", "base", "lg", "xl"], default: ""
  
  def default(
    title: "Click Me", 
    variant: :primary, 
    size: :md, 
    disabled: false,
    background_color: "",
    text_color: "",
    corner_radius: "md",
    padding_x: "",
    padding_y: "",
    font_weight: "medium",
    font_size: ""
  )
    props = {
      title: title,
      variant: variant,
      size: size,
      disabled: disabled,
      corner_radius: corner_radius,
      font_weight: font_weight
    }
    
    # Only include non-empty string properties
    props[:background_color] = background_color if background_color.present?
    props[:text_color] = text_color if text_color.present?
    props[:padding_x] = padding_x if padding_x.present?
    props[:padding_y] = padding_y if padding_y.present?
    props[:font_size] = font_size if font_size.present?
    
    render SimpleButtonComponent.new(**props)
  end
  
  def all_variants
    content_tag(:div, class: "space-y-4") do
      [:primary, :secondary, :danger, :success, :warning].map do |variant|
        content_tag(:div, class: "flex items-center space-x-4") do
          safe_join([
            render(SimpleButtonComponent.new(title: variant.to_s.capitalize, variant: variant)),
            content_tag(:span, variant.to_s, class: "text-sm text-gray-600")
          ])
        end
      end.join.html_safe
    end
  end
  
  def all_sizes
    content_tag(:div, class: "space-y-4") do
      [:sm, :md, :lg, :xl].map do |size|
        content_tag(:div, class: "flex items-center space-x-4") do
          safe_join([
            render(SimpleButtonComponent.new(title: "Button", variant: :primary, size: size)),
            content_tag(:span, size.to_s, class: "text-sm text-gray-600")
          ])
        end
      end.join.html_safe
    end
  end
  
  def swiftui_style_demo
    content_tag(:div, class: "space-y-6") do
      demos = [
        { title: "Custom Colors", background_color: "#ff6b6b", text_color: "#ffffff", corner_radius: "lg" },
        { title: "Pill Button", corner_radius: "full", variant: :success },
        { title: "Large Padding", padding_x: "8", padding_y: "4", font_size: "lg" },
        { title: "Sharp Corners", corner_radius: "none", variant: :warning },
        { title: "Bold Text", font_weight: "bold", variant: :secondary }
      ]
      
      demos.map do |demo|
        content_tag(:div, class: "flex items-center space-x-4") do
          safe_join([
            render(SimpleButtonComponent.new(**demo)),
            content_tag(:code, demo.inspect, class: "text-xs text-gray-600 bg-gray-100 px-2 py-1 rounded")
          ])
        end
      end.join.html_safe
    end
  end
  
  def chainable_dsl_demo
    include SwiftUIRails::DSL
    
    content_tag(:div, class: "space-y-8") do
      demos = [
        {
          title: "Primary Button",
          code: 'button("Primary").button_style(:primary).animation.focus_ring',
          component: button("Primary").button_style(:primary).animation.focus_ring
        },
        {
          title: "Custom Styled", 
          code: 'button("Custom").background("#ff6b6b").foreground_color("#ffffff").corner_radius("lg").font_bold',
          component: button("Custom").background("#ff6b6b").foreground_color("#ffffff").corner_radius("lg").font_bold
        },
        {
          title: "Pill Button",
          code: 'button("Pill").button_style(:success).corner_radius("full").button_size(:lg)',
          component: button("Pill").button_style(:success).corner_radius("full").button_size(:lg)
        },
        {
          title: "Large Padded",
          code: 'button("Large").padding_horizontal(8).padding_vertical(4).font_size("lg").button_style(:warning)',
          component: button("Large").padding_horizontal(8).padding_vertical(4).font_size("lg").button_style(:warning)
        }
      ]
      
      demos.map do |demo|
        content_tag(:div, class: "bg-gray-50 p-6 rounded-lg border") do
          safe_join([
            content_tag(:h4, demo[:title], class: "text-sm font-semibold text-gray-900 mb-3"),
            content_tag(:div, class: "flex items-center justify-between") do
              safe_join([
                content_tag(:div, class: "flex-1") do
                  demo[:component]
                end,
                content_tag(:div, class: "flex-1 ml-6") do
                  content_tag(:pre, demo[:code], class: "text-xs text-gray-700 bg-white p-3 rounded border overflow-x-auto")
                end
              ])
            end
          ])
        end
      end.join.html_safe
    end
  end
end