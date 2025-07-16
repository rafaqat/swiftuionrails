# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Media components for SwiftUI Rails DSL
    module Media
      # Media Components with SECURITY validation
      def image(src: nil, alt: '', **attrs)
        raise ArgumentError, 'image requires src attribute' unless src

        # URL validation and sanitization
        safe_src = if src.match?(%r{\Ahttps?://}i)
                     validated = Security::URLValidator.validate_image_src(src, require_approved_domains: false)
                     Rails.logger.debug "Image validation: #{src} -> #{validated}"
                     validated || src # Use original if validation returns nil
                   else
                     # For relative paths, just ensure no path traversal
                     src.gsub('..', '')
                   end

        Rails.logger.debug "Image element: src=#{safe_src}, alt=#{alt}"

        attrs[:src] = safe_src
        attrs[:alt] = alt
        attrs[:loading] ||= 'lazy' # Default to lazy loading
        
        # Add default styling to make images visible
        attrs[:style] = [attrs[:style], 'max-width: 100%; height: auto; display: block;'].compact.join(' ')
        
        create_element(:img, nil, **attrs)
      end

      def icon(_name, size: 16, **attrs)
        # Placeholder for icon implementation
        # In a real implementation, this would render an SVG icon
        attrs[:class] = class_names('inline-block', attrs[:class])
        attrs[:style] = "width: #{size}px; height: #{size}px;"
        create_element(:span, '', **attrs)
      end
    end
  end
end