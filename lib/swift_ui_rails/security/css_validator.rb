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
        ##
        # Returns a safe CSS class string for background color based on validated color and optional shade.
        # Defaults to 'bg-gray-500' if the input is invalid or missing.
        # @param [String, Symbol] color - The base color name.
        # @param [String, Integer, nil] shade - Optional shade value for the color.
        # @return [String] A safe background color CSS class string.
        def safe_bg_class(color, shade = nil)
          return 'bg-gray-500' unless color

          color_str = color.to_s.downcase
          if VALID_COLORS.include?(color_str)
            if shade && VALID_SHADES.include?(shade.to_s)
              "bg-#{color_str}-#{shade}"
            elsif %w[transparent current inherit].include?(color_str)
              "bg-#{color_str}"
            elsif %w[white black].include?(color_str)
              "bg-#{color_str}"
            else
              "bg-#{color_str}-500"
            end
          else
            'bg-gray-500'
          end
        end

        ##
        # Returns a safe text color CSS class string based on validated color and optional shade.
        # Falls back to 'text-gray-900' if the color is invalid or not provided.
        # @param [String, Symbol] color - The base color name to use.
        # @param [String, Integer, nil] shade - Optional shade value for the color.
        # @return [String] A safe text color CSS class string.
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

        ##
        # Returns a safe CSS class string for aspect ratio based on allowed values.
        # Defaults to 'aspect-square' if the input is invalid or not provided.
        # @param [String, Symbol, nil] ratio - The desired aspect ratio.
        # @return [String] A validated aspect ratio CSS class name.
        def safe_aspect_class(ratio)
          return 'aspect-square' unless ratio

          ratio_str = ratio.to_s
          if VALID_ASPECTS.include?(ratio_str)
            "aspect-#{ratio_str.tr('/', '-')}"
          else
            'aspect-square'
          end
        end

        ##
        # Returns a safe CSS class string for grid column count.
        # If the provided value is not allowed, defaults to 'grid-cols-1'.
        # @param cols The desired number of grid columns.
        # @return [String] A validated grid columns CSS class string.
        def safe_grid_cols_class(cols)
          return 'grid-cols-1' unless cols

          cols_value = cols.to_s
          if VALID_GRID_COLS.include?(cols.to_i) || VALID_GRID_COLS.include?(cols_value)
            "grid-cols-#{cols_value}"
          else
            'grid-cols-1'
          end
        end

        ##
        # Returns a safe CSS spacing class string for the given prefix and value.
        # If the prefix or value is invalid, defaults to "#{prefix}-0".
        # @param [String] prefix The spacing property prefix (e.g., 'p', 'm', 'px', 'py', etc.).
        # @param [String, Integer] value The spacing value to validate.
        # @return [String] A validated and safe spacing class string.
        def safe_spacing_class(prefix, value)
          return "#{prefix}-0" unless value && %w[p m px py mx my pt pb pl pr mt mb ml mr].include?(prefix)

          value_str = value.to_s
          if VALID_SPACING.include?(value_str)
            "#{prefix}-#{value_str.tr('/', '-')}"
          else
            "#{prefix}-0"
          end
        end

        ##
        # Returns a safe CSS class string for shadow size.
        # If the provided size is valid, returns 'shadow-none' for 'none', or 'shadow-<size>' for other valid sizes.
        # Defaults to 'shadow' if the size is invalid or not provided.
        # @param [String, Symbol, nil] size - The desired shadow size.
        # @return [String] The validated shadow CSS class string.
        def safe_shadow_class(size)
          return 'shadow' unless size

          size_str = size.to_s
          if VALID_SHADOWS.include?(size_str)
            size_str == 'none' ? 'shadow-none' : "shadow-#{size_str}"
          else
            'shadow'
          end
        end

        ##
        # Returns a safe CSS class for rounded corners based on the provided size.
        # Defaults to 'rounded' if the size is invalid or not provided.
        # @param [String, Symbol, nil] size - The desired rounded size.
        # @return [String] A validated rounded CSS class name.
        def safe_rounded_class(size)
          return 'rounded' unless size

          size_str = size.to_s
          if VALID_ROUNDED.include?(size_str)
            size_str == 'none' ? 'rounded-none' : "rounded-#{size_str}"
          else
            'rounded'
          end
        end

        ##
        # Returns a safe CSS class for text size based on allowed values.
        # Defaults to 'text-base' if the provided size is invalid or missing.
        # @param [String, Symbol, nil] size - The desired text size.
        # @return [String] A validated text size CSS class.
        def safe_text_size_class(size)
          return 'text-base' unless size

          size_str = size.to_s
          if VALID_TEXT_SIZES.include?(size_str)
            "text-#{size_str}"
          else
            'text-base'
          end
        end

        ##
        # Returns a safe font weight CSS class string based on the provided weight.
        # Defaults to 'font-normal' if the weight is invalid or not provided.
        # @param [String, Symbol, nil] weight - The desired font weight.
        # @return [String] A validated font weight CSS class name.
        def safe_font_weight_class(weight)
          return 'font-normal' unless weight

          weight_str = weight.to_s
          if VALID_FONT_WEIGHTS.include?(weight_str)
            "font-#{weight_str}"
          else
            'font-normal'
          end
        end

        ##
        # Checks if the given value is a valid CSS identifier.
        # @param value The value to validate.
        # @return [Boolean] True if the value matches the allowed CSS identifier pattern, false otherwise.
        def valid_css_value?(value)
          return false unless value

          value.to_s.match?(CSS_IDENTIFIER)
        end

        ##
        # Removes any characters from the input that are not letters, digits, hyphens, underscores, or slashes to sanitize CSS values.
        # @param value The input to sanitize.
        # @return [String] The sanitized CSS value, or an empty string if input is nil.
        def sanitize_css_value(value)
          return '' unless value

          # Remove any potentially dangerous characters
          value.to_s.gsub(%r{[^a-zA-Z0-9\-_/]}, '')
        end

        ##
        # Determines if a CSS class string is safe by checking for dangerous characters, substrings, and ensuring it matches a valid pattern.
        # @param [String] css_class The CSS class string to validate.
        # @return [Boolean] True if the CSS class is considered safe, false otherwise.
        def safe_css_class?(css_class)
          return false unless css_class

          # Check for common injection patterns
          return false if css_class.include?(';') || css_class.include?('{') || css_class.include?('}')
          return false if css_class.include?('<') || css_class.include?('>')
          return false if css_class.include?('javascript:') || css_class.include?('data:')

          # Must match valid CSS class pattern
          css_class.match?(%r{\A[a-zA-Z0-9\-_:/\s]+\z})
        end

        ##
        # Constructs a safe CSS class string by sanitizing the prefix and value, joining them with a hyphen.
        # Returns the fallback if either input is missing or sanitizes to an empty string.
        # @param [String] prefix The CSS class prefix to sanitize and use.
        # @param [String] value The CSS class value to sanitize and use.
        # @param [String, nil] fallback The value to return if the prefix or value is invalid.
        # @return [String, nil] The constructed safe CSS class string, or the fallback if inputs are invalid.
        def build_safe_class(prefix, value, fallback = nil)
          return fallback unless prefix && value

          sanitized_prefix = sanitize_css_value(prefix)
          sanitized_value = sanitize_css_value(value)

          return fallback if sanitized_prefix.empty? || sanitized_value.empty?

          "#{sanitized_prefix}-#{sanitized_value}"
        end
      end
    end
  end
end
# Copyright 2025
