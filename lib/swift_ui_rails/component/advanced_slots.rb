# frozen_string_literal: true

module SwiftUIRails
  module Component
    # AdvancedSlots provides polymorphic slot functionality for components
    #
    # Features:
    # - Polymorphic slots with type-safe definitions
    # - Required slot validation
    # - Default slot implementations
    # - Nested slot composition
    # - Slot content caching and optimization
    #
    # Usage:
    #   class MyComponent < ApplicationComponent
    #     include AdvancedSlots
    #     
    #     slot :header, default: -> { default_header }
    #     slot :actions, many: true, types: {
    #       button: ->(text:, **opts) { button_action(text, **opts) },
    #       link: ->(text:, url:, **opts) { link_action(text, url, **opts) }
    #     }
    #   end
    module AdvancedSlots
      extend ActiveSupport::Concern
      
      included do
        class_attribute :slot_configurations, default: {}
        
        attr_reader :slot_contents
      end
      
      class_methods do
        # Define a slot with advanced options
        def slot(name, types: nil, many: false, required: false, default: nil, &default_block)
          slot_config = {
            types: types,
            many: many,
            required: required,
            default: default || default_block
          }
          
          slot_configurations[name] = slot_config
          
          if types
            define_polymorphic_slot(name, types, many, required)
          else
            define_regular_slot(name, many, required, default, &default_block)
          end
          
          # Define query methods
          define_slot_query_methods(name, many)
          
          # Define render methods
          define_slot_render_methods(name, many)
        end
        
        private
        
        def define_polymorphic_slot(name, types, many, required)
          # Create type-specific methods
          types.each do |type_name, component_class_or_proc|
            method_name = many ? "with_#{name}_#{type_name}" : "with_#{name}_as_#{type_name}"
            
            define_method method_name do |*args, **kwargs, &block|
              content = if component_class_or_proc.respond_to?(:call)
                # Proc or lambda - call with arguments
                capture_slot_content do
                  instance_exec(*args, **kwargs, &component_class_or_proc)
                end
              elsif component_class_or_proc.respond_to?(:new)
                # Component class - instantiate
                component_class_or_proc.new(*args, **kwargs, &block)
              else
                # String or other content
                component_class_or_proc
              end
              
              store_slot_content(name, content, many, type: type_name)
              self
            end
          end
          
          # Create generic slot method if multiple types
          if types.size > 1
            define_method "with_#{name}" do |type:, **kwargs, &block|
              if types.key?(type.to_sym)
                send("with_#{name}_#{type}", **kwargs, &block)
              else
                raise ArgumentError, "Unknown #{name} type: #{type}. Available types: #{types.keys.join(', ')}"
              end
            end
          end
        end
        
        def define_regular_slot(name, many, required, default, &default_block)
          method_name = many ? "with_#{name}" : "with_#{name}"
          
          define_method method_name do |content = nil, **kwargs, &block|
            slot_content = if block_given?
              capture_slot_content(&block)
            elsif content
              content
            else
              kwargs
            end
            
            store_slot_content(name, slot_content, many)
            self
          end
        end
        
        def define_slot_query_methods(name, many)
          # Define predicate method
          define_method "#{name}?" do
            slot_contents&.key?(name) && 
              (many ? slot_contents[name].any? : !slot_contents[name].nil?)
          end
          
          # Define getter method
          if many
            define_method name do
              slot_contents&.dig(name) || []
            end
          else
            define_method name do
              slot_contents&.dig(name)
            end
          end
        end
        
        def define_slot_render_methods(name, many)
          if many
            # Render all items in collection
            define_method "render_#{name}" do |&wrapper_block|
              items = send(name)
              return unless items.any?
              
              if wrapper_block
                wrapper_block.call(items)
              else
                items.map { |item| render_slot_item(item) }.join.html_safe
              end
            end
            
            # Render with collection helper
            define_method "render_#{name}_with_collection" do |collection, &item_block|
              return unless collection&.any?
              
              collection.map.with_index do |item, index|
                if item_block
                  item_block.call(item, index)
                else
                  render_slot_item(item, context: { item: item, index: index })
                end
              end.join.html_safe
            end
          else
            # Render single item
            define_method "render_#{name}" do |&wrapper_block|
              content = send(name)
              return render_default_slot(name) unless content
              
              if wrapper_block
                wrapper_block.call(content)
              else
                render_slot_item(content)
              end
            end
          end
        end
      end
      
      def initialize(*args, **kwargs)
        super
        initialize_slot_contents
        validate_required_slots
      end
      
      private
      
      def initialize_slot_contents
        @slot_contents = {}
      end
      
      def store_slot_content(name, content, many, metadata: {})
        @slot_contents ||= {}
        
        if many
          @slot_contents[name] ||= []
          @slot_contents[name] << { content: content, metadata: metadata }
        else
          @slot_contents[name] = { content: content, metadata: metadata }
        end
      end
      
      def capture_slot_content(&block)
        if block_given?
          # Capture the DSL output
          old_elements = @pending_elements
          @pending_elements = []
          
          result = instance_eval(&block)
          captured_elements = @pending_elements
          
          @pending_elements = old_elements
          
          # Return elements if any were captured, otherwise return the result
          captured_elements.any? ? captured_elements : result
        end
      end
      
      def render_slot_item(slot_data, context: {})
        return "" unless slot_data
        
        content = slot_data.is_a?(Hash) ? slot_data[:content] : slot_data
        
        case content
        when Array
          # Multiple DSL elements
          content.map { |element| element.to_s }.join.html_safe
        when String
          content.html_safe
        when SwiftUIRails::DSL::Element
          content.to_s.html_safe
        else
          # Component or other renderable object
          if content.respond_to?(:render_in)
            content.render_in(view_context)
          elsif content.respond_to?(:to_s)
            content.to_s.html_safe
          else
            "".html_safe
          end
        end
      rescue => e
        Rails.logger.error "Error rendering slot content: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        "".html_safe
      end
      
      def render_default_slot(name)
        config = self.class.slot_configurations[name]
        return "".html_safe unless config&.dig(:default)
        
        default_content = config[:default]
        
        case default_content
        when Proc
          result = instance_eval(&default_content)
          render_slot_item({ content: result })
        when String
          default_content.html_safe
        else
          render_slot_item({ content: default_content })
        end
      rescue => e
        Rails.logger.error "Error rendering default slot #{name}: #{e.message}"
        "".html_safe
      end
      
      def validate_required_slots
        self.class.slot_configurations.each do |name, config|
          if config[:required] && !send("#{name}?")
            raise ArgumentError, "Required slot '#{name}' is missing"
          end
        end
      end
      
      # Public API for slot management
      public
      
      def clear_slot(name)
        @slot_contents&.delete(name)
      end
      
      def clear_all_slots
        @slot_contents&.clear
      end
      
      def slot_metadata(name)
        slot_data = @slot_contents&.dig(name)
        return {} unless slot_data
        
        if slot_data.is_a?(Array)
          slot_data.map { |item| item[:metadata] || {} }
        else
          slot_data[:metadata] || {}
        end
      end
      
      def has_slot_content?(name)
        send("#{name}?")
      end
      
      def slot_content_count(name)
        content = send(name)
        case content
        when Array
          content.size
        when nil
          0
        else
          1
        end
      end
    end
  end
end