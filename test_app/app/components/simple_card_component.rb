# frozen_string_literal: true

# Copyright 2025

class SimpleCardComponent < SwiftUIRails::Component::Base
  # Disable memoization since we have slots that can change
  enable_memoization false

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
    div.tw(card_classes) do
      # Header - we need to create a method that doesn't collide with DSL's header
      if header_slot?
        # Create a div with the slot content as its content directly
        create_element(:div, header_slot, class: "pb-4 mb-4 border-b border-gray-200")
      end

      # Content (from block)
      div do
        # ViewComponent's content is available directly
        if content.present?
          text(content.to_s)
        end
      end

      # Footer - we need to create a method that doesn't collide with DSL's footer
      if footer_slot?
        # Create a div with the slot content as its content directly
        create_element(:div, footer_slot, class: "pt-4 mt-4 border-t border-gray-200")
      end
    end
  end

  # Helper methods to access slots without DSL collision
  def header_slot?
    header?
  end

  def header_slot
    header
  end

  def footer_slot?
    footer?
  end

  def footer_slot
    footer
  end

  private

  def card_classes
    base = "bg-white rounded-lg"
    variant_class = VARIANT_CLASSES[variant] || VARIANT_CLASSES[:elevated]
    padding_class = PADDING_CLASSES[padding] || PADDING_CLASSES[:md]

    [ base, variant_class, padding_class ].compact.join(" ")
  end
end
# Copyright 2025
