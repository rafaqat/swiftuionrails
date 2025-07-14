# frozen_string_literal: true

module SwiftUIRails
  module Tailwind
    # Converts pixel values to Tailwind spacing scale
    module SpacingConverter
      # Tailwind spacing scale (each unit = 0.25rem = 4px)
      # Special cases: px = 1px, 0.5 = 2px, 1 = 4px, 1.5 = 6px, etc.
      PIXEL_TO_SPACING = {
        0 => '0',
        1 => 'px',     # 1px
        2 => '0.5',    # 2px = 0.5 * 4px
        4 => '1',      # 4px = 1 * 4px
        6 => '1.5',    # 6px = 1.5 * 4px
        8 => '2',      # 8px = 2 * 4px
        10 => '2.5',   # 10px = 2.5 * 4px
        12 => '3',     # 12px = 3 * 4px
        14 => '3.5',   # 14px = 3.5 * 4px
        16 => '4',     # 16px = 4 * 4px
        20 => '5',     # 20px = 5 * 4px
        24 => '6',     # 24px = 6 * 4px
        28 => '7',     # 28px = 7 * 4px
        32 => '8',     # 32px = 8 * 4px
        36 => '9',     # 36px = 9 * 4px
        40 => '10',    # 40px = 10 * 4px
        44 => '11',    # 44px = 11 * 4px
        48 => '12',    # 48px = 12 * 4px
        56 => '14',    # 56px = 14 * 4px
        64 => '16',    # 64px = 16 * 4px
        80 => '20',    # 80px = 20 * 4px
        96 => '24',    # 96px = 24 * 4px
        112 => '28',   # 112px = 28 * 4px
        128 => '32',   # 128px = 32 * 4px
        144 => '36',   # 144px = 36 * 4px
        160 => '40',   # 160px = 40 * 4px
        176 => '44',   # 176px = 44 * 4px
        192 => '48',   # 192px = 48 * 4px
        208 => '52',   # 208px = 52 * 4px
        224 => '56',   # 224px = 56 * 4px
        240 => '60',   # 240px = 60 * 4px
        256 => '64',   # 256px = 64 * 4px
        288 => '72',   # 288px = 72 * 4px
        320 => '80',   # 320px = 80 * 4px
        384 => '96'    # 384px = 96 * 4px
      }.freeze
      
      # Converts a numeric value to Tailwind spacing scale
      # @param value [Integer, String, Float] The value to convert
      # @return [String] The Tailwind spacing value
      def self.convert(value)
        return value.to_s if value.is_a?(String)
        
        # Handle numeric values
        num_value = value.to_i
        
        # Direct mapping
        return PIXEL_TO_SPACING[num_value] if PIXEL_TO_SPACING.key?(num_value)
        
        # For values not in the map, calculate the closest Tailwind unit
        # Each Tailwind unit = 4px
        tailwind_units = (num_value / 4.0).round(1)
        
        # Convert to string, removing unnecessary .0
        tailwind_units % 1 == 0 ? tailwind_units.to_i.to_s : tailwind_units.to_s
      end
      
      # Check if the value should be interpreted as pixels
      # @param value [Integer, String, Float] The value to check
      # @return [Boolean] true if the value should be treated as pixels
      def self.pixel_value?(value)
        # If it's a number greater than 6, it's likely meant as pixels
        # Tailwind spacing 0-6 are common values (0, px, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6)
        # Values above 6 that are multiples of 4 are likely pixel values
        return false unless value.is_a?(Numeric)
        
        # Common Tailwind values we should NOT convert
        tailwind_values = [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6]
        return false if tailwind_values.include?(value)
        
        # Otherwise, if it's a multiple of 4 or 2, it's likely pixels
        value > 6
      end
    end
  end
end