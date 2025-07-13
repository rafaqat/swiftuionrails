# frozen_string_literal: true

require 'spec_helper'
require 'swift_ui_rails'

RSpec.describe SwiftUIRails::Security::UrlValidator do
  let(:validator) { described_class.new }

  describe '#validate_url' do
    context 'with safe URLs' do
      it 'allows standard HTTP/HTTPS URLs' do
        expect(validator.validate_url('http://example.com')).to be true
        expect(validator.validate_url('https://example.com')).to be true
        expect(validator.validate_url('https://example.com/path/to/page')).to be true
        expect(validator.validate_url('https://example.com/page?param=value')).to be true
        expect(validator.validate_url('https://example.com/page#anchor')).to be true
      end

      it 'allows relative URLs' do
        expect(validator.validate_url('/path/to/page')).to be true
        expect(validator.validate_url('../relative/path')).to be true
        expect(validator.validate_url('./current/path')).to be true
        expect(validator.validate_url('page.html')).to be true
      end

      it 'allows mailto URLs' do
        expect(validator.validate_url('mailto:user@example.com')).to be true
        expect(validator.validate_url('mailto:user@example.com?subject=Hello')).to be true
      end

      it 'allows tel URLs' do
        expect(validator.validate_url('tel:+1234567890')).to be true
        expect(validator.validate_url('tel:555-1234')).to be true
      end

      it 'allows anchor links' do
        expect(validator.validate_url('#section')).to be true
        expect(validator.validate_url('#top')).to be true
      end

      it 'allows data URLs for images' do
        expect(validator.validate_url('data:image/png;base64,iVBORw0KG')).to be true
        expect(validator.validate_url('data:image/jpeg;base64,/9j/4AAQ')).to be true
        expect(validator.validate_url('data:image/gif;base64,R0lGODlh')).to be true
        expect(validator.validate_url('data:image/svg+xml;base64,PHN2Zy')).to be true
      end
    end

    context 'with dangerous URLs' do
      it 'blocks JavaScript URLs' do
        expect(validator.validate_url('javascript:alert(1)')).to be false
        expect(validator.validate_url('JAVASCRIPT:alert(1)')).to be false
        expect(validator.validate_url('   javascript:alert(1)')).to be false
        expect(validator.validate_url('java\0script:alert(1)')).to be false
      end

      it 'blocks VBScript URLs' do
        expect(validator.validate_url('vbscript:msgbox(1)')).to be false
        expect(validator.validate_url('VBSCRIPT:msgbox(1)')).to be false
      end

      it 'blocks data URLs with HTML/scripts' do
        expect(validator.validate_url('data:text/html,<script>alert(1)</script>')).to be false
        expect(validator.validate_url('data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==')).to be false
        expect(validator.validate_url('data:application/javascript,alert(1)')).to be false
      end

      it 'blocks file URLs' do
        expect(validator.validate_url('file:///etc/passwd')).to be false
        expect(validator.validate_url('FILE:///C:/Windows/System32/config')).to be false
      end

      it 'blocks about URLs' do
        expect(validator.validate_url('about:blank')).to be false
        expect(validator.validate_url('about:config')).to be false
      end

      it 'blocks chrome URLs' do
        expect(validator.validate_url('chrome://settings')).to be false
        expect(validator.validate_url('chrome-extension://abc123')).to be false
      end

      it 'blocks ws/wss URLs' do
        expect(validator.validate_url('ws://evil.com')).to be false
        expect(validator.validate_url('wss://evil.com')).to be false
      end

      it 'blocks URLs with encoded attacks' do
        expect(validator.validate_url('java%73cript:alert(1)')).to be false
        expect(validator.validate_url('%6A%61%76%61%73%63%72%69%70%74:alert(1)')).to be false
        expect(validator.validate_url('&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;:alert(1)')).to be false
      end

      it 'blocks URLs with null bytes' do
        expect(validator.validate_url("https://example.com\0javascript:alert(1)")).to be false
        expect(validator.validate_url("https://example.com\x00javascript:alert(1)")).to be false
      end
    end

    context 'with edge cases' do
      it 'handles empty values' do
        expect(validator.validate_url('')).to be true
        expect(validator.validate_url(nil)).to be true
      end

      it 'handles URLs with special characters' do
        expect(validator.validate_url('https://example.com/path with spaces')).to be true
        expect(validator.validate_url('https://example.com/path%20with%20spaces')).to be true
        expect(validator.validate_url('https://example.com/path?q=hello+world')).to be true
      end

      it 'handles international domains' do
        expect(validator.validate_url('https://例え.jp')).to be true
        expect(validator.validate_url('https://münchen.de')).to be true
      end

      it 'blocks mixed case protocol attacks' do
        expect(validator.validate_url('jAvAsCrIpT:alert(1)')).to be false
        expect(validator.validate_url('VbScRiPt:msgbox(1)')).to be false
      end
    end

    context 'with logging' do
      it 'logs blocked attempts with details' do
        allow(Rails.logger).to receive(:warn)
        
        validator.validate_url('javascript:alert(1)')
        
        expect(Rails.logger).to have_received(:warn).with(/URL Injection attempt blocked/)
      end
    end
  end

  describe '#safe_url' do
    it 'returns safe URLs unchanged' do
      expect(validator.safe_url('https://example.com')).to eq('https://example.com')
      expect(validator.safe_url('/path/to/page')).to eq('/path/to/page')
    end

    it 'returns # for dangerous URLs' do
      expect(validator.safe_url('javascript:alert(1)')).to eq('#')
      expect(validator.safe_url('vbscript:msgbox(1)')).to eq('#')
    end

    it 'uses custom fallback when provided' do
      expect(validator.safe_url('javascript:alert(1)', '/')).to eq('/')
      expect(validator.safe_url('vbscript:msgbox(1)', '/home')).to eq('/home')
    end
  end

  describe '#extract_domain' do
    it 'extracts domain from URLs' do
      expect(validator.send(:extract_domain, 'https://example.com/path')).to eq('example.com')
      expect(validator.send(:extract_domain, 'http://subdomain.example.com')).to eq('subdomain.example.com')
      expect(validator.send(:extract_domain, 'https://example.com:8080')).to eq('example.com')
    end

    it 'returns nil for invalid URLs' do
      expect(validator.send(:extract_domain, 'not-a-url')).to be_nil
      expect(validator.send(:extract_domain, 'javascript:alert(1)')).to be_nil
    end
  end

  describe '#check_approved_domain' do
    before do
      allow(SwiftUIRails.configuration).to receive(:domain_approved?).and_return(true)
    end

    it 'checks domain approval for external URLs' do
      expect(SwiftUIRails.configuration).to receive(:domain_approved?).with('example.com')
      validator.validate_url('https://example.com/image.jpg')
    end

    it 'does not check for relative URLs' do
      expect(SwiftUIRails.configuration).not_to receive(:domain_approved?)
      validator.validate_url('/local/image.jpg')
    end
  end
end