# frozen_string_literal: true

class TailwindButtonComponentStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::Storybook::Layouts
  include SwiftUIRails::Storybook::Previews
  include SwiftUIRails::Storybook::Documentation

  # Default story with all controls
  story :default do
    component TailwindButtonComponent
    
    controls do
      swift_text :title, default: "Click Me"
      swift_select :variant, 
        options: [:primary, :secondary, :success, :danger, :warning, :info, :ghost, :link],
        default: :primary
      swift_select :size,
        options: [:xs, :sm, :md, :lg, :xl],
        default: :md
      swift_boolean :disabled, default: false
      swift_boolean :loading, default: false
      swift_select :icon,
        options: [nil, :star, :heart, :check, :arrow_right],
        default: nil
      swift_select :icon_position,
        options: [:left, :right],
        default: :left
      swift_boolean :full_width, default: false
      swift_text :on_click, default: "#"
    end
  end

  # All button variants
  story :variants do
    component TailwindButtonComponent
    
    controls do
      swift_text :title, default: "Button"
      swift_select :size, options: [:sm, :md, :lg], default: :md
    end
    
    layout :variants_grid
  end

  # All button sizes
  story :sizes do
    component TailwindButtonComponent
    
    controls do
      swift_text :title, default: "Button Size"
      swift_select :variant, 
        options: [:primary, :secondary],
        default: :primary
    end
    
    layout :sizes_showcase
  end

  # Button states
  story :states do
    component TailwindButtonComponent
    
    controls do
      swift_text :title, default: "Button State"
      swift_select :variant, 
        options: [:primary, :secondary, :danger],
        default: :primary
    end
    
    layout :states_showcase
  end

  # With icons
  story :with_icons do
    component TailwindButtonComponent
    
    controls do
      swift_text :title, default: "With Icon"
      swift_select :variant,
        options: [:primary, :secondary, :ghost],
        default: :primary
      swift_select :icon,
        options: [:star, :heart, :download, :arrow_right],
        default: :star
    end
    
    layout :icons_showcase
  end
end
# Copyright 2025
