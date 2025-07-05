# frozen_string_literal: true

module ViewComponent
  module Storybook
    class StoriesParser
      def initialize(paths)
        @paths = paths
        @after_parse_callbacks = []
        @after_parse_once_callbacks = []
        @parsing = false
      end

      def parse(&block)
        return if @parsing

        @parsing = true
        @after_parse_once_callbacks << block if block
        
        # Simple file-based parsing instead of YARD
        story_classes = []
        
        @paths.each do |path|
          Dir.glob(File.join(path, "**/*_stories.rb")).each do |file|
            # Load the file
            require file
            
            # Extract class name from filename
            class_name = File.basename(file, ".rb").camelize
            
            # Try to constantize it
            begin
              klass = class_name.constantize
              if klass < ViewComponent::Storybook::Stories
                story_classes << MockCodeObject.new(class_name, file)
              end
            rescue NameError => e
              Rails.logger.debug "Could not load story class #{class_name}: #{e.message}"
            end
          end
        end
        
        # Create a mock registry
        registry = MockRegistry.new(story_classes)
        run_callbacks(registry)
        
        @parsing = false
      end

      def after_parse(&block)
        @after_parse_callbacks << block
      end

      attr_reader :paths

      protected

      def callbacks
        [
          *@after_parse_callbacks,
          *@after_parse_once_callbacks
        ]
      end

      def run_callbacks(registry)
        callbacks.each { |cb| cb.call(registry) }
        @after_parse_once_callbacks = []
      end
      
      # Mock classes to replace YARD functionality
      class MockCodeObject
        attr_reader :path
        
        def initialize(path, file_path = nil)
          # Ensure path is never nil and is a valid string
          if path.nil? || path.to_s.empty?
            Rails.logger.warn "MockCodeObject initialized with nil or empty path. File: #{file_path}"
            @path = file_path ? File.basename(file_path, ".rb").camelize : "UnknownStory"
          else
            @path = path.to_s
          end
          
          @file_path = file_path
          # Try to get the actual class to read its methods
          @story_class = @path.constantize rescue nil
        end
        
        def file
          @file_path || ""
        end
        
        def meths
          return [] unless @story_class
          
          # Get public instance methods and create mock method objects
          methods = @story_class.public_instance_methods(false)
          methods.map { |method_name| MockMethodObject.new(method_name) }
        end
      end
      
      class MockMethodObject
        attr_reader :name
        
        def initialize(name)
          @name = name
        end
      end
      
      class MockRegistry
        def initialize(classes)
          @classes = classes
        end
        
        def all(type)
          type == :class ? @classes : []
        end
      end
    end
  end
end
# Copyright 2025
