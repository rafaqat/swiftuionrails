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
      ALLOWED_SCHEMES = %w[http https].freeze

      # Dangerous URL patterns
      DANGEROUS_PATTERNS = [
        /javascript:/i,
        %r{data:(?!image/(png|jpg|jpeg|gif|webp|svg\+xml))}i,
        /vbscript:/i,
        /file:/i,
        /about:/i,
        /chrome:/i,
        /chrome-extension:/i
      ].freeze

      class << self
        ##
        # Validates and sanitizes a URL, blocking dangerous patterns, disallowed schemes, and unapproved domains.
        # Returns the original URL if it passes all checks, or a fallback value or nil if validation fails.
        # @param [String] url - The URL to validate.
        # @param [Hash] options - Validation options. Use :allow_relative (default true) to permit relative URLs, :require_approved_domains (default false) to enforce domain approval, and :fallback to specify a value to return if validation fails due to an unapproved domain.
        # @return [String, nil] The validated URL, the fallback value, or nil if the URL is invalid or unsafe.
        def validate_url(url, options = {})
          return nil if url.blank?

          # Check for dangerous patterns first
          if contains_dangerous_pattern?(url)
            Rails.logger.warn "Blocked dangerous URL pattern: #{url}"
            return nil
          end

          # Parse the URL
          begin
            uri = URI.parse(url)
          rescue URI::InvalidURIError
            Rails.logger.warn "Invalid URL format: #{url}"
            return nil
          end

          # Check if it's a relative URL (allowed by default)
          if uri.relative?
            return url if options[:allow_relative] != false

            Rails.logger.warn "Relative URLs not allowed: #{url}"
            return nil
          end

          # Check scheme
          unless ALLOWED_SCHEMES.include?(uri.scheme&.downcase)
            Rails.logger.warn "Disallowed URL scheme: #{uri.scheme} in #{url}"
            return nil
          end

          # Check domain if external URLs need approval
          if options[:require_approved_domains] && !approved_domain?(uri.host)
            Rails.logger.warn "Unapproved external domain: #{uri.host}"
            return options[:fallback] || nil
          end

          # Return the validated URL
          url
        end

        ##
        # Determines if the given host is considered approved for loading external resources.
        # Checks configuration-based approval first, then falls back to a legacy list of approved domains.
        # @param [String, nil] host - The host to check.
        # @return [Boolean] true if the host is approved, false otherwise.
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

        ##
        # Determines if the given URL matches any known dangerous patterns.
        # @param [String] url - The URL to check.
        # @return [Boolean] True if the URL contains a dangerous pattern, false otherwise.
        def contains_dangerous_pattern?(url)
          DANGEROUS_PATTERNS.any? { |pattern| url.match?(pattern) }
        end

        ##
        # Validates an image source URL, ensuring it is safe and from an approved domain.
        # Uses a placeholder image as a fallback if validation fails.
        # @param [String] src The image source URL to validate.
        # @param [Hash] options Optional validation settings to override defaults.
        # @return [String, nil] The validated image URL, a fallback placeholder, or nil if invalid and no fallback is set.
        def validate_image_src(src, options = {})
          # Set default options for images
          options = {
            allow_relative: true,
            require_approved_domains: true,
            fallback: '/images/placeholder.png'
          }.merge(options)

          validate_url(src, options)
        end

        ##
        # Validates a script source URL, enforcing stricter checks such as requiring approved domains.
        # Allows relative URLs by default and does not provide a fallback unless specified.
        # @param [String] src - The script source URL to validate.
        # @param [Hash] options - Optional validation settings to override defaults.
        # @return [String, nil] The validated script source URL, or nil if invalid.
        def validate_script_src(src, options = {})
          # Scripts should be more restricted
          options = {
            allow_relative: true,
            require_approved_domains: true,
            fallback: nil
          }.merge(options)

          validate_url(src, options)
        end

        ##
        # Validates a link href to ensure it is safe for use, allowing relative URLs and not requiring approved domains by default.
        # Falls back to '#' if validation fails.
        # @param [String] href - The link href to validate.
        # @param [Hash] options - Optional validation settings to override defaults.
        # @return [String, nil] The validated href, or the fallback value if invalid.
        def validate_link_href(href, options = {})
          # Links can be more permissive
          options = {
            allow_relative: true,
            require_approved_domains: false,
            fallback: '#'
          }.merge(options)

          validate_url(href, options)
        end

        ##
        # Generates a URL for a safe placeholder image with the specified dimensions and optional text.
        # @param [Integer] width The width of the placeholder image in pixels.
        # @param [Integer] height The height of the placeholder image in pixels.
        # @param [String, nil] text Optional text to display on the image.
        # @return [String] The URL of the generated placeholder image.
        def safe_placeholder_image(width: 400, height: 400, text: nil)
          # Use a safe placeholder service
          if text
            "https://via.placeholder.com/#{width}x#{height}?text=#{ERB::Util.url_encode(text)}"
          else
            "https://via.placeholder.com/#{width}x#{height}"
          end
        end

        ##
        # Adds a domain to the approved domains list at runtime via configuration.
        # @param [String] domain - The domain to approve.
        def add_approved_domain(domain)
          # Delegate to configuration
          SwiftUIRails.configuration.add_approved_domain(domain)
        end

        ##
        # Yields the module to a block for configuration purposes.
        # Use this method to customize URL validation settings within a Rails application.
        def configure
          yield self if block_given?
        end
      end
    end
  end
end
# Copyright 2025
