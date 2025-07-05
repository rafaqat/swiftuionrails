# frozen_string_literal: true

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
        # Enable caching for this component
        def enable_caching(expires_in: nil, key_attributes: [])
          self.caching_enabled = true
          self.cache_expiry = expires_in
          self.cache_key_attributes = Array(key_attributes)
        end
        
        # Define custom cache key generation
        def cache_key(&block)
          define_method :cache_key_parts, &block
        end
        
        # Cache versioning for automatic invalidation
        def cache_version(version)
          define_method :cache_version do
            version
          end
        end
      end
      
      # Override call to add caching
      def call
        return super unless caching_enabled? && helpers.respond_to?(:cache)
        
        helpers.cache(component_cache_key, expires_in: cache_expiry) do
          super
        end
      end
      
      # Generate cache key for this component instance
      def component_cache_key
        parts = [
          self.class.name.underscore,
          cache_version,
          *cache_key_from_attributes,
          *custom_cache_key_parts
        ].compact
        
        parts.join("/")
      end
      
      # Check if caching is enabled
      def caching_enabled?
        self.class.caching_enabled && !Rails.env.development?
      end
      
      # Default cache version
      def cache_version
        "v1"
      end
      
      private
      
      # Extract cache key from specified attributes
      def cache_key_from_attributes
        cache_key_attributes.map do |attr|
          value = send(attr)
          case value
          when ActiveRecord::Base
            "#{value.class.name}-#{value.id}-#{value.updated_at.to_i}"
          when Array
            value.map { |v| cache_key_for_value(v) }.join("-")
          else
            cache_key_for_value(value)
          end
        end
      end
      
      # Convert value to cache key part
      def cache_key_for_value(value)
        case value
        when NilClass
          "nil"
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
      
      # Custom cache key parts (can be overridden)
      def custom_cache_key_parts
        respond_to?(:cache_key_parts) ? Array(cache_key_parts) : []
      end
      
      # Cache helpers for conditional caching
      def cache_if(condition, key = nil, **options, &block)
        if condition && helpers.respond_to?(:cache)
          cache_key = key || "#{component_cache_key}/partial/#{caller_locations(1,1)[0].label}"
          helpers.cache(cache_key, **options, &block)
        else
          yield
        end
      end
      
      # Fragment caching within components
      def cache_fragment(name, **options, &block)
        return yield unless caching_enabled? && helpers.respond_to?(:cache)
        
        fragment_key = "#{component_cache_key}/fragment/#{name}"
        helpers.cache(fragment_key, **options, &block)
      end
      
      # Russian doll caching support
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