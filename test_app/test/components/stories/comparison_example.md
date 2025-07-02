# SwiftUI-like Preview DSL Comparison

## Before: Traditional ViewComponent Storybook

```ruby
class ButtonComponentStories < ViewComponent::Storybook::Stories
  story :default do
    controls do
      text :title, default: "Click Me"
      select :variant, options: [:primary, :secondary], default: :primary
    end
  end
  
  def default(title: "Click Me", variant: :primary)
    # Manual component instantiation
    render ButtonComponent.new(title: title, variant: variant)
  end
  
  def with_icon
    # Have to manually compose
    render ButtonComponent.new(title: "Save", icon: "save", variant: :primary)
  end
end
```

## After: SwiftUI-like Preview DSL

```ruby
class ButtonComponentStories < SwiftUIRails::Storybook
  preview "Button Examples" do
    scenario "Default Button" do
      # Direct DSL usage - no render or .new!
      button("Click Me")
        .bg("blue-600")
        .text_color("white")
        .px(4).py(2)
        .rounded("md")
        .hover("bg-blue-700")
        .transition
    end
    
    scenario "With Icon" do
      # Natural composition
      button do
        hstack(spacing: 2) do
          icon("save")
          text("Save")
        end
      end
      .bg("green-600")
      .text_color("white")
      .px(4).py(2)
      .rounded("md")
    end
    
    scenario "Button Group" do
      # Complex compositions are easy
      hstack(spacing: 4) do
        button("Previous").bg("gray-200").text_color("gray-700")
        button("Next").bg("blue-600").text_color("white")
      end
      .p(4)
      .bg("gray-50")
      .rounded("lg")
    end
  end
end
```

## Key Benefits

1. **Unified Syntax**: Use the exact same DSL in views and previews
2. **Natural Composition**: Easily combine multiple components
3. **No Boilerplate**: No `render Component.new()` repetition
4. **SwiftUI Feel**: Mirrors SwiftUI's preview system perfectly
5. **Discoverable**: Shows exactly how to use components in real views