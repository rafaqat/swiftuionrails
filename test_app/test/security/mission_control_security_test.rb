# frozen_string_literal: true

require "test_helper"
require "tempfile"

class MissionControlSecurityTest < ActionDispatch::IntegrationTest
  test "mission forms emit Rails authenticity tokens when forgery protection is enabled" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    get showcase_mission_control_path

    assert_response :success
    assert_select "form[action='#{showcase_mission_control_advance_path}']" do
      assert_select "input[name='authenticity_token']", count: 1
    end
    assert_select "form[action='#{showcase_mission_control_reset_path}']" do
      assert_select "input[name='authenticity_token']", count: 1
    end
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  test "all mission mutations retain the application CSRF boundary" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    patch showcase_mission_control_system_action_path(system: "range", mission_action: "go")

    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  test "missing and hostile mutation parameters fail without dynamic dispatch" do
    patch showcase_mission_control_sequence_path
    assert_response :see_other
    assert_equal "param is missing or the value is empty or invalid: reorder", flash[:alert]

    patch showcase_mission_control_sequence_path,
      params: {
        reorder: {
          item_key: "Kernel.exit!",
          direction: "constantize",
          target_key: "Object",
          placement: "inside",
          admin: true
        }
      }
    assert_response :see_other
    assert_equal "Unknown mission sequence item", flash[:alert]
  end

  test "tampered provenance and content-spoofed uploads never enter the session envelope" do
    token = SwiftUIRails::DocumentWorkflow.sign_creation_context(
      source: :import,
      metadata: { mission: "atlas-7" }
    )

    with_upload(
      "<html><script>alert(1)</script></html>",
      filename: "flight-plan.txt"
    ) do |executable|
      post showcase_mission_control_document_import_path,
        params: { document: { creation_context: token, file: executable } }
    end
    assert_response :see_other
    assert_match(/contents do not match/, flash[:alert])

    upload = fixture_file_upload("workflow-demo.txt", "text/plain")
    post showcase_mission_control_document_import_path,
      params: { document: { creation_context: "forged", file: upload } }
    assert_response :see_other
    assert_match(/invalid or expired/, flash[:alert])

    get showcase_mission_control_path
    assert_select "#atlas-documents", text: /flight-plan\.txt/, count: 0
    assert_select "#atlas-documents", text: /workflow-demo\.txt/, count: 0
  end

  test "oversized uploads are rejected before document state changes" do
    token = SwiftUIRails::DocumentWorkflow.sign_creation_context(
      source: :import,
      metadata: { mission: "atlas-7" }
    )

    with_upload(
      "x" * (Showcase::MissionControlState::MAX_DOCUMENT_BYTES + 1),
      filename: "oversized.txt"
    ) do |upload|
      post showcase_mission_control_document_import_path,
        params: { document: { creation_context: token, file: upload } }
    end

    assert_response :see_other
    assert_match(/exceeds/, flash[:alert])
  end

  test "signed document contexts remain bound to the Atlas endpoint and operation" do
    template_token = SwiftUIRails::DocumentWorkflow.sign_creation_context(
      source: :template,
      metadata: { mission: "atlas-7" }
    )
    upload = fixture_file_upload("workflow-demo.txt", "text/plain")

    post showcase_mission_control_document_import_path,
      params: { document: { creation_context: template_token, file: upload } }
    assert_response :see_other
    assert_match(/does not match/, flash[:alert])

    other_mission_token = SwiftUIRails::DocumentWorkflow.sign_creation_context(
      source: :generated,
      metadata: { mission: "other-mission" }
    )
    post showcase_mission_control_documents_path,
      params: { document: { creation_context: other_mission_token } }
    assert_response :see_other
    assert_match(/does not match/, flash[:alert])
  end

  test "only allowlisted no-JavaScript presentations can open on GET" do
    {
      "brief" => "atlas-command-sheet",
      "transmission" => "atlas-transmission-alert",
      "reset" => "atlas-abort-confirmation"
    }.each do |presentation, dialog_id|
      get showcase_mission_control_path, params: { presentation: presentation }
      assert_response :success
      assert_select "dialog##{dialog_id}[open]", count: 1
    end

    get showcase_mission_control_path, params: { presentation: "javascript:alert(1)" }
    assert_response :success
    assert_select "dialog#atlas-command-sheet[open]", count: 0
    assert_select "dialog#atlas-transmission-alert[open]", count: 0
    assert_select "dialog#atlas-abort-confirmation[open]", count: 0
  end

  test "the exported CSV contains only fixed normalized fields" do
    patch showcase_mission_control_sequence_path,
      params: {
        reorder: {
          item_key: "range",
          direction: "up",
          owner: "=HYPERLINK(\"https://attacker.test\")"
        }
      }
    get showcase_mission_control_document_export_path

    assert_response :success
    refute_includes response.body, "HYPERLINK"
    refute_includes response.body, "attacker.test"
    assert_equal %w[position sequence status owner], response.body.lines.first.strip.split(",")
  end

  private

  def with_upload(contents, filename:, content_type: "text/plain")
    Tempfile.create(["mission-control", File.extname(filename)]) do |file|
      file.binmode
      file.write(contents)
      file.flush
      upload = Rack::Test::UploadedFile.new(
        file.path,
        content_type,
        true,
        original_filename: filename
      )
      yield upload
    end
  end
end
