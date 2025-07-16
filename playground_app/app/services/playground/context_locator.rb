# frozen_string_literal: true

require "ripper"
require_relative "fast_lexer"

module Playground
  class ContextLocator
    def initialize(source)
      @source = source
      @sexp = safe_parse(source)
    end

    # Find the last method call chain before cursor
    def last_receiver_chain
      # Try AST parsing first
      if @sexp
        calls = find_nodes(:call)
        unless calls.empty?
          last_call = calls.last
          chain = extract_receiver_chain(last_call)
          return chain if chain
        end
      end

      # Fallback to FastLexer for incomplete code
      FastLexer.chain_before_dot(@source)
    end

    # Get the current context (what we're completing)
    def completion_context
      # Use FastLexer to check for open method call (parameter completion)
      if (open_call_info = FastLexer.open_call(@source))
        method_name, receiver_chain = open_call_info
        {
          type: :parameter_completion,
          method: method_name,
          receiver: receiver_chain
        }
      # Check if we're after a dot (method completion)
      elsif @source =~ /\.\s*(\w*)\z/
        partial = $1 || ""
        receiver = FastLexer.receiver_for_method_completion(@source)
        {
          type: :method_completion,
          partial: partial,
          receiver: receiver
        }
      # Top level completion
      elsif FastLexer.at_top_level?(@source)
        {
          type: :top_level,
          partial: FastLexer.current_partial(@source)
        }
      else
        # Default to top level with current partial
        {
          type: :top_level,
          partial: FastLexer.current_partial(@source)
        }
      end
    end

    private

    def safe_parse(source)
      # Try to parse, handle incomplete code gracefully
      Ripper.sexp(source)
    rescue StandardError => e
      # If Ripper fails, try with a closing paren/end to help it
      attempts = [
        source + ")",
        source + " end",
        source + "\nend"
      ]

      attempts.each do |attempt|
        result = Ripper.sexp(attempt)
        return result if result
      rescue StandardError
        next
      end

      nil
    end

    def find_nodes(type, node = @sexp, acc = [])
      return acc unless node.is_a?(Array)

      acc << node if node[0] == type
      node.each { |child| find_nodes(type, child, acc) }
      acc
    end

    def extract_receiver_chain(call_node)
      return nil unless call_node.is_a?(Array) && call_node[0] == :call

      receiver = call_node[1]
      method = extract_method_name(call_node[2])

      chain = []

      # Walk up the receiver chain
      while receiver
        case receiver
        when Array
          if receiver[0] == :call
            # Nested call, recurse
            parent_method = extract_method_name(receiver[2])
            chain.unshift(parent_method) if parent_method
            receiver = receiver[1]
          elsif receiver[0] == :vcall
            # Variable call (method without receiver)
            chain.unshift(extract_identifier(receiver[1]))
            break
          else
            break
          end
        else
          break
        end
      end

      # Add the current method
      chain << method if method

      chain.empty? ? nil : chain
    end

    def extract_method_name(node)
      case node
      when Array
        if node[0] == :@ident
          node[1]
        end
      end
    end

    def extract_identifier(node)
      case node
      when Array
        if node[0] == :@ident
          node[1]
        end
      end
    end
  end
end
