# frozen_string_literal: true

require 'spec_helper'
require 'swift_ui_rails/component'

RSpec.describe SwiftUIRails::Component::Base do
  # Test component for specs
  class TestComponent < described_class
    prop :title, type: String, required: true
    prop :count, type: Integer, default: 0
    prop :active, type: [TrueClass, FalseClass], default: false
    prop :items, type: Array, default: []
    prop :options, type: Hash, default: {}

    renders_one :header
    renders_many :actions

    swift_ui do
      div do
        text(title).font_size("xl")
        text(count.to_s) if count > 0
      end
    end
  end

  describe 'prop system' do
    context 'with required props' do
      it 'raises error when required prop is missing' do
        expect { TestComponent.new }.to raise_error(ArgumentError, /Missing required prop: title/)
      end

      it 'accepts required props' do
        component = TestComponent.new(title: 'Test')
        expect(component.title).to eq('Test')
      end
    end

    context 'with optional props' do
      it 'uses default values when not provided' do
        component = TestComponent.new(title: 'Test')
        expect(component.count).to eq(0)
        expect(component.active).to be false
        expect(component.items).to eq([])
        expect(component.options).to eq({})
      end

      it 'accepts provided values' do
        component = TestComponent.new(
          title: 'Test',
          count: 5,
          active: true,
          items: [1, 2, 3],
          options: { key: 'value' }
        )
        expect(component.count).to eq(5)
        expect(component.active).to be true
        expect(component.items).to eq([1, 2, 3])
        expect(component.options).to eq({ key: 'value' })
      end
    end

    context 'with type validation' do
      it 'validates prop types' do
        expect {
          TestComponent.new(title: 123)
        }.to raise_error(ArgumentError, /Invalid type for prop title/)
      end

      it 'allows correct types' do
        component = TestComponent.new(title: 'Valid String')
        expect(component.title).to eq('Valid String')
      end

      it 'handles union types' do
        component1 = TestComponent.new(title: 'Test', active: true)
        component2 = TestComponent.new(title: 'Test', active: false)
        expect(component1.active).to be true
        expect(component2.active).to be false
      end
    end
  end

  describe 'slots' do
    it 'supports single slots' do
      component = TestComponent.new(title: 'Test')
      expect(component).to respond_to(:with_header)
      expect(component).to respond_to(:header?)
    end

    it 'supports multiple slots' do
      component = TestComponent.new(title: 'Test')
      expect(component).to respond_to(:with_action)
      expect(component).to respond_to(:actions)
    end
  end

  describe 'swift_ui DSL' do
    it 'renders DSL content' do
      component = TestComponent.new(title: 'Hello World', count: 5)
      rendered = component.call
      
      expect(rendered).to include('Hello World')
      expect(rendered).to include('5')
    end

    it 'supports conditional rendering' do
      component1 = TestComponent.new(title: 'Test', count: 0)
      component2 = TestComponent.new(title: 'Test', count: 5)
      
      rendered1 = component1.call
      rendered2 = component2.call
      
      expect(rendered1).not_to include('0')
      expect(rendered2).to include('5')
    end
  end

  describe 'collection rendering' do
    class CollectionTestComponent < described_class
      prop :item, type: String, required: true
      prop :index, type: Integer, default: 0

      swift_ui do
        div do
          text("#{index}: #{item}")
        end
      end
    end

    it 'supports ViewComponent collection rendering' do
      items = ['Apple', 'Banana', 'Cherry']
      components = CollectionTestComponent.with_collection(items.map.with_index { |item, i| { item: item, index: i } })
      
      expect(components).to be_an(Array)
      expect(components.size).to eq(3)
    end
  end

  describe 'component composition' do
    class ParentComponent < described_class
      prop :title, type: String, required: true

      swift_ui do
        div do
          text(title)
          render ChildComponent.new(message: "Child of #{title}")
        end
      end
    end

    class ChildComponent < described_class
      prop :message, type: String, required: true

      swift_ui do
        span { text(message) }
      end
    end

    it 'supports nested components' do
      component = ParentComponent.new(title: 'Parent')
      rendered = component.call
      
      expect(rendered).to include('Parent')
      expect(rendered).to include('Child of Parent')
    end
  end

  describe 'security features' do
    class SecureComponent < described_class
      prop :user_input, type: String, required: true
      prop :css_value, type: String, default: 'red'
      prop :url, type: String, default: '#'

      swift_ui do
        div do
          # Text should be escaped
          text(user_input)
          # CSS should be validated
          div.style("color: #{css_value}")
          # URLs should be validated
          link("Click", destination: url)
        end
      end
    end

    it 'escapes HTML in text content' do
      component = SecureComponent.new(user_input: '<script>alert(1)</script>')
      rendered = component.call
      
      expect(rendered).not_to include('<script>')
      expect(rendered).to include('&lt;script&gt;')
    end

    it 'validates CSS values' do
      component = SecureComponent.new(
        user_input: 'Test',
        css_value: 'javascript:alert(1)'
      )
      rendered = component.call
      
      expect(rendered).not_to include('javascript:')
    end

    it 'validates URLs' do
      component = SecureComponent.new(
        user_input: 'Test',
        url: 'javascript:alert(1)'
      )
      rendered = component.call
      
      expect(rendered).not_to include('javascript:')
      expect(rendered).to include('href="#"')
    end
  end

  describe 'error handling' do
    class ErrorComponent < described_class
      prop :will_error, type: [TrueClass, FalseClass], default: false

      swift_ui do
        if will_error
          raise 'Intentional error'
        else
          text('No error')
        end
      end
    end

    it 'handles errors gracefully in development' do
      component = ErrorComponent.new(will_error: true)
      expect { component.call }.to raise_error('Intentional error')
    end
  end

  describe 'performance features' do
    it 'supports memoization' do
      expect(TestComponent.swift_ui_memoization_enabled).to be true
    end

    it 'generates consistent cache keys' do
      component1 = TestComponent.new(title: 'Test', count: 5)
      component2 = TestComponent.new(title: 'Test', count: 5)
      
      expect(component1.cache_key_with_version).to eq(component2.cache_key_with_version)
    end
  end

  describe 'DSL method chaining' do
    class ChainTestComponent < described_class
      prop :content, type: String, required: true

      swift_ui do
        div do
          text(content)
            .font_size("xl")
            .font_weight("bold")
            .text_color("blue-500")
            .bg("gray-100")
            .p(4)
            .rounded("lg")
            .shadow("md")
        end
      end
    end

    it 'supports method chaining' do
      component = ChainTestComponent.new(content: 'Chained')
      rendered = component.call
      
      expect(rendered).to include('text-xl')
      expect(rendered).to include('font-bold')
      expect(rendered).to include('text-blue-500')
      expect(rendered).to include('bg-gray-100')
      expect(rendered).to include('p-4')
      expect(rendered).to include('rounded-lg')
      expect(rendered).to include('shadow-md')
    end
  end
end