# frozen_string_literal: true

class ProductPriceComponent < ApplicationComponent
  prop :price, type: [Integer, Float, String], required: true
  prop :original_price, type: [Integer, Float, String, NilClass], default: nil
  prop :currency, type: String, default: "$"
  prop :size, type: Symbol, default: :sm # :xs, :sm, :md, :lg
  
  swift_ui do
    vstack(alignment: :trailing, spacing: 1) do
      # Current price
      text("#{currency}#{formatted_price(price)}")
        .text_size(size_class)
        .font_weight(original_price ? "semibold" : "medium")
        .text_color(original_price ? "red-600" : "gray-900")
      
      # Original price (strikethrough)
      if original_price && original_price != price
        text("#{currency}#{formatted_price(original_price)}")
          .text_size(smaller_size_class)
          .text_color("gray-500")
          .tw("line-through")
      end
      
      # Discount percentage
      if original_price && original_price > price
        text("#{discount_percentage}% off")
          .text_size("xs")
          .text_color("green-600")
          .font_weight("medium")
      end
    end
  end
  
  def formatted_price(amount)
    return "0" if amount.nil?
    
    # Handle string prices (e.g., "35.99")
    amount = amount.to_f if amount.is_a?(String)
    
    # Format with 2 decimal places if has decimals, otherwise as integer
    amount % 1 == 0 ? amount.to_i.to_s : sprintf("%.2f", amount)
  end
  
  def discount_percentage
    return 0 unless original_price && price
    
    discount = ((original_price.to_f - price.to_f) / original_price.to_f * 100).round
    discount
  end
  
  def size_class
    case size
    when :xs then "xs"
    when :sm then "sm"
    when :md then "base"
    when :lg then "lg"
    else "sm"
    end
  end
  
  def smaller_size_class
    case size
    when :xs then "xs"
    when :sm then "xs"
    when :md then "sm"
    when :lg then "base"
    else "xs"
    end
  end
end
# Copyright 2025
