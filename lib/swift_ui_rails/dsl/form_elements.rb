# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # Form-related components for SwiftUI Rails DSL
    module FormElements
      def form(**attrs, &block)
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
        create_element(:label, nil, **attrs) do
          concat(tag.input(type: 'checkbox', checked: is_on))
          concat(tag.span(label_text))
        end
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