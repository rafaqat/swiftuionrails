# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # SafeElement wraps any object and provides Element-like methods
    # This handles cases where Rails helpers might return strings instead of Elements
    class SafeElement
      def initialize(content)
        @content = content
        @css_classes = []
        @attributes = {}
      end

      def tw(*classes)
        if @content.respond_to?(:tw)
          @content.tw(*classes)
        else
          # If content is a string, we can't modify it, so just return self
          @css_classes.concat(classes.flatten.compact)
          self
        end
      end

      def mr(size)
        tw("mr-#{size}")
      end

      def ml(size)
        tw("ml-#{size}")
      end

      def disabled(value = true)
        if @content.respond_to?(:disabled)
          @content.disabled(value)
        else
          @attributes[:disabled] = value if value
          self
        end
      end

      def to_s
        if @content.respond_to?(:to_s)
          # If we have CSS classes to add and content is a string, wrap it
          if @css_classes.any? && @content.is_a?(String)
            # Extract the tag and add classes
            modified = @content.sub(/^<(\w+)([^>]*)>/) do |match|
              tag = $1
              attrs = $2
              classes = @css_classes.join(" ")
              
              if attrs.include?('class=')
                attrs = attrs.sub(/class=(["'])(.*?)\1/) do |m|
                  quote = $1
                  existing = $2
                  "class=#{quote}#{existing} #{classes}#{quote}"
                end
              else
                attrs = "#{attrs} class=\"#{classes}\""
              end
              
              "<#{tag}#{attrs}>"
            end
            
            # Add disabled attribute if needed
            if @attributes[:disabled]
              modified = modified.sub(/^<(\w+)([^>]*)>/) do |match|
                tag = $1
                attrs = $2
                "<#{tag}#{attrs} disabled>"
              end
            end
            
            modified.html_safe
          else
            @content.to_s
          end
        else
          @content
        end
      end

      def html_safe?
        true
      end
      
      # Delegate other methods to content if it responds to them
      def method_missing(method, *args, &block)
        if @content.respond_to?(method)
          result = @content.send(method, *args, &block)
          # Wrap the result if it's chainable
          if result == @content
            self
          else
            result
          end
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        @content.respond_to?(method, include_private) || super
      end
    end
  end
end