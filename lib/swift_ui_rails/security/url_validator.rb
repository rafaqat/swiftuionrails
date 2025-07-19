# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Security
    # SECURITY: Validates URLs to prevent loading from untrusted sources
    module URLValidator
      # List of approved external domains for resources
      # This is now deprecated in favor of configuration
      APPROVED_DOMAINS = [
        # Development/placeholder services
        'picsum.photos',
        'via.placeholder.com',
        'placehold.co',
        'placeholder.com',

        # CDN services
        'cdn.jsdelivr.net',
        'unpkg.com',
        'cdnjs.cloudflare.com',

        # Common image services
        'images.unsplash.com',
        'i.imgur.com',
        'gravatar.com',

        # Development and documentation services
        'tailwindui.com',
        'tailwindcss.com'

        # Add your approved domains here
      ].freeze

      # URL schemes that are allowed
      ALLOWED_SCHEMES = %w[http https mailto tel data].freeze

      # Dangerous URL patterns - data URLs handled separately in validate_data_url
      DANGEROUS_PATTERNS = [
        /javascript:/i,
        /vbscript:/i,
        /file:/i,
        /about:/i,
        /chrome:/i,
        /chrome-extension:/i,
        /ws:/i,
        /wss:/i
      ].freeze

      class << self
        # Validate and sanitize a URL
        def validate_url(url, options = {})
          return nil if url.nil? || url.to_s.strip.empty?

          # Check for dangerous patterns first
          if contains_dangerous_pattern?(url)
            safe_logger_warn "URL Injection attempt blocked: #{url}"
            return nil
          end

          # Parse the URL with better error handling
          begin
            # Try parsing the URL, but be more forgiving for international domains
            uri = URI.parse(url)
          rescue URI::InvalidURIError => e
            # Try to handle common URL cases that URI.parse might reject
            if url.match?(%r{^https?://}i)
              # For international domains and special characters, be more permissive
              # Still check for dangerous patterns but don't fail on parsing
              return url if !contains_dangerous_pattern?(url)
            elsif url.match?(%r{^data:}i)
              # Handle data URLs that fail URI parsing
              return validate_data_url(url)
            elsif url.match?(%r{^(mailto|tel):}i)
              # Handle other schemes that might fail parsing
              return url if !contains_dangerous_pattern?(url)
            end
            safe_logger_warn "Invalid URL format: #{url}"
            return nil
          end

          # Check if it's a relative URL (allowed by default)
          if uri.relative?
            return url if options[:allow_relative] != false

            safe_logger_warn "Relative URLs not allowed: #{url}"
            return nil
          end

          # Check scheme
          unless ALLOWED_SCHEMES.include?(uri.scheme&.downcase)
            safe_logger_warn "Disallowed URL scheme: #{uri.scheme} in #{url}"
            return nil
          end

          # For data URLs, do additional validation
          if uri.scheme&.downcase == 'data'
            return validate_data_url(url)
          end

          # For mailto and tel URLs, they're generally safe
          if %w[mailto tel].include?(uri.scheme&.downcase)
            return url
          end

          # Check domain if external URLs need approval
          if options[:require_approved_domains] && !approved_domain?(uri.host)
            safe_logger_warn "Unapproved external domain: #{uri.host}"
            return options[:fallback] || nil
          end

          # Return the validated URL
          url
        end

        # Check if URL is from an approved domain
        def approved_domain?(host)
          return false if host.nil?

          host_lower = host.downcase

          # First check configuration if available
          if SwiftUIRails.configuration.respond_to?(:domain_approved?) && SwiftUIRails.configuration.domain_approved?(host)
            return true
          end

          # Fall back to legacy APPROVED_DOMAINS constant
          APPROVED_DOMAINS.any? do |approved|
            # Exact match or subdomain match
            host_lower == approved || host_lower.end_with?(".#{approved}")
          end
        end

        # Check if URL contains dangerous patterns
        def contains_dangerous_pattern?(url)
          return false if url.nil? || url.to_s.strip.empty?
          
          # Clean up URL for pattern matching
          cleaned_url = url.to_s.downcase.strip
          
          # Check for null bytes
          return true if cleaned_url.include?("\0") || cleaned_url.include?("\x00")
          
          # URL decode to catch encoded attacks
          begin
            require 'uri'
            decoded_url = URI.decode_www_form_component(cleaned_url)
            # Also check the decoded version
            cleaned_url = [cleaned_url, decoded_url].join(' ')
          rescue => e
            # If decoding fails, continue with original
          end
          
          # Check against dangerous patterns
          DANGEROUS_PATTERNS.any? { |pattern| cleaned_url.match?(pattern) }
        end

        # Validate image source URL
        def validate_image_src(src, options = {})
          # Set default options for images
          options = {
            allow_relative: true,
            require_approved_domains: true,
            fallback: '/images/placeholder.png'
          }.merge(options)

          validate_url(src, options)
        end

        # Validate script source URL
        def validate_script_src(src, options = {})
          # Scripts should be more restricted
          options = {
            allow_relative: true,
            require_approved_domains: true,
            fallback: nil
          }.merge(options)

          validate_url(src, options)
        end

        # Validate link href
        def validate_link_href(href, options = {})
          # Links can be more permissive
          options = {
            allow_relative: true,
            require_approved_domains: false,
            fallback: '#'
          }.merge(options)

          validate_url(href, options)
        end

        # Generate a safe placeholder image URL
        def safe_placeholder_image(width: 400, height: 400, text: nil)
          # Use a safe placeholder service
          if text
            "https://via.placeholder.com/#{width}x#{height}?text=#{ERB::Util.url_encode(text)}"
          else
            "https://via.placeholder.com/#{width}x#{height}"
          end
        end

        # Add a domain to the approved list at runtime (for configuration)
        def add_approved_domain(domain)
          # Delegate to configuration
          SwiftUIRails.configuration.add_approved_domain(domain)
        end

        # Configuration helper for Rails apps
        def configure
          yield self if block_given?
        end

        private

        # Validate data URLs - only allow image data URLs
        def validate_data_url(url)
          # Only allow image data URLs, block HTML/script data URLs
          if url.match?(/^data:image\/(png|jpe?g|gif|svg\+xml|webp);/i)
            url
          else
            safe_logger_warn "Blocked non-image data URL: #{url}"
            nil
          end
        end

        # Safe logger helper that handles nil Rails.logger in tests
        def safe_logger_warn(message)
          if defined?(Rails) && Rails.logger
            Rails.logger.warn(message)
          end
        end
      end
    end

    # Class wrapper for test compatibility
    class UrlValidator
      def validate_url(url, options = {})
        # Tests expect boolean returns, module returns URL or nil
        result = URLValidator.validate_url(url, options)
        # Convert to boolean: valid if we get the URL back or if it's empty/nil (allowed)
        return true if url.nil? || url.to_s.strip.empty?  # Empty/nil URLs are considered valid
        result == url  # Valid if returned unchanged
      end

      def approved_domain?(host)
        URLValidator.approved_domain?(host)
      end

      def contains_dangerous_pattern?(url)
        URLValidator.contains_dangerous_pattern?(url)
      end

      def validate_image_src(src, options = {})
        URLValidator.validate_image_src(src, options)
      end

      def validate_script_src(src, options = {})
        URLValidator.validate_script_src(src, options)
      end

      def validate_link_href(href, options = {})
        URLValidator.validate_link_href(href, options)
      end

      # Missing method expected by tests
      def safe_url(url, fallback = '#')
        result = URLValidator.validate_url(url, allow_relative: true)
        result || fallback
      end

      private

      # Missing method expected by tests
      def extract_domain(url)
        return nil if url.nil? || url.to_s.strip.empty?
        
        begin
          uri = URI.parse(url)
          uri.host
        rescue URI::InvalidURIError
          nil
        end
      end
    end
  end
end
# Copyright 2025
