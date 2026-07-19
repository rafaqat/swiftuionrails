# frozen_string_literal: true

require "test_helper"

class DslMethodCoverageTest < ActiveSupport::TestCase
  # These calls appear in story source, but their receivers are ordinary Ruby
  # values rather than DSL elements. Keep this list deliberately narrow so an
  # unknown modifier chained from an element still fails the coverage test.
  NON_DSL_CHAIN_METHODS = %w[
    call
    clamp
    controller
    count
    each
    each_with_index
    fetch
    find
    first
    freeze
    gsub
    html_safe
    keys
    last
    map
    mission_status
    new
    params
    session
    sort
    times
    to_s
  ].freeze

  DOCUMENTED_CORE_MODIFIERS = %w[
    accessibility_hint
    background_style
    appearance
    button_style
    font
    foreground_style
    text_style
    visually_hidden
    tw
  ].freeze

  FORBIDDEN_APPLICATION_BROWSER_PATTERN = Regexp.union(
    /\bstimulus_(?:controller|action|target|param)\b/i,
    /data[_-](?:controller|action|[a-z0-9_-]+_target)\b/i,
    /[a-z]+->[^#\s]+#[a-z_]+/i,
    /\b(?:querySelector|addEventListener)\b/,
    /\b(?:document|window)\s*\./
  ).freeze

  def setup
    @story_files = Dir[Rails.root.join("test/components/stories/*_stories.rb")]
    @readme = File.read(Rails.root.join("../README.md"))
  end

  test "all element modifiers used in stories are implemented" do
    assert_not_empty @story_files, "Expected story files for DSL coverage"
    assert_empty find_missing_dsl_methods,
      -> { "Missing DSL methods: #{find_missing_dsl_methods.join(', ')}" }
  end

  test "default story components instantiate and render" do
    failures = @story_files.filter_map { |file| render_default_story(file) }

    assert_empty failures,
      -> { "Default stories failed:\n#{failures.join("\n")}" }
  end

  test "story samples contain no application-authored browser controllers" do
    violations = @story_files.filter_map do |file|
      source = File.read(file)
      match = source.match(FORBIDDEN_APPLICATION_BROWSER_PATTERN)
      "#{File.basename(file)}:#{source[0...match.begin(0)].count("\n") + 1}: #{match[0]}" if match
    end

    assert_empty violations,
      -> { "Story samples must declare behavior in Ruby/RenderIR:\n#{violations.join("\n")}" }
  end

  test "documented DSL modifiers are implemented and core examples remain documented" do
    documented_methods = documented_modifier_methods

    assert_not_empty documented_methods, "Expected DSL modifier examples in README.md"
    assert_empty DOCUMENTED_CORE_MODIFIERS - documented_methods,
      -> { "README is missing core DSL examples: #{(DOCUMENTED_CORE_MODIFIERS - documented_methods).join(', ')}" }
    assert_empty documented_methods - implemented_element_methods,
      -> { "README references missing DSL methods: #{(documented_methods - implemented_element_methods).join(', ')}" }
  end

  private

  def find_missing_dsl_methods
    find_all_used_methods.keys.reject do |method_name|
      implemented_element_methods.include?(method_name) ||
        non_dsl_chain_method?(method_name)
    end.sort
  end

  def find_all_used_methods
    @story_files.each_with_object(Hash.new(0)) do |file, usage|
      File.read(file).scan(/\.([a-z_]+)(?:\(|\s|$)/).flatten.each do |method_name|
        usage[method_name] += 1
      end
    end
  end

  def implemented_element_methods
    @implemented_element_methods ||= (
      SwiftUIRails::DSL::Element.public_instance_methods - Object.public_instance_methods
    ).map(&:to_s).uniq
  end

  def non_dsl_chain_method?(method_name)
    NON_DSL_CHAIN_METHODS.include?(method_name) || view_component_slot_method?(method_name)
  end

  def view_component_slot_method?(method_name)
    method_name.match?(/\Awith_[a-z_]+\z/)
  end

  def render_default_story(file)
    story_class = story_class_for(file)
    return unless story_class.public_instance_methods(false).include?(:default)

    result = story_class.new.public_send(:default, **default_params_for(story_class))
    ApplicationController.render(result) if result.is_a?(ViewComponent::Base)
    nil
  rescue StandardError => error
    "#{File.basename(file)}: #{error.class}: #{error.message}"
  end

  def story_class_for(file)
    require_dependency file
    "#{File.basename(file, '_stories.rb').camelize}Stories".constantize
  end

  def default_params_for(story_class)
    story = story_class.find_story(:default)
    return {} unless story

    accepted_keywords = story_class.instance_method(:default).parameters.filter_map do |kind, name|
      name if %i[key keyreq].include?(kind)
    end

    story.controls.each_with_object({}) do |control, params|
      params[control.param] = control.default if accepted_keywords.include?(control.param)
    end
  end

  def documented_modifier_methods
    styling_sections = [ "Semantic styling", "Layout and modifiers" ].filter_map do |heading|
      @readme[/^## #{Regexp.escape(heading)}\s*$.*?(?=^##\s)/m]
    end
    return [] if styling_sections.empty?

    styling_sections.join("\n").scan(/\.([a-z_]+)(?:\(|\s|$)/).flatten.uniq.reject do |method_name|
      non_dsl_chain_method?(method_name)
    end
  end
end
