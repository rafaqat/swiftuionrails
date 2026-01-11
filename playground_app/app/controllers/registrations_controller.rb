class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 5, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_url, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    
    if @user.save
      start_new_session_for @user
      respond_to do |format|
        format.html { redirect_to after_authentication_url, notice: "Welcome! Your account was created successfully." }
        format.json { render json: { success: true, redirect_url: after_authentication_url } }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @user.errors.to_hash } }
      end
    end
  end

  private

  def registration_params
    # Handle both direct params and register dialog params
    if params[:register]
      # Dialog component parameters
      params.require(:register).permit(:first_name, :last_name, :email, :password, :password_confirmation, :terms_accepted)
        .transform_keys { |key| key == 'email' ? 'email_address' : key }
    else
      # Direct parameters (legacy)
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
  end
end
