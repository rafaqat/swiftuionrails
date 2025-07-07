# frozen_string_literal: true

# Copyright 2025

require 'listen'

module SwiftUIRails
  module DevTools
    # Live reload support for component development
    class LiveReload
      class << self
        def enabled?
          Rails.env.development? && ENV['SWIFT_UI_LIVE_RELOAD'] != 'false'
        end

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

        def stop!
          @listener&.stop
        end

        private

        def watched_paths
          [
            Rails.root.join('app/components'),
            Rails.root.join('app/views'),
            Rails.root.join('test/components/stories') # Storybook stories
          ]
        end

        def watched_extensions
          /\.(rb|erb|html\.erb)$/
        end

        def ignored_paths
          [
            /tmp/,
            /node_modules/,
            /coverage/,
            /public/
          ]
        end

        def handle_file_changes(modified, added, removed)
          all_changed = modified + added + removed

          component_files = all_changed.select { |f| f.include?('component') }
          story_files = all_changed.select { |f| f.include?('stories') }

          reload_components(component_files) if component_files.any?

          reload_stories(story_files) if story_files.any?

          # Notify connected browsers via ActionCable
          broadcast_reload(all_changed)
        end

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

        def reload_stories(files)
          files.each do |file|
            load file
            Rails.logger.debug { "Reloaded story: #{file}" }
          rescue StandardError => e
            Rails.logger.error "Failed to reload story #{file}: #{e.message}"
          end
        end

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
