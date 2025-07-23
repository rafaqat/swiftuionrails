# SwiftUI Rails Playground Sandbox - Phase 2 Implementation Guide

> **Status**: Development Feature Documentation  
> **Priority**: Future Enhancement  
> **Purpose**: Advanced security hardening for playground development tool

## Overview

This document outlines Phase 2 implementation for the SwiftUI Rails Playground sandbox system. Phase 2 focuses on advanced DSL context security and comprehensive resource management for the development playground tool.

**Note**: This is a development-only feature, not intended for production deployment. The playground is designed to help developers experiment with SwiftUI Rails DSL syntax in a controlled environment.

---

## Phase 2 Components

### 2.1 Secure DSL Context

**File**: `playground_app/app/services/playground/dsl_context.rb`

```ruby
class Playground::DSLContext
  include SwiftUIRails::DSL
  
  # Override potentially dangerous DSL methods
  def initialize
    @output_buffer = []
    @element_count = 0
    @max_elements = 1000  # Prevent excessive DOM generation
    @nesting_level = 0
    @max_nesting = 50     # Prevent stack overflow
  end

  # Override element creation to add limits and security checks
  def create_element(tag, content = nil, **attrs, &block)
    @element_count += 1
    @nesting_level += 1 if block_given?
    
    # Resource limits
    if @element_count > @max_elements
      raise Playground::SecurityViolation, "Too many elements (limit: #{@max_elements})"
    end
    
    if @nesting_level > @max_nesting
      raise Playground::SecurityViolation, "Nesting too deep (limit: #{@max_nesting})"
    end

    # Sanitize attributes for security
    safe_attrs = sanitize_attributes(attrs)
    
    begin
      result = super(tag, content, **safe_attrs, &block)
    ensure
      @nesting_level -= 1 if block_given?
    end
    
    result
  end

  # Override data iteration methods with limits
  def each_with_limit(collection, max_items: 100)
    if collection.size > max_items
      raise Playground::SecurityViolation, "Collection too large (limit: #{max_items} items)"
    end
    
    collection.each { |item| yield(item) }
  end

  # Safe data access methods
  def safe_data_access(data)
    case data
    when Hash
      data.slice(*allowed_hash_keys)
    when Array
      data.first(100) # Limit array size
    else
      data.to_s.truncate(1000) # Limit string size
    end
  end

  private

  def sanitize_attributes(attrs)
    # Remove dangerous attributes that could lead to XSS or other issues
    dangerous_attrs = %w[
      onclick onload onerror onmouseover onfocus onblur
      javascript: data-action href src
      style class id
    ]
    
    sanitized = attrs.dup
    
    attrs.each do |key, value|
      key_str = key.to_s.downcase
      value_str = value.to_s.downcase
      
      # Remove attributes that match dangerous patterns
      if dangerous_attrs.any? { |dangerous| key_str.include?(dangerous) }
        sanitized.delete(key)
        next
      end
      
      # Remove values with dangerous content
      if value_str.match?(/javascript:|data:|<script|eval\(|expression\(/)
        sanitized.delete(key)
        next
      end
      
      # Sanitize string values
      if value.is_a?(String)
        sanitized[key] = sanitize_string_value(value)
      end
    end
    
    sanitized
  end

  def sanitize_string_value(value)
    # Remove potentially dangerous characters and sequences
    value
      .gsub(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/mi, '') # Remove script tags
      .gsub(/javascript:/i, '')                                        # Remove javascript: protocol
      .gsub(/on\w+\s*=/i, '')                                         # Remove event handlers
      .gsub(/expression\s*\(/i, '')                                   # Remove CSS expressions
      .strip
  end

  def allowed_hash_keys
    # Only allow safe, common data keys
    %w[
      id name title description content text label value
      color background border padding margin
      width height size type variant
      href url path route
      created_at updated_at
    ]
  end
end
```

### 2.2 Advanced Resource Monitor

**File**: `playground_app/app/services/playground/resource_monitor.rb`

