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
          
          # Safe keyword-based detection instead of complex regex to prevent ReDoS
          FORBIDDEN_KEYWORDS = %w[
            <script javascript: select union insert delete drop exec
          ].freeze
          
          # Only simple, safe regex patterns without quantifiers that could cause ReDoS
          SIMPLE_PATTERNS = [
            /<script/i,
            /javascript:/i,
            /%[0-9a-f]{2}/i,         # URL encoding (specific, limited)
            /[\x00-\x1f]/,           # Control characters (character class)
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
            # Use allowlist approach - only keep explicitly safe characters
            input
              .gsub(/[<>]/, '')                    # Remove angle brackets
              .gsub(/javascript:/i, '')            # Remove javascript: protocol (simple match)
              .gsub(/[^\w\s\-_.,!?'"()]/, '')     # Keep only safe characters
              .gsub(/\s+/, ' ')                   # Normalize whitespace
              .strip
          end
          
          def contains_suspicious_patterns?(input)
            # Use simple keyword detection to avoid ReDoS vulnerabilities
            lower_input = input.downcase
            
            # Check forbidden keywords
            return true if FORBIDDEN_KEYWORDS.any? { |keyword| lower_input.include?(keyword) }
            
            # Check simple patterns that don't cause ReDoS
            return true if SIMPLE_PATTERNS.any? { |pattern| pattern.match?(input) }
            
            # Check for event handlers safely
            return true if contains_event_handler?(input)
            
            false
          end
          
          def contains_event_handler?(input)
            # Simple string-based detection to avoid ReDoS
            lower_input = input.downcase
            lower_input.include?('on') && lower_input.match?(/\bon[a-z]+=/i)
          end
          
          def remove_suspicious_patterns(input)
            result = input.dup
            
            # Remove forbidden keywords using simple string replacement
            FORBIDDEN_KEYWORDS.each do |keyword|
              result.gsub!(keyword, '')
            end
            
            # Remove simple patterns using safe regex
            result.gsub!(/<script/i, '')
            result.gsub!(/javascript:/i, '')
            result.gsub!(/%[0-9a-f]{2}/i, '')
            result.gsub!(/[\x00-\x1f]/, '')
            
            # Remove event handlers using simple string operations
            result = remove_event_handlers_safely(result)
            
            # Final cleanup - only keep allowlisted characters
            result.gsub!(/[^\w\s\-_.,!?'"()]/, '')
            result.gsub!(/\s+/, ' ')
            result.strip
          end
          
          def remove_event_handlers_safely(input)
            # Simple approach: remove any "on" followed by letters and "="
            # Split into words and filter out event handler patterns
            words = input.split(/\s+/)
            clean_words = words.reject do |word|
              word.downcase.match?(/\bon[a-z]+=/)
            end
            clean_words.join(' ')
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