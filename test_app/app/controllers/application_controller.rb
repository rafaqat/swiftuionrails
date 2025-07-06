# Copyright 2025
class ApplicationController < ActionController::Base
  include SwiftUIRails::Security::ContentSecurityPolicy
  include SwiftUIRails::Security::RateLimitConcern
  
  protect_from_forgery with: :exception
  
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Set security headers
  before_action :set_security_headers
  
  def test_grid
    render "application/test_grid"
  end
  
  private
  
  def set_security_headers
    # Security headers for defense in depth
    response.set_header('X-Frame-Options', 'DENY')
    response.set_header('X-Content-Type-Options', 'nosniff')
    response.set_header('X-XSS-Protection', '1; mode=block')
    response.set_header('Referrer-Policy', 'strict-origin-when-cross-origin')
    response.set_header('Permissions-Policy', 'geolocation=(), microphone=(), camera=()')
  end
end
# Copyright 2025
