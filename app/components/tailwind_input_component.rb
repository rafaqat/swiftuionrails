class TailwindInputComponent < SwiftUIComponent
  prop :name, type: String, required: true
  prop :label, type: String
  prop :type, type: Symbol, default: :text
  prop :value, type: [String, Numeric, TrueClass, FalseClass]
  prop :placeholder, type: String
  prop :help_text, type: String
  prop :error, type: String
  prop :required, type: [TrueClass, FalseClass], default: false
  prop :disabled, type: [TrueClass, FalseClass], default: false
  prop :size, type: Symbol, default: :md
  
  state :focused, false
  state :touched, false
  
  SIZE_CLASSES = {
    sm: "px-3 py-1.5 text-sm",
    md: "px-3 py-2 text-sm",
    lg: "px-4 py-3 text-base"
  }.freeze
  
  swift_ui do
    div.tw("w-full") do
      # Label
      if label
        label(for: input_id).tw("block text-sm font-medium text-gray-700 mb-1") do
          text(label)
          if required
            span.tw("text-red-500 ml-1") { text("*") }
          end
        end
      end
      
      # Input field
      case type
      when :textarea
        textarea(
          name: name,
          id: input_id,
          placeholder: placeholder,
          rows: 4,
          disabled: disabled
        ).tw(textarea_classes) { value }
      when :select
        select(
          name: name,
          id: input_id,
          disabled: disabled
        ).tw(input_classes) do
          if placeholder
            option(value: "").tw("text-gray-500") { placeholder }
          end
          yield if block_given?
        end
      when :checkbox
        div.tw("flex items-center") do
          input(
            type: "checkbox",
            name: name,
            id: input_id,
            value: "1",
            checked: value,
            disabled: disabled
          ).tw("h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded")
          
          if label
            label(for: input_id).tw("ml-2 block text-sm text-gray-900") { text(label) }
          end
        end
      when :radio
        # Radio buttons would be handled by a RadioGroupComponent
        yield if block_given?
      when :toggle
        label(for: input_id).tw("flex items-center cursor-pointer") do
          div.tw("relative") do
            input(
              type: "checkbox",
              name: name,
              id: input_id,
              value: "1",
              checked: value,
              disabled: disabled
            ).tw("sr-only peer")
            
            div.tw("w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600")
          end
          
          if label
            span.tw("ml-3 text-sm font-medium text-gray-900") { text(label) }
          end
        end
      else
        input(
          type: type,
          name: name,
          id: input_id,
          value: value,
          placeholder: placeholder,
          disabled: disabled
        ).tw(input_classes)
      end
      
      # Help text or error
      if error
        p.tw("mt-1 text-sm text-red-600") { text(error) }
      elsif help_text
        p.tw("mt-1 text-sm text-gray-500") { text(help_text) }
      end
    end
  end
  
  private
  
  def input_id
    @input_id ||= "#{name.gsub(/[\[\]]/, '_')}_#{SecureRandom.hex(4)}"
  end
  
  def input_classes
    classes = [
      "block w-full rounded-md shadow-sm",
      SIZE_CLASSES[size],
      "focus:ring-blue-500 focus:border-blue-500",
      error ? "border-red-300 text-red-900 placeholder-red-300" : "border-gray-300",
      disabled ? "bg-gray-50 cursor-not-allowed" : "",
      "transition duration-150 ease-in-out"
    ]
    classes.join(" ")
  end
  
  def textarea_classes
    input_classes + " resize-none"
  end
end