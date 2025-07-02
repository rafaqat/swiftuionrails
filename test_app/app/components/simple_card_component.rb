# frozen_string_literal: true

class SimpleCardComponent < SwiftUIRails::Component::Base
  renders_one :header
  renders_one :footer
  
  prop :variant, type: Symbol, default: :elevated
  prop :padding, type: Symbol, default: :md
  
  VARIANT_CLASSES = {
    elevated: "shadow-md",
    outlined: "border border-gray-200",
    filled: "bg-gray-50"
  }.freeze
  
  PADDING_CLASSES = {
    sm: "p-4",
    md: "p-6",
    lg: "p-8"
  }.freeze
  
  swift_ui do
    content_tag(:div, class: card_classes) do
      safe_join([
        # Header
        if header?
          content_tag(:div, class: "pb-4 mb-4 border-b border-gray-200") do
            header.to_s
          end
        end,
        
        # Content (from block)
        content_tag(:div) do
          content
        end,
        
        # Footer
        if footer?
          content_tag(:div, class: "pt-4 mt-4 border-t border-gray-200") do
            footer.to_s
          end
        end
      ].compact)
    end
  end
  
  private
  
  def card_classes
    base = "bg-white rounded-lg"
    variant_class = VARIANT_CLASSES[variant] || VARIANT_CLASSES[:elevated]
    padding_class = PADDING_CLASSES[padding] || PADDING_CLASSES[:md]
    
    [base, variant_class, padding_class].compact.join(" ")
  end
end