# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Form-related components for SwiftUI Rails DSL
    module FormElements
      # New Reactive Form component (SwiftUI-style)
      # Form(onSubmit: :save_data) { ... } -> Reactive (Live Component)
      # Form(action: "/users", method: :post) { ... } -> Standard Rails Form
      def Form(action: nil, method: nil, onSubmit: nil, **attrs, &block)
        if onSubmit
          # Reactive Form Mode
          attrs[:data] ||= {}
          attrs[:data][:controller] = class_names("reactive-form", attrs[:data][:controller])
          attrs[:data][:action] = class_names("submit->reactive-form#submit", attrs[:data][:action])
          attrs[:data][:reactive_form_submit_method_value] = onSubmit.to_s
          
          HTMLForm(**attrs, &block)
        elsif action
          # Standard Rails Form Mode (Secure)
          secure_form(action: action, method: method || 'POST', **attrs, &block)
        else
          # Fallback / Plain HTML Form
          HTMLForm(**attrs, &block)
        end
      end

      def HTMLForm(**attrs, &block)
        create_element(:form, nil, **attrs, &block)
      end

      # Secure form with CSRF protection
      def secure_form(action:, method: 'POST', **attrs)
        # Create the form element
        create_element(:form, nil, action: action, method: method.to_s.casecmp('GET').zero? ? 'GET' : 'POST', **attrs) do
          # Only add CSRF token if method is not GET and protection is enabled
          csrf_context = self.is_a?(SwiftUIRails::Component::Base) ? view_context : self

          if !method.to_s.casecmp('GET').zero? && respond_to?(:protect_against_forgery?) && protect_against_forgery? && respond_to?(:get_form_authenticity_token)
            token = get_form_authenticity_token
            param = respond_to?(:request_forgery_protection_token) ? request_forgery_protection_token : :authenticity_token

            create_element(:input, nil,
                           type: 'hidden',
                           name: param.to_s,
                           value: token,
                           autocomplete: 'off')
          end

          # Add method override for non-POST/GET methods
          if %w[PUT PATCH DELETE].include?(method.to_s.upcase)
            create_element(:input, nil,
                           type: 'hidden',
                           name: '_method',
                           value: method.to_s.downcase,
                           autocomplete: 'off')
          end

          # Yield for form contents
          yield if block_given?
        end
      end

      def button(title = nil, **attrs, &block)
        # Pure structure - no behavior. Behavior is handled by Stimulus
        if block_given?
          create_element(:button, nil, **attrs, &block)
        else
          create_element(:button, title, **attrs)
        end
      end

      def input(**attrs, &block)
        create_element(:input, nil, **attrs, &block)
      end

      def textfield(placeholder: '', value: '', **attrs)
        attrs[:type] ||= 'text'
        attrs[:placeholder] = placeholder
        attrs[:value] = value
        create_element(:input, nil, **attrs)
      end

      def textarea(**attrs, &block)
        create_element(:textarea, nil, **attrs, &block)
      end

      def label(text_content = nil, for_input: nil, **attrs, &block)
        attrs[:for] = for_input if for_input
        if block_given?
          create_element(:label, nil, **attrs, &block)
        elsif text_content
          create_element(:label, text_content, **attrs)
        else
          create_element(:label, nil, **attrs)
        end
      end

      def select(name: nil, selected: nil, **attrs, &block)
        attrs[:name] = name if name
        attrs[:value] = selected if selected
        create_element(:select, nil, **attrs, &block)
      end

      def option(value, text_content = nil, selected: false, **attrs)
        attrs[:value] = value
        attrs[:selected] = selected if selected
        content = text_content || value
        create_element(:option, content, **attrs)
      end

      def toggle(label_text, is_on: false, **attrs)
        # iOS-style toggle switch
        hstack(justify: :between, alignment: :center, **attrs) do
          text(label_text).font(:body)
          
          # The Toggle Switch
          label(class: "relative inline-flex items-center cursor-pointer") do
            input(type: "checkbox", checked: is_on, class: "sr-only peer")
            div(class: "w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600")
          end
        end.padding(:y, 2)
      end

      def slider(value: 50, min: 0, max: 100, step: 1, **attrs)
        attrs[:type] = 'range'
        attrs[:value] = value
        attrs[:min] = min
        attrs[:max] = max
        attrs[:step] = step
        create_element(:input, nil, **attrs)
      end
    end
  end
end