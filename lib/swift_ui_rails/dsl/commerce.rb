# frozen_string_literal: true

module SwiftUIRails
  module DSL
    module Commerce
      # ProductPrice(19.99, currency: "$", discount: 29.99)
      def ProductPrice(price, currency: "$", discount: nil, **attrs)
        hstack(spacing: 2, alignment: :first_text_baseline, **attrs) do
          Text("#{currency}#{price}").font(:title3).font_bold.foreground(:gray_900)
          
          if discount
            Text("#{currency}#{discount}")
              .font(:subheadline)
              .foreground(:gray_500)
              .style(:strikethrough) # Requires CSS class or style
              .attr("style", "text-decoration: line-through")
          end
        end
      end

      # RatingView(4.5, max: 5)
      def RatingView(rating, max: 5, **attrs)
        hstack(spacing: 1, **attrs) do
          max.times do |i|
            if i < rating.floor
              # Full star
              Text("★").foreground(:yellow_400).font(:caption)
            elsif i < rating
              # Half star (simulated)
              Text("★").foreground(:yellow_200).font(:caption) # Simplification
            else
              # Empty star
              Text("☆").foreground(:gray_300).font(:caption)
            end
          end
          
          Text(rating.to_s).font(:caption).foreground(:gray_500).padding(:leading, 1)
        end
      end

      # Badge("Sale", color: :red)
      def Badge(text_content, color: :blue, **attrs)
        Text(text_content)
          .font(:caption)
          .font_bold
          .foreground(color)
          .bg("#{color}-100")
          .padding(:x, 2)
          .padding(:y, 0.5)
          .rounded(:md)
      end

      # AddToCartButton { ... }
      def AddToCartButton(**attrs, &block)
        button(**attrs) do
          if block_given?
            yield
          else
            Label("Add to Cart", system_image: :cart)
              .frame(width: :full)
              .padding(3)
              .bg(:black)
              .foreground(:white)
              .rounded(:lg)
          end
        end
      end
    end
  end
end
