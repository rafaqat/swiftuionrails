# frozen_string_literal: true

# Copyright 2025

module ViewComponent
  module Storybook
    class Stories < ViewComponent::Preview
      class << self
        def title(title = nil)
          @stories_title = title
        end

        def parameters(params, only: nil, except: nil)
          parameters_collection.add(params, only: only, except: except)
        end

        def layout(layout, only: nil, except: nil)
          layout_collection.add(layout, only: only, except: except)
        end

        def control(param, as:, **opts)
          controls.add(param, as: as, **opts)
        end

        def stories_name
          name.chomp('Stories').underscore
        end

        def preview_name
          stories_name
        end

        def to_csf_params
          csf_params = { title: stories_title }
          csf_params[:parameters] = parameters_collection.for_all if parameters_collection.for_all.present?
          csf_params[:stories] = stories.map(&:to_csf_params)
          csf_params
        end

        def write_csf_json
          File.write(stories_json_path, JSON.pretty_generate(to_csf_params))
          stories_json_path
        end

        def stories
          @stories ||= story_names.map do |name|
            Story.new(story_id(name), name, parameters_collection.for_story(name), controls.for_story(name))
          end
        end

        # find the story by name
        def find_story(name)
          stories.find { |story| story.name == name.to_sym }
        end

        # Returns the arguments for rendering of the component in its layout
        def render_args(story_name, params: {})
          # mostly reimplementing the super method but adding logic to parse the params through the controls and find the layout
          story_params_names = instance_method(story_name).parameters.map(&:last)
          provided_params = params.slice(*story_params_names).to_h.symbolize_keys

          story = find_story(story_name)

          control_parsed_params = provided_params.to_h do |param, value|
            control = story.controls.find { |c| c.param == param }
            value = control.parse_param_value(value) if control

            [param, value]
          end

          result = if control_parsed_params.empty?
                     new.public_send(story_name)
                   else
                     new.public_send(story_name,
                                     **control_parsed_params)
                   end
          result ||= {}
          result[:template] = preview_example_template_path(story_name) if result[:template].nil?
          @layout = layout_collection.for_story(story_name.to_sym)
          result.merge(layout: @layout)
        end

        attr_reader :code_object, :stories_json_path

        def code_object=(object)
          @code_object = object
          @stories_json_path ||= begin
            dir = File.dirname(object.file)

            # Defensive programming for nil path
            if object.path.nil?
              Rails.logger.error "Code object path is nil for file: #{object.file}"
              json_filename = 'unknown_story'
            else
              json_filename = object.path.demodulize.underscore
            end

            File.join(dir, "#{json_filename}.stories.json")
          end

          controls.code_object = object

          # ordering of public_instance_methods isn't consistent
          # use the code_object to sort the methods to the order that they're declared
          @story_names = object.meths.select { |m| story_names.include?(m.name) }.map(&:name)
        end

        private

        def controls
          @controls ||= Collections::ControlsCollection.new
        end

        def stories_title
          @stories_title ||= Storybook.stories_title_generator.call(self)
        end

        def parameters_collection
          @parameters_collection ||= Collections::ParametersCollection.new
        end

        def layout_collection
          @layout_collection ||= Collections::LayoutCollection.new
        end

        def story_names
          @story_names ||= public_instance_methods(false)
        end

        def story_id(name)
          "#{stories_name}/#{name.to_s.parameterize}".underscore
        end
      end
    end
  end
end
# Copyright 2025
