# frozen_string_literal: true

require 'spec_helper'
require 'swift_ui_rails/deprecations'

RSpec.describe SwiftUIRails::Deprecations do
  describe '.warn_if_removed' do
    it 'warns for removed components' do
      expect {
        described_class.warn_if_removed('ProductListComponent')
      }.to output(/DEPRECATION.*ProductListComponent has been removed/).to_stderr
    end

    it 'warns for EnhancedProductListComponent' do
      expect {
        described_class.warn_if_removed('EnhancedProductListComponent')
      }.to output(/Use DSL-based product cards/).to_stderr
    end

    it 'warns for renamed components' do
      expect {
        described_class.warn_if_removed('SwiftUIComponent')
      }.to output(/renamed to SwiftUIRails::Component::Base/).to_stderr
    end

    it 'does not warn for valid components' do
      expect {
        described_class.warn_if_removed('ValidComponent')
      }.not_to output.to_stderr
    end
  end

  describe '.check_component_usage' do
    it 'checks component class names' do
      # Mock a component class
      klass = double('ComponentClass')
      allow(klass).to receive(:name).and_return('MyModule::ProductListComponent')
      
      expect {
        described_class.check_component_usage(klass)
      }.to output(/ProductListComponent has been removed/).to_stderr
    end
    
    it 'handles namespaced components' do
      klass = double('ComponentClass')
      allow(klass).to receive(:name).and_return('Admin::EnhancedProductListComponent')
      
      expect {
        described_class.check_component_usage(klass)
      }.to output(/EnhancedProductListComponent has been removed/).to_stderr
    end
  end

  describe 'Rails logger integration' do
    before do
      @original_logger = Rails.logger if defined?(Rails)
      Rails.logger = Logger.new(StringIO.new) if defined?(Rails)
    end

    after do
      Rails.logger = @original_logger if defined?(Rails)
    end

    it 'logs to Rails logger when available' do
      if defined?(Rails) && Rails.logger
        expect(Rails.logger).to receive(:warn).with(/ProductListComponent has been removed/)
        described_class.warn_if_removed('ProductListComponent')
      end
    end
  end
end