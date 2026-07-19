# frozen_string_literal: true

require "test_helper"

class FormHelpersSecurityTest < ActiveSupport::TestCase
  class StandaloneFormContext
    include SwiftUIRails::DSL
  end

  test "secure forms use the supported Rails forgery-protection class attribute" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    context = StandaloneFormContext.new
    assert context.protect_against_forgery?
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  test "secure forms honor a disabled Rails forgery-protection switch" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false

    assert_not StandaloneFormContext.new.protect_against_forgery?
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end
end
