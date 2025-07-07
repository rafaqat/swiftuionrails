# frozen_string_literal: true

# Copyright 2025

require 'listen'

module SwiftUIRails
  module DevTools
    # Live reload support for component development
    class LiveReload
      class << self
        ##
        # Determines if live reload is enabled in the current environment.
        # @return [Boolean] true if running in development mode and live reload is not explicitly disabled.
        def enabled?
          Rails.env.development? && ENV['SWIFT_UI_LIVE_RELOAD'] != 'false'
        end

        ##
        # Starts the live reload file listener if enabled, monitoring component and view directories for changes and triggering reloads when files are modified.
        def start!
          return unless enabled?

          @listener = Listen.to(
            *watched_paths,
            only: watched_extensions,
            ignore: ignored_paths
          ) do |modified, added, removed|
            handle_file_changes(modified, added, removed)
          end

          @listener.start
          Rails.logger.info 'SwiftUI Rails LiveReload started. Watching for component changes...'
        end

        ##
        # Stops the live reload file listener if it is currently running.
        def stop!
          @listener&.stop
        end

        private

        ##
        # Returns the list of directories to watch for file changes, including components, views, and storybook stories.
        # @return [Array<Pathname>] The directories monitored for live reload.
        def watched_paths
          [
            Rails.root.join('app/components'),
            Rails.root.join('app/views'),
            Rails.root.join('test/components/stories') # Storybook stories
          ]
        end

        ##
        # Returns a regular expression matching file extensions to watch for changes, including `.rb`, `.erb`, and `.html.erb` files.
        # @return [Regexp] The regular expression for watched file extensions.
        def watched_extensions
          /\.(rb|erb|html\.erb)$/
        end

        ##
        # Returns an array of regex patterns for directory paths to ignore when watching for file changes.
        # @return [Array<Regexp>] The list of ignored directory patterns.
        def ignored_paths
          [
            /tmp/,
            /node_modules/,
            /coverage/,
            /public/
          ]
        end

        ##
        # Handles file changes by reloading affected components and stories, then broadcasts reload notifications to connected clients.
        # @param [Array<String>] modified - List of modified file paths.
        # @param [Array<String>] added - List of newly added file paths.
        # @param [Array<String>] removed - List of removed file paths.
        def handle_file_changes(modified, added, removed)
          all_changed = modified + added + removed

          component_files = all_changed.select { |f| f.include?('component') }
          story_files = all_changed.select { |f| f.include?('stories') }

          reload_components(component_files) if component_files.any?

          reload_stories(story_files) if story_files.any?

          # Notify connected browsers via ActionCable
          broadcast_reload(all_changed)
        end

        ##
        # Reloads the specified component files and invalidates their ViewComponent compile cache.
        # For each file, attempts to reload the component and logs any errors encountered.
        # @param [Array<String>] files - The list of component file paths to reload.
        def reload_components(files)
          files.each do |file|
            # Clear ViewComponent cache
            ViewComponent::CompileCache.invalidate_class!(component_class_from_file(file))

            # Reload the file
            load file

            Rails.logger.debug { "Reloaded component: #{file}" }
          rescue StandardError => e
            Rails.logger.error "Failed to reload component #{file}: #{e.message}"
          end
        end

        ##
        # Reloads the specified story files and logs the outcome for each file.
        # @param [Array<String>] files - The list of story file paths to reload.
        def reload_stories(files)
          files.each do |file|
            load file
            Rails.logger.debug { "Reloaded story: #{file}" }
          rescue StandardError => e
            Rails.logger.error "Failed to reload story #{file}: #{e.message}"
          end
        end

        ##
        # Attempts to derive the component class constant from a given file path.
        # Returns the class constant if successful, or nil if the class cannot be constantized.
        # @param [String] file - The absolute path to the component file.
        # @return [Class, nil] The component class constant, or nil if not found.
        def component_class_from_file(file)
          # Extract class name from file path
          relative_path = file.sub(Rails.root.join.to_s, '')
          class_name = relative_path
                       .sub(%r{^app/components/}, '')
                       .sub(/\.rb$/, '')
                       .camelize

          class_name.constantize
        rescue NameError => e
          Rails.logger.debug { "[LiveReload] Failed to constantize component: #{class_name} - #{e.message}" }
          nil
        end

        ##
        # Broadcasts a reload notification via ActionCable with the names of changed components or stories.
        # Only component or story names are sent to clients to avoid exposing file paths.
        # @param [Array<String>] changed_files - The list of changed file paths to process.
        def broadcast_reload(changed_files)
          return unless defined?(ActionCable)

          # SECURITY: Only send component names instead of full paths to prevent information disclosure
          component_names = changed_files.filter_map do |file|
            if file.include?('component')
              component_class_from_file(file)&.name
            elsif file.include?('stories')
              # Extract story name from file path
              File.basename(file, '.rb').camelize
            else
              # For other files, just send the type
              'view_file'
            end
          end.uniq

          ActionCable.server.broadcast(
            'swift_ui_live_reload',
            {
              type: 'reload',
              components: component_names,
              timestamp: Time.current.to_i
            }
          )
        end
      end
    end

    # Rails integration
    class Railtie < Rails::Railtie
      initializer 'swift_ui_rails.live_reload' do
        if SwiftUIRails::DevTools::LiveReload.enabled?
          ActiveSupport.on_load(:action_controller) do
            SwiftUIRails::DevTools::LiveReload.start!
          end
        end
      end
    end
  end
end
# Copyright 2025
