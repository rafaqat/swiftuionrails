# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Component
    # ViewComponent 2.0 slots support with SwiftUI-like syntax
    module Slots
      extend ActiveSupport::Concern

      included do
        # Track defined slots for documentation
        class_attribute :defined_slots, default: {}
      end

      class_methods do
        ##
        # Defines a slot for the component, supporting both single and multiple slot configurations.
        # Stores slot metadata for documentation and internal use, sets up rendering helpers, and provides a DSL-friendly setter for slot assignment.
        # @param [Symbol] name - The name of the slot to define.
        # @param [Class, Array<Class>, nil] types - Optional type(s) for slot content validation.
        # @param [Boolean] many - Whether the slot accepts multiple entries (`true` for multiple, `false` for single).
        # @yield [block] Optional default content block for the slot.
        # @return [void]
        def slot(name, types: nil, many: false, &default_block)
          # Store slot metadata
          defined_slots[name] = {
            types: types,
            many: many,
            default: default_block
          }

          if many
            # Multiple slots (renders_many)
            renders_many name, types

            # Add helper to render all slots
            define_method "render_#{name}" do |**options|
              slots = send(name)
              return nil if slots.empty?

              wrapper_tag = options.delete(:wrapper) || :div
              wrapper_class = options.delete(:class) || 'space-y-4'

              content_tag(wrapper_tag, class: wrapper_class) do
                safe_join(slots.map(&:to_s))
              end
            end
          else
            # Single slot (renders_one)
            renders_one name, types

            # Add helper to render slot with fallback
            define_method "render_#{name}" do |&fallback|
              slot_content = send(name)

              if slot_content
                slot_content
              elsif fallback
                capture(&fallback)
              elsif defined_slots[name][:default]
                instance_eval(&defined_slots[name][:default])
              end
            end
          end

          # Add DSL-friendly slot setter
          define_method "with_#{name}" do |*args, **kwargs, &block|
            if many
            end
            send("with_#{name}_slot", *args, **kwargs, &block)
            self # Enable chaining
          end
        end

        ##
        # Defines a single header slot with default content styled as a semibold, gray-900 header.
        # The default content is "Header" if no custom slot is provided.
        def header_slot
          slot :header do
            # Default header implementation
            text('Header')
              .font_weight('semibold')
              .text_color('gray-900')
          end
        end

        ##
        # Defines a single footer slot with a default styled "Footer" text.
        # The default content uses small text size and gray-600 color styling.
        def footer_slot
          slot :footer do
            # Default footer implementation
            text('Footer')
              .text_size('sm')
              .text_color('gray-600')
          end
        end

        ##
        # Defines a single `content` slot with default content styled as gray text.
        # The default displays the text "Content goes here" with a gray-700 color if no content is provided.
        def content_slot
          slot :content do
            # Default content implementation
            text('Content goes here')
              .text_color('gray-700')
          end
        end

        ##
        # Defines a multiple slot named `actions`, allowing the component to accept and render multiple action slots.
        def actions_slot
          slot :actions, many: true
        end

        ##
        # Defines a multiple slot named `items`, allowing the component to accept and render multiple item slots.
        def items_slot
          slot :items, many: true
        end
      end

      ##
      # Returns true if the slot with the given name exists and contains content.
      # Returns false if the slot is absent, empty, or an error occurs when accessing it.
      # @param [Symbol, String] name - The name of the slot to check.
      # @return [Boolean] Whether the slot is present and non-empty.
      def has_slot?(name)
        slot_content = begin
          send(name)
        rescue StandardError
          nil
        end
        slot_content.present?
      end

      ##
      # Returns the content of a slot if present, otherwise yields the value of a property with the same or given name.
      # @param [Symbol, String] slot_name - The name of the slot to check.
      # @param [Symbol, String, nil] prop_name - The name of the property to use if the slot is not present. Defaults to `slot_name`.
      # @return [Object, nil] The slot content, the result of the block with the property value, or nil if neither is present.
      def slot_or_prop(slot_name, prop_name = nil)
        prop_name ||= slot_name

        if has_slot?(slot_name)
          send(slot_name)
        elsif respond_to?(prop_name) && send(prop_name).present?
          yield(send(prop_name)) if block_given?
        end
      end

      ##
      # Renders the specified slot wrapped in an HTML tag if the slot exists.
      # @param [Symbol, String] name - The name of the slot to render.
      # @param [Symbol, String] wrapper - The HTML tag to use as the wrapper (default: :div).
      # @param [Hash] wrapper_options - Additional HTML attributes for the wrapper tag.
      # @return [String, nil] The wrapped slot content, or nil if the slot does not exist.
      def wrapped_slot(name, wrapper: :div, **wrapper_options)
        return unless has_slot?(name)

        content_tag(wrapper, **wrapper_options) do
          send(name)
        end
      end

      ##
      # Returns the content of the specified slot if the condition is truthy and the slot exists.
      # @param condition [Object] The condition to evaluate for rendering the slot.
      # @param name [Symbol, String] The name of the slot to render.
      # @return [Object, nil] The slot content if the condition is met and the slot exists, otherwise nil.
      def slot_if(condition, name)
        return unless condition && has_slot?(name)

        send(name)
      end
    end
  end
end
# Copyright 2025
