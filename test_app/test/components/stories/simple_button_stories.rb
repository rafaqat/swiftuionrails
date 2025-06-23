# frozen_string_literal: true

class SimpleButtonStories < ViewComponent::Storybook::Stories
  # Define controls
  control :title, as: :text, default: "Button Text"
  control :variant, as: :select, options: [:primary, :secondary, :danger], default: :primary
  control :size, as: :select, options: [:sm, :md, :lg], default: :md
  control :disabled, as: :boolean, default: false
  
  # Simple story to test Swift DSL button rendering
  def default(title: "Click Me", variant: :primary, size: :md, disabled: false)
    render SimpleButtonComponent.new(
      title: title,
      variant: variant,
      size: size,
      disabled: disabled
    )
  end
  
  def with_variants(title: "Button Text", variant: :primary, size: :md, disabled: false)
    render SimpleButtonComponent.new(
      title: title,
      variant: variant,
      size: size,
      disabled: disabled
    )
  end
  
  def all_variants(title: "Button Example", size: :md, disabled: false)
    "<div class='space-y-4'>
      <h4 class='text-sm font-medium text-gray-700'>Primary</h4>
      #{render(SimpleButtonComponent.new(title: title, variant: :primary, size: size, disabled: disabled))}
      
      <h4 class='text-sm font-medium text-gray-700 mt-4'>Secondary</h4>
      #{render(SimpleButtonComponent.new(title: title, variant: :secondary, size: size, disabled: disabled))}
      
      <h4 class='text-sm font-medium text-gray-700 mt-4'>Danger</h4>
      #{render(SimpleButtonComponent.new(title: title, variant: :danger, size: size, disabled: disabled))}
    </div>".html_safe
  end
  
  def all_sizes(title: "Button Example", variant: :primary, disabled: false)
    "<div class='space-y-4'>
      <div class='flex items-center space-x-4'>
        #{render(SimpleButtonComponent.new(title: title, variant: variant, size: :sm, disabled: disabled))}
        <span class='text-sm text-gray-600'>sm</span>
      </div>
      
      <div class='flex items-center space-x-4'>
        #{render(SimpleButtonComponent.new(title: title, variant: variant, size: :md, disabled: disabled))}
        <span class='text-sm text-gray-600'>md</span>
      </div>
      
      <div class='flex items-center space-x-4'>
        #{render(SimpleButtonComponent.new(title: title, variant: variant, size: :lg, disabled: disabled))}
        <span class='text-sm text-gray-600'>lg</span>
      </div>
    </div>".html_safe
  end
end