```ruby
class Playground::ResourceMonitor
  # Resource limits for development environment
  MAX_EXECUTION_TIME = 5.seconds
  MAX_MEMORY_MB = 50
  MAX_OUTPUT_SIZE = 1.megabyte
  MAX_DOM_NODES = 1000
  MAX_RECURSIVE_CALLS = 100

  class ResourceUsage
    attr_accessor :execution_time, :memory_used, :dom_nodes, :recursive_calls
    
    def initialize
      @execution_time = 0
      @memory_used = 0
      @dom_nodes = 0
      @recursive_calls = 0
    end
    
    def to_h
      {
        execution_time: @execution_time,
        memory_used: @memory_used,
        dom_nodes: @dom_nodes,
        recursive_calls: @recursive_calls
      }
    end
  end

  def self.monitor(&block)
    new.monitor(&block)
  end

  def initialize
    @usage = ResourceUsage.new
    @start_time = nil
    @start_memory = nil
    @call_stack = []
  end

  def monitor
    setup_monitoring
    
    result = nil
    begin
      result = yield
    ensure
      cleanup_monitoring
    end
    
    validate_final_usage(result)
    
    {
      result: result,
      usage: @usage.to_h,
      warnings: generate_warnings
    }
  end

  private

  def setup_monitoring
    @start_time = Time.current
    @start_memory = get_memory_usage
    
    # Set up periodic monitoring
    @monitor_thread = Thread.new { periodic_monitor }
  end

  def cleanup_monitoring
    @usage.execution_time = Time.current - @start_time
    @usage.memory_used = get_memory_usage - @start_memory
    
    @monitor_thread&.kill
  end

  def periodic_monitor
    loop do
      sleep 0.1
      check_current_usage
    end
  rescue ThreadError
    # Thread was killed, exit gracefully
  end

  def check_current_usage
    current_time = Time.current - @start_time
    current_memory = get_memory_usage - @start_memory
    
    if current_time > MAX_EXECUTION_TIME
      raise Playground::SecurityViolation, 
            "Execution time exceeded: #{current_time.round(2)}s (limit: #{MAX_EXECUTION_TIME}s)"
    end

    if current_memory > MAX_MEMORY_MB.megabytes
      raise Playground::SecurityViolation, 
            "Memory usage exceeded: #{(current_memory / 1.megabyte).round(2)}MB (limit: #{MAX_MEMORY_MB}MB)"
    end
  end

  def validate_final_usage(result)
    # Check DOM node count
    if result.respond_to?(:scan)
      node_count = result.scan(/<[^>]+>/).length
      @usage.dom_nodes = node_count
      
      if node_count > MAX_DOM_NODES
        raise Playground::SecurityViolation, 
              "Too many DOM nodes: #{node_count} (limit: #{MAX_DOM_NODES})"
      end
    end

    # Check output size
    if result.to_s.bytesize > MAX_OUTPUT_SIZE
      raise Playground::SecurityViolation, 
            "Output size exceeded: #{result.to_s.bytesize} bytes (limit: #{MAX_OUTPUT_SIZE} bytes)"
    end
  end

  def generate_warnings
    warnings = []
    
    if @usage.execution_time > MAX_EXECUTION_TIME * 0.8
      warnings << "Execution time approaching limit (#{(@usage.execution_time).round(2)}s)"
    end
    
    if @usage.memory_used > MAX_MEMORY_MB.megabytes * 0.8
      warnings << "Memory usage approaching limit (#{(@usage.memory_used / 1.megabyte).round(2)}MB)"
    end
    
    if @usage.dom_nodes > MAX_DOM_NODES * 0.8
      warnings << "DOM node count approaching limit (#{@usage.dom_nodes})"
    end
    
    warnings
  end

  def get_memory_usage
    # Get current process memory usage in bytes
    `ps -o rss= -p #{Process.pid}`.to_i * 1024
  rescue
    0
  end
end
```

### 2.3 Enhanced Safe Stub System

**File**: `playground_app/app/services/playground/safe_stub.rb`

```ruby
class Playground::SafeStub
  def initialize(name, allowed_methods: [])
    @name = name
    @allowed_methods = Set.new(allowed_methods.map(&:to_s))
    @access_log = []
  end

  def method_missing(method, *args, &block)
    @access_log << { method: method, args: args.map(&:class), timestamp: Time.current }
    
    if @allowed_methods.include?(method.to_s)
      handle_allowed_method(method, *args, &block)
    else
      raise Playground::SecurityViolation, 
            "Access to #{@name}.#{method} is not allowed in sandbox"
    end
  end

  def respond_to_missing?(method, include_private = false)
    @allowed_methods.include?(method.to_s)
  end

  def const_get(*args)
    raise Playground::SecurityViolation, 
          "Constant access through #{@name} is not allowed"
  end

  def access_log
    @access_log.dup
  end

  private

  def handle_allowed_method(method, *args, &block)
    case @name
    when "ENV"
      handle_env_method(method, *args, &block)
    when "Time"
      handle_time_method(method, *args, &block)
    else
      # Default: return safe dummy data
      "#{@name}.#{method}(safe_response)"
    end
  end

  def handle_env_method(method, *args, &block)
    case method.to_s
    when "[]"
      # Only allow safe environment variables
      safe_env_vars = %w[RAILS_ENV NODE_ENV]
      key = args.first.to_s
      safe_env_vars.include?(key) ? ENV[key] : nil
    else
      raise Playground::SecurityViolation, "ENV.#{method} not allowed"
    end
  end

  def handle_time_method(method, *args, &block)
    case method.to_s
    when "current", "now"
      Time.current
    when "zone"
      Time.zone.name
    else
      raise Playground::SecurityViolation, "Time.#{method} not allowed"
    end
  end
end

class Playground::SecurityViolation < StandardError
  attr_reader :violation_type, :attempted_action, :timestamp

  def initialize(message, violation_type: :unauthorized_access, attempted_action: nil)
    super(message)
    @violation_type = violation_type
    @attempted_action = attempted_action
    @timestamp = Time.current
  end

  def to_h
    {
      message: message,
      violation_type: @violation_type,
      attempted_action: @attempted_action,
      timestamp: @timestamp
    }
  end
