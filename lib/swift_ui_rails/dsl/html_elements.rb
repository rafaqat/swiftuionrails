# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Basic HTML elements for SwiftUI Rails DSL
    module HTMLElements
      def div(**attrs, &block)
        Rails.logger.debug { "DSL.div called with block: #{block}" }
        
        # Use the same pattern as layout elements for proper block handling
        create_element(:div, nil, **attrs) do
          if block && (is_a?(SwiftUIRails::DSLContext) || is_a?(SwiftUIRails::Component::Base))
            # Execute the block and capture any returned element or string
            result = instance_eval(&block)
            
            # If the block returns a string, create a text element for it
            if result.is_a?(String)
              text_element = create_element(:span, result)
              register_element(text_element)
            elsif result.is_a?(Element) && !(@pending_elements || []).include?(result)
              # If the block returns an element, ensure it's registered
              register_element(result)
            end
            
            # Return nil to let the DSL context handle rendering via flush_elements
            nil
          elsif block
            # For non-DSL contexts, just execute the block
            instance_eval(&block)
          end
        end
      end

      def span(**attrs, &block)
        create_element(:span, nil, **attrs, &block)
      end

      def section(**attrs, &block)
        Rails.logger.debug { "DSL.section called with block: #{block}, attrs: #{attrs.inspect}" }
        
        # Use the same pattern as div for proper block handling
        create_element(:section, nil, **attrs) do
          if block && (is_a?(SwiftUIRails::DSLContext) || is_a?(SwiftUIRails::Component::Base))
            # Execute the block and capture any returned element or string
            result = instance_eval(&block)
            
            # If the block returns a string, create a text element for it
            if result.is_a?(String)
              text_element = create_element(:span, result)
              register_element(text_element)
            elsif result.is_a?(Element) && !(@pending_elements || []).include?(result)
              # If the block returns an element, ensure it's registered
              register_element(result)
            end
            
            # Return nil to let the DSL context handle rendering via flush_elements
            nil
          elsif block
            # For non-DSL contexts, just execute the block
            instance_eval(&block)
          end
        end
      end

      def article(**attrs, &block)
        create_element(:article, nil, **attrs, &block)
      end

      def header(**attrs, &block)
        create_element(:header, nil, **attrs, &block)
      end

      def footer(**attrs, &block)
        create_element(:footer, nil, **attrs, &block)
      end

      def nav(**attrs, &block)
        Rails.logger.debug { "DSL.nav called with block: #{block}, attrs: #{attrs.inspect}" }
        
        # Use the same pattern as div for proper block handling
        create_element(:nav, nil, **attrs) do
          if block && (is_a?(SwiftUIRails::DSLContext) || is_a?(SwiftUIRails::Component::Base))
            # Execute the block and capture any returned element or string
            result = instance_eval(&block)
            
            # If the block returns a string, create a text element for it
            if result.is_a?(String)
              text_element = create_element(:span, result)
              register_element(text_element)
            elsif result.is_a?(Element) && !(@pending_elements || []).include?(result)
              # If the block returns an element, ensure it's registered
              register_element(result)
            end
            
            # Return nil to let the DSL context handle rendering via flush_elements
            nil
          elsif block
            # For non-DSL contexts, just execute the block
            instance_eval(&block)
          end
        end
      end

      def a(**attrs, &block)
        Rails.logger.debug { "DSL.a called with block: #{block}, attrs: #{attrs.inspect}" }
        
        # Use the same pattern as div for proper block handling
        create_element(:a, nil, **attrs) do
          if block && (is_a?(SwiftUIRails::DSLContext) || is_a?(SwiftUIRails::Component::Base))
            # Execute the block and capture any returned element or string
            result = instance_eval(&block)
            
            # If the block returns a string, create a text element for it
            if result.is_a?(String)
              text_element = create_element(:span, result)
              register_element(text_element)
            elsif result.is_a?(Element) && !(@pending_elements || []).include?(result)
              # If the block returns an element, ensure it's registered
              register_element(result)
            end
            
            # Return nil to let the DSL context handle rendering via flush_elements
            nil
          elsif block
            # For non-DSL contexts, just execute the block
            instance_eval(&block)
          end
        end
      end

      def h1(**attrs, &block)
        # Use the same pattern as div for proper block handling
        create_element(:h1, nil, **attrs) do
          if block && (is_a?(SwiftUIRails::DSLContext) || is_a?(SwiftUIRails::Component::Base))
            # Execute the block and capture any returned element or string
            result = instance_eval(&block)
            
            # If the block returns a string, create a text element for it
            if result.is_a?(String)
              text_element = create_element(:span, result)
              register_element(text_element)
            elsif result.is_a?(Element) && !(@pending_elements || []).include?(result)
              # If the block returns an element, ensure it's registered
              register_element(result)
            end
            
            # Return nil to let the DSL context handle rendering via flush_elements
            nil
          elsif block
            # For non-DSL contexts, just execute the block
            instance_eval(&block)
          end
        end
      end

      def h2(**attrs, &block)
        create_element(:h2, nil, **attrs, &block)
      end

      def h3(**attrs, &block)
        create_element(:h3, nil, **attrs, &block)
      end

      def h4(**attrs, &block)
        create_element(:h4, nil, **attrs, &block)
      end

      def h5(**attrs, &block)
        create_element(:h5, nil, **attrs, &block)
      end

      def h6(**attrs, &block)
        create_element(:h6, nil, **attrs, &block)
      end

      # HTML paragraph element - clean separation from Tailwind p() modifier
      def paragraph(**attrs, &block)
        Rails.logger.debug { "DSL.paragraph called with attrs: #{attrs.inspect}, block: #{block}" }
        
        # Use the same pattern as div for proper block handling
        create_element(:p, nil, **attrs) do
          if block && (is_a?(SwiftUIRails::DSLContext) || is_a?(SwiftUIRails::Component::Base))
            # Execute the block and capture any returned element or string
            result = instance_eval(&block)
            
            # If the block returns a string, create a text element for it
            if result.is_a?(String)
              text_element = create_element(:span, result)
              register_element(text_element)
            elsif result.is_a?(Element) && !(@pending_elements || []).include?(result)
              # If the block returns an element, ensure it's registered
              register_element(result)
            end
            
            # Return nil to let the DSL context handle rendering via flush_elements
            nil
          elsif block
            # For non-DSL contexts, just execute the block
            instance_eval(&block)
          end
        end
      end

      # Text element - special handling for inline text
      def text(content, **attrs)
        create_element(:span, content, **attrs)
      end

      # Link helper with destination
      def link(title = nil, destination: '#', **attrs, &block)
        attrs[:href] = destination
        if block_given?
          create_element(:a, nil, **attrs, &block)
        else
          create_element(:a, title, **attrs)
        end
      end

      # Script element for inline JavaScript
      def script(**attrs, &block)
        create_element(:script, nil, **attrs, &block)
      end

      # Main element for semantic HTML
      def main(**attrs, &block)
        create_element(:main, nil, **attrs, &block)
      end

      # Line break element - self-closing
      def br(**attrs)
        create_element(:br, nil, **attrs)
      end
    end
  end
end