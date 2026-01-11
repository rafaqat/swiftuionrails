# frozen_string_literal: true

class AuthTestController < ApplicationController
  # Controller for testing auth components in isolation
  allow_unauthenticated_access
  
  def login
    @show_login = params[:show_login] == 'true'
    @show_social = params[:show_social] != 'false'  # Default to true, false only if explicitly set to 'false'
    
    # Safe parameter parsing for errors
    @errors = {}
    if params[:errors].is_a?(Hash) || params[:errors].is_a?(ActionController::Parameters)
      params[:errors].each do |key, value|
        @errors[key.to_sym] = Array(value) if value.present?
      end
    end
    
    # Safe parameter parsing for form_data
    @form_data = { email: '', password: '', remember_me: false }
    if params[:form_data].is_a?(Hash) || params[:form_data].is_a?(ActionController::Parameters)
      params[:form_data].each do |key, value|
        # Handle both string and symbol keys, convert boolean strings
        if key.to_s == 'remember_me'
          @form_data[key.to_sym] = value == 'true' || value == true
        elsif value.present?
          @form_data[key.to_sym] = value
        end
      end
    end
    
    render layout: 'component_test'
  end
  
  def register
    @show_register = params[:show_register] == 'true'
    @show_social = params[:show_social] != 'false'  # Default to true, false only if explicitly set to 'false'
    
    # Safe parameter parsing for errors
    @errors = {}
    if params[:errors].is_a?(Hash)
      params[:errors].each do |key, value|
        @errors[key.to_sym] = Array(value) if value.present?
      end
    end
    
    # Safe parameter parsing for form_data
    @form_data = { 
      first_name: '', 
      last_name: '', 
      email: '', 
      password: '', 
      password_confirmation: '',
      terms_accepted: false 
    }
    if params[:form_data].is_a?(Hash) || params[:form_data].is_a?(ActionController::Parameters)
      params[:form_data].each do |key, value|
        # Handle both string and symbol keys, convert boolean strings
        if key.to_s == 'terms_accepted'
          @form_data[key.to_sym] = value == 'true' || value == true
        else
          @form_data[key.to_sym] = value.to_s  # Convert to string, don't filter by present?
        end
      end
    end
    
    render layout: 'component_test'
  end
  
  def combined
    @show_login = params[:show_login] == 'true'
    @show_register = params[:show_register] == 'true'
    @show_social = params[:show_social] != 'false'  # Default to true, false only if explicitly set to 'false'
    render layout: 'component_test'
  end
  
  def login_submit
    # Simulate login processing for testing
    email = params[:email]
    password = params[:password]
    remember_me = params[:remember_me]
    
    # Simulate different response scenarios for testing
    case email
    when 'success@example.com'
      render json: { success: true, message: 'Welcome back!', redirect: '/dashboard' }
    when 'error@example.com'
      render json: { success: false, errors: { email: ['Invalid email or password'] } }
    when 'network@example.com'
      head :request_timeout
    when 'server@example.com'
      head :internal_server_error
    else
      if password == 'validpassword123'
        render json: { success: true, message: 'Welcome back!', redirect: '/dashboard' }
      else
        render json: { success: false, errors: { email: ['Invalid email or password'] } }
      end
    end
  end
  
  def register_submit
    # Simulate registration processing for testing
    email = params[:email]
    password = params[:password]
    password_confirmation = params[:password_confirmation]
    first_name = params[:first_name]
    last_name = params[:last_name]
    terms_accepted = params[:terms_accepted]
    
    errors = {}
    
    # Validation simulation
    errors[:first_name] = ['First name is required'] if first_name.blank?
    errors[:last_name] = ['Last name is required'] if last_name.blank?
    errors[:email] = ['Email is required'] if email.blank?
    errors[:email] = ['Email is already taken'] if email == 'existing@example.com'
    errors[:password] = ['Password is required'] if password.blank?
    errors[:password] = ['Password must be at least 8 characters'] if password.present? && password.length < 8
    errors[:password_confirmation] = ['Passwords do not match'] if password != password_confirmation
    errors[:terms_accepted] = ['You must accept the terms of service'] if terms_accepted != 'true'
    
    if errors.any?
      render json: { success: false, errors: errors }
    else
      render json: { 
        success: true, 
        message: "Welcome to SwiftUI Rails, #{first_name}!", 
        redirect: '/onboarding' 
      }
    end
  end
  
  private
  
  def test_data
    {
      valid_user: {
        email: 'user@example.com',
        password: 'validpassword123',
        first_name: 'John',
        last_name: 'Doe'
      },
      invalid_user: {
        email: 'invalid-email',
        password: '123'
      }
    }
  end
end