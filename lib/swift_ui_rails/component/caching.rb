# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Component
    # Caching support for ViewComponent 2.0
    module Caching
      extend ActiveSupport::Concern

      included do
        # Track if caching is enabled for this component
        class_attribute :caching_enabled, default: false
        class_attribute :cache_key_attributes, default: []
        class_attribute :cache_expiry, default: nil
      end

      class_methods do
        ##
        # Enables caching for the component, optionally setting cache expiration and specifying attributes to use in cache key generation.
        # @param [Object] expires_in - Optional duration for cache expiration.
        # @param [Array] key_attributes - Optional list of attribute names to include in the cache key.
        def enable_caching(expires_in: nil, key_attributes: [])
          self.caching_enabled = true
          self.cache_expiry = expires_in
          self.cache_key_attributes = Array(key_attributes)
        end

        ##
        # Defines a custom method for generating additional cache key parts for the component.
        # The provided block will be used as the implementation of the `cache_key_parts` instance method.
        def cache_key(&block)
          define_method :cache_key_parts, &block
        end

        ##
        # Sets a custom cache version for the component by defining an instance method that returns the specified version string.
        # @param [String] version - The cache version identifier to use for cache invalidation.
        def cache_version(version)
          define_method :cache_version do
            version
          end
        end
      end

      ##
      # Renders the component, wrapping the output in a cache block if caching is enabled and supported.
      # Falls back to the original render method if caching is not active.
      def call
        return super unless caching_enabled? && helpers.respond_to?(:cache)

        helpers.cache(component_cache_key, expires_in: cache_expiry) do
          super
        end
      end

      ##
      # Generates a cache key string for the component instance based on class name, cache version, specified attributes, and any custom cache key parts.
      # @return [String] The generated cache key for this component instance.
      def component_cache_key
        parts = [
          self.class.name.underscore,
          cache_version,
          *cache_key_from_attributes,
          *custom_cache_key_parts
        ].compact

        parts.join('/')
      end

      ##
      # Returns true if caching is enabled for the component and the environment is not development.
      def caching_enabled?
        self.class.caching_enabled && !Rails.env.development?
      end

      ##
      # Returns the default cache version string used for cache key generation.
      # @return [String] The cache version, defaulting to 'v1'.
      def cache_version
        'v1'
      end

      private

      ##
      # Generates cache key parts from the specified attributes for use in component caching.
      # Handles ActiveRecord objects, arrays, and other value types to ensure unique and consistent cache keys.
      # @return [Array<String>] An array of cache key parts derived from the component's cache key attributes.
      def cache_key_from_attributes
        cache_key_attributes.map do |attr|
          value = send(attr)
          case value
          when ActiveRecord::Base
            "#{value.class.name}-#{value.id}-#{value.updated_at.to_i}"
          when Array
            value.map { |v| cache_key_for_value(v) }.join('-')
          else
            cache_key_for_value(value)
          end
        end
      end

      ##
      # Converts a value into a string suitable for use as a cache key part.
      # Handles nil, booleans, numerics, strings, symbols, times, and ActiveRecord objects with type-specific formatting.
      # @param value The value to convert into a cache key part.
      # @return [String] The string representation of the value for cache key usage.
      def cache_key_for_value(value)
        case value
        when NilClass
          'nil'
        when TrueClass, FalseClass
          value.to_s
        when Numeric, String, Symbol
          value.to_s
        when Time, DateTime
          value.to_i.to_s
        when ActiveRecord::Base
          "#{value.class.name}-#{value.id}"
        else
          value.to_s
        end
      end

      ##
      # Returns an array of custom cache key parts if the `cache_key_parts` method is defined; otherwise, returns an empty array.
      def custom_cache_key_parts
        respond_to?(:cache_key_parts) ? Array(cache_key_parts) : []
      end

      ##
      # Conditionally caches the result of a block if the condition is true and caching is supported.
      # If caching is not enabled or supported, yields the block without caching.
      # @param [Boolean] condition - Determines whether caching should be applied.
      # @param [String, nil] key - Optional custom cache key. If not provided, a key is generated.
      # @return The result of the block, either cached or freshly computed.
      def cache_if(condition, key = nil, **options, &block)
        if condition && helpers.respond_to?(:cache)
          cache_key = key || "#{component_cache_key}/partial/#{caller_locations(1, 1)[0].label}"
          helpers.cache(cache_key, **options, &block)
        else
          yield
        end
      end

      ##
      # Caches a fragment of the component output under a fragment-specific cache key.
      # If caching is not enabled or supported, yields the block without caching.
      # @param name [String] The name identifying the fragment within the component.
      # @return [Object] The cached or freshly rendered fragment output.
      def cache_fragment(name, ...)
        return yield unless caching_enabled? && helpers.respond_to?(:cache)

        fragment_key = "#{component_cache_key}/fragment/#{name}"
        helpers.cache(fragment_key, ...)
      end

      ##
      # Caches the rendered output of each item in a collection using Russian doll caching.
      # If caching is not enabled or supported, yields the entire collection to the block.
      # @param collection [Enumerable] The collection of items to cache individually.
      # @return [String] The concatenated cached or rendered results for the collection.
      def cache_collection(collection, **options)
        return yield(collection) unless caching_enabled? && helpers.respond_to?(:cache)

        # Generate cache keys for collection
        cache_keys = collection.map do |item|
          "#{component_cache_key}/collection/#{cache_key_for_value(item)}"
        end

        # Use Rails multi-fetch for efficiency
        cached_results = Rails.cache.fetch_multi(*cache_keys, **options) do |key|
          index = cache_keys.index(key)
          item = collection[index]
          capture { yield(item) }
        end

        safe_join(cached_results.values)
      end
    end
  end
end
# Copyright 2025
