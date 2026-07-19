# frozen_string_literal: true

require "test_helper"
require "stringio"

class PortableWorkflowsSecurityTest < ActiveSupport::TestCase
  setup do
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  test "all workflow mutation and export routes reject cross-origin executable and ambiguous paths" do
    dangerous = [
      "javascript:alert(1)",
      "data:text/html,<script>alert(1)</script>",
      "https://attacker.test/steal",
      "//attacker.test/steal",
      "/safe path",
      "/safe\\evil",
      "/safe#fragment",
      "/safe%0aheader",
      "/%2f%2fattacker.test"
    ]

    dangerous.each do |path|
      assert_raises(ArgumentError) { render_dsl { swipe_action("Bad", action: path) } }
      assert_raises(ArgumentError) { render_dsl { document_export("Bad", destination: path) } }
      assert_raises(ArgumentError) do
        render_dsl do
          reorderable_collection(items: [1], key: ->(item) { item }, move_path: path, label: "Bad") do
            text("Bad")
          end
        end
      end
    end
  end

  test "hostile keys labels and filenames cannot create active markup or attributes" do
    attack = '\"><img src=x onerror="alert(1)">'
    html = render_dsl do
      reorderable_collection(
        items: [{ id: attack, name: attack }],
        key: :id,
        item_label: :name,
        move_path: "/safe",
        label: attack
      ) { |item| text(item.fetch(:name)) }
      action = swipe_action(attack, action: "/safe")
      swipe_actions(label: attack, actions: [action]) { text(attack) }
    end
    fragment = Nokogiri::HTML.fragment(html)

    assert_empty fragment.css("img")
    assert_empty fragment.css("script")
    assert_empty fragment.css("[onerror], [onclick], [onload]")
    assert_equal attack, fragment.at_css(".swift-ui-reorderable-list")["aria-label"]
    assert_equal attack, fragment.at_css(".swift-ui-reorder-item")["data-sui-workflow-key"]
    assert_equal attack, fragment.at_css(".swift-ui-swipe-action").text
  end

  test "signed creation context detects tampering and bounds client metadata" do
    token = SwiftUIRails::DocumentWorkflow.sign_creation_context(
      source: :template,
      metadata: { template_id: "safe" }
    )
    assert_equal "safe", SwiftUIRails::DocumentWorkflow.verify_creation_context!(token).dig(:metadata, "template_id")

    decoded = token.dup
    decoded[decoded.length / 2] = decoded[decoded.length / 2] == "a" ? "b" : "a"
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.verify_creation_context!(decoded)
    end
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.verify_creation_context!("x" * 16.kilobytes.succ)
    end

    assert_raises(ArgumentError) do
      SwiftUIRails::DocumentWorkflow.sign_creation_context(
        source: :template,
        metadata: { "bad][role" => "admin" }
      )
    end
    assert_raises(ArgumentError) do
      SwiftUIRails::DocumentWorkflow.sign_creation_context(
        source: :template,
        metadata: 21.times.to_h { |index| ["key#{index}", index] }
      )
    end
    assert_raises(ArgumentError) do
      SwiftUIRails::DocumentWorkflow.sign_creation_context(
        source: :template,
        metadata: { note: "x" * 501 }
      )
    end
  end

  test "application JavaScript metadata is rejected and workflow policy cannot be displaced" do
    assert_raises(SwiftUIRails::RenderIR::InvalidStructure) do
      render_dsl do
        document_import(
          action: "/documents",
          accept: ".pdf",
          max_bytes: 1_024,
          data: { controller: "legacy", action: "submit->legacy#upload" }
        )
      end
    end

    html = render_dsl do
      document_import(
        action: "/documents",
        accept: ".pdf",
        max_bytes: 1_024,
        data: {
          analytics: "documents",
          sui_workflow: JSON.generate(
            kind: "script",
            maxBytes: 999_999,
            maxFiles: 999,
            directUpload: true,
            source: "unsafe"
          )
        }
      )
    end
    form = Nokogiri::HTML.fragment(html).at_css("form")
    descriptor = JSON.parse(form["data-sui-workflow"])

    assert_nil form["data-controller"]
    assert_nil form["data-action"]
    assert_equal "documents", form["data-analytics"]
    assert_equal "document", descriptor.fetch("kind")
    assert_equal 1_024, descriptor.fetch("maxBytes")
    assert_equal 1, descriptor.fetch("maxFiles")
    assert_equal false, descriptor.fetch("directUpload")
    assert_equal "import", descriptor.fetch("source")
  end

  test "server validation rejects missing unverifiable or falsely typed uploads" do
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.validate_upload!(nil, max_bytes: 100, content_types: ["text/plain"])
    end

    unbounded = Struct.new(:content_type, :original_filename).new("text/plain", "notes.txt")
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.validate_upload!(unbounded, max_bytes: 100, content_types: ["text/plain"])
    end

    upload = Struct.new(:byte_size, :content_type, :original_filename).new(1, "text/html", "notes.txt")
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.validate_upload!(upload, max_bytes: 100, content_types: ["text/plain"])
    end

    spoofed = Struct.new(:byte_size, :content_type, :original_filename, :io).new(
      34,
      "text/plain",
      "notes.txt",
      StringIO.new("<html><body>executable</body></html>")
    )
    error = assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.validate_upload!(spoofed, max_bytes: 100, content_types: ["text/plain"])
    end
    assert_match(/contents do not match/, error.message)
  end

  private

  def render_dsl(&block)
    @view.swift_ui(&block)
  end
end
