# Copyright 2025
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  def test_grid
    render "application/test_grid"
  end
end
# Copyright 2025
