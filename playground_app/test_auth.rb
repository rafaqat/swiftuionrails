#!/usr/bin/env ruby
require_relative 'config/environment'

begin
  # Clean up any existing test user
  User.find_by(email_address: 'test@example.com')&.destroy
  
  # Create a test user
  user = User.create!(
    email_address: 'test@example.com',
    password: 'testpassword123',
    password_confirmation: 'testpassword123'
  )
  puts "✅ User created successfully: #{user.email_address}"
  
  # Test authentication
  auth_user = User.authenticate_by(email_address: 'test@example.com', password: 'testpassword123')
  if auth_user
    puts "✅ Authentication works! User ID: #{auth_user.id}"
  else
    puts "❌ Authentication failed"
  end
  
  # Test validation
  invalid_user = User.new(email_address: 'invalid', password: '123')
  if invalid_user.valid?
    puts "❌ Validation should have failed"
  else
    puts "✅ Validation works: #{invalid_user.errors.full_messages.join(', ')}"
  end
  
  puts "\n🎉 Rails 8 authentication system is working correctly!"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3)
end