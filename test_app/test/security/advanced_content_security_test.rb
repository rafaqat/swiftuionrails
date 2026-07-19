# frozen_string_literal: true

require "test_helper"

class AdvancedContentSecurityTest < ActiveSupport::TestCase
  test "embed policy is independent from image approval" do
    validator = SwiftUIRails::Security::URLValidator

    assert validator.approved_domain?("images.unsplash.com")
    refute validator.approved_embed_domain?("images.unsplash.com")
    assert_nil validator.validate_embed_src("https://images.unsplash.com/document.html")
    assert_equal "https://player.vimeo.com/video/123", validator.validate_embed_src("https://player.vimeo.com/video/123")
  end

  test "embed policy blocks scheme confusion credentials and protocol-relative attackers" do
    validator = SwiftUIRails::Security::URLValidator

    assert_nil validator.validate_embed_src("javascript:alert(1)")
    assert_nil validator.validate_embed_src("data:text/html,<script>alert(1)</script>")
    assert_nil validator.validate_embed_src("//attacker.example/frame")
    assert_nil validator.validate_embed_src("http://player.vimeo.com/video/123")
    assert_nil validator.validate_embed_src("https://user:password@player.vimeo.com/video/123")
    assert_nil validator.validate_embed_src("/local\nHeader: injected")
  end

  test "protocol-relative approved embeds remain allowlisted" do
    assert_equal "//player.vimeo.com/video/123",
                 SwiftUIRails::Security::URLValidator.validate_embed_src("//player.vimeo.com/video/123")
  end

  test "invalid embed configuration domains are rejected" do
    validator = SwiftUIRails::Security::URLValidator

    refute validator.add_approved_embed_domain("")
    refute validator.add_approved_embed_domain("https://trusted.example")
    refute validator.add_approved_embed_domain("trusted.example/path")
    refute validator.add_approved_embed_domain(".trusted.example")
    refute validator.add_approved_embed_domain("trusted..example")
    refute validator.add_approved_embed_domain("-trusted.example")
  end
end
