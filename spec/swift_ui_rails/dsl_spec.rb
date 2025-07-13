# frozen_string_literal: true

require 'spec_helper'
require 'swift_ui_rails/dsl'

RSpec.describe SwiftUIRails::DSL do
  class DSLTestComponent < SwiftUIRails::Component::Base
    include SwiftUIRails::DSL
    
    def call
      render_dsl
    end
    
    def render_dsl(&block)
      instance_eval(&block)
    end
  end
  
  let(:component) { DSLTestComponent.new }

  describe 'layout components' do
    describe '#vstack' do
      it 'creates vertical stack with default spacing' do
        result = component.render_dsl do
          vstack do
            text('Item 1')
            text('Item 2')
          end
        end
        
        expect(result.to_s).to include('flex-col')
        expect(result.to_s).to include('space-y-4')
      end
      
      it 'accepts custom spacing' do
        result = component.render_dsl do
          vstack(spacing: 8) do
            text('Item 1')
          end
        end
        
        expect(result.to_s).to include('space-y-8')
      end
      
      it 'accepts alignment options' do
        result = component.render_dsl do
          vstack(align: :center) do
            text('Centered')
          end
        end
        
        expect(result.to_s).to include('items-center')
      end
    end
    
    describe '#hstack' do
      it 'creates horizontal stack' do
        result = component.render_dsl do
          hstack do
            text('Left')
            text('Right')
          end
        end
        
        expect(result.to_s).to include('flex-row')
        expect(result.to_s).to include('space-x-4')
      end
      
      it 'supports justify options' do
        result = component.render_dsl do
          hstack(justify: :between) do
            text('Start')
            text('End')
          end
        end
        
        expect(result.to_s).to include('justify-between')
      end
    end
    
    describe '#zstack' do
      it 'creates layered stack' do
        result = component.render_dsl do
          zstack do
            div.bg("blue-500").w("full").h(64)
            text('Overlay').text_color("white")
          end
        end
        
        expect(result.to_s).to include('relative')
        expect(result.to_s).to include('absolute')
      end
    end
    
    describe '#grid' do
      it 'creates grid layout' do
        result = component.render_dsl do
          grid(cols: 3, gap: 4) do
            3.times { |i| text("Item #{i}") }
          end
        end
        
        expect(result.to_s).to include('grid')
        expect(result.to_s).to include('grid-cols-3')
        expect(result.to_s).to include('gap-4')
      end
    end
  end

  describe 'basic elements' do
    describe '#text' do
      it 'creates text element' do
        result = component.render_dsl do
          text('Hello World')
        end
        
        expect(result.to_s).to include('Hello World')
      end
      
      it 'escapes HTML' do
        result = component.render_dsl do
          text('<script>alert(1)</script>')
        end
        
        expect(result.to_s).not_to include('<script>')
        expect(result.to_s).to include('&lt;script&gt;')
      end
    end
    
    describe '#button' do
      it 'creates button element' do
        result = component.render_dsl do
          button('Click Me')
        end
        
        expect(result.to_s).to include('<button')
        expect(result.to_s).to include('Click Me')
      end
      
      it 'supports type attribute' do
        result = component.render_dsl do
          button('Submit', type: 'submit')
        end
        
        expect(result.to_s).to include('type="submit"')
      end
    end
    
    describe '#link' do
      it 'creates link element' do
        result = component.render_dsl do
          link('Home', destination: '/')
        end
        
        expect(result.to_s).to include('<a')
        expect(result.to_s).to include('href="/"')
        expect(result.to_s).to include('Home')
      end
      
      it 'validates URLs' do
        result = component.render_dsl do
          link('Danger', destination: 'javascript:alert(1)')
        end
        
        expect(result.to_s).not_to include('javascript:')
        expect(result.to_s).to include('href="#"')
      end
    end
    
    describe '#image' do
      it 'creates image element' do
        result = component.render_dsl do
          image(src: '/logo.png', alt: 'Logo')
        end
        
        expect(result.to_s).to include('<img')
        expect(result.to_s).to include('src="/logo.png"')
        expect(result.to_s).to include('alt="Logo"')
      end
      
      it 'validates image URLs' do
        result = component.render_dsl do
          image(src: 'javascript:alert(1)', alt: 'XSS')
        end
        
        expect(result.to_s).not_to include('javascript:')
      end
    end
  end

  describe 'form elements' do
    describe '#textfield' do
      it 'creates input element' do
        result = component.render_dsl do
          textfield(name: 'email', placeholder: 'Enter email')
        end
        
        expect(result.to_s).to include('<input')
        expect(result.to_s).to include('type="text"')
        expect(result.to_s).to include('name="email"')
        expect(result.to_s).to include('placeholder="Enter email"')
      end
      
      it 'supports different input types' do
        result = component.render_dsl do
          textfield(name: 'password', type: 'password')
        end
        
        expect(result.to_s).to include('type="password"')
      end
    end
    
    describe '#select' do
      it 'creates select element with options' do
        result = component.render_dsl do
          select(name: 'country') do
            option('usa', 'United States')
            option('uk', 'United Kingdom')
          end
        end
        
        expect(result.to_s).to include('<select')
        expect(result.to_s).to include('name="country"')
        expect(result.to_s).to include('<option value="usa"')
        expect(result.to_s).to include('United States')
      end
    end
    
    describe '#label' do
      it 'creates label element' do
        result = component.render_dsl do
          label('Email', for_input: 'email_field')
        end
        
        expect(result.to_s).to include('<label')
        expect(result.to_s).to include('for="email_field"')
        expect(result.to_s).to include('Email')
      end
    end
  end

  describe 'chainable modifiers' do
    it 'supports spacing modifiers' do
      result = component.render_dsl do
        div.p(4).m(2).px(6).py(3).mt(1).mb(2).ml(3).mr(4)
      end
      
      expect(result.to_s).to include('p-4')
      expect(result.to_s).to include('m-2')
      expect(result.to_s).to include('px-6')
      expect(result.to_s).to include('py-3')
    end
    
    it 'supports color modifiers' do
      result = component.render_dsl do
        div.bg("blue-500").text_color("white").border_color("gray-200")
      end
      
      expect(result.to_s).to include('bg-blue-500')
      expect(result.to_s).to include('text-white')
      expect(result.to_s).to include('border-gray-200')
    end
    
    it 'supports typography modifiers' do
      result = component.render_dsl do
        text('Hello')
          .font_size("xl")
          .font_weight("bold")
          .text_align("center")
          .line_height("tight")
      end
      
      expect(result.to_s).to include('text-xl')
      expect(result.to_s).to include('font-bold')
      expect(result.to_s).to include('text-center')
      expect(result.to_s).to include('leading-tight')
    end
    
    it 'supports layout modifiers' do
      result = component.render_dsl do
        div.w("full").h(64).flex.items_center.justify_between
      end
      
      expect(result.to_s).to include('w-full')
      expect(result.to_s).to include('h-64')
      expect(result.to_s).to include('flex')
      expect(result.to_s).to include('items-center')
      expect(result.to_s).to include('justify-between')
    end
    
    it 'supports effect modifiers' do
      result = component.render_dsl do
        div.rounded("lg").shadow("md").opacity(75).transition
      end
      
      expect(result.to_s).to include('rounded-lg')
      expect(result.to_s).to include('shadow-md')
      expect(result.to_s).to include('opacity-75')
      expect(result.to_s).to include('transition')
    end
    
    it 'supports state modifiers' do
      result = component.render_dsl do
        button('Click').hover("bg-blue-600").focus("ring-2")
      end
      
      expect(result.to_s).to include('hover:bg-blue-600')
      expect(result.to_s).to include('focus:ring-2')
    end
  end

  describe 'data attributes' do
    it 'supports Stimulus data attributes' do
      result = component.render_dsl do
        div.data(
          controller: "my-controller",
          action: "click->my-controller#handleClick",
          "my-controller-value-value": 42
        )
      end
      
      expect(result.to_s).to include('data-controller="my-controller"')
      expect(result.to_s).to include('data-action="click->my-controller#handleClick"')
      expect(result.to_s).to include('data-my-controller-value-value="42"')
    end
  end

  describe 'conditional rendering' do
    it 'supports if conditions' do
      show = true
      result = component.render_dsl do
        if show
          text('Visible')
        else
          text('Hidden')
        end
      end
      
      expect(result.to_s).to include('Visible')
      expect(result.to_s).not_to include('Hidden')
    end
    
    it 'supports iterators' do
      items = ['Apple', 'Banana', 'Cherry']
      result = component.render_dsl do
        vstack do
          items.each do |item|
            text(item)
          end
        end
      end
      
      expect(result.to_s).to include('Apple')
      expect(result.to_s).to include('Banana')
      expect(result.to_s).to include('Cherry')
    end
  end

  describe 'complex compositions' do
    it 'builds complex UI structures' do
      result = component.render_dsl do
        card(elevation: 2) do
          vstack(spacing: 4) do
            hstack(justify: :between) do
              text('Title').font_size("xl").font_weight("bold")
              button('×').text_color("gray-500")
            end
            
            divider
            
            text('Content goes here').text_color("gray-700")
            
            hstack(spacing: 2) do
              button('Cancel').variant(:secondary)
              button('Save').variant(:primary)
            end
          end
        end
      end
      
      expect(result.to_s).to include('shadow')
      expect(result.to_s).to include('flex-col')
      expect(result.to_s).to include('justify-between')
      expect(result.to_s).to include('text-xl')
    end
  end
end