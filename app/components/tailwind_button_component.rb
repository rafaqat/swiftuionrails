class TailwindButtonComponent < SwiftUIComponent
  prop :title, type: String, required: true
  prop :variant, type: Symbol, default: :primary
  prop :size, type: Symbol, default: :md
  prop :disabled, type: [TrueClass, FalseClass], default: false
  prop :loading, type: [TrueClass, FalseClass], default: false
  prop :icon, type: String
  prop :icon_position, type: Symbol, default: :left
  prop :full_width, type: [TrueClass, FalseClass], default: false
  prop :on_click, type: String
  
  state :hover, false
  state :pressed, false
  
  VARIANT_CLASSES = {
    primary: "bg-blue-600 hover:bg-blue-700 text-white focus:ring-blue-500",
    secondary: "bg-gray-200 hover:bg-gray-300 text-gray-900 focus:ring-gray-500",
    success: "bg-green-600 hover:bg-green-700 text-white focus:ring-green-500",
    danger: "bg-red-600 hover:bg-red-700 text-white focus:ring-red-500",
    warning: "bg-yellow-500 hover:bg-yellow-600 text-white focus:ring-yellow-500",
    info: "bg-blue-500 hover:bg-blue-600 text-white focus:ring-blue-500",
    ghost: "bg-transparent hover:bg-gray-100 text-gray-700 focus:ring-gray-500",
    link: "bg-transparent hover:bg-transparent text-blue-600 hover:text-blue-700 underline-offset-4 hover:underline"
  }.freeze
  
  SIZE_CLASSES = {
    xs: "px-2.5 py-1.5 text-xs",
    sm: "px-3 py-2 text-sm",
    md: "px-4 py-2 text-sm",
    lg: "px-4 py-2 text-base",
    xl: "px-6 py-3 text-base"
  }.freeze
  
  swift_ui do
    button(on_click || "#") do
      hstack(spacing: 0) do
        if loading
          spinner(size: size_to_spinner_size(size)).mr(2)
        elsif icon && icon_position == :left
          icon(icon, size: size_to_icon_size(size)).mr(2)
        end
        
        text(title)
        
        if icon && !loading && icon_position == :right
          icon(icon, size: size_to_icon_size(size)).ml(2)
        end
      end
    end
    .tw(base_classes)
    .tw(VARIANT_CLASSES[variant])
    .tw(SIZE_CLASSES[size])
    .tw(full_width ? "w-full justify-center" : "inline-flex")
    .tw(disabled || loading ? "opacity-50 cursor-not-allowed" : "")
    .disabled(disabled || loading)
  end
  
  private
  
  def base_classes
    "inline-flex items-center font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors duration-200"
  end
  
  def size_to_spinner_size(size)
    { xs: :xs, sm: :sm, md: :sm, lg: :md, xl: :lg }[size]
  end
  
  def size_to_icon_size(size)
    { xs: 16, sm: 16, md: 20, lg: 20, xl: 24 }[size]
  end
end