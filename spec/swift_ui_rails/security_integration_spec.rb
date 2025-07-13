# frozen_string_literal: true

require 'spec_helper'
require 'swift_ui_rails'

RSpec.describe 'Security Integration' do
  class VulnerableComponent < SwiftUIRails::Component::Base
    prop :user_input, type: String, required: true
    prop :style_input, type: String, default: ''
    prop :url_input, type: String, default: '#'
    prop :class_input, type: String, default: ''

    swift_ui do
      div do
        # Various injection vectors
        text(user_input)
        div.style(style_input)
        link('Click', destination: url_input)
        div(class: class_input) { text('Content') }
      end
    end
  end

  describe 'XSS Prevention' do
    let(:xss_payloads) do
      [
        '<script>alert("XSS")</script>',
        '"><script>alert("XSS")</script>',
        '<img src=x onerror=alert("XSS")>',
        '<svg onload=alert("XSS")>',
        'javascript:alert("XSS")',
        '<iframe src="javascript:alert(\'XSS\')"></iframe>',
        '<body onload=alert("XSS")>',
        '<input onfocus=alert("XSS") autofocus>',
        '<select onfocus=alert("XSS") autofocus>',
        '<textarea onfocus=alert("XSS") autofocus>',
        '<marquee onstart=alert("XSS")>',
        '<details open ontoggle=alert("XSS")>',
        '<<SCRIPT>alert("XSS");//<</SCRIPT>',
        '<script src=https://evil.com/xss.js></script>',
        '<a href="javascript:void(0)" onclick="alert(\'XSS\')">Click</a>'
      ]
    end

    it 'prevents XSS in text content' do
      xss_payloads.each do |payload|
        component = VulnerableComponent.new(user_input: payload)
        rendered = component.call
        
        # Should not contain unescaped script tags
        expect(rendered).not_to include('<script')
        expect(rendered).not_to include('alert(')
        expect(rendered).not_to include('onerror=')
        expect(rendered).not_to include('onload=')
        expect(rendered).not_to include('onclick=')
      end
    end
  end

  describe 'CSS Injection Prevention' do
    let(:css_injection_payloads) do
      [
        'expression(alert("XSS"))',
        'url("javascript:alert(\'XSS\')")',
        'url(\'javascript:alert("XSS")\')',
        'url(data:text/html,<script>alert("XSS")</script>)',
        '-moz-binding: url("http://evil.com/xss.xml#xss")',
        'behavior: url("http://evil.com/xss.htc")',
        'background: url("javascript:alert(\'XSS\')")',
        '@import url("http://evil.com/evil.css")',
        'width: expression(alert("XSS")); color: red',
        '</style><script>alert("XSS")</script><style>',
        'background-image: url("javascript:alert(\'XSS\')")',
        'list-style-image: url("javascript:alert(\'XSS\')")',
        'cursor: url("javascript:alert(\'XSS\')")',
        'content: url("javascript:alert(\'XSS\')")'
      ]
    end

    it 'prevents CSS injection attacks' do
      css_injection_payloads.each do |payload|
        component = VulnerableComponent.new(
          user_input: 'Safe',
          style_input: payload
        )
        rendered = component.call
        
        # Should not contain dangerous CSS
        expect(rendered).not_to include('expression(')
        expect(rendered).not_to include('javascript:')
        expect(rendered).not_to include('@import')
        expect(rendered).not_to include('<script')
        expect(rendered).not_to include('behavior:')
        expect(rendered).not_to include('-moz-binding:')
      end
    end
  end

  describe 'URL Injection Prevention' do
    let(:url_injection_payloads) do
      [
        'javascript:alert("XSS")',
        'JaVaScRiPt:alert("XSS")',
        'javascript:void(0)',
        'vbscript:msgbox("XSS")',
        'data:text/html,<script>alert("XSS")</script>',
        'data:text/html;base64,PHNjcmlwdD5hbGVydCgiWFNTIik8L3NjcmlwdD4=',
        'file:///etc/passwd',
        'about:blank',
        'chrome://settings',
        'javascript\x00:alert("XSS")',
        'java\tscript:alert("XSS")',
        'java\nscript:alert("XSS")',
        'java\rscript:alert("XSS")',
        '&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;:alert("XSS")',
        'jav%61script:alert("XSS")',
        'javascript&#58;alert("XSS")',
        'javascript&#x3A;alert("XSS")'
      ]
    end

    it 'prevents URL injection attacks' do
      url_injection_payloads.each do |payload|
        component = VulnerableComponent.new(
          user_input: 'Safe',
          url_input: payload
        )
        rendered = component.call
        
        # Should not contain dangerous URLs
        expect(rendered).not_to match(/javascript:/i)
        expect(rendered).not_to match(/vbscript:/i)
        expect(rendered).not_to include('file://')
        expect(rendered).not_to include('about:')
        expect(rendered).not_to include('chrome://')
        
        # Should use safe fallback
        expect(rendered).to include('href="#"')
      end
    end
  end

  describe 'Class Injection Prevention' do
    let(:class_injection_payloads) do
      [
        'valid-class onclick=alert("XSS")',
        'valid-class" onclick="alert(\'XSS\')" class="other',
        'valid-class\' onclick=\'alert("XSS")\' class=\'other',
        'valid-class"><script>alert("XSS")</script><div class="',
        'valid-class; expression(alert("XSS"))',
        'valid-class" style="expression(alert(\'XSS\'))"'
      ]
    end

    it 'prevents class attribute injection' do
      class_injection_payloads.each do |payload|
        component = VulnerableComponent.new(
          user_input: 'Safe',
          class_input: payload
        )
        rendered = component.call
        
        # Should not break out of class attribute
        expect(rendered).not_to include('onclick=')
        expect(rendered).not_to include('<script')
        expect(rendered).not_to include('expression(')
        expect(rendered).not_to include('style=')
      end
    end
  end

  describe 'Multi-vector Attacks' do
    it 'prevents polyglot attacks' do
      polyglot = 'jaVasCript:/*-/*`/*\`/*\'/*"/**/(/* */oNcliCk=alert() )//%0D%0A%0d%0a//</stYle/</titLe/</teXtarEa/</scRipt/--!>\x3csVg/<sVg/oNloAd=alert()//>\x3e'
      
      component = VulnerableComponent.new(
        user_input: polyglot,
        style_input: polyglot,
        url_input: polyglot,
        class_input: polyglot
      )
      rendered = component.call
      
      # Should not execute any part of the polyglot
      expect(rendered).not_to match(/javascript:/i)
      expect(rendered).not_to include('alert(')
      expect(rendered).not_to include('oNcliCk')
      expect(rendered).not_to include('oNloAd')
      expect(rendered).not_to include('<svg')
    end
  end

  describe 'Rate Limiting' do
    before do
      SwiftUIRails::Security::RateLimiter.instance.reset('test-action')
    end

    it 'prevents rapid-fire attacks' do
      threshold = SwiftUIRails.configuration.rate_limit_threshold
      
      # Should allow up to threshold requests
      threshold.times do |i|
        expect(SwiftUIRails::Security::RateLimiter.instance.check('test-action')).to be true
      end
      
      # Should block after threshold
      expect(SwiftUIRails::Security::RateLimiter.instance.check('test-action')).to be false
    end
  end

  describe 'Content Security Policy' do
    it 'generates secure CSP headers' do
      csp = SwiftUIRails::Security::ContentSecurityPolicy.new
      header = csp.header_value
      
      expect(header).to include("default-src 'self'")
      expect(header).to include("script-src 'self'")
      expect(header).to include("style-src 'self'")
      expect(header).to include("img-src 'self'")
      expect(header).not_to include("'unsafe-inline'")
      expect(header).not_to include("'unsafe-eval'")
    end
  end

  describe 'Component Validation' do
    it 'validates component depth to prevent DoS' do
      # Create deeply nested component that would cause stack overflow
      
      class DeepComponent < SwiftUIRails::Component::Base
        def call
          depth = 0
          result = self
          while depth < 100
            result = div { result }
            depth += 1
          end
          result
        end
      end
      
      # Should have depth protection
      component = DeepComponent.new
      expect { component.call }.not_to raise_error(SystemStackError)
    end
  end

  describe 'Secure Form Helpers' do
    class FormComponent < SwiftUIRails::Component::Base
      include SwiftUIRails::Security::FormHelpers

      swift_ui do
        secure_form(action: '/submit', method: 'post') do
          textfield(name: 'email', type: 'email')
          button('Submit', type: 'submit')
        end
      end
    end

    it 'includes CSRF token in forms' do
      component = FormComponent.new
      rendered = component.call
      
      expect(rendered).to include('authenticity_token')
      expect(rendered).to include('<input type="hidden"')
    end
  end
end