# frozen_string_literal: true

class TailwindCardComponentStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::Storybook::Layouts
  include SwiftUIRails::Storybook::Previews
  
  story :default do
    component TailwindCardComponent
    
    controls do
      swift_select :variant,
        options: [:elevated, :outlined, :filled],
        default: :elevated
      swift_select :padding,
        options: [:none, :sm, :md, :lg, :xl],
        default: :md
      swift_boolean :hover_effect, default: false
      swift_boolean :clickable, default: false
    end
    
    content do
      swift_ui do
        vstack(spacing: 12) do
          text("Card Content").text_size("lg").font_weight("semibold")
          text("This is a sample card component with customizable styling options.")
            .text_color("gray-600")
        end
      end
    end
  end
  
  story :with_slots do
    component TailwindCardComponent
    
    controls do
      swift_select :variant,
        options: [:elevated, :outlined, :filled],
        default: :elevated
    end
    
    header do
      swift_ui do
        hstack do
          text("Card Title").text_size("lg").font_weight("semibold")
          spacer
          button("Action").text_size("sm").text_color("blue-600")
        end
      end
    end
    
    content do
      swift_ui do
        text("This card demonstrates the use of header, content, and footer slots.")
          .text_color("gray-600")
      end
    end
    
    footer do
      swift_ui do
        hstack do
          button("Cancel").variant(:ghost)
          spacer
          button("Save").variant(:primary)
        end
      end
    end
  end
  
  story :with_media do
    component TailwindCardComponent
    
    controls do
      swift_select :variant, options: [:elevated, :outlined], default: :elevated
      swift_boolean :hover_effect, default: true
    end
    
    media do
      swift_ui do
        # Placeholder for image
        div.h(48).bg("gray-300").flex.items("center").justify("center") do
          text("Media Content").text_color("gray-600")
        end
      end
    end
    
    content do
      swift_ui do
        vstack(spacing: 8) do
          text("Featured Content").text_size("xl").font_weight("bold")
          text("Cards can include media sections for images or other visual content.")
            .text_color("gray-600")
          
          hstack(spacing: 12).mt(4) do
            button("Learn More").variant(:primary).size(:sm)
            button("Share").variant(:ghost).size(:sm)
          end
        end
      end
    end
  end
  
  story :grid_layout do
    component TailwindCardComponent
    
    controls do
      swift_select :variant,
        options: [:elevated, :outlined, :filled],
        default: :elevated
      swift_boolean :hover_effect, default: true
    end
    
    layout :card_grid
  end
end
# Copyright 2025
