# frozen_string_literal: true

# Copyright 2025

module SwiftUIRails
  module Security
    # SECURITY: Validates CSS classes to prevent CSS injection attacks
    module CSSValidator
      # Allowed values for various CSS properties
      VALID_COLORS = %w[
        white black red blue green yellow gray purple pink orange indigo
        slate zinc neutral stone amber teal cyan sky violet fuchsia rose
        transparent current inherit
      ].freeze

      VALID_SHADES = %w[50 100 200 300 400 500 600 700 800 900 950].freeze

      VALID_ASPECTS = %w[
        auto square video wide
        1/1 3/2 4/3 5/4 16/9 16/10 21/9
      ].freeze

      VALID_GRID_COLS = (1..12).to_a + %w[none subgrid].freeze

      VALID_SPACING = %w[
        0 px 0.5 1 1.5 2 2.5 3 3.5 4 5 6 7 8 9 10 11 12
        14 16 20 24 28 32 36 40 44 48 52 56 60 64 72 80 96
        auto full 1/2 1/3 2/3 1/4 2/4 3/4
      ].freeze

      VALID_SHADOWS = %w[none sm md lg xl 2xl inner].freeze

      VALID_ROUNDED = %w[none sm md lg xl 2xl 3xl full].freeze

      VALID_TEXT_SIZES = %w[xs sm base lg xl 2xl 3xl 4xl 5xl 6xl 7xl 8xl 9xl].freeze

      VALID_FONT_WEIGHTS = %w[thin extralight light normal medium semibold bold extrabold black].freeze

      VALID_TRANSITIONS = %w[none all colors opacity shadow transform].freeze

      VALID_DURATIONS = %w[75 100 150 200 300 500 700 1000].freeze

      VALID_SCALES = %w[0 50 75 90 95 100 105 110 125 150].freeze

      VALID_OPACITIES = %w[0 5 10 20 25 30 40 50 60 70 75 80 90 95 100].freeze

      # Pattern for valid CSS identifiers
      CSS_IDENTIFIER = %r{\A[a-zA-Z0-9\-_/]+\z}

      class << self
        # Validate and return safe background color class
        def safe_bg_class(color, shade = nil)
          return 'bg-gray-500' unless color

          color_str = color.to_s.downcase
          if VALID_COLORS.include?(color_str)
            if shade && VALID_SHADES.include?(shade.to_s)
              "bg-#{color_str}-#{shade}"
            elsif %w[transparent current inherit white black].include?(color_str)
              "bg-#{color_str}"
            else
              # For colors like "blue", "red", "green" without shade, use -500 as default
              "bg-#{color_str}-500"
            end
          else
            'bg-gray-500'
          end
        end

        # Validate and return safe text color class
        def safe_text_class(color, shade = nil)
          return 'text-gray-900' unless color

          color_str = color.to_s.downcase
          if VALID_COLORS.include?(color_str)
            if shade && VALID_SHADES.include?(shade.to_s)
              "text-#{color_str}-#{shade}"
            elsif %w[transparent current inherit].include?(color_str)
              "text-#{color_str}"
            elsif %w[white black].include?(color_str)
              "text-#{color_str}"
            else
              "text-#{color_str}-900"
            end
          else
            'text-gray-900'
          end
        end

        # Validate and return safe aspect ratio class
        def safe_aspect_class(ratio)
          return 'aspect-square' unless ratio

          ratio_str = ratio.to_s
          if VALID_ASPECTS.include?(ratio_str)
            "aspect-#{ratio_str.tr('/', '-')}"
          else
            'aspect-square'
          end
        end

        # Validate and return safe grid columns class
        def safe_grid_cols_class(cols)
          return 'grid-cols-1' unless cols

          cols_value = cols.to_s
          if VALID_GRID_COLS.include?(cols.to_i) || VALID_GRID_COLS.include?(cols_value)
            "grid-cols-#{cols_value}"
          else
            'grid-cols-1'
          end
        end

        # Validate and return safe spacing class
        def safe_spacing_class(prefix, value)
          return "#{prefix}-0" unless value && %w[p m px py mx my pt pb pl pr mt mb ml mr].include?(prefix)

          value_str = value.to_s
          if VALID_SPACING.include?(value_str)
            "#{prefix}-#{value_str.tr('/', '-')}"
          else
            "#{prefix}-0"
          end
        end

        # Validate and return safe shadow class
        def safe_shadow_class(size)
          return 'shadow' unless size

          size_str = size.to_s
          if VALID_SHADOWS.include?(size_str)
            size_str == 'none' ? 'shadow-none' : "shadow-#{size_str}"
          else
            'shadow'
          end
        end

        # Validate and return safe rounded class
        def safe_rounded_class(size)
          return 'rounded' unless size

          size_str = size.to_s
          if VALID_ROUNDED.include?(size_str)
            size_str == 'none' ? 'rounded-none' : "rounded-#{size_str}"
          else
            'rounded'
          end
        end

        # Validate and return safe text size class
        def safe_text_size_class(size)
          return 'text-base' unless size

          size_str = size.to_s
          if VALID_TEXT_SIZES.include?(size_str)
            "text-#{size_str}"
          else
            'text-base'
          end
        end

        # Validate and return safe font weight class
        def safe_font_weight_class(weight)
          return 'font-normal' unless weight

          weight_str = weight.to_s
          if VALID_FONT_WEIGHTS.include?(weight_str)
            "font-#{weight_str}"
          else
            'font-normal'
          end
        end

        # Validate any generic CSS value - comprehensive validation for tests
        def valid_css_value?(value)
          return true if value.nil? || value.to_s.strip.empty?  # Empty values are allowed
          
          value_str = value.to_s.strip
          
          # Check for dangerous patterns first
          return false if contains_dangerous_css_pattern?(value_str)
          
          # Allow a wide range of valid CSS values
          return true if valid_css_pattern?(value_str)
          
          false
        end

        private

        # Check for dangerous CSS injection patterns
        def contains_dangerous_css_pattern?(value)
          dangerous_patterns = [
            /javascript:/i,
            /vbscript:/i,
            /data:(?!image\/)/i,  # Allow image data URLs
            /expression\s*\(/i,
            /@import/i,
            /<script/i,
            /<\/script/i,
            /<\/style/i,
            /eval\s*\(/i,
            /setTimeout/i,
            /setInterval/i,
            /-moz-binding/i,
            /behavior\s*:/i,
            /-ms-behavior/i
          ]
          
          if dangerous_patterns.any? { |pattern| value.match?(pattern) }
            safe_logger_warn "CSS Injection attempt blocked: #{value}"
            true
          else
            false
          end
        end

        # Safe logger helper that handles nil Rails.logger in tests
        def safe_logger_warn(message)
          if defined?(Rails) && Rails.logger
            Rails.logger.warn(message)
          end
        end

        # Check if value matches valid CSS patterns using safe non-ReDoS methods
        def valid_css_pattern?(value)
          # First check length to prevent DoS on very long strings
          return false if value.length > 1000
          
          # Use safe character-by-character validation instead of catastrophic backtracking patterns
          return true if safe_basic_css_identifier?(value)
          return true if safe_hex_color?(value)
          return true if safe_css_function?(value)
          return true if safe_css_unit?(value)
          return true if safe_css_keyword?(value)
          
          false
        end
        
        # Safe validation methods to avoid ReDoS
        def safe_basic_css_identifier?(value)
          # Allow only alphanumeric, hyphens, underscores (no quantifiers that cause ReDoS)
          value.chars.all? { |char| char.match?(/[a-zA-Z0-9\-_]/) }
        end
        
        def safe_hex_color?(value)
          return false unless value.start_with?('#')
          hex_part = value[1..-1]
          return false unless [3, 4, 6, 8].include?(hex_part.length)
          hex_part.chars.all? { |char| char.match?(/[0-9a-fA-F]/) }
        end
        
        def safe_css_function?(value)
          # Check for common CSS functions without ReDoS patterns
          function_names = %w[rgb rgba hsl hsla calc var linear-gradient radial-gradient conic-gradient
                             translate translateX translateY translateZ translate3d rotate rotateX rotateY
                             rotateZ rotate3d scale scaleX scaleY scaleZ scale3d skew skewX skewY matrix
                             matrix3d perspective cubic-bezier drop-shadow]
          
          function_names.any? do |func|
            value.downcase.start_with?("#{func}(") && value.end_with?(')')
          end
        end
        
        def safe_css_unit?(value)
          # Check for CSS units without ReDoS patterns
          units = %w[px em rem % vh vw vmin vmax cm mm in pt pc ex ch]
          
          # Safe extraction without ReDoS patterns - character by character approach
          numeric_part = ""
          unit_part = ""
          decimal_found = false
          
          value.chars.each_with_index do |char, index|
            if char.match?(/\d/)
              numeric_part += char
            elsif char == '.' && !decimal_found
              numeric_part += char
              decimal_found = true
            else
              unit_part = value[index..-1]
              break
            end
          end
          
          return false if numeric_part.empty? || unit_part.empty?
          units.include?(unit_part.downcase)
        end
        
        def safe_css_keyword?(value)
          # Whitelist of safe CSS keywords (no regex quantifiers)
          keywords = %w[auto inherit initial unset none normal bold italic underline overline
                       line-through left right center justify top bottom middle baseline sub super
                       text-top text-bottom transparent current]
          
          keywords.include?(value.downcase)
        end

        public

        # Sanitize any CSS value to prevent injection
        def sanitize_css_value(value)
          return '' unless value

          # Remove any potentially dangerous characters
          value.to_s.gsub(%r{[^a-zA-Z0-9\-_/]}, '')
        end

        # Check if a complete CSS class is safe
        def safe_css_class?(css_class)
          return false unless css_class

          # Check for common injection patterns
          return false if css_class.include?(';') || css_class.include?('{') || css_class.include?('}')
          return false if css_class.include?('<') || css_class.include?('>')
          return false if css_class.include?('javascript:') || css_class.include?('data:')

          # Must match valid CSS class pattern
          css_class.match?(%r{\A[a-zA-Z0-9\-_:/\s]+\z})
        end

        # Build a safe CSS class string from components
        def build_safe_class(prefix, value, fallback = nil)
          return fallback unless prefix && value

          sanitized_prefix = sanitize_css_value(prefix)
          sanitized_value = sanitize_css_value(value)

          return fallback if sanitized_prefix.empty? || sanitized_value.empty?

          "#{sanitized_prefix}-#{sanitized_value}"
        end
      end
    end

    # Class wrapper for test compatibility
    class CssValidator
      def validate_css_value(value)
        CSSValidator.valid_css_value?(value)
      end

      def sanitize_css_value(value)
        CSSValidator.sanitize_css_value(value)
      end

      def safe_css_class?(css_class)
        CSSValidator.safe_css_class?(css_class)
      end

      # Missing method expected by tests
      def safe_css_value(value, fallback = 'inherit')
        if validate_css_value(value)
          value.to_s
        else
          fallback
        end
      end
    end
  end
end
# Copyright 2025
