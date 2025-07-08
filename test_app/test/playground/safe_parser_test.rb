# frozen_string_literal: true

require "test_helper"
require "swift_ui_rails/playground/token_parser"

class SafeParserTest < ActiveSupport::TestCase
  setup do
    @parser = nil
  end

  test "parses simple method call" do
    code = 'text("Hello World")'
    parser = SwiftUIRails::Playground::TokenParser.new(code)
    ast = parser.parse

    assert_equal :method_call, ast[:type]
    assert_equal "text", ast[:method]
    assert_equal 1, ast[:args].length
    assert_equal "Hello World", ast[:args][0][:value]
  end

  test "parses method chain" do
    code = 'text("Hello").font_size("xl").text_color("blue")'
    parser = SwiftUIRails::Playground::TokenParser.new(code)
    ast = parser.parse

    assert_equal :method_call, ast[:type]
    assert_equal "text_color", ast[:method]

    # Check the chain
    receiver = ast[:receiver]
    assert_equal :method_call, receiver[:type]
    assert_equal "font_size", receiver[:method]

    receiver = receiver[:receiver]
    assert_equal :method_call, receiver[:type]
    assert_equal "text", receiver[:method]
  end

  test "parses block syntax" do
    code = <<~RUBY
      vstack do
        text("Hello")
        text("World")
      end
    RUBY

    parser = SwiftUIRails::Playground::TokenParser.new(code)
    ast = parser.parse

    assert_equal :method_call, ast[:type]
    assert_equal "vstack", ast[:method]
    assert ast[:block]
    assert_equal 2, ast[:block][:statements].length
  end

  test "parses named arguments" do
    code = "vstack(spacing: 16, alignment: :center)"
    parser = SwiftUIRails::Playground::TokenParser.new(code)
    ast = parser.parse

    assert_equal :method_call, ast[:type]
    assert_equal "vstack", ast[:method]
    assert_equal 2, ast[:args].length

    # Check named args
    assert_equal :named_arg, ast[:args][0][:type]
    assert_equal :spacing, ast[:args][0][:key]
    assert_equal 16, ast[:args][0][:value][:value]
  end

  test "parses nested blocks" do
    code = <<~RUBY
      vstack do
        hstack do
          text("Nested")
        end
      end
    RUBY

    parser = SwiftUIRails::Playground::TokenParser.new(code)
    ast = parser.parse

    assert_equal :method_call, ast[:type]
    assert_equal "vstack", ast[:method]

    inner = ast[:block][:statements][0]
    assert_equal :method_call, inner[:type]
    assert_equal "hstack", inner[:method]
    assert inner[:block]
  end

  test "rejects unsafe methods" do
    code = 'eval("dangerous code")'
    parser = SwiftUIRails::Playground::TokenParser.new(code)

    assert_raises(SwiftUIRails::Playground::TokenParser::SecurityError) do
      parser.parse
    end
  end

  test "parses literal values" do
    code = "vstack(spacing: 8, enabled: true, name: nil)"
    parser = SwiftUIRails::Playground::TokenParser.new(code)
    ast = parser.parse

    assert_equal 3, ast[:args].length
    assert_equal 8, ast[:args][0][:value][:value]
    assert_equal true, ast[:args][1][:value][:value]
    assert_nil ast[:args][2][:value][:value]
  end

  test "parses symbols" do
    code = "button(:primary)"
    parser = SwiftUIRails::Playground::TokenParser.new(code)
    ast = parser.parse

    assert_equal :primary, ast[:args][0][:value]
  end

  test "handles comments" do
    code = <<~RUBY
      # This is a comment
      text("Hello") # Another comment
    RUBY

    parser = SwiftUIRails::Playground::TokenParser.new(code)
    ast = parser.parse

    assert_equal :method_call, ast[:type]
    assert_equal "text", ast[:method]
  end

  test "executes parsed AST" do
    code = 'text("Hello World").font_size("xl")'

    # Create a mock context
    context = MockDSLContext.new

    # Parse and execute
    parser = SwiftUIRails::Playground::TokenParser.new(code)
    ast = parser.parse

    executor = SwiftUIRails::Playground::ASTExecutor.new(context)
    result = executor.execute(ast)

    assert_equal '<span class="text-xl">Hello World</span>', result.to_s
  end

  test "executes blocks with proper scoping" do
    code = <<~RUBY
      vstack(spacing: 4) do
        text("Line 1")
        text("Line 2")
      end
    RUBY

    context = MockDSLContext.new
    parser = SwiftUIRails::Playground::TokenParser.new(code)
    ast = parser.parse

    executor = SwiftUIRails::Playground::ASTExecutor.new(context)
    result = executor.execute(ast)

    assert result.to_s.include?("space-y-4")
    assert result.to_s.include?("Line 1")
    assert result.to_s.include?("Line 2")
  end

  # Mock DSL context for testing
  class MockDSLContext
    class Element
      def initialize(tag, content, attrs = {})
        @tag = tag
        @content = content
        @attrs = attrs
        @classes = []
      end

      def font_size(size)
        @classes << "text-#{size}"
        self
      end

      def to_s
        classes = @classes.join(" ")
        attrs = @attrs.merge(class: classes).map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
        "<#{@tag} #{attrs}>#{@content}</#{@tag}>"
      end
    end

    def text(content)
      Element.new("span", content)
    end

    def vstack(spacing: 8, &block)
      content = block ? capture(&block) : ""
      "<div class=\"flex flex-col space-y-#{spacing}\">#{content}</div>"
    end

    def capture(&block)
      instance_eval(&block)
    end
  end
end
