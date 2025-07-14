# frozen_string_literal: true

require 'test_helper'

class Playground::FastLexerTest < ActiveSupport::TestCase
  test "chain_before_dot extracts simple method chain" do
    assert_equal ['text', 'bg'], Playground::FastLexer.chain_before_dot('text("hello").bg("red").')
  end
  
  test "chain_before_dot handles chain without trailing dot" do
    assert_equal ['text', 'bg'], Playground::FastLexer.chain_before_dot('text("hello").bg("red")')
  end
  
  test "chain_before_dot handles single method" do
    assert_equal ['text'], Playground::FastLexer.chain_before_dot('text("hello").')
  end
  
  test "chain_before_dot handles methods without parentheses" do
    assert_equal ['spacer', 'flex'], Playground::FastLexer.chain_before_dot('spacer.flex.')
  end
  
  test "open_call detects open method call with double quote" do
    result = Playground::FastLexer.open_call('text("Hello").bg("')
    assert_equal ['bg', ['text']], result
  end
  
  test "open_call detects open method call with single quote" do
    result = Playground::FastLexer.open_call("text('Hello').bg('")
    assert_equal ['bg', ['text']], result
  end
  
  test "open_call detects open method call without quote" do
    result = Playground::FastLexer.open_call('padding(')
    assert_equal ['padding', []], result
  end
  
  test "open_call returns nil for closed call" do
    assert_nil Playground::FastLexer.open_call('text("hello")')
  end
  
  test "partial_after_dot extracts partial method name" do
    assert_equal 'fo', Playground::FastLexer.partial_after_dot('text("hi").fo')
  end
  
  test "partial_after_dot returns empty string when just dot" do
    assert_equal '', Playground::FastLexer.partial_after_dot('text("hi").')
  end
  
  test "receiver_for_method_completion gets receiver chain" do
    assert_equal ['text'], Playground::FastLexer.receiver_for_method_completion('text("hi").font_')
  end
  
  test "receiver_for_method_completion handles multiple receivers" do
    assert_equal ['text', 'bg'], Playground::FastLexer.receiver_for_method_completion('text("hi").bg("red").fo')
  end
  
  test "at_top_level returns true for partial identifier" do
    assert Playground::FastLexer.at_top_level?('tex')
  end
  
  test "at_top_level returns false for method chain" do
    assert_not Playground::FastLexer.at_top_level?('text.')
  end
  
  test "current_partial extracts partial at end" do
    assert_equal 'tex', Playground::FastLexer.current_partial('tex')
  end
  
  test "current_partial extracts partial after newline" do
    assert_equal 'bu', Playground::FastLexer.current_partial("vstack do\n  bu")
  end
end