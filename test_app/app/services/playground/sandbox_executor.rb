# frozen_string_literal: true

module Playground
  class SandboxExecutor
    TIMEOUT = 2.seconds
    MAX_OUTPUT_SIZE = 10_000
    
    # Whitelist of allowed classes and methods for safety
    ALLOWED_CLASSES = %w[
      String Integer Float Array Hash Symbol NilClass TrueClass FalseClass
      Range Regexp Time Date
    ].freeze
    
    ALLOWED_METHODS = {
      'String' => %w[length size upcase downcase capitalize strip split join],
      'Integer' => %w[+ - * / % ** abs to_s to_f],
      'Array' => %w[length size first last push pop shift unshift each map select],
      'Hash' => %w[keys values each map select merge]
    }.freeze
    
    class ExecutionError < StandardError; end
    class TimeoutError < ExecutionError; end
    class SecurityError < ExecutionError; end
    
    def initialize(code, context = {})
      @code = code
      @context = context
    end
    
    def execute
      # Basic security checks
      validate_code_safety!
      
      # Execute in a restricted environment
      result = nil
      output = StringIO.new
      
      # Use Timeout for basic protection
      begin
        Timeout.timeout(TIMEOUT) do
          # Redirect stdout
          old_stdout = $stdout
          $stdout = output
          
          # Create a clean binding with DSL context
          sandbox_binding = create_sandbox_binding
          
          # Execute the code
          result = sandbox_binding.eval(@code)
          
          $stdout = old_stdout
        end
      rescue Timeout::Error
        raise TimeoutError, "Code execution timed out after #{TIMEOUT} seconds"
      rescue StandardError => e
        raise ExecutionError, "Execution error: #{e.message}"
      ensure
        $stdout = $stdout if $stdout != output
      end
      
      {
        result: result,
        output: output.string.slice(0, MAX_OUTPUT_SIZE),
        success: true
      }
    rescue ExecutionError => e
      {
        error: e.message,
        success: false
      }
    end
    
    private
    
    def validate_code_safety!
      # Check for dangerous patterns
      dangerous_patterns = [
        /\b(eval|exec|system|backticks|%x|spawn|fork|load|require|open|File|Dir|IO)\b/,
        /`.*`/,  # Backticks
        /%x\{.*\}/,  # %x{} syntax
        /\$\w+/,  # Global variables
        /@@\w+/,  # Class variables
        /\:\:/,  # Scope resolution (accessing constants)
        /\.send/,  # Dynamic method calls
        /\.public_send/,
        /\.method/,
        /\.instance_eval/,
        /\.instance_exec/,
        /\.class_eval/,
        /\.module_eval/
      ]
      
      dangerous_patterns.each do |pattern|
        if @code =~ pattern
          raise SecurityError, "Code contains potentially dangerous pattern: #{pattern.source}"
        end
      end
    end
    
    def create_sandbox_binding
      # Create a clean binding with only DSL methods
      sandbox = Object.new
      
      # Include DSL modules
      sandbox.extend(SwiftUIRails::DSL)
      sandbox.extend(SwiftUIRails::Helpers)
      
      # Create a restricted binding
      binding = sandbox.instance_eval { binding }
      
      # Remove dangerous methods
      remove_dangerous_methods(binding)
      
      binding
    end
    
    def remove_dangerous_methods(binding)
      # List of methods to remove from the binding context
      dangerous_methods = %i[
        eval exec system spawn fork
        load require require_relative
        open popen read write
        send public_send __send__
        instance_eval instance_exec
        class_eval module_eval
        const_get const_set
        remove_const define_method
      ]
      
      # Remove access to these methods
      dangerous_methods.each do |method|
        if binding.receiver.respond_to?(method)
          binding.receiver.singleton_class.undef_method(method) rescue nil
        end
      end
    end
  end
  
  # Alternative: Use a subprocess with restricted permissions
  class SubprocessExecutor
    def initialize(code, context = {})
      @code = code
      @context = context
    end
    
    def execute
      # Create a temporary file for the code
      require 'tempfile'
      
      Tempfile.create(['playground', '.rb']) do |file|
        file.write(wrap_code)
        file.flush
        
        # Execute in a subprocess with restrictions
        output = nil
        error = nil
        
        # Use Open3 for better control
        require 'open3'
        
        stdout, stderr, status = Open3.capture3(
          'timeout', '2s',  # Hard timeout
          'ruby', file.path,
          # Restrict file system access
          unsetenv_others: true,
          rlimit_cpu: [1, 2],  # CPU time limit
          rlimit_as: [50_000_000, 50_000_000],  # Memory limit (50MB)
          rlimit_nproc: [0, 0]  # No subprocess creation
        )
        
        if status.success?
          {
            result: stdout.strip,
            output: stdout,
            success: true
          }
        else
          {
            error: stderr.presence || "Execution failed",
            success: false
          }
        end
      end
    end
    
    private
    
    def wrap_code
      # Wrap the code with necessary requires and safety measures
      <<~RUBY
        # Disable dangerous features
        class << self
          undef :eval
          undef :exec
          undef :system
          undef :spawn
          undef :fork
          undef :load
          undef :require
          undef :open
        end
        
        # Load DSL
        require_relative '#{Rails.root.join('lib/swift_ui_rails/dsl')}'
        
        # Execute user code
        include SwiftUIRails::DSL
        include SwiftUIRails::Helpers
        
        begin
          result = begin
            #{@code}
          end
          
          puts result.inspect
        rescue => e
          $stderr.puts "Error: \#{e.message}"
          exit 1
        end
      RUBY
    end
  end
end