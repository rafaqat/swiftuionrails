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
        # SwiftUI-like slot definition
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

        # Define common slot patterns
        def header_slot
          slot :header do
            # Default header implementation
            text('Header')
              .font_weight('semibold')
              .text_color('gray-900')
          end
        end

        def footer_slot
          slot :footer do
            # Default footer implementation
            text('Footer')
              .text_size('sm')
              .text_color('gray-600')
          end
        end

        def content_slot
          slot :content do
            # Default content implementation
            text('Content goes here')
              .text_color('gray-700')
          end
        end

        def actions_slot
          slot :actions, many: true
        end

        def items_slot
          slot :items, many: true
        end
      end

      # Instance methods for working with slots
      def has_slot?(name)
        slot_content = begin
          send(name)
        rescue StandardError
          nil
        end
        slot_content.present?
      end

      def slot_or_prop(slot_name, prop_name = nil)
        prop_name ||= slot_name

        if has_slot?(slot_name)
          send(slot_name)
        elsif respond_to?(prop_name) && send(prop_name).present?
          yield(send(prop_name)) if block_given?
        end
      end

      # Render slot with wrapper
      def wrapped_slot(name, wrapper: :div, **wrapper_options)
        return unless has_slot?(name)

        content_tag(wrapper, **wrapper_options) do
          send(name)
        end
      end

      # Conditional slot rendering
      def slot_if(condition, name)
        return unless condition && has_slot?(name)

        send(name)
      end
    end
  end
end
# Copyright 2025
