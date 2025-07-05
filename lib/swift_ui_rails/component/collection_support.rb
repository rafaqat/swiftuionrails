# frozen_string_literal: true

module SwiftUIRails
  module Component
    # ViewComponent 2.0 collection rendering support
    module CollectionSupport
      extend ActiveSupport::Concern
      
      included do
        # Add collection counter support
        attr_reader :item_counter
        
        # Collection-specific attributes (not using prop since it might not be defined yet)
        attr_reader :collection_index, :collection_size, :is_first, :is_last
      end
      
      class_methods do
        # DSL method to render a collection of components
        def collection(items, **options, &block)
          # Use ViewComponent's optimized collection rendering
          with_collection(items, **options)
        end
        
        # Configure collection behavior
        def collection_options(**options)
          @collection_options ||= {}
          @collection_options.merge!(options)
        end
        
        # Define what prop receives the collection item
        def collection_prop(prop_name)
          @collection_prop_name = prop_name
        end
        
        # Get the collection prop name
        def collection_prop_name
          @collection_prop_name || :item
        end
      end
      
      # Override initialize to handle collection parameters
      def initialize(**args)
        # Extract collection-specific parameters
        if args.key?(:item)
          @item = args.delete(:item)
          @item_counter = args.delete(:item_counter)
          
          # Set collection metadata
          args[:collection_index] = @item_counter
          args[:is_first] = @item_counter == 0 if @item_counter
          
          # Map item to the appropriate prop
          prop_name = self.class.collection_prop_name
          args[prop_name] = @item if prop_name != :item
        end
        
        super(**args)
      end
      
      # Helper methods for collection items
      def collection_item?
        collection_index.present?
      end
      
      def even_item?
        collection_item? && collection_index.even?
      end
      
      def odd_item?
        collection_item? && collection_index.odd?
      end
      
      # Render helpers for collections
      def with_alternating_background(&block)
        wrapper_class = even_item? ? "bg-white" : "bg-gray-50"
        div(class: wrapper_class, &block)
      end
      
      def with_divider(&block)
        content = capture(&block)
        
        if is_last
          content
        else
          vstack(spacing: 0) do
            content
            div.h("px").bg("gray-200").my(2) # Divider
          end
        end
      end
    end
  end
end
# Copyright 2025
