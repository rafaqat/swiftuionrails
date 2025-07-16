# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Layout components for SwiftUI Rails DSL
    # Provides stack-based layouts similar to SwiftUI
    module Layout
      def vstack(alignment: :center, spacing: 8, justify: :start, **attrs, &block)
        classes = ['flex', 'flex-col', "items-#{alignment_class(alignment)}", justify_class(justify)]
        
        # Only add spacing classes for justify values that don't handle spacing automatically
        # justify-between, justify-around, and justify-evenly handle spacing automatically
        if spacing.positive? && ![:between, :around, :evenly].include?(justify)
          classes << "space-y-#{spacing}"
        end
        
        # Add h-full for justify-between, justify-around, justify-evenly to ensure proper distribution
        if [:between, :around, :evenly].include?(justify)
          classes << 'h-full'
        end
        
        attrs[:class] = class_names(classes, attrs[:class])

        # Create element with special handling for collecting children
        create_element(:div, nil, **attrs) do
          if is_a?(SwiftUIRails::DSLContext) || is_a?(SwiftUIRails::Component::Base)
            # If we're in a DSL context, the block will be handled properly
            # If not, we need to collect all elements created in the block
            if block
              # Execute the block and capture any returned element
              result = instance_eval(&block)
              # If the block returns an element, ensure it's registered
              register_element(result) if result.is_a?(Element) && !(@pending_elements || []).include?(result)
              # Return nil to let the DSL context handle rendering via flush_elements
              nil
            end
          else
            # For non-DSL contexts, we need to capture elements created in the block
            elements = []
            original_create = method(:create_element)
            define_singleton_method(:create_element) do |*args, &inner_block|
              element = original_create.call(*args, &inner_block)
              elements << element
              element
            end

            # Execute the block
            result = instance_eval(&block) if block

            # Restore original method
            define_singleton_method(:create_element, original_create)

            # Return all collected elements or the block result if it's an array
            if result.is_a?(Array)
              result
            else
              elements
            end
          end
        end
      end

      def hstack(alignment: :center, spacing: 8, justify: :start, **attrs, &block)
        classes = ['flex', 'flex-row', "items-#{alignment_class(alignment)}", justify_class(justify)]
        
        # Only add spacing classes for justify values that don't handle spacing automatically
        # justify-between, justify-around, and justify-evenly handle spacing automatically
        if spacing.positive? && ![:between, :around, :evenly].include?(justify)
          classes << "space-x-#{spacing}"
        end
        
        # Add w-full for justify-between, justify-around, justify-evenly to ensure proper distribution
        if [:between, :around, :evenly].include?(justify)
          classes << 'w-full'
        end
        
        attrs[:class] = class_names(classes, attrs[:class])

        # Create element with special handling for collecting children
        create_element(:div, nil, **attrs) do
          if is_a?(SwiftUIRails::DSLContext) || is_a?(SwiftUIRails::Component::Base)
            # If we're in a DSL context, the block will be handled properly
            # If not, we need to collect all elements created in the block
            if block
              # Execute the block and capture any returned element
              result = instance_eval(&block)
              # If the block returns an element, ensure it's registered
              register_element(result) if result.is_a?(Element) && !(@pending_elements || []).include?(result)
              # Return nil to let the DSL context handle rendering via flush_elements
              nil
            end
          else
            # For non-DSL contexts, we need to capture elements created in the block
            elements = []
            original_create = method(:create_element)
            define_singleton_method(:create_element) do |*args, &inner_block|
              element = original_create.call(*args, &inner_block)
              elements << element
              element
            end

            # Execute the block
            result = instance_eval(&block) if block

            # Restore original method
            define_singleton_method(:create_element, original_create)

            # Return all collected elements or the block result if it's an array
            if result.is_a?(Array)
              result
            else
              elements
            end
          end
        end
      end

      def zstack(**attrs, &block)
        attrs[:class] = class_names('relative', attrs[:class])
        create_element(:div, nil, **attrs, &block)
      end

      def grid(columns: 2, spacing: 8, **attrs, &block)
        Rails.logger.debug { "DSL.grid called with columns: #{columns}, spacing: #{spacing}" }

        # Extract e-commerce specific properties
        row_gap = attrs.delete(:row_gap) || spacing
        column_gap = attrs.delete(:column_gap) || spacing
        responsive = attrs.delete(:responsive) { true }
        min_item_width = attrs.delete(:min_item_width)
        attrs.delete(:max_columns) || columns
        align = attrs.delete(:align) || :stretch
        justify = attrs.delete(:justify) || :start
        auto_rows = attrs.delete(:auto_rows)
        auto_flow = attrs.delete(:auto_flow)
        masonry = attrs.delete(:masonry) { false }

        Rails.logger.debug { "DSL.grid min_item_width: #{min_item_width.inspect}" }

        # Build base grid classes
        grid_classes = ['grid']

        # Handle responsive columns
        if min_item_width
          # Auto-fit grid with minimum item width takes precedence
          grid_classes << "grid-cols-[repeat(auto-fit,minmax(#{min_item_width}px,1fr))]"
        elsif columns.is_a?(Hash)
          # Support responsive object like { base: 1, sm: 2, lg: 3 }
          columns.each do |breakpoint, cols|
            if breakpoint == :base
              grid_classes << Security::CSSValidator.safe_grid_cols_class(cols)
            else
              safe_cols = Security::CSSValidator.safe_grid_cols_class(cols)
              grid_classes << "#{breakpoint}:#{safe_cols}"
            end
          end
        elsif responsive && columns.is_a?(Integer)
          grid_classes << case columns
                          when 1
                            'grid-cols-1'
                          when 2
                            'grid-cols-1 sm:grid-cols-2'
                          when 3
                            'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3'
                          when 4
                            'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
                          when 5
                            'grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5'
                          when 6
                            'grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6'
                          else
                            Security::CSSValidator.safe_grid_cols_class(columns)
                          end
        else
          grid_classes << Security::CSSValidator.safe_grid_cols_class(columns)
        end

        # Handle gap/spacing
        if row_gap == column_gap
          grid_classes << "gap-#{spacing}"
        else
          grid_classes << "gap-x-#{column_gap}" if column_gap.positive?
          grid_classes << "gap-y-#{row_gap}" if row_gap.positive?
        end

        # Alignment and justification
        case align
        when :start
          grid_classes << 'items-start'
        when :center
          grid_classes << 'items-center'
        when :end
          grid_classes << 'items-end'
        when :stretch
          grid_classes << 'items-stretch'
        end

        case justify
        when :start
          grid_classes << 'justify-start'
        when :center
          grid_classes << 'justify-center'
        when :end
          grid_classes << 'justify-end'
        when :between
          grid_classes << 'justify-between'
        when :around
          grid_classes << 'justify-around'
        when :evenly
          grid_classes << 'justify-evenly'
        end

        # Auto rows for consistent heights
        if auto_rows
          case auto_rows
          when :min
            grid_classes << 'auto-rows-min'
          when :max
            grid_classes << 'auto-rows-max'
          when :fr
            grid_classes << 'auto-rows-fr'
          else
            grid_classes << "auto-rows-[#{auto_rows}]" if auto_rows.is_a?(String)
          end
        end

        # Auto flow for grid item placement
        if auto_flow
          case auto_flow
          when :row
            grid_classes << 'grid-flow-row'
          when :col, :column
            grid_classes << 'grid-flow-col'
          when :dense
            grid_classes << 'grid-flow-dense'
          when :row_dense
            grid_classes << 'grid-flow-row-dense'
          when :col_dense, :column_dense
            grid_classes << 'grid-flow-col-dense'
          end
        end

        # Masonry layout
        if masonry
          attrs[:data] ||= {}
          attrs[:data][:masonry] = 'true'
        end

        # Apply the classes and create element
        attrs[:class] = class_names(grid_classes.join(' '), attrs[:class])
        Rails.logger.debug { "DSL.grid final class: #{attrs[:class]}" }
        create_element(:div, nil, **attrs, &block)
      end

      def lazy_vgrid(columns:, spacing: 20, **attrs, &block)
        # Calculate grid classes based on columns
        grid_classes = responsive_grid_classes(columns)

        # Main grid container with isolation
        attrs[:class] = class_names('swift-ui-grid', attrs[:class])
        attrs[:data] ||= {}
        attrs[:data][:grid_type] = 'lazy-vgrid'

        div(**attrs) do
          # Grid implementation with proper isolation
          inner_attrs = { class: "grid gap-#{spacing} #{grid_classes}" }
          div(**inner_attrs, &block)
        end
      end

      def grid_item_wrapper(**attrs, &block)
        # Wrapper for grid items to ensure proper isolation
        attrs[:class] = class_names('contents', attrs[:class])

        div(**attrs) do
          yield if block_given?
        end
      end

      def spacer(min_length: nil)
        attrs = { class: 'flex-1' }
        attrs[:style] = "min-height: #{min_length}px" if min_length
        create_element(:div, '', **attrs)
      end

      def divider(**attrs)
        attrs[:class] = class_names('border-t border-gray-300', attrs[:class])
        create_element(:hr, nil, **attrs)
      end

      private

      def alignment_class(alignment)
        case alignment
        when :top, :start then 'start'
        when :center then 'center'
        when :bottom, :end then 'end'
        when :stretch then 'stretch'
        when :baseline then 'baseline'
        else 'center'
        end
      end

      def justify_class(justify)
        case justify
        when :start then 'justify-start'
        when :center then 'justify-center'
        when :end then 'justify-end'
        when :between then 'justify-between'
        when :around then 'justify-around'
        when :evenly then 'justify-evenly'
        else 'justify-start'
        end
      end

      def responsive_grid_classes(columns)
        case columns
        when 1 then 'grid-cols-1'
        when 2 then 'grid-cols-1 sm:grid-cols-2'
        when 3 then 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3'
        when 4 then 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4'
        when 6 then 'grid-cols-2 sm:grid-cols-3 lg:grid-cols-6'
        else "grid-cols-#{columns}"
        end
      end

      def responsive_grid_for_items(item_count)
        case item_count
        when 0..150 then 'grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6'
        when 151..250 then 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
        else 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3'
        end
      end
    end
  end
end