# frozen_string_literal: true

require "test_helper"
require "stringio"

class SwiftUIRails::PortableWorkflowsTest < ActiveSupport::TestCase
  Upload = Struct.new(:byte_size, :content_type, :original_filename, :io, keyword_init: true)

  setup do
    @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @view.extend(SwiftUIRails::Helpers)
  end

  test "reorderable collections use stable keys and route-backed keyboard controls" do
    items = [
      { id: "alpha", name: "Alpha" },
      { id: 'quote\"<script>', name: "Quoted" },
      { id: 30, name: "Thirty" }
    ]
    html = render_dsl do
      reorderable_collection(
        items: items,
        key: :id,
        item_label: :name,
        move_path: "/projects/7/order",
        label: "Project order",
        id: "project-order",
        method: :patch,
        drag: true
      ) do |item, index|
        text("#{index + 1}. #{item.fetch(:name)}")
      end
    end
    fragment = Nokogiri::HTML.fragment(html)
    root = fragment.at_css("#project-order")

    assert_equal "list", root["role"]
    assert_equal "Project order", root["aria-label"]
    workflow = JSON.parse(root["data-sui-workflow"])
    assert_equal "reorder", workflow.fetch("kind")
    assert_equal true, workflow.fetch("drag")
    assert_nil root["data-controller"]
    assert_nil root["data-action"]

    rows = root.css("[role='listitem']")
    assert_equal 3, rows.length
    assert_equal %w[alpha quote\"<script> 30], rows.map { |row| row["data-sui-workflow-key"] }
    assert_equal 3, rows.map { |row| row["id"] }.uniq.length
    assert rows.all? { |row| row["id"].match?(/\Aproject-order-item-[a-f0-9]{24}\z/) }
    assert_equal ["1. Alpha", "2. Quoted", "3. Thirty"], rows.map { |row| row.at_css(".swift-ui-reorder-content").text }

    first_buttons = rows.first.css("button")
    assert first_buttons.first.key?("disabled")
    refute first_buttons.last.key?("disabled")
    assert_equal "Move up Alpha", first_buttons.first["aria-label"]
    assert_equal "Move down Alpha", first_buttons.last["aria-label"]

    move_forms = root.css("form.swift-ui-reorder-form")
    assert_equal 6, move_forms.length
    assert move_forms.all? { |form| form["action"] == "/projects/7/order" && form["method"] == "post" }
    assert move_forms.all? { |form| form.at_css("input[name='_method'][value='patch']") }
    assert_equal "alpha", move_forms.first.at_css("input[name='reorder[item_key]']")["value"]
    assert_equal "up", move_forms.first.at_css("input[name='reorder[direction]']")["value"]

    drag_form = root.at_css("form.swift-ui-reorder-drag-form[hidden]")
    assert drag_form.at_css("input[name='reorder[item_key]'][data-sui-workflow-role='drag-item-key']")
    assert drag_form.at_css("input[name='reorder[target_key]'][data-sui-workflow-role='drag-target-key']")
    assert_equal "before", drag_form.at_css("input[name='reorder[placement]']")["value"]
    assert_empty fragment.css("script")
  end

  test "reorder identities survive changes in collection position and support grid or custom layout" do
    first = render_reorder(%w[a b c], layout: :grid)
    second = render_reorder(%w[c a b], layout: :grid)
    first_rows = Nokogiri::HTML.fragment(first).css("[role='listitem']").index_by do |row|
      row["data-sui-workflow-key"]
    end
    second_rows = Nokogiri::HTML.fragment(second).css("[role='listitem']").index_by do |row|
      row["data-sui-workflow-key"]
    end

    assert_equal first_rows.transform_values { |row| row["id"] }, second_rows.transform_values { |row| row["id"] }
    grid = Nokogiri::HTML.fragment(first).at_css(".swift-ui-reorderable-grid")
    assert_includes grid["style"], "repeat(2, minmax(0, 1fr))"

    custom = render_dsl do
      reorderable_collection(
        items: [1],
        key: ->(item) { item },
        move_path: "/order",
        label: "Custom",
        layout: :custom,
        drag: false,
        class: "my-layout"
      ) { |item| text(item.to_s) }
    end
    custom_root = Nokogiri::HTML.fragment(custom).at_css(".swift-ui-reorderable-custom.my-layout")
    assert_equal false, JSON.parse(custom_root["data-sui-workflow"]).fetch("drag")
    assert_nil custom_root["data-action"]
    assert_nil custom_root.at_css(".swift-ui-reorder-drag-form")
  end

  test "reorder field extractors accept JSON-restored string keys" do
    items = JSON.parse([{ id: "alpha", name: "Alpha" }].to_json)
    html = render_dsl do
      reorderable_collection(
        items: items,
        key: :id,
        item_label: :name,
        move_path: "/projects/7/order",
        label: "JSON project order"
      ) do |item|
        text(item.fetch("name"))
      end
    end
    row = Nokogiri::HTML.fragment(html).at_css("[role='listitem']")

    assert_equal "alpha", row["data-sui-workflow-key"]
    assert_includes row.text, "Alpha"
    assert_equal "Move down Alpha", row.css("button").last["aria-label"]
  end

  test "reorder declarations reject duplicate unstable and unbounded keys or unsafe routes" do
    assert_raises(ArgumentError) { render_reorder(%w[a a]) }
    assert_raises(ArgumentError) do
      render_dsl do
        reorderable_collection(
          items: [{ id: {} }], key: :id, move_path: "/order", label: "Bad"
        ) { text("bad") }
      end
    end
    assert_raises(ArgumentError) do
      render_dsl do
        reorderable_collection(
          items: Array.new(501) { |index| index },
          key: ->(item) { item },
          move_path: "/order",
          label: "Too many"
        ) { |item| text(item.to_s) }
      end
    end
    assert_raises(ArgumentError) do
      render_dsl do
        reorderable_collection(
          items: [1], key: ->(item) { item }, move_path: "https://evil.test/order", label: "Bad"
        ) { text("bad") }
      end
    end
    assert_raises(ArgumentError) do
      render_dsl do
        reorderable_collection(
          items: [1], key: ->(item) { item }, move_path: "/order", label: "Bad", param: "x][admin"
        ) { text("bad") }
      end
    end
  end

  test "swipe actions remain visible focusable Rails forms and pointer gestures only reveal" do
    html = render_dsl do
      archive = swipe_action("Archive", action: "/messages/9/archive", method: :patch, tone: :accent)
      destroy = swipe_action("Delete", action: "/messages/9", method: :delete, tone: :destructive)
      swipe_actions(
        label: "Message from Ari",
        actions: [archive, destroy],
        edge: :trailing,
        threshold: 64,
        id: "message-actions"
      ) do
        text("Quarterly plan")
      end
    end
    root = Nokogiri::HTML.fragment(html).at_css("#message-actions")

    assert_equal "Message from Ari", root["aria-label"]
    assert_equal "pan-y", root["style"].split(":", 2).last.strip
    assert_equal "swipe", JSON.parse(root["data-sui-workflow"]).fetch("kind")
    assert_nil root["data-action"]
    assert_equal "Quarterly plan", root.at_css(".swift-ui-swipe-actions-content").text
    assert_equal "status", root.at_css("[data-sui-workflow-role='swipe-status']")["role"]

    buttons = root.css(".swift-ui-swipe-actions-buttons button")
    assert_equal %w[Archive Delete], buttons.map(&:text)
    assert buttons.all? { |button| !button.key?("hidden") && !button.key?("disabled") && button["type"] == "submit" }
    forms = root.css(".swift-ui-swipe-action-form")
    assert_equal ["/messages/9/archive", "/messages/9"], forms.map { |form| form["action"] }
    assert_equal %w[patch delete], forms.map { |form| form.at_css("input[name='_method']")["value"] }
  end

  test "swipe action declarations fail closed" do
    assert_raises(ArgumentError) { render_dsl { swipe_action("Bad", action: "javascript:alert(1)") } }
    assert_raises(ArgumentError) { render_dsl { swipe_action("Bad", action: "/safe", method: :get) } }
    assert_raises(ArgumentError) { render_dsl { swipe_action("Bad", action: "/safe", tone: :invisible) } }
    assert_raises(ArgumentError) do
      render_dsl { swipe_action("Bad", action: "/safe", formaction: "https://evil.test/steal") }
    end
    assert_raises(ArgumentError) do
      render_dsl { swipe_action("Bad", action: "/safe", name: "_method", value: "get") }
    end
    assert_raises(ArgumentError) do
      render_dsl { swipe_actions(label: "Bad", actions: [{ action: "/unsafe" }]) { text("Bad") } }
    end
    assert_raises(ArgumentError) do
      render_dsl do
        action = swipe_action("OK", action: "/safe")
        swipe_actions(label: "Bad", actions: [action], threshold: 1) { text("Bad") }
      end
    end
  end

  test "document import emits a bounded multipart form signed provenance and progress hooks" do
    html = render_dsl do
      document_import(
        action: "/documents/import",
        accept: [".pdf", "application/pdf"],
        max_bytes: 5.megabytes,
        source: :template,
        metadata: { template_id: 42, reviewed: true },
        label: "Project brief",
        submit_label: "Import brief",
        method: :post,
        id: "brief-import"
      ) do
        text("PDF only")
      end
    end
    form = Nokogiri::HTML.fragment(html).at_css("form#brief-import")

    assert_equal "/documents/import", form["action"]
    assert_equal "multipart/form-data", form["enctype"]
    workflow = JSON.parse(form["data-sui-workflow"])
    assert_equal "document", workflow.fetch("kind")
    assert_equal 5.megabytes, workflow.fetch("maxBytes")
    assert_nil form["data-action"]
    assert_includes form.text, "PDF only"

    file = form.at_css("input[type='file']")
    assert_equal "document[file]", file["name"]
    assert_equal ".pdf,application/pdf", file["accept"]
    assert file.key?("required")
    assert_equal "file-input", file["data-sui-workflow-role"]
    refute file.key?("data-direct-upload-url")

    token = form.at_css("input[name='document[creation_context]']")["value"]
    context = SwiftUIRails::DocumentWorkflow.verify_creation_context!(token)
    assert_equal :template, context.fetch(:source)
    assert_equal({ "template_id" => 42, "reviewed" => true }, context.fetch(:metadata))

    progress = form.at_css("progress[data-sui-workflow-role='upload-progress']")
    assert_equal "100", progress["max"]
    assert_equal "0", progress["value"]
    assert progress.key?("hidden")
    assert_equal "Import brief", form.at_css("button[type='submit']").text
  end

  test "direct upload creation and streaming export use native Rails contracts" do
    html = render_dsl do
      document_workflow(label: "Reports", id: "reports") do
        document_import(
          action: "/reports",
          accept: "text/csv",
          max_bytes: 10_000,
          direct_upload: true,
          direct_upload_url: "/rails/active_storage/direct_uploads"
        )
        document_creation_action(
          "Create blank report",
          action: "/reports",
          source: :new,
          metadata: { workspace: "north" }
        )
        document_export(
          "Export CSV",
          destination: "/reports/7.csv?audit=true",
          filename: "report-7.csv",
          content_type: "text/csv"
        )
      end
    end
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css("section#reports[role='region'][aria-label='Reports']")
    direct_input = fragment.at_css("input[type='file']")
    assert_equal "/rails/active_storage/direct_uploads", direct_input["data-direct-upload-url"]
    import_workflow = JSON.parse(fragment.at_css("form.swift-ui-document-import")["data-sui-workflow"])
    assert_equal true, import_workflow.fetch("directUpload")

    creation_form = fragment.at_css("form.swift-ui-document-creation")
    creation_token = creation_form.at_css("input[name='document[creation_context]']")["value"]
    creation_context = SwiftUIRails::DocumentWorkflow.verify_creation_context!(creation_token)
    assert_equal({ source: :new, metadata: { "workspace" => "north" } }, creation_context)

    export = fragment.at_css("a.swift-ui-document-export")
    assert_equal "/reports/7.csv?audit=true", export["href"]
    assert_equal "report-7.csv", export["download"]
    assert_equal "text/csv", export["type"]
    assert_equal "false", export["data-turbo"]
    assert_equal "stream", export["data-document-export"]
  end

  test "multiple document imports use Rails array parameters and a matching total policy" do
    html = render_dsl do
      document_import(
        action: "/documents/import",
        name: "document[files]",
        accept: "text/plain",
        max_bytes: 1_000,
        multiple: true,
        max_files: 2
      )
    end
    form = Nokogiri::HTML.fragment(html).at_css("form")
    file = form.at_css("input[type='file']")

    assert_equal "document[files][]", file["name"]
    assert file.key?("multiple")
    assert_equal "file-input", file["data-sui-workflow-role"]
    assert_equal 2, JSON.parse(form["data-sui-workflow"]).fetch("maxFiles")

    first = Upload.new(
      byte_size: 400,
      content_type: "text/plain",
      original_filename: "one.txt",
      io: StringIO.new("a" * 400)
    )
    second = Upload.new(
      byte_size: 500,
      content_type: "text/plain",
      original_filename: "two.txt",
      io: StringIO.new("b" * 500)
    )
    assert_equal [first, second], SwiftUIRails::DocumentWorkflow.validate_uploads!(
      [first, second], max_bytes: 1_000, max_files: 2, content_types: ["text/plain"]
    )
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.validate_uploads!(
        [first, second], max_bytes: 800, max_files: 2, content_types: ["text/plain"]
      )
    end
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.validate_uploads!(
        [first, second], max_bytes: 1_000, max_files: 1, content_types: ["text/plain"]
      )
    end
  end

  test "server document policy enforces payload size type filename and signed context" do
    valid = Upload.new(
      byte_size: 512,
      content_type: "application/pdf; charset=binary",
      original_filename: "brief.pdf",
      io: StringIO.new("%PDF-1.7\n" + ("x" * 503))
    )
    assert_same valid, SwiftUIRails::DocumentWorkflow.validate_upload!(
      valid,
      max_bytes: 1_024,
      content_types: ["application/pdf"]
    )

    too_large = Upload.new(
      byte_size: 2_048,
      content_type: "application/pdf",
      original_filename: "brief.pdf",
      io: StringIO.new("%PDF-1.7\n" + ("x" * 2_039))
    )
    wrong_type = Upload.new(
      byte_size: 10,
      content_type: "text/html",
      original_filename: "brief.html",
      io: StringIO.new("<p>x</p>")
    )
    bad_name = Upload.new(
      byte_size: 10,
      content_type: "application/pdf",
      original_filename: "bad\u0000.pdf",
      io: StringIO.new("%PDF-1.7\n")
    )
    path_name = Upload.new(
      byte_size: 10,
      content_type: "application/pdf",
      original_filename: "../brief.pdf",
      io: StringIO.new("%PDF-1.7\n")
    )
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.validate_upload!(too_large, max_bytes: 1_024, content_types: ["application/pdf"])
    end
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.validate_upload!(wrong_type, max_bytes: 1_024, content_types: ["application/pdf"])
    end
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.validate_upload!(bad_name, max_bytes: 1_024, content_types: ["application/pdf"])
    end
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.validate_upload!(path_name, max_bytes: 1_024, content_types: ["application/pdf"])
    end

    token = SwiftUIRails::DocumentWorkflow.sign_creation_context(source: :generated, metadata: { generator: "v2" })
    assert_equal :generated, SwiftUIRails::DocumentWorkflow.verify_creation_context!(token).fetch(:source)
    assert_raises(SwiftUIRails::DocumentWorkflow::ValidationError) do
      SwiftUIRails::DocumentWorkflow.verify_creation_context!("#{token}tampered")
    end
  end

  test "document declarations reject unsafe paths names types limits and metadata" do
    assert_raises(ArgumentError) do
      render_dsl { document_export("Bad", destination: "https://evil.test/report") }
    end
    assert_raises(ArgumentError) do
      render_dsl { document_export("Bad", destination: "/report", filename: "../secret") }
    end
    assert_raises(ArgumentError) do
      render_dsl { document_export("Bad", destination: "/report", content_type: "text/html; charset=utf-8") }
    end
    assert_raises(ArgumentError) do
      render_dsl do
        document_import(action: "/documents", name: "document[file][x]evil", accept: ".pdf", max_bytes: 10)
      end
    end
    assert_raises(ArgumentError) do
      render_dsl { document_import(action: "/documents", accept: "*/*", max_bytes: 10) }
    end
    assert_raises(ArgumentError) do
      render_dsl { document_import(action: "/documents", accept: ".pdf", max_bytes: 0) }
    end
    assert_raises(ArgumentError) do
      render_dsl { document_import(action: "/documents", accept: ".pdf", max_bytes: 10.5) }
    end
    assert_raises(ArgumentError) do
      render_dsl do
        document_import(
          action: "/documents", accept: ".pdf", max_bytes: 10, multiple: false, max_files: 2
        )
      end
    end
    assert_raises(ArgumentError) do
      SwiftUIRails::DocumentWorkflow.sign_creation_context(source: :new, metadata: { nested: { admin: true } })
    end
  end

  private

  def render_dsl(&block)
    @view.swift_ui(&block)
  end

  def render_reorder(keys, layout: :list)
    render_dsl do
      reorderable_collection(
        items: keys,
        key: ->(item) { item },
        move_path: "/order",
        label: "Order",
        id: "stable-order",
        layout: layout,
        columns: 2
      ) { |item| text(item) }
    end
  end
end
