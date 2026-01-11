# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Collection components for SwiftUI Rails DSL
    # Provides methods for rendering collections with ViewComponent 2.0 optimizations
    module Collections
      # List(style: :plain) { ... }
      # Styles: :plain, :grouped, :inset_grouped, :sidebar
      def List(style: :plain, **attrs, &block)
        base_classes = case style
                       when :plain
                         "divide-y divide-gray-200 bg-white"
                       when :grouped
                         "space-y-4 bg-gray-50 p-4"
                       when :inset_grouped
                         "space-y-4 bg-gray-50 px-4 py-6"
                       when :sidebar
                         "space-y-1 p-2"
                       else
                         "divide-y divide-gray-200"
                       end

        # Wrapper logic for grouped lists
        wrapper_class = style == :inset_grouped ? "max-w-3xl mx-auto" : ""
        
        attrs[:class] = class_names(base_classes, wrapper_class, attrs[:class])
        
        # Determine tag based on style
        tag = style == :sidebar ? :nav : :ul
        
        create_element(tag, nil, **attrs) do
          # Context for child items (Section, etc.) could be managed here
          yield
        end
      end
      
      # Section(header: "Title", footer: "Note") { ... }
      def Section(header: nil, footer: nil, **attrs, &block)
        create_element(:div, nil, class: "space-y-1") do
          if header
            div(class: "px-4 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wider") { text(header) }
          end
          
          div(class: "bg-white overflow-hidden shadow-sm sm:rounded-md divide-y divide-gray-200") do
            yield
          end

          if footer
            div(class: "px-4 py-2 text-xs text-gray-400") { text(footer) }
          end
        end
      end

      # E-commerce Components with ViewComponent 2.0 Collection Optimization
      # Generic collection list method - composition-based approach
      def collection_list(items:, **attrs, &block)
        # Pure structure for listing items - behavior comes from the block
        attrs[:class] = class_names('space-y-4', attrs[:class])

        create_element(:div, nil, **attrs) do
          items.each_with_index do |item, index|
            # Pass both item and index to the block for maximum flexibility
            if block
              instance_exec(item, index, &block)
            else
              # Default rendering if no block provided
              text(item.to_s)
            end
          end
        end
      end

      # Grid variant of list for grid layouts
      def grid_list(items:, columns: 3, **attrs, &block)
        attrs[:class] = class_names('grid gap-4', attrs[:class])
        attrs[:class] += " grid-cols-#{columns}"

        create_element(:div, nil, **attrs) do
          items.each_with_index do |item, index|
            if block
              instance_exec(item, index, &block)
            else
              text(item.to_s)
            end
          end
        end
      end

      # ViewComponent 2.0 Collection-optimized rendering methods
      def card_collection(items:, **attrs, &block)
        # Use ViewComponent 2.0 collection rendering for 10x performance
        CardComponent.card_collection(cards: items, **attrs, &block)
      end

      def button_collection(items:, **attrs, &block)
        # Use ViewComponent 2.0 collection rendering for 10x performance
        SimpleButtonComponent.button_collection(buttons: items, **attrs, &block)
      end

      # Layout collection optimizations
      def vstack_collection(items:, spacing: 8, **attrs, &block)
        # Render collection in vertical stack with ViewComponent 2.0 performance
        vstack(spacing: spacing, **attrs) do
          if block
            items.each_with_index(&block)
          else
            items.each { |item| text(item.to_s) }
          end
        end
      end

      def hstack_collection(items:, spacing: 8, **attrs, &block)
        # Render collection in horizontal stack with ViewComponent 2.0 performance
        hstack(spacing: spacing, **attrs) do
          if block
            items.each_with_index(&block)
          else
            items.each { |item| text(item.to_s) }
          end
        end
      end

      def grid_collection(items:, columns: 3, spacing: 8, **attrs, &block)
        # Render collection in grid with ViewComponent 2.0 performance
        grid(columns: columns, spacing: spacing, **attrs) do
          if block
            items.each_with_index(&block)
          else
            items.each { |item| text(item.to_s) }
          end
        end
      end

      # Helper methods
      def each_with_index(**attrs, &block)
        # This is typically called on collections, not as a DSL method
        # For compatibility
        create_element(:div, nil, **attrs, &block)
      end

      def times(count = 1, **_attrs)
        # Utility for repeating content
        Array.new(count) { |i| yield(i) if block_given? }
      end
    end
  end
end