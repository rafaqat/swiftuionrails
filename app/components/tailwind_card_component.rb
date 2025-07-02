class TailwindCardComponent < SwiftUIComponent
  prop :variant, type: Symbol, default: :elevated # :elevated, :outlined, :filled
  prop :padding, type: Symbol, default: :md
  prop :hover_effect, type: [TrueClass, FalseClass], default: false
  prop :clickable, type: [TrueClass, FalseClass], default: false
  
  renders_one :header
  renders_one :content
  renders_one :footer
  renders_one :media
  
  PADDING_CLASSES = {
    none: "",
    sm: "p-4",
    md: "p-6",
    lg: "p-8",
    xl: "p-10"
  }.freeze
  
  swift_ui do
    div do
      # Media slot (full width, no padding)
      if media?
        div.tw("relative overflow-hidden rounded-t-lg") do
          media
        end
      end
      
      # Header
      if header?
        div.tw("px-6 py-4 border-b border-gray-200") do
          header
        end
      end
      
      # Content
      div.tw(PADDING_CLASSES[padding]) do
        if content?
          content
        else
          yield if block_given?
        end
      end
      
      # Footer
      if footer?
        div.tw("px-6 py-4 border-t border-gray-200 bg-gray-50") do
          footer
        end
      end
    end
    .tw(base_classes)
    .tw(variant_classes)
    .tw(hover_effect ? "hover:shadow-lg hover:-translate-y-0.5 transform" : "")
    .tw(clickable ? "cursor-pointer" : "")
  end
  
  private
  
  def base_classes
    "bg-white rounded-lg transition-all duration-200"
  end
  
  def variant_classes
    case variant
    when :elevated
      "shadow-md"
    when :outlined
      "border border-gray-200"
    when :filled
      "bg-gray-50"
    else
      ""
    end
  end
end