end
```

### 2.4 Execution Context Manager

**File**: `playground_app/app/services/playground/execution_context.rb`

```ruby
class Playground::ExecutionContext
  attr_reader :variables, :method_calls, :warnings

  def initialize
    @variables = {}
    @method_calls = []
    @warnings = []
    @binding = create_secure_binding
  end

  def execute(code)
    # Wrap code in monitoring context
    wrapped_code = wrap_code_for_monitoring(code)
    
    Playground::ResourceMonitor.monitor do
      @binding.eval(wrapped_code)
    end
  end

  private

  def create_secure_binding
    binding = Binding.new
    
    # Add SwiftUI DSL
    binding.extend(SwiftUIRails::DSL)
    binding.extend(SwiftUIRails::Helpers)
    
    # Add safe utilities
    binding.instance_variable_set(:@context_manager, self)
    
    # Override variable assignment tracking
    binding.eval(<<~RUBY)
      def self.method_missing(method, *args, &block)
        if method.to_s.end_with?('=')
          var_name = method.to_s.chomp('=')
          @context_manager.track_variable(var_name, args.first)
          instance_variable_set("@\#{var_name}", args.first)
        else
          @context_manager.track_method_call(method, args)
          super
        end
      end
    RUBY
    
    binding
  end

  def wrap_code_for_monitoring(code)
    <<~RUBY
      begin
        #{code}
      rescue => e
        @context_manager.track_error(e)
        raise e
      end
    RUBY
  end

  def track_variable(name, value)
    @variables[name] = {
      value: safe_inspect(value),
      type: value.class.name,
      size: calculate_size(value),
      timestamp: Time.current
    }
  end

  def track_method_call(method, args)
    @method_calls << {
      method: method,
      args: args.map { |arg| safe_inspect(arg) },
      timestamp: Time.current
    }
  end

  def track_error(error)
    @warnings << {
      type: :runtime_error,
      message: error.message,
      backtrace: error.backtrace&.first(3),
      timestamp: Time.current
    }
  end

  private

  def safe_inspect(value)
    case value
    when String
      value.length > 100 ? "#{value[0...100]}... (truncated)" : value
    when Array
      value.length > 10 ? "Array(#{value.length} items)" : value.inspect
    when Hash
      value.keys.length > 10 ? "Hash(#{value.keys.length} keys)" : value.inspect
    else
      value.inspect
    end
  rescue
    value.class.name
  end

  def calculate_size(value)
    case value
    when String
      value.bytesize
    when Array, Hash
      value.to_s.bytesize
    else
      value.inspect.bytesize
    end
  rescue
    0
  end
end
```

---

## Integration Points

### Controller Integration
```ruby
# In playground_v2_controller.rb
def execute_with_phase2
  context = Playground::ExecutionContext.new
  result = context.execute(params[:code])
  
  render json: {
    success: true,
    result: result[:result],
    usage: result[:usage],
    warnings: result[:warnings],
    variables: context.variables,
    method_calls: context.method_calls
  }
end
```

### Configuration
```ruby
# config/playground.rb (for development)
Playground.configure do |config|
  config.max_execution_time = 5.seconds
  config.max_memory_mb = 50
  config.max_output_size = 1.megabyte
  config.max_dom_nodes = 1000
  config.enable_variable_tracking = true
  config.enable_method_call_tracking = true
  config.log_security_violations = true
end
```

---

## Implementation Notes

### Development Priority
- **Phase 2 is optional enhancement** for the development playground
- Focus on Phase 1 (basic sandbox) first for security
- Phase 2 adds developer experience improvements and advanced monitoring

### Testing Strategy
```ruby
# test/services/playground/dsl_context_test.rb
class Playground::DSLContextTest < ActiveSupport::TestCase
  test "limits element creation" do
    context = Playground::DSLContext.new
    
    assert_raises(Playground::SecurityViolation) do
      1001.times { context.create_element(:div) }
    end
  end
  
  test "sanitizes dangerous attributes" do
    context = Playground::DSLContext.new
    result = context.create_element(:div, onclick: "alert('xss')")
    
    assert_not_includes result.to_s, "onclick"
  end
end
```

### Performance Considerations
- Resource monitoring runs in separate thread
- Variable tracking has memory overhead
- Method call tracking should be disabled in production
- Consider implementing sampling for high-frequency operations

### Security Boundaries
- All Phase 2 components maintain the security model from Phase 1
- Additional monitoring does not bypass existing restrictions
- Resource limits are enforceable and non-negotiable
- Error handling maintains security context

---

## Future Enhancements

### Phase 3 Considerations
- Visual debugging interface for tracked variables
- Real-time resource usage display in playground UI
- Advanced DSL intellisense based on tracked method calls
- Integration with Rails development tools
- Export of playground sessions for documentation

### Monitoring Dashboard
- Web interface showing resource usage trends
- Security violation reports
- Popular DSL patterns from usage data
- Performance optimization recommendations

---

**Note**: This document serves as implementation guidance for future development. The playground sandbox is a development tool and should never be deployed to production environments.