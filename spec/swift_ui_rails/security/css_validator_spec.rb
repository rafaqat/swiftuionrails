# frozen_string_literal: true

require 'spec_helper'
require 'swift_ui_rails'

RSpec.describe SwiftUIRails::Security::CssValidator do
  let(:validator) { described_class.new }

  describe '#validate_css_value' do
    context 'with safe CSS values' do
      it 'allows standard color values' do
        expect(validator.validate_css_value('red')).to be true
        expect(validator.validate_css_value('#FF0000')).to be true
        expect(validator.validate_css_value('rgb(255, 0, 0)')).to be true
        expect(validator.validate_css_value('rgba(255, 0, 0, 0.5)')).to be true
        expect(validator.validate_css_value('hsl(0, 100%, 50%)')).to be true
      end

      it 'allows standard units' do
        expect(validator.validate_css_value('10px')).to be true
        expect(validator.validate_css_value('2em')).to be true
        expect(validator.validate_css_value('100%')).to be true
        expect(validator.validate_css_value('5rem')).to be true
        expect(validator.validate_css_value('50vh')).to be true
        expect(validator.validate_css_value('100vw')).to be true
      end

      it 'allows calc expressions' do
        expect(validator.validate_css_value('calc(100% - 20px)')).to be true
        expect(validator.validate_css_value('calc(50vh + 10px)')).to be true
      end

      it 'allows CSS variables' do
        expect(validator.validate_css_value('var(--primary-color)')).to be true
        expect(validator.validate_css_value('var(--spacing-unit, 8px)')).to be true
      end

      it 'allows gradients' do
        expect(validator.validate_css_value('linear-gradient(to right, red, blue)')).to be true
        expect(validator.validate_css_value('radial-gradient(circle, yellow, green)')).to be true
      end

      it 'allows transforms' do
        expect(validator.validate_css_value('translateX(10px)')).to be true
        expect(validator.validate_css_value('rotate(45deg)')).to be true
        expect(validator.validate_css_value('scale(1.5)')).to be true
      end

      it 'allows common keywords' do
        expect(validator.validate_css_value('auto')).to be true
        expect(validator.validate_css_value('inherit')).to be true
        expect(validator.validate_css_value('initial')).to be true
        expect(validator.validate_css_value('unset')).to be true
        expect(validator.validate_css_value('none')).to be true
      end
    end

    context 'with dangerous CSS values' do
      it 'blocks JavaScript URLs' do
        expect(validator.validate_css_value('javascript:alert(1)')).to be false
        expect(validator.validate_css_value('JAVASCRIPT:alert(1)')).to be false
        expect(validator.validate_css_value('   javascript:alert(1)')).to be false
      end

      it 'blocks data URLs with scripts' do
        expect(validator.validate_css_value('data:text/html,<script>alert(1)</script>')).to be false
        expect(validator.validate_css_value('data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==')).to be false
      end

      it 'blocks expression() function' do
        expect(validator.validate_css_value('expression(alert(1))')).to be false
        expect(validator.validate_css_value('EXPRESSION(alert(1))')).to be false
        expect(validator.validate_css_value('width:expression(alert(1))')).to be false
      end

      it 'blocks @import statements' do
        expect(validator.validate_css_value('@import url("evil.css")')).to be false
        expect(validator.validate_css_value('@IMPORT url("evil.css")')).to be false
      end

      it 'blocks script tags' do
        expect(validator.validate_css_value('<script>alert(1)</script>')).to be false
        expect(validator.validate_css_value('</style><script>alert(1)</script>')).to be false
      end

      it 'blocks eval-like patterns' do
        expect(validator.validate_css_value('eval(alert(1))')).to be false
        expect(validator.validate_css_value('setTimeout(alert, 1000)')).to be false
        expect(validator.validate_css_value('setInterval(alert, 1000)')).to be false
      end

      it 'blocks vbscript' do
        expect(validator.validate_css_value('vbscript:msgbox(1)')).to be false
        expect(validator.validate_css_value('VBSCRIPT:msgbox(1)')).to be false
      end

      it 'blocks moz-binding' do
        expect(validator.validate_css_value('-moz-binding: url("evil.xml")')).to be false
        expect(validator.validate_css_value('binding: url("evil.xml")')).to be false
      end

      it 'blocks behavior property' do
        expect(validator.validate_css_value('behavior: url("evil.htc")')).to be false
        expect(validator.validate_css_value('-ms-behavior: url("evil.htc")')).to be false
      end
    end

    context 'with edge cases' do
      it 'handles empty values' do
        expect(validator.validate_css_value('')).to be true
        expect(validator.validate_css_value(nil)).to be true
      end

      it 'handles complex valid expressions' do
        expect(validator.validate_css_value('cubic-bezier(0.4, 0, 0.2, 1)')).to be true
        expect(validator.validate_css_value('drop-shadow(0 10px 8px rgb(0 0 0 / 0.04))')).to be true
      end

      it 'blocks obfuscated attacks' do
        expect(validator.validate_css_value('java\0script:alert(1)')).to be false
        expect(validator.validate_css_value('java\tscript:alert(1)')).to be false
        expect(validator.validate_css_value('java\nscript:alert(1)')).to be false
      end
    end

    context 'with logging' do
      it 'logs blocked attempts' do
        allow(Rails.logger).to receive(:warn)
        
        validator.validate_css_value('javascript:alert(1)')
        
        expect(Rails.logger).to have_received(:warn).with(/CSS Injection attempt blocked/)
      end
    end
  end

  describe '#safe_css_value' do
    it 'returns safe values unchanged' do
      expect(validator.safe_css_value('red')).to eq('red')
      expect(validator.safe_css_value('10px')).to eq('10px')
    end

    it 'returns inherit for dangerous values' do
      expect(validator.safe_css_value('javascript:alert(1)')).to eq('inherit')
      expect(validator.safe_css_value('expression(alert(1))')).to eq('inherit')
    end

    it 'uses custom fallback when provided' do
      expect(validator.safe_css_value('javascript:alert(1)', 'none')).to eq('none')
      expect(validator.safe_css_value('expression(alert(1))', 'auto')).to eq('auto')
    end
  end
end