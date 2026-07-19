# frozen_string_literal: true

require "test_helper"

class ContentSecurityPolicyTest < ActiveSupport::TestCase
  test "nonce generator never depends on an initialized session" do
    generator = Rails.application.config.content_security_policy_nonce_generator
    request = ActionDispatch::TestRequest.create

    first_nonce = generator.call(request)
    second_nonce = generator.call(request)

    refute_empty first_nonce
    refute_equal first_nonce, second_nonce
  end
end
