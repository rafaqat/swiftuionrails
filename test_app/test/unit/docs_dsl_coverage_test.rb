# frozen_string_literal: true

require "test_helper"
require_relative "dsl_method_coverage_test"

# The prose docs are the few-shot corpus LLM agents learn the DSL from —
# validate them the way stories are validated, so phantom APIs cannot creep
# back in. (A doc example teaching a nonexistent signature fails silently at
# authoring time and poisons every generation that imitates it.)
class DocsDslCoverageTest < ActiveSupport::TestCase
  DOC_FILES = [
    Rails.root.join("../README.md"),
    Rails.root.join("../CLAUDE.md"),
    Rails.root.join("../docs/dsl_authoring.md")
  ].freeze

  # Vocabulary that appears in doc examples but is not an Element modifier:
  # plain Ruby, Rails helpers, component-defined helpers used in snippets,
  # and illustrative pseudo-code the docs explicitly mark as aspirational.
  DOC_CHAIN_ALLOWANCES = %w[
    all any? appearance blank? capitalize compact count delete dig downcase
    each_with_object empty? filter filter_map find_story flat_map include?
    index inspect join key? length now page present? push reduce reject update
    round select size slice sort_by strftime strip sum tap titleize to_a
    to_f to_h to_i to_json to_sym transform_values uniq upcase values zip
  ].freeze

  REMOVED_SYNONYMS = %w[hover_background full_width].freeze

  test "docs do not teach removed synonyms or phantom signatures" do
    DOC_FILES.each do |path|
      next unless path.file?

      content = path.read
      REMOVED_SYNONYMS.each do |synonym|
        refute_match(/\.#{synonym}\b/, content,
                     "#{path.basename} still teaches removed synonym .#{synonym}")
      end
      refute_match(/grid\(cols:/, content, "#{path.basename} teaches grid(cols:) — signature is grid(columns:)")
      refute_match(/gap: \d+\)/, content.scan(/grid\([^)]*\)/).join("\n"),
                   "#{path.basename} teaches grid(gap:) — keyword is spacing:")
      refute_match(/\.width\(/, content, "#{path.basename} teaches .width() — use .w()")
    end
  end

  test "every chained modifier in doc ruby fences exists in the DSL" do
    implemented = (SwiftUIRails::DSL::Element.public_instance_methods -
                   Object.public_instance_methods).map(&:to_s).to_set
    non_dsl = DslMethodCoverageTest::NON_DSL_CHAIN_METHODS.to_set + DOC_CHAIN_ALLOWANCES

    offenders = DOC_FILES.flat_map do |path|
      next [] unless path.file?

      fences = path.read.scan(/```ruby\n(.*?)```/m).flatten
      fences.flat_map { |fence| fence.scan(/\.([a-z_]+[a-z])\(/).flatten }
            .uniq
            .reject { |name| implemented.include?(name) || non_dsl.include?(name) || name.start_with?("with_") }
            .map { |name| "#{path.basename}: .#{name}" }
    end.uniq

    assert_empty offenders,
                 "Doc fences teach modifiers the DSL does not implement:\n#{offenders.join("\n")}"
  end
end
