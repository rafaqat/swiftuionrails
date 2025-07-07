# frozen_string_literal: true

# Copyright 2025

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

      ##
      # Returns the string representation of the wrapped content, injecting any accumulated CSS classes and the disabled attribute into the HTML tag if applicable.
      # If the content is a string and CSS classes or disabled state have been set, modifies the opening HTML tag to include them.
      # @return [String] The modified or original string representation of the content, marked as HTML safe if modified.
      def to_s
        if @content.respond_to?(:to_s)
          # If we have CSS classes to add and content is a string, wrap it
          if @css_classes.any? && @content.is_a?(String)
            # Extract the tag and add classes
            modified = @content.sub(/^<(\w+)([^>]*)>/) do |_match|
              tag = ::Regexp.last_match(1)
              attrs = ::Regexp.last_match(2)
              classes = @css_classes.join(' ')

              attrs = if attrs.include?('class=')
                        attrs.sub(/class=(["'])(.*?)\1/) do |_m|
                          quote = ::Regexp.last_match(1)
                          existing = ::Regexp.last_match(2)
                          "class=#{quote}#{existing} #{classes}#{quote}"
                        end
                      else
                        "#{attrs} class=\"#{classes}\""
                      end

              "<#{tag}#{attrs}>"
            end

            # Add disabled attribute if needed
            if @attributes[:disabled]
              modified = modified.sub(/^<(\w+)([^>]*)>/) do |_match|
                tag = ::Regexp.last_match(1)
                attrs = ::Regexp.last_match(2)
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

      ##
      # Indicates that the output is considered safe HTML.
      # @return [Boolean] Always returns true.
      def html_safe?
        true
      end

      ##
      # Forwards undefined method calls to the wrapped content if possible, returning self for chainable calls.
      # Returns the result of the delegated method, or raises NoMethodError if the content does not respond.
      def method_missing(method, ...)
        if @content.respond_to?(method)
          result = @content.send(method, ...)
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
# Copyright 2025
