# frozen_string_literal: true

module SwiftUIRails
  module Playground
    # Safe DSL parser that converts DSL code into an AST without using eval
    class SafeDSLParser
      class ParseError < StandardError; end

      # Token types
      TOKEN_TYPES = {
        identifier: /\A[a-z_][a-z0-9_]*[!?]?/i,
        symbol: /\A:[a-z_][a-z0-9_]*/i,
        string: /\A"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/,
        number: /\A-?\d+(\.\d+)?/,
        arrow: /\A=>/,
        dot: /\A\./,
        comma: /\A,/,
        lparen: /\A\(/,
        rparen: /\A\)/,
        lbrace: /\A\{/,
        rbrace: /\A\}/,
        do: /\Ado\b/,
        end: /\Aend\b/,
        colon: /\A:/,
        whitespace: /\A\s+/,
        comment: /\A#.*/
      }.freeze

      # Whitelisted DSL methods
      ALLOWED_METHODS = %w[
        swift_ui vstack hstack zstack grid spacer divider
        text button image card list list_item
        textfield input select option label form
        link nav_link scroll_view
        bg background text_color font_size font_weight
        padding p px py pt pb pl pr
        margin m mx my mt mb ml mr
        width w height h min_width min_height max_width max_height
        rounded corner_radius shadow border border_color
        flex items_center justify_center align
        hidden visible opacity
        hover focus active disabled
        transition animation
        data attr id class style
        if unless each map
      ].freeze

      attr_reader :tokens, :position

      def initialize(code)
        @code = code
        @position = 0
        @tokens = []
      end

      def parse
        tokenize
        @position = 0
        parse_expression
      end

      private

      def tokenize
        pos = 0
        while pos < @code.length
          matched = false
          
          TOKEN_TYPES.each do |type, pattern|
            if match = @code[pos..-1].match(pattern)
              # Skip whitespace and comments
              unless [:whitespace, :comment].include?(type)
                @tokens << {
                  type: type,
                  value: match[0],
                  position: pos
                }
              end
              pos += match[0].length
              matched = true
              break
            end
          end

          unless matched
            raise ParseError, "Unexpected character at position #{pos}: #{@code[pos]}"
          end
        end
      end

      def current_token
        @tokens[@position]
      end

      def consume(expected_type = nil)
        token = current_token
        
        if expected_type && (!token || token[:type] != expected_type)
          raise ParseError, "Expected #{expected_type} but got #{token&.[](:type) || 'EOF'}"
        end
        
        @position += 1
        token
      end

      def peek_token(offset = 0)
        @tokens[@position + offset]
      end

      def parse_expression
        parse_method_chain
      end

      def parse_method_chain
        expr = parse_primary

        while current_token && current_token[:type] == :dot
          consume(:dot)
          method_token = consume(:identifier)
          
          validate_method(method_token[:value])
          
          args = parse_arguments if current_token && current_token[:type] == :lparen
          block = parse_block if current_token && current_token[:type] == :do
          
          expr = {
            type: :method_call,
            receiver: expr,
            method: method_token[:value],
            arguments: args || [],
            block: block
          }
        end

        expr
      end

      def parse_primary
        token = current_token
        
        case token[:type]
        when :identifier
          parse_method_or_variable
        when :string
          consume
          { type: :string, value: parse_string_literal(token[:value]) }
        when :number
          consume
          { type: :number, value: token[:value].include?('.') ? token[:value].to_f : token[:value].to_i }
        when :symbol
          consume
          { type: :symbol, value: token[:value][1..-1].to_sym }
        else
          raise ParseError, "Unexpected token: #{token[:type]}"
        end
      end

      def parse_method_or_variable
        method_token = consume(:identifier)
        method_name = method_token[:value]
        
        validate_method(method_name)
        
        # Check if it's a method call with arguments or block
        if current_token && [:lparen, :do].include?(current_token[:type])
          args = parse_arguments if current_token[:type] == :lparen
          block = parse_block if current_token && current_token[:type] == :do
          
          {
            type: :method_call,
            receiver: nil,
            method: method_name,
            arguments: args || [],
            block: block
          }
        else
          # It's a simple method call without parens
          {
            type: :method_call,
            receiver: nil,
            method: method_name,
            arguments: [],
            block: nil
          }
        end
      end

      def parse_arguments
        consume(:lparen)
        args = []
        
        while current_token && current_token[:type] != :rparen
          # Handle named arguments (key: value)
          if peek_token(1) && peek_token(1)[:type] == :colon
            key_token = consume(:identifier)
            consume(:colon)
            value = parse_expression
            args << { type: :named_arg, name: key_token[:value].to_sym, value: value }
          else
            args << parse_expression
          end
          
          if current_token && current_token[:type] == :comma
            consume(:comma)
          elsif current_token && current_token[:type] != :rparen
            raise ParseError, "Expected comma or closing paren"
          end
        end
        
        consume(:rparen)
        args
      end

      def parse_block
        consume(:do)
        statements = []
        
        while current_token && current_token[:type] != :end
          statements << parse_expression
        end
        
        consume(:end)
        { type: :block, statements: statements }
      end

      def validate_method(method_name)
        unless ALLOWED_METHODS.include?(method_name)
          raise ParseError, "Method '#{method_name}' is not allowed in the DSL"
        end
      end

      def parse_string_literal(str)
        # Remove quotes and handle escape sequences
        str[1..-2].gsub(/\\(.)/) do |match|
          case $1
          when 'n' then "\n"
          when 't' then "\t"
          when 'r' then "\r"
          when '\\' then "\\"
          when '"' then '"'
          when "'" then "'"
          else match
          end
        end
      end
    end

    # AST executor that safely executes the parsed AST
    class ASTExecutor
      def initialize(context)
        @context = context
      end

      def execute(node)
        return nil unless node
        
        case node[:type]
        when :method_call
          execute_method_call(node)
        when :string
          node[:value]
        when :number
          node[:value]
        when :symbol
          node[:value]
        when :block
          execute_block(node)
        else
          raise "Unknown node type: #{node[:type]}"
        end
      end

      private

      def execute_method_call(node)
        receiver = node[:receiver] ? execute(node[:receiver]) : @context
        args = node[:arguments].map { |arg| execute_argument(arg) }
        
        # SECURITY: Use public_send to prevent calling private methods
        # The method name has already been validated against ALLOWED_METHODS
        method_name = node[:method].to_sym
        
        # If there's a block, pass it as a proc
        if node[:block]
          block_proc = -> { execute_block(node[:block]) }
          receiver.public_send(method_name, *args, &block_proc)
        else
          receiver.public_send(method_name, *args)
        end
      end

      def execute_argument(arg)
        if arg[:type] == :named_arg
          { arg[:name] => execute(arg[:value]) }
        else
          execute(arg)
        end
      end

      def execute_block(node)
        results = node[:statements].map { |stmt| execute(stmt) }
        results.last
      end
    end
  end
end