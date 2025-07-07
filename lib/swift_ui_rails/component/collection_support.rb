# frozen_string_literal: true

# Copyright 2025

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
        ##
        # Renders a collection of components using ViewComponent's optimized collection rendering.
        # @param [Enumerable] items The collection of items to render.
        # @return [Array] The rendered components for each item in the collection.
        def collection(items, **options)
          # Use ViewComponent's optimized collection rendering
          with_collection(items, **options)
        end

        ##
        # Sets or updates configuration options for collection rendering.
        # @param [Hash] options - Options to merge into the collection configuration.
        # @return [Hash] The updated collection options.
        def collection_options(**options)
          @collection_options ||= {}
          @collection_options.merge!(options)
        end

        ##
        # Sets the name of the prop that will receive each item from the collection.
        # @param [Symbol, String] prop_name The name to assign to the collection item prop.
        def collection_prop(prop_name)
          @collection_prop_name = prop_name
        end

        ##
        # Returns the name of the prop used to receive each collection item, defaulting to :item if not set.
        # @return [Symbol] The collection prop name.
        def collection_prop_name
          @collection_prop_name || :item
        end
      end

      ##
      # Initializes the component, extracting and mapping collection-related parameters when rendering collection items.
      # Sets collection metadata such as index and first-item status, and remaps the item to the configured prop name if necessary.
      def initialize(**args)
        # Extract collection-specific parameters
        if args.key?(:item)
          @item = args.delete(:item)
          @item_counter = args.delete(:item_counter)

          # Set collection metadata
          args[:collection_index] = @item_counter
          args[:is_first] = @item_counter.zero? if @item_counter

          # Map item to the appropriate prop
          prop_name = self.class.collection_prop_name
          args[prop_name] = @item if prop_name != :item
        end

        super
      end

      ##
      # Returns true if the current instance represents an item within a collection.
      def collection_item?
        collection_index.present?
      end

      ##
      # Returns true if the current item is part of a collection and its index is even.
      # @return [Boolean] Whether the item is at an even index in the collection.
      def even_item?
        collection_item? && collection_index.even?
      end

      ##
      # Returns true if the current item is part of a collection and its index is odd.
      def odd_item?
        collection_item? && collection_index.odd?
      end

      ##
      # Wraps the given block in a div with a background color that alternates based on the item's index in the collection.
      # The background is white for even-indexed items and gray for odd-indexed items.
      def with_alternating_background(&block)
        wrapper_class = even_item? ? 'bg-white' : 'bg-gray-50'
        div(class: wrapper_class, &block)
      end

      ##
      # Wraps the given block content with a divider unless the item is the last in the collection.
      # For the last item, returns the content without a divider.
      def with_divider(&block)
        content = capture(&block)

        if is_last
          content
        else
          vstack(spacing: 0) do
            div.h('px').bg('gray-200').my(2) # Divider
          end
        end
      end
    end
  end
end
# Copyright 2025
