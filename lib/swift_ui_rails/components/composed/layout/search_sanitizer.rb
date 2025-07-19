# frozen_string_literal: true

module SwiftUIRails
  module Component
    module Composed
      module Layout
        # SearchSanitizer - Server-side search input sanitization and validation
        module SearchSanitizer
          extend self
          
          # Maximum allowed search length
          MAX_SEARCH_LENGTH = 255
          
          # Minimum search length
          MIN_SEARCH_LENGTH = 2
          
          # Safe characters pattern - alphanumeric, spaces, and basic punctuation
          SAFE_PATTERN = /\A[a-zA-Z0-9\s\-_.,!?'"()]*\z/
          
          # Suspicious patterns that might indicate injection attempts
          # Note: These patterns are designed to avoid ReDoS vulnerabilities
          SUSPICIOUS_PATTERNS = [
            /<script/i,
            /javascript:/i,
            /\bon\w+\s*=/i,         # Fixed: Added word boundary to prevent ReDoS
            /\bselect\b.*?\bfrom\b/i, # Fixed: Non-greedy quantifier to prevent ReDoS
            /\bunion\b.*?\bselect\b/i, # Fixed: Non-greedy quantifier
            /\binsert\b.*?\binto\b/i,  # Fixed: Non-greedy quantifier
            /\bdelete\b.*?\bfrom\b/i,  # Fixed: Non-greedy quantifier
            /\bdrop\b.*?\btable\b/i,   # Fixed: Non-greedy quantifier
            /\bexec\b/i,             # SQL EXEC
            /\{[^}]{0,100}\}/,       # Fixed: Limited quantifier to prevent ReDoS
            /\$\{[^}]{0,100}\}/,     # Fixed: Limited quantifier for template literals
            /%[0-9a-f]{2}/i,         # URL encoding (potential bypass attempt)
            /\\[a-zA-Z0-9]{1,10}/,   # Fixed: Limited escape sequences to prevent ReDoS
            /[\x00-\x1f]/,           # Fixed: Character class for control characters
          ].freeze
          
          # Sanitize and validate search input
          # @param input [String] The raw search input
          # @return [Hash] { valid: Boolean, sanitized: String, errors: Array }
          def sanitize_search_input(input)
            return { valid: false, sanitized: "", errors: ["Search term is required"] } if input.nil? || input.to_s.strip.empty?
            
            errors = []
            sanitized = input.to_s.strip
            
            # Length validation
            if sanitized.length > MAX_SEARCH_LENGTH
              errors << "Search term too long (maximum #{MAX_SEARCH_LENGTH} characters)"
              sanitized = sanitized[0, MAX_SEARCH_LENGTH]
            end
            
            if sanitized.length < MIN_SEARCH_LENGTH
              errors << "Search term too short (minimum #{MIN_SEARCH_LENGTH} characters)"
            end
            
            # Pattern validation
            unless SAFE_PATTERN.match?(sanitized)
              errors << "Search term contains invalid characters"
              sanitized = sanitize_characters(sanitized)
            end
            
            # Suspicious pattern detection
            if contains_suspicious_patterns?(sanitized)
              errors << "Search term contains potentially dangerous content"
              sanitized = remove_suspicious_patterns(sanitized)
            end
            
            # Final sanitization
            sanitized = final_sanitization(sanitized)
            
            {
              valid: errors.empty? && sanitized.length >= MIN_SEARCH_LENGTH,
              sanitized: sanitized,
              errors: errors
            }
          end
          
          # Check if input is valid without sanitizing
          # @param input [String] The search input to validate
          # @return [Boolean] True if input is valid
          def valid_search_input?(input)
            return false if input.nil? || input.to_s.strip.empty?
            
            sanitized = input.to_s.strip
            
            # Length check
            return false if sanitized.length < MIN_SEARCH_LENGTH || sanitized.length > MAX_SEARCH_LENGTH
            
            # Pattern check
            return false unless SAFE_PATTERN.match?(sanitized)
            
            # Suspicious pattern check
            return false if contains_suspicious_patterns?(sanitized)
            
            true
          end
          
          private
          
          def sanitize_characters(input)
            input
              .gsub(/[<>]/, '')                    # Remove angle brackets
              .gsub(/javascript:/i, '')            # Remove javascript: protocol
              .gsub(/on\w+\s*=/i, '')             # Remove event handlers
              .gsub(/[^\w\s\-_.,!?'"()]/, '')     # Keep only safe characters
              .gsub(/\s+/, ' ')                   # Normalize whitespace
              .strip
          end
          
          def contains_suspicious_patterns?(input)
            SUSPICIOUS_PATTERNS.any? { |pattern| pattern.match?(input) }
          end
          
          def remove_suspicious_patterns(input)
            result = input.dup
            
            # Remove script tags and content - Fixed: More robust script tag removal
            # Handle multiple variations of script tags to prevent bypass
            result.gsub!(/<script\b[^>]*>.*?<\/script>/mi, '')
            result.gsub!(/<script\b[^>]*\/>/mi, '')  # Self-closing script tags
            result.gsub!(/<script\b[^>]*>/mi, '')    # Unclosed script tags
            
            # Remove javascript: protocols
            result.gsub!(/javascript:/i, '')
            
            # Remove event handlers - Fixed: More comprehensive removal
            # Handle all variations of event handlers to prevent bypass
            result.gsub!(/\bon\w+\s*=\s*[^"'\s>]+/i, '')     # Unquoted handlers
            result.gsub!(/\bon\w+\s*=\s*"[^"]*"/i, '')      # Double-quoted handlers
            result.gsub!(/\bon\w+\s*=\s*'[^']*'/i, '')       # Single-quoted handlers
            result.gsub!(/\bon\w+\s*=\s*`[^`]*`/i, '')       # Backtick-quoted handlers
            
            # Remove SQL keywords in suspicious contexts
            result.gsub!(/\b(select|union|insert|delete|drop|exec)\b.*?\b(from|into|table)\b/i, '')
            
            # Remove template injection patterns - Fixed: Handle nested patterns
            # Iteratively remove template patterns to handle nested cases
            10.times do  # Limit iterations to prevent infinite loops
              old_length = result.length
              result.gsub!(/\{[^{}]*\}/, '')      # Remove simple braces
              result.gsub!(/\$\{[^{}]*\}/, '')    # Remove template literals
              break if result.length == old_length  # No more changes
            end
            
            # Remove URL encoding
            result.gsub!(/%[0-9a-f]{2}/i, '')
            
            # Remove escape sequences - Fixed: More comprehensive patterns
            result.gsub!(/\\[a-zA-Z0-9]{1,10}/, '')      # Alphanumeric escapes
            result.gsub!(/\\x[0-9a-fA-F]{1,4}/, '')      # Hex escapes
            result.gsub!(/\\u[0-9a-fA-F]{1,6}/, '')      # Unicode escapes
            result.gsub!(/\\[0-7]{1,3}/, '')             # Octal escapes
            
            # Remove control characters
            result.gsub!(/[\x00-\x1f]/, '')
            
            result.strip
          end
          
          def final_sanitization(input)
            input
              .gsub(/\s+/, ' ')                   # Normalize whitespace
              .strip                              # Trim
              .slice(0, MAX_SEARCH_LENGTH)        # Ensure length limit
          end
        end
      end
    end
  end
end