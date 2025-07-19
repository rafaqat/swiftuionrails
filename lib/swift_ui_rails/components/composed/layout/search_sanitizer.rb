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
          SUSPICIOUS_PATTERNS = [
            /<script/i,
            /javascript:/i,
            /on\w+\s*=/i,          # Event handlers like onclick=
            /\bselect\b.*\bfrom\b/i, # SQL SELECT
            /\bunion\b.*\bselect\b/i, # SQL UNION
            /\binsert\b.*\binto\b/i,  # SQL INSERT
            /\bdelete\b.*\bfrom\b/i,  # SQL DELETE
            /\bdrop\b.*\btable\b/i,   # SQL DROP
            /\bexec\b/i,             # SQL EXEC
            /\{.*\}/,                # Template injection patterns
            /\$\{.*\}/,              # Template literal injection
            /%[0-9a-f]{2}/i,         # URL encoding (potential bypass attempt)
            /\\\w+/,                 # Escape sequences
            /\x00-\x1f/,             # Control characters
          ].freeze
          
          # Sanitize and validate search input
          # @param input [String] The raw search input
          # @return [Hash] { valid: Boolean, sanitized: String, errors: Array }
          def sanitize_search_input(input)
            return { valid: false, sanitized: "", errors: ["Search term is required"] } if input.blank?
            
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
            return false if input.blank?
            
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
            
            # Remove script tags and content
            result.gsub!(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/mi, '')
            
            # Remove javascript: protocols
            result.gsub!(/javascript:/i, '')
            
            # Remove event handlers
            result.gsub!(/on\w+\s*=[^"'\s>]*/i, '')
            result.gsub!(/on\w+\s*=\s*"[^"]*"/i, '')
            result.gsub!(/on\w+\s*=\s*'[^']*'/i, '')
            
            # Remove SQL keywords in suspicious contexts
            result.gsub!(/\b(select|union|insert|delete|drop|exec)\b.*?\b(from|into|table)\b/i, '')
            
            # Remove template injection patterns
            result.gsub!(/\{[^}]*\}/, '')
            result.gsub!(/\$\{[^}]*\}/, '')
            
            # Remove URL encoding
            result.gsub!(/%[0-9a-f]{2}/i, '')
            
            # Remove escape sequences
            result.gsub!(/\\[a-z0-9]/i, '')
            
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