# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Container components for SwiftUI Rails DSL
    module Containers
      # Container Components - Simplified for composition
      def card(**attrs, &block)
        # Extract slot attributes
        header_slot = attrs.delete(:header)
        content_slot = attrs.delete(:content)
        actions_slot = attrs.delete(:actions)
        elevation = attrs.delete(:elevation) || 1

        # Apply elevation shadow
        shadow_class = case elevation
                       when 0 then ''
                       when 1 then 'shadow'
                       when 2 then 'shadow-md'
                       when 3 then 'shadow-lg'
                       when 4 then 'shadow-xl'
                       else 'shadow'
                       end

        # Simple card container - just structure and styling
        attrs[:class] = class_names('rounded-lg bg-white', shadow_class, attrs[:class])

        # For slots, we need to ensure they render properly
        if header_slot || content_slot || actions_slot
          # Use div for the card with header/content/actions structure
          div(**attrs) do
            # Header slot
            if header_slot
              div(class: 'p-4 border-b') do
                if header_slot.is_a?(String)
                  text(header_slot)
                elsif header_slot.respond_to?(:call)
                  instance_eval(&header_slot)
                elsif header_slot.is_a?(Element)
                  header_slot
                else
                  text(header_slot.to_s)
                end
              end
            end

            # Content slot - main area
            div(class: 'p-4') do
              if content_slot
                if content_slot.is_a?(String)
                  text(content_slot)
                elsif content_slot.respond_to?(:call)
                  instance_eval(&content_slot)
                elsif content_slot.is_a?(Element)
                  content_slot
                else
                  text(content_slot.to_s)
                end
              elsif block_given?
                yield
              end
            end

            # Actions slot
            if actions_slot
              div(class: 'p-4 border-t') do
                if actions_slot.is_a?(String)
                  text(actions_slot)
                elsif actions_slot.respond_to?(:call)
                  instance_eval(&actions_slot)
                elsif actions_slot.is_a?(Element)
                  actions_slot
                else
                  text(actions_slot.to_s)
                end
              end
            end
          end
        else
          # Standard card with block content
          create_element(:div, nil, **attrs, &block)
        end
      end

      def card_header(**attrs, &block)
        # A helper for the header area
        attrs[:class] = class_names('p-4 border-b', attrs[:class])
        create_element(:div, nil, **attrs, &block)
      end

      def card_content(**attrs, &block)
        # A helper for the main content area
        attrs[:class] = class_names('p-4', attrs[:class])
        create_element(:div, nil, **attrs, &block)
      end

      def card_footer(**attrs, &block)
        # A helper for the footer/actions area
        attrs[:class] = class_names('p-4 border-t', attrs[:class])
        create_element(:div, nil, **attrs, &block)
      end

      def card_section(**attrs, &block)
        # A helper for sections within a card
        attrs[:class] = class_names('p-4', attrs[:class])
        create_element(:div, nil, **attrs, &block)
      end

      def list(**attrs, &block)
        create_element(:ul, nil, **attrs, &block)
      end

      def list_item(**attrs, &block)
        create_element(:li, nil, **attrs, &block)
      end

      def scroll_view(axes: :vertical, shows_indicators: true, **attrs, &block)
        classes = ["overflow-auto"]
        classes << (axes == :horizontal ? "overflow-x-auto flex-row" : "overflow-y-auto flex-col")
        classes << "scrollbar-hide" unless shows_indicators
        
        attrs[:class] = class_names(classes, attrs[:class])
        
        # Flex container to ensure scrolling works as expected
        create_element(:div, nil, **attrs, &block)
      end

      # Sheet(is_presented: boolean) { ... }
      def Sheet(is_presented: false, **attrs, &block)
        # Using HTML <dialog>
        classes = class_names(
          "backdrop:bg-gray-900/50 fixed inset-0 z-50 m-auto p-0 rounded-t-xl sm:rounded-xl shadow-2xl w-full sm:w-auto sm:min-w-[400px] h-[90%] sm:h-auto overflow-hidden", 
          attrs[:class]
        )
        
        attrs[:class] = classes
        attrs[:open] = true if is_presented
        
        create_element(:dialog, nil, **attrs) do
          div(class: "h-full flex flex-col bg-white") do
            # Drag handle for mobile feel
            div(class: "w-full flex justify-center py-2 bg-white") do
              div(class: "w-12 h-1.5 bg-gray-300 rounded-full")
            end
            
            # Content
            div(class: "flex-1 overflow-y-auto p-4") do
              yield
            end
          end
        end
      end

      # Virtualized Stack (Uses CSS content-visibility for performance)
      def LazyVStack(spacing: nil, **attrs, &block)
        attrs[:class] = class_names(
          "flex flex-col",
          spacing ? "space-y-#{spacing}" : nil,
          attrs[:class]
        )
        
        # Enable CSS virtualization
        # content-visibility: auto skips layout work for off-screen content
        attrs[:style] = [attrs[:style], "content-visibility: auto; contain-intrinsic-size: 100px"].compact.join(";")
        
        create_element(:div, nil, **attrs, &block)
      end

      # Grid variant
      def LazyVGrid(columns:, **attrs, &block)
        # Reuse standard grid logic but add virtualization
        attrs[:style] = [attrs[:style], "content-visibility: auto; contain-intrinsic-size: 100px"].compact.join(";")
        grid(columns: columns, **attrs, &block)
      end