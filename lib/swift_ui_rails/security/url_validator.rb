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
        'tailwindcss.com',
        
        # Add your approved domains here
      ].freeze
      
      # URL schemes that are allowed
      ALLOWED_SCHEMES = %w[http https].freeze
      
      # Dangerous URL patterns
      DANGEROUS_PATTERNS = [
        /javascript:/i,
        /data:(?!image\/(png|jpg|jpeg|gif|webp|svg\+xml))/i,
        /vbscript:/i,
        /file:/i,
        /about:/i,
        /chrome:/i,
        /chrome-extension:/i
      ].freeze
      
      class << self
        # Validate and sanitize a URL
        def validate_url(url, options = {})
          return nil if url.nil? || url.empty?
          
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
          if options[:require_approved_domains]
            unless approved_domain?(uri.host)
              Rails.logger.warn "Unapproved external domain: #{uri.host}"
              return options[:fallback] || nil
            end
          end
          
          # Return the validated URL
          url
        end
        
        # Check if URL is from an approved domain
        def approved_domain?(host)
          return false if host.nil?
          
          host_lower = host.downcase
          
          # First check configuration if available
          if SwiftUIRails.configuration.respond_to?(:domain_approved?)
            return true if SwiftUIRails.configuration.domain_approved?(host)
          end
          
          # Fall back to legacy APPROVED_DOMAINS constant
          APPROVED_DOMAINS.any? do |approved|
            # Exact match or subdomain match
            host_lower == approved || host_lower.end_with?(".#{approved}")
          end
        end
        
        # Check if URL contains dangerous patterns
        def contains_dangerous_pattern?(url)
          DANGEROUS_PATTERNS.any? { |pattern| url.match?(pattern) }
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
      end
    end
  end
end
# Copyright 2025
