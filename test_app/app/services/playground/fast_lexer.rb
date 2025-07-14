# frozen_string_literal: true

module Playground
  # Lightweight lexer for extracting method chains from incomplete Ruby code
  # Designed to handle cases where Ripper fails (e.g., code ending with '.' or '("')
  class FastLexer
    IDENT     = /[a-z_]\w*/i
    CALL_HEAD = /(#{IDENT})\s*\(?/   # captures method name before '(' if present
    
    # Returns array of method names in chain
    # Example: 'text("hi").bg("' => ["text", "bg"]
    def self.chain_before_dot(src)
      # Remove trailing dot and whitespace
      pre = src.sub(/\.\s*\z/, '')
      return [] if pre.empty?
      
      # Split by dots and extract method names
      pre.split('.').map do |segment|
        # Extract method name, ignoring arguments
        segment[CALL_HEAD, 1]
      end.compact
    end
    
    # Returns [method_name, receiver_chain] if we're inside an open method call
    # Example: 'text("Hi").bg("' => ["bg", ["text"]]
    def self.open_call(src)
      # Match method call with open parenthesis and optional quote
      if src =~ /(#{IDENT})\s*\(\s*["']?[^)"']*\z/
        method_name = Regexp.last_match(1)
        # Get everything before this method call
        pre_call = src[0, Regexp.last_match.begin(0)]
        # Extract the chain before this call
        chain = chain_before_dot(pre_call)
        [method_name, chain]
      end
    end
    
    # Extract partial method name after last dot
    # Example: 'text("hi").fo' => "fo"
    def self.partial_after_dot(src)
      if src =~ /\.(\w*)\z/
        Regexp.last_match(1)
      else
        ""
      end
    end
    
    # Get the receiver chain for method completion
    # Example: 'text("hi").font_' => ["text"]
    def self.receiver_for_method_completion(src)
      # Remove the partial method name after the last dot
      pre_dot = src.sub(/\.(\w*)\z/, '')
      chain_before_dot(pre_dot + '.')
    end
    
    # Determine if we're at top level or inside a method chain
    def self.at_top_level?(src)
      # Strip whitespace and check if we have any dots
      src = src.strip
      return true if src.empty?
      
      # If no dots and not inside a method call, we're at top level
      !src.include?('.') && open_call(src).nil?
    end
    
    # Extract the current partial identifier being typed
    # Example: 'tex' => 'tex', 'vstack do\n  bu' => 'bu'
    def self.current_partial(src)
      # Match word characters at the end of string
      src[/(\w*)\z/, 1] || ""
    end
  end
end