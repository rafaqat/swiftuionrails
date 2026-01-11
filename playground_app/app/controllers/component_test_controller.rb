# frozen_string_literal: true

class ComponentTestController < ApplicationController
  # Test individual components in isolation
  
  def hero
    # Test page for HeroLandingComponent
    render layout: 'component_test'
  end
  
  private
  
  def set_test_data
    # Override in specific actions if needed
  end
end