# frozen_string_literal: true

class SimpleCardComponentStories < ViewComponent::Storybook::Stories
  control :variant, as: :select, options: [:elevated, :outlined, :filled], default: :elevated
  control :padding, as: :select, options: [:sm, :md, :lg], default: :md
  
  def default(variant: :elevated, padding: :md)
    component = SimpleCardComponent.new(variant: variant, padding: padding)
    
    render component do
      '<div>
        <h3 class="text-lg font-semibold mb-2">Card Content</h3>
        <p class="text-gray-600">This is a simple card component with Swift DSL.</p>
      </div>'.html_safe
    end
  end
  
  def with_header_and_footer(variant: :elevated)
    component = SimpleCardComponent.new(variant: variant)
    
    component.with_header do
      '<h3 class="text-lg font-semibold">Card Header</h3>'.html_safe
    end
    
    component.with_footer do
      '<div class="flex justify-end space-x-2">
        <button class="px-3 py-2 text-sm bg-gray-200 hover:bg-gray-300 text-gray-900 rounded-md">Cancel</button>
        <button class="px-3 py-2 text-sm bg-blue-600 hover:bg-blue-700 text-white rounded-md">Save</button>
      </div>'.html_safe
    end
    
    # Return the rendered component
    render component do
      '<p class="text-gray-600">This card has a header and footer using ViewComponent slots.</p>'.html_safe
    end
  end
  
  def all_variants
    variants_html = [:elevated, :outlined, :filled].map do |variant|
      card_html = render(SimpleCardComponent.new(variant: variant)) do
        "<p class=\"text-gray-600\">This is a #{variant} card.</p>".html_safe
      end
      
      "<div>
        <h4 class=\"text-sm font-medium text-gray-700 mb-2\">#{variant.to_s.capitalize}</h4>
        #{card_html}
      </div>"
    end.join
    
    "<div class=\"space-y-6\">#{variants_html}</div>".html_safe
  end
end