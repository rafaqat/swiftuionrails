# Copyright 2025
class HomeController < ApplicationController
  def index
    # Component showcase page
  end
  
  def counter
    # Counter component demo page
  end
  
  def debug_demo
    # Debug demo view in development only
    redirect_to root_path unless Rails.env.development?
  end
end
# Copyright 2025
