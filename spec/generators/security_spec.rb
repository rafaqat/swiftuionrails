# frozen_string_literal: true

require 'spec_helper'
require 'generators/swift_ui_rails/component/component_generator'
require 'generators/swift_ui_rails/stories/stories_generator'

# Mock ApplicationComponent for tests
class ApplicationComponent < ViewComponent::Base
end unless defined?(ApplicationComponent)

RSpec.describe 'Generator Security' do
  describe 'Path Traversal Prevention' do
    let(:generator) { SwiftUIRails::Generators::ComponentGenerator.new(['../../etc/passwd']) }

    it 'sanitizes path traversal attempts in component names' do
      # Access protected methods via send
      expect(generator.send(:class_path)).not_to include('..')
      expect(generator.send(:class_path).join('/')).not_to include('..')
      expect(generator.send(:file_name)).not_to include('..')
      expect(generator.send(:file_name)).not_to include('/')
    end

    it 'removes directory traversal sequences' do
      generator = SwiftUIRails::Generators::ComponentGenerator.new(['../../../root/Component'])
      # The '../' parts get converted to '__' by the sanitizer
      expect(generator.send(:class_path)).to eq(['__', '__', '__', 'root'])
      # Or we can just check that no '..' remains
      expect(generator.send(:class_path).join('/')).not_to include('..')
      expect(generator.send(:file_name)).to eq('component')
    end
  end

  describe 'Command Injection Prevention' do
    it 'validates component names against dangerous patterns' do
      dangerous_names = [
        'Component;rm -rf /',
        'Component`echo hacked`',
        'Component$(whoami)',
        'Component|cat /etc/passwd',
        'Component&& evil_command'
      ]

      dangerous_names.each do |name|
        expect {
          generator = SwiftUIRails::Generators::ComponentGenerator.new([name])
          generator.validate_all_inputs
        }.to raise_error(Thor::Error)
      end
    end

    it 'prevents eval-like method names' do
      forbidden_names = %w[system exec eval constantize send public_send instance_eval class_eval module_eval]
      
      forbidden_names.each do |name|
        expect {
          generator = SwiftUIRails::Generators::ComponentGenerator.new([name])
          generator.validate_all_inputs
        }.to raise_error(Thor::Error, /forbidden keywords/)
      end
    end
  end

  describe 'ReDoS Prevention' do
    it 'handles malicious regex input safely' do
      # Create a string that would cause ReDoS with vulnerable regex
      malicious_input = 'A' * 100 + '::' * 50 + 'B' * 100
      
      generator = SwiftUIRails::Generators::ComponentGenerator.new(['TestComponent', "prop:#{malicious_input}"])
      
      # Should complete quickly without hanging
      expect {
        Timeout.timeout(1) do
          generator.send(:sanitize_type, malicious_input)
        end
      }.not_to raise_error
    end

    it 'sanitizes type strings efficiently' do
      generator = SwiftUIRails::Generators::ComponentGenerator.new(['TestComponent'])
      
      result = generator.send(:sanitize_type, 'String<>!@#$%^&*()')
      expect(result).to eq('String')
      
      result = generator.send(:sanitize_type, 'ActiveRecord::Base<script>')
      expect(result).to eq('ActiveRecord::Base')
    end
  end

  describe 'Prop Validation' do
    it 'validates prop names for security' do
      generator = SwiftUIRails::Generators::ComponentGenerator.new(['Component', 'name:String;DROP TABLE', 'email:String'])
      
      expect {
        generator.validate_all_inputs
      }.to raise_error(Thor::Error, /suspicious characters/)
    end

    it 'prevents reserved word usage as prop names' do
      generator = SwiftUIRails::Generators::ComponentGenerator.new(['Component', 'class:String'])
      
      expect {
        generator.validate_all_inputs
      }.to raise_error(Thor::Error, /reserved word/)
    end
  end

  describe 'Safe Constantize' do
    before do
      # Create a test component class
      stub_const('TestComponent', Class.new(ApplicationComponent))
    end

    it 'only allows valid component class names' do
      generator = SwiftUIRails::Generators::StoriesGenerator.new(['Test'])
      
      # Valid component
      expect(generator.send(:component_class)).to eq(TestComponent)
      
      # Invalid component names should return nil
      generator = SwiftUIRails::Generators::StoriesGenerator.new(['../../etc/passwd'])
      expect(generator.send(:component_class)).to be_nil
      
      generator = SwiftUIRails::Generators::StoriesGenerator.new(['Kernel'])
      expect(generator.send(:component_class)).to be_nil
    end
  end
end