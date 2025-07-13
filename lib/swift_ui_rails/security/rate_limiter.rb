# frozen_string_literal: true

# Copyright 2025

require 'digest'

module SwiftUIRails
  module Security
    # SECURITY: Rate limiter for Stimulus action handlers to prevent abuse
    class RateLimiter
      class RateLimitExceeded < StandardError; end

      attr_reader :store, :threshold, :window

      def initialize(store: nil, threshold: nil, window: nil)
        @store = store || (defined?(Rails.cache) ? Rails.cache : nil)
        @threshold = threshold || SwiftUIRails.configuration.rate_limit_threshold
        @window = window || SwiftUIRails.configuration.rate_limit_window
      end

      # Check if action is allowed for given identifier
      def allow?(identifier, action_name = nil)
        return true unless SwiftUIRails.configuration.rate_limit_actions

        key = rate_limit_key(identifier, action_name)
        current_count = store.read(key, raw: true).to_i

        if current_count >= threshold
          Rails.logger.warn "[SECURITY] Rate limit exceeded for #{identifier} - action: #{action_name}"
          false
        else
          true
        end
      end

      # Record an action and check if limit is exceeded
      def record!(identifier, action_name = nil)
        return true unless SwiftUIRails.configuration.rate_limit_actions

        key = rate_limit_key(identifier, action_name)

        # Increment counter with expiration
        begin
          new_count = store.increment(key, 1, expires_in: window)

          # If increment returns nil, initialize the counter
          if new_count.nil?
            store.write(key, 1, raw: true, expires_in: window)
            new_count = 1
          end

          if new_count > threshold
            Rails.logger.warn "[SECURITY] Rate limit exceeded for #{identifier} - count: #{new_count}"
            raise RateLimitExceeded, 'Rate limit exceeded. Please try again later.'
          end

          true
        rescue StandardError => e
          Rails.logger.error "[SECURITY] Rate limiter error: #{e.message}"
          # Fail open in case of errors to not break functionality
          true
        end
      end

      # Reset rate limit for identifier
      def reset!(identifier, action_name = nil)
        key = rate_limit_key(identifier, action_name)
        store.delete(key)
      end

      # Get current count for identifier
      def current_count(identifier, action_name = nil)
        key = rate_limit_key(identifier, action_name)
        store.read(key, raw: true).to_i
      end

      # Get remaining actions allowed
      def remaining(identifier, action_name = nil)
        [threshold - current_count(identifier, action_name), 0].max
      end

      # Get time until reset (in seconds)
      def reset_in(identifier, action_name = nil)
        key = rate_limit_key(identifier, action_name)

        # Try to get TTL from cache store if supported
        if store.respond_to?(:ttl)
          ttl = store.ttl(key)
          ttl.positive? ? ttl : window
        else
          # Fallback - estimate based on window
          window
        end
      end

      private

      def rate_limit_key(identifier, action_name)
        # Create a unique key for rate limiting
        base = 'swift_ui_rails:rate_limit'
        id_hash = Digest::SHA256.hexdigest(identifier.to_s)[0..16]

        if action_name
          "#{base}:#{id_hash}:#{action_name}"
        else
          "#{base}:#{id_hash}"
        end
      end
    end

    # Middleware for rate limiting HTTP requests
    class RateLimitMiddleware
      def initialize(app, options = {})
        @app = app
        @limiter = RateLimiter.new(options)
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        # Only rate limit SwiftUI Rails action endpoints
        if request.path.include?('/rails/actions/')
          identifier = request.session.id || request.remote_ip

          return rate_limit_exceeded_response unless @limiter.allow?(identifier, request.path)

          begin
            @limiter.record!(identifier, request.path)
          rescue RateLimiter::RateLimitExceeded
            return rate_limit_exceeded_response
          end
        end

        @app.call(env)
      end

      private

      def rate_limit_exceeded_response
        [
          429,
          {
            'Content-Type' => 'application/json',
            'Retry-After' => @limiter.window.to_s
          },
          [{ error: 'Rate limit exceeded. Please try again later.' }.to_json]
        ]
      end
    end

    # Controller concern for rate limiting
    module RateLimitConcern
      extend ActiveSupport::Concern

      included do
        # Rate limiter instance
        class_attribute :rate_limiter
        self.rate_limiter = RateLimiter.new
      end

      # Check rate limit before action
      def check_rate_limit!(identifier = nil, action = nil)
        identifier ||= current_rate_limit_identifier
        action ||= "#{controller_name}##{action_name}"

        unless self.class.rate_limiter.allow?(identifier, action)
          render_rate_limit_exceeded
          return false
        end

        begin
          self.class.rate_limiter.record!(identifier, action)
          true
        rescue RateLimiter::RateLimitExceeded
          render_rate_limit_exceeded
          false
        end
      end

      private

      def current_rate_limit_identifier
        # Use session ID if available, otherwise IP address
        session.id || request.remote_ip
      end

      def render_rate_limit_exceeded
        respond_to do |format|
          format.json do
            render json: {
              error: 'Rate limit exceeded',
              retry_after: self.class.rate_limiter.window
            }, status: :too_many_requests
          end
          format.html do
            render plain: 'Rate limit exceeded. Please try again later.',
                   status: :too_many_requests
          end
        end
      end

      module ClassMethods
        # Configure rate limiting for controller
        def rate_limit(threshold: nil, window: nil, only: nil, except: nil)
          options = {}
          options[:only] = only if only
          options[:except] = except if except

          before_action(options) do
            check_rate_limit!
          end

          # Configure rate limiter if custom values provided
          return unless threshold || window

          self.rate_limiter = RateLimiter.new(
            threshold: threshold,
            window: window
          )
        end
      end
    end
  end
end
# Copyright 2025
