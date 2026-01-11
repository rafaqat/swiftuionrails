class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create omniauth_callback ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    # Handle both direct params and login dialog params
    email = params[:login]&.[](:email) || params[:email_address]
    password = params[:login]&.[](:password) || params[:password]
    
    if user = User.authenticate_by(email_address: email, password: password)
      start_new_session_for user
      respond_to do |format|
        format.html { redirect_to after_authentication_url }
        format.json { render json: { success: true, redirect_url: after_authentication_url } }
      end
    else
      respond_to do |format|
        format.html { redirect_to new_session_path, alert: "Try another email address or password." }
        format.json { render json: { success: false, errors: { base: ["Try another email address or password."] } } }
      end
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  # OAuth callback handler
  def omniauth_callback
    provider = params[:provider]
    auth_data = request.env["omniauth.auth"]
    
    if auth_data.nil?
      redirect_to new_session_path, alert: "Authentication failed. Please try again."
      return
    end

    # Find or create user from OAuth data
    user = find_or_create_oauth_user(auth_data, provider)
    
    if user.persisted?
      start_new_session_for user
      redirect_to after_authentication_url, notice: "Successfully signed in with #{provider.capitalize}!"
    else
      redirect_to new_session_path, alert: "Authentication failed. Please try again or use email/password."
    end
  rescue => e
    Rails.logger.error "OAuth callback error: #{e.message}"
    redirect_to new_session_path, alert: "Authentication failed. Please try again."
  end

  # OAuth failure handler
  def auth_failure
    provider = params[:strategy] || 'social'
    message = params[:message] || 'Authentication failed'
    
    Rails.logger.warn "OAuth failure for #{provider}: #{message}"
    redirect_to new_session_path, alert: "#{provider.capitalize} authentication failed. Please try again or use email/password."
  end

  private

  def find_or_create_oauth_user(auth_data, provider)
    # Extract user info from OAuth response
    info = auth_data.info
    uid = auth_data.uid
    email = info.email
    name = info.name || "#{info.first_name} #{info.last_name}".strip
    
    # Try to find existing user by email first
    user = User.find_by(email_address: email) if email.present?
    
    if user
      # User exists, update their OAuth info if needed
      update_user_oauth_info(user, provider, uid, auth_data)
    else
      # Create new user from OAuth data
      user = create_user_from_oauth(email, name, provider, uid, auth_data)
    end
    
    user
  end

  def update_user_oauth_info(user, provider, uid, auth_data)
    # Store OAuth provider info (you might want to create a separate table for this)
    # For now, we'll just update the user record if needed
    Rails.logger.info "User #{user.email_address} signed in with #{provider}"
    user
  end

  def create_user_from_oauth(email, name, provider, uid, auth_data)
    return User.new unless email.present? && name.present?
    
    # Generate a random password since OAuth users don't need to know it
    random_password = SecureRandom.alphanumeric(20)
    
    user = User.new(
      email_address: email,
      password: random_password,
      password_confirmation: random_password
    )
    
    # Set name if User model supports it
    user.name = name if user.respond_to?(:name=)
    
    if user.save
      Rails.logger.info "Created new user from #{provider} OAuth: #{email}"
    else
      Rails.logger.error "Failed to create user from #{provider} OAuth: #{user.errors.full_messages.join(', ')}"
    end
    
    user
  end
end
