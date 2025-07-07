# frozen_string_literal: true

module SwiftUIRails
  module Playground
    # Token-based DSL parser that provides safe execution without eval
    # This is a simpler alternative that doesn't require external parser gems
    class TokenParser
      Token = Struct.new(:type, :value, :line, :column, keyword_init: true)
      
      # Token types
      IDENTIFIER = :identifier
      STRING = :string
      NUMBER = :number
      SYMBOL = :symbol
      LPAREN = :lparen
      RPAREN = :rparen
      LBRACE = :lbrace
      RBRACE = :rbrace
      DOT = :dot
      COMMA = :comma
      COLON = :colon
      ARROW = :arrow
      DO = :do
      END_TOKEN = :end
      NEWLINE = :newline
      EOF = :eof

      # Keywords
      KEYWORDS = %w[do end true false nil].freeze

      # Whitelist of allowed DSL methods
      DSL_METHODS = %w[
        swift_ui vstack hstack zstack grid
        text label button link input textfield
        card list list_item scroll_view
        image icon spacer divider
        div span section article header footer nav
        h1 h2 h3 h4 h5 h6 p
        form secure_form select option
        dsl_product_card product_list
      ].freeze

      # Whitelist of allowed modifier methods
      MODIFIER_METHODS = %w[
        bg background text_color font_size font_weight
        padding p pt pr pb pl px py
        margin m mt mr mb ml mx my
        w h width height max_width max_height
        rounded corner_radius shadow border
        flex block inline hidden
        hover focus active disabled
        transition animate scale rotate
        data attr id class style
        on_tap on_click on_change on_input
        title break_inside ring_hover group_hover_opacity
        flex_shrink
      ].freeze

      class ParseError < StandardError; end
      class SecurityError < StandardError; end

      def initialize(code)
        @code = code
        @position = 0
        @line = 1
        @column = 1
        @tokens = []
      end

      def parse
        tokenize
        @current = 0
        parse_expression
      end

      private

      def tokenize
        while @position < @code.length
          skip_whitespace_and_comments
          break if @position >= @code.length
          
          token = next_token
          @tokens << token if token && token.type != NEWLINE
        end
        
        @tokens << Token.new(type: EOF, line: @line, column: @column)
      end

      def skip_whitespace_and_comments
        while @position < @code.length
          case current_char
          when ' ', "\t"
            advance
          when "\n"
            @line += 1
            @column = 1
            advance
          when '#'
            # Skip comment
            advance until current_char == "\n" || @position >= @code.length
          else
            break
          end
        end
      end

      def next_token
        return nil if @position >= @code.length

        start_line = @line
        start_column = @column

        case current_char
        when '"'
          parse_string('"', start_line, start_column)
        when "'"
          parse_string("'", start_line, start_column)
        when ':'
          advance
          if current_char =~ /[a-zA-Z_]/
            value = parse_identifier_value
            Token.new(type: SYMBOL, value: value.to_sym, line: start_line, column: start_column)
          else
            Token.new(type: COLON, line: start_line, column: start_column)
          end
        when '('
          advance
          Token.new(type: LPAREN, line: start_line, column: start_column)
        when ')'
          advance
          Token.new(type: RPAREN, line: start_line, column: start_column)
        when '{'
          advance
          Token.new(type: LBRACE, line: start_line, column: start_column)
        when '}'
          advance
          Token.new(type: RBRACE, line: start_line, column: start_column)
        when '.'
          advance
          Token.new(type: DOT, line: start_line, column: start_column)
        when ','
          advance
          Token.new(type: COMMA, line: start_line, column: start_column)
        when '='
          advance
          if current_char == '>'
            advance
            Token.new(type: ARROW, line: start_line, column: start_column)
          else
            raise ParseError, "Unexpected character '=' at line #{start_line}, column #{start_column}"
          end
        when /[0-9]/
          parse_number(start_line, start_column)
        when /[a-zA-Z_]/
          parse_identifier(start_line, start_column)
        else
          raise ParseError, "Unexpected character '#{current_char}' at line #{start_line}, column #{start_column}"
        end
      end

      def parse_string(quote, line, column)
        advance # Skip opening quote
        value = ''
        
        while current_char != quote && @position < @code.length
          if current_char == '\\'
            advance
            value += escape_char(current_char)
          else
            value += current_char
          end
          advance
        end
        
        if current_char != quote
          raise ParseError, "Unterminated string at line #{line}, column #{column}"
        end
        
        advance # Skip closing quote
        Token.new(type: STRING, value: value, line: line, column: column)
      end

      def escape_char(char)
        case char
        when 'n' then "\n"
        when 't' then "\t"
        when 'r' then "\r"
        when '\\' then '\\'
        when '"' then '"'
        when "'" then "'"
        else char
        end
      end

      def parse_number(line, column)
        value = ''
        
        while current_char =~ /[0-9._]/
          value += current_char
          advance
        end
        
        if value.include?('.')
          Token.new(type: NUMBER, value: value.to_f, line: line, column: column)
        else
          Token.new(type: NUMBER, value: value.to_i, line: line, column: column)
        end
      end

      def parse_identifier(line, column)
        value = parse_identifier_value
        
        type = case value
               when 'do' then DO
               when 'end' then END_TOKEN
               when 'true', 'false', 'nil' then IDENTIFIER
               else IDENTIFIER
               end
        
        Token.new(type: type, value: value, line: line, column: column)
      end

      def parse_identifier_value
        value = ''
        
        while current_char =~ /[a-zA-Z0-9_!?]/
          value += current_char
          advance
        end
        
        value
      end

      def current_char
        @position < @code.length ? @code[@position] : nil
      end

      def advance
        @column += 1
        @position += 1
      end

      # Parser methods

      def current_token
        @current < @tokens.length ? @tokens[@current] : nil
      end

      def peek_token
        @current + 1 < @tokens.length ? @tokens[@current + 1] : nil
      end

      def consume_token
        token = current_token
        @current += 1
        token
      end

      def parse_expression
        parse_method_chain
      end

      def parse_method_chain
        expr = parse_primary
        
        while current_token&.type == DOT
          consume_token # consume dot
          method_token = consume_token
          
          unless method_token.type == IDENTIFIER
            raise ParseError, "Expected method name after '.' at line #{method_token.line}"
          end
          
          validate_method(method_token.value)
          
          # Parse method arguments if present
          args = []
          block = nil
          
          if current_token&.type == LPAREN
            args = parse_arguments
          end
          
          if current_token&.type == DO || current_token&.type == LBRACE
            block = parse_block
          end
          
          expr = {
            type: :method_call,
            receiver: expr,
            method: method_token.value,
            args: args,
            block: block
          }
        end
        
        expr
      end

      def parse_primary
        token = current_token
        
        case token&.type
        when IDENTIFIER
          parse_method_or_value
        when STRING
          consume_token
          { type: :literal, value: token.value }
        when NUMBER
          consume_token
          { type: :literal, value: token.value }
        when SYMBOL
          consume_token
          { type: :literal, value: token.value }
        when LPAREN
          consume_token
          expr = parse_expression
          if current_token&.type != RPAREN
            raise ParseError, "Expected ')' at line #{current_token&.line}"
          end
          consume_token
          expr
        when EOF
          nil
        else
          raise ParseError, "Unexpected token #{token.type} at line #{token.line}"
        end
      end

      def parse_method_or_value
        token = consume_token
        
        case token.value
        when 'true'
          { type: :literal, value: true }
        when 'false'
          { type: :literal, value: false }
        when 'nil'
          { type: :literal, value: nil }
        else
          validate_method(token.value)
          
          args = []
          block = nil
          
          # Check for arguments
          if current_token&.type == LPAREN
            args = parse_arguments
          elsif current_token&.type != DOT && current_token&.type != EOF && 
                current_token&.type != RBRACE && current_token&.type != END_TOKEN
            # Space-separated arguments (Ruby style)
            args = parse_space_separated_args
          end
          
          # Check for block
          if current_token&.type == DO
            block = parse_block
          end
          
          {
            type: :method_call,
            receiver: nil,
            method: token.value,
            args: args,
            block: block
          }
        end
      end

      def parse_arguments
        consume_token # consume '('
        args = []
        
        while current_token&.type != RPAREN
          # Handle named arguments (key: value)
          if peek_token&.type == COLON
            key_token = consume_token
            consume_token # consume ':'
            value = parse_expression
            args << { type: :named_arg, key: key_token.value.to_sym, value: value }
          else
            args << parse_expression
          end
          
          if current_token&.type == COMMA
            consume_token
          elsif current_token&.type != RPAREN
            raise ParseError, "Expected ',' or ')' at line #{current_token.line}"
          end
        end
        
        consume_token # consume ')'
        args
      end

      def parse_space_separated_args
        args = []
        
        # Parse arguments until we hit a terminator
        until current_token.nil? || 
              %i[DOT DO END_TOKEN RBRACE EOF].include?(current_token.type) ||
              (current_token.type == IDENTIFIER && peek_token&.type == COLON)
          
          # Handle named arguments
          if current_token.type == IDENTIFIER && peek_token&.type == COLON
            key_token = consume_token
            consume_token # consume ':'
            value = parse_primary
            args << { type: :named_arg, key: key_token.value.to_sym, value: value }
          else
            args << parse_primary
          end
          
          # Skip commas if present
          consume_token if current_token&.type == COMMA
        end
        
        args
      end

      def parse_block
        consume_token # consume 'do' or '{'
        statements = []
        
        end_token = current_token&.type == LBRACE ? RBRACE : END_TOKEN
        
        while current_token&.type != end_token && current_token&.type != EOF
          stmt = parse_expression
          statements << stmt if stmt
        end
        
        if current_token&.type != end_token
          raise ParseError, "Expected '#{end_token}' at line #{current_token&.line}"
        end
        
        consume_token # consume 'end' or '}'
        
        { type: :block, statements: statements }
      end

      def validate_method(method_name)
        unless DSL_METHODS.include?(method_name) || 
               MODIFIER_METHODS.include?(method_name)
          raise SecurityError, "Method '#{method_name}' is not allowed in DSL"
        end
      end
    end

    # AST executor that safely executes the parsed AST
    class ASTExecutor
      def initialize(context)
        @context = context
      end

      def execute(ast)
        return nil unless ast
        
        case ast[:type]
        when :method_call
          execute_method_call(ast)
        when :block
          execute_block(ast)
        when :literal
          ast[:value]
        when :named_arg
          { ast[:key] => execute(ast[:value]) }
        else
          raise "Unknown AST node type: #{ast[:type]}"
        end
      end

      private

      def execute_method_call(ast)
        receiver = ast[:receiver] ? execute(ast[:receiver]) : @context
        method_name = ast[:method]
        
        # Process arguments
        args = []
        kwargs = {}
        
        ast[:args].each do |arg|
          if arg[:type] == :named_arg
            kwargs[arg[:key]] = execute(arg[:value])
          else
            args << execute(arg)
          end
        end
        
        # Execute method
        if ast[:block]
          block_proc = create_block_proc(ast[:block])
          if kwargs.empty?
            receiver.send(method_name, *args, &block_proc)
          else
            receiver.send(method_name, *args, **kwargs, &block_proc)
          end
        else
          if kwargs.empty?
            receiver.send(method_name, *args)
          else
            receiver.send(method_name, *args, **kwargs)
          end
        end
      end

      def execute_block(ast)
        result = nil
        ast[:statements].each do |stmt|
          result = execute(stmt)
        end
        result
      end

      def create_block_proc(block_ast)
        proc do
          execute_block(block_ast)
        end
      end
    end
  end
end