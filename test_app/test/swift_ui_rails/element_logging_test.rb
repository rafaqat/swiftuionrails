# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "stringio"

class SwiftUIRails::ElementLoggingTest < ActiveSupport::TestCase
  test "element debug logs retain structure without content or fixture secrets" do
    fixture_secret = "customer_token=playground-secret-7f98"
    content = JSON.generate(profile: { note: fixture_secret })
    output = StringIO.new
    logger = ActiveSupport::Logger.new(output)
    logger.level = Logger::DEBUG
    element = SwiftUIRails::DSL::Element.new(:span, content)
    element.view_context = ApplicationController.new.view_context

    html = nil
    Rails.stub(:logger, logger) do
      html = element.to_s
    end
    logger.flush if logger.respond_to?(:flush)
    logs = output.string

    assert_includes html, ERB::Util.html_escape(content)
    assert_includes logs, "Element.to_s: tag=span"
    assert_includes logs, "has_block=false"
    assert_includes logs, "content_present=true"
    refute_includes logs, fixture_secret
    refute_includes logs, content
    refute_match(/content=(?:\{|\[|\"|customer_)/, logs)
  end
end
