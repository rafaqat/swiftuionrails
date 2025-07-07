# frozen_string_literal: true

class UserProfileComponentStories < SwiftUIRails::Storybook::Stories
  include SwiftUIRails::Storybook::Layouts
  include SwiftUIRails::Storybook::Previews
  include SwiftUIRails::Storybook::Documentation
  
  # Documentation story
  story :docs do
    component UserProfileComponent
    
    controls do
    end
  end
  
  # Default story
  story :default do
    component UserProfileComponent
    
    controls do
    end
  end
  
  # With avatar story
  story :with_avatar do
    component UserProfileComponent
    
    controls do
    end
  end
  
  # Loading state story
  story :loading_state do
    component UserProfileComponent
    
    controls do
    end
  end
  
  # Layout variations
  story :layout_examples do
    component UserProfileComponent
    
    controls do
      # Add minimal controls for layout demonstration
    end
    
    layout :layout_examples
  end
  
  # Responsive preview
  story :responsive do
    component UserProfileComponent
    
    controls do
    end
    
    layout :responsive
  end
  
  # Theme variations
  story :themes do
    component UserProfileComponent
    
    controls do
    end
    
    layout :themes
  end
end