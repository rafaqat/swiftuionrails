# frozen_string_literal: true

require "digest"
require "json"
require "marcel"
require "uri"

module SwiftUIRails
  # Shared server-side policy for DocumentWorkflow forms. The browser's
  # `accept` and file-size checks are usability hints, never an authorization
  # boundary, so controllers should call validate_upload! before persistence.
  module DocumentWorkflow
    CREATION_SOURCES = %i[new import template duplicate generated].freeze
    MAX_UPLOAD_BYTES = 2.gigabytes
    MAX_UPLOAD_FILES = 20
    MAX_METADATA_BYTES = 4.kilobytes
    MAX_METADATA_ENTRIES = 20
    SIGNING_PURPOSE = "swift_ui_rails.document_creation"

    class ValidationError < SwiftUIRails::Error; end

    module_function

    def validate_upload!(upload, max_bytes:, content_types:)
      raise ValidationError, "document upload is required" unless upload

      limit = normalize_max_bytes(max_bytes)
      size = upload_size(upload)
      raise ValidationError, "document size is unavailable" unless size
      raise ValidationError, "document size is invalid" if size.negative?
      raise ValidationError, "document exceeds the #{limit}-byte limit" if size > limit

      allowed_types = normalize_content_types(content_types)
      declared_type = upload_content_type(upload)
      unless declared_type && allowed_types.include?(declared_type)
        raise ValidationError, "document content type is not allowed"
      end

      filename = upload_filename(upload)
      if filename && (!filename.valid_encoding? || filename.bytesize > 255 ||
          filename.match?(/[\u0000-\u001f\u007f\\\/]/) ||
          filename != File.basename(filename))
        raise ValidationError, "document filename is invalid"
      end

      detected_type = detected_upload_content_type(upload, filename: filename)
      unless detected_type && allowed_types.include?(detected_type)
        raise ValidationError, "document contents do not match an allowed content type"
      end

      upload
    end

    def validate_uploads!(uploads, max_bytes:, content_types:, max_files: MAX_UPLOAD_FILES)
      files = Array(uploads).compact
      file_limit = strict_integer(max_files, "max_files")
      unless file_limit.between?(1, MAX_UPLOAD_FILES)
        raise ArgumentError, "max_files must be between 1 and #{MAX_UPLOAD_FILES}"
      end
      unless files.length.between?(1, file_limit)
        raise ValidationError, "document upload must contain 1 to #{file_limit} files"
      end

      byte_limit = normalize_max_bytes(max_bytes)
      sizes = files.map { |file| upload_size(file) }
      raise ValidationError, "document size is unavailable" if sizes.any?(&:nil?)
      raise ValidationError, "documents exceed the #{byte_limit}-byte total limit" if sizes.sum > byte_limit

      files.each do |file|
        validate_upload!(file, max_bytes: byte_limit, content_types: content_types)
      end
      files
    end

    def sign_creation_context(source:, metadata: {}, expires_in: 1.hour)
      normalized_source = normalize_source(source)
      normalized_metadata = normalize_metadata(metadata)
      lifetime = begin
        Integer(expires_in)
      rescue TypeError, ArgumentError
        raise ArgumentError, "creation context expiry must be an integer number of seconds"
      end
      unless lifetime.between?(60, 24.hours.to_i)
        raise ArgumentError, "creation context expiry must be between 60 seconds and 24 hours"
      end

      verifier.generate(
        { "source" => normalized_source.to_s, "metadata" => normalized_metadata },
        purpose: SIGNING_PURPOSE,
        expires_in: lifetime
      )
    end

    def verify_creation_context!(token)
      encoded = token.to_s
      unless encoded.valid_encoding? && encoded.bytesize.between?(1, 16.kilobytes)
        raise ValidationError, "document creation context is invalid or expired"
      end

      payload = verifier.verify(encoded, purpose: SIGNING_PURPOSE)
      raise ValidationError, "document creation context is invalid or expired" unless payload.is_a?(Hash)

      source = normalize_source(payload.fetch("source"))
      metadata = normalize_metadata(payload.fetch("metadata", {}))

      { source: source, metadata: metadata }
    rescue ActiveSupport::MessageVerifier::InvalidSignature, KeyError, TypeError, ArgumentError
      raise ValidationError, "document creation context is invalid or expired"
    end

    def creation_source!(source)
      normalize_source(source)
    end

    def max_bytes!(value)
      normalize_max_bytes(value)
    end

    def normalize_source(source)
      value = source.to_s.downcase
      if value.valid_encoding? && value.bytesize <= 16 && CREATION_SOURCES.any? { |allowed| allowed.to_s == value }
        return value.to_sym
      end

      raise ArgumentError, "unknown document creation source: #{source.inspect}"
    end
    private_class_method :normalize_source

    def normalize_metadata(metadata)
      raise ArgumentError, "creation metadata must be a hash" unless metadata.is_a?(Hash)
      raise ArgumentError, "creation metadata has too many entries" if metadata.size > MAX_METADATA_ENTRIES

      normalized = metadata.each_with_object({}) do |(key, value), output|
        normalized_key = key.to_s
        unless normalized_key.valid_encoding? && normalized_key.bytesize <= 64 &&
            normalized_key.match?(/\A[a-zA-Z][a-zA-Z0-9_.-]{0,63}\z/)
          raise ArgumentError, "creation metadata contains an invalid key"
        end

        output[normalized_key] = normalize_metadata_value(value)
      end
      if JSON.generate(normalized).bytesize > MAX_METADATA_BYTES
        raise ArgumentError, "creation metadata is too large"
      end

      normalized.freeze
    end
    private_class_method :normalize_metadata

    def normalize_metadata_value(value)
      case value
      when String
        if !value.valid_encoding? || value.bytesize > 500
          raise ArgumentError, "creation metadata value is too long or invalidly encoded"
        end
        raise ArgumentError, "creation metadata contains control characters" if value.match?(/[\u0000-\u001f\u007f]/)

        value
      when Integer, Float
        raise ArgumentError, "creation metadata number must be finite" if value.is_a?(Float) && !value.finite?

        value
      when TrueClass, FalseClass, NilClass
        value
      else
        raise ArgumentError, "creation metadata values must be scalar JSON values"
      end
    end
    private_class_method :normalize_metadata_value

    def normalize_max_bytes(value)
      bytes = strict_integer(value, "max_bytes")
      unless bytes.between?(1, MAX_UPLOAD_BYTES)
        raise ArgumentError, "max_bytes must be between 1 and #{MAX_UPLOAD_BYTES}"
      end

      bytes
    rescue TypeError, ArgumentError => error
      raise error if error.is_a?(ArgumentError) && error.message.start_with?("max_bytes")

      raise ArgumentError, "max_bytes must be an integer"
    end
    private_class_method :normalize_max_bytes

    def strict_integer(value, name)
      if value.is_a?(Integer)
        value
      elsif value.is_a?(String) && value.match?(/\A[0-9]+\z/)
        value.to_i
      else
        raise ArgumentError, "#{name} must be an integer"
      end
    end
    private_class_method :strict_integer

    def normalize_content_types(content_types)
      types = Array(content_types).map { |type| type.to_s.downcase.strip }.uniq
      if types.empty? || types.length > 20 || types.any? { |type| !valid_mime_type?(type) }
        raise ArgumentError, "content_types must contain 1 to 20 concrete MIME types"
      end

      types
    end
    private_class_method :normalize_content_types

    def valid_mime_type?(type)
      type.match?(%r{\A[a-z0-9][a-z0-9!#$&^_.+-]{0,63}/[a-z0-9][a-z0-9!#$&^_.+-]{0,63}\z})
    end
    private_class_method :valid_mime_type?

    def upload_size(upload)
      value = if upload.respond_to?(:tempfile) && upload.tempfile.respond_to?(:size)
        upload.tempfile.size
      elsif upload.respond_to?(:io) && upload.io.respond_to?(:size)
        upload.io.size
      elsif upload.respond_to?(:byte_size)
        upload.byte_size
      elsif upload.respond_to?(:size)
        upload.size
      end
      Integer(value) if value
    rescue TypeError, ArgumentError
      nil
    end
    private_class_method :upload_size

    def upload_content_type(upload)
      value = upload.content_type if upload.respond_to?(:content_type)
      value.to_s.downcase.split(";", 2).first.strip.presence
    end
    private_class_method :upload_content_type

    def upload_filename(upload)
      value = if upload.respond_to?(:original_filename)
        upload.original_filename
      elsif upload.respond_to?(:filename)
        upload.filename.to_s
      end
      value.to_s.presence
    end
    private_class_method :upload_filename

    def detected_upload_content_type(upload, filename:)
      io = if upload.respond_to?(:tempfile)
        upload.tempfile
      elsif upload.respond_to?(:io)
        upload.io
      elsif upload.respond_to?(:read)
        upload
      end
      unless io&.respond_to?(:read)
        raise ValidationError, "document contents are unavailable for inspection"
      end

      original_position = io.pos if io.respond_to?(:pos)
      Marcel::MimeType.for(io, name: filename).to_s.downcase.presence
    rescue IOError, SystemCallError, ArgumentError
      raise ValidationError, "document contents could not be inspected"
    ensure
      if defined?(io) && io && defined?(original_position) && !original_position.nil? && io.respond_to?(:seek)
        io.seek(original_position)
      end
    end
    private_class_method :detected_upload_content_type

    def verifier
      Rails.application.message_verifier(SIGNING_PURPOSE)
    end
    private_class_method :verifier
  end

  module DSL
    # SwiftUI 2027's collection reordering and document APIs do not map to a
    # client-only state model on the web. These equivalents keep Rails routes
    # authoritative and make pointer interaction an optional enhancement.
    SwipeActionDefinition = Struct.new(:label, :action, :method, :tone, :attributes, keyword_init: true)
    private_constant :SwipeActionDefinition

    REORDER_LAYOUTS = %i[list grid custom].freeze
    REORDER_METHODS = %i[post patch put].freeze
    SWIPE_METHODS = %i[post patch put delete].freeze
    SWIPE_EDGES = %i[leading trailing].freeze
    SWIPE_TONES = {
      neutral: "border border-slate-300 bg-white text-slate-800",
      accent: "bg-blue-600 text-white",
      destructive: "bg-red-600 text-white"
    }.freeze
    MAX_REORDER_ITEMS = 500
    MAX_SWIPE_ACTIONS = 8
    SWIPE_FORBIDDEN_ATTRIBUTES = %w[
      form
      formaction
      formenctype
      formmethod
      formnovalidate
      formtarget
      name
      value
    ].freeze

    # Renders a server-owned ordered collection. Every row/card has stable-key
    # Up and Down forms; drag and drop submits the same route with a target key
    # and never mutates the DOM as an alternative source of truth.
    def reorderable_collection(
      items:,
      key:,
      move_path:,
      label:,
      id: nil,
      item_label: nil,
      layout: :list,
      columns: 3,
      method: :patch,
      param: :reorder,
      drag: true,
      **attrs,
      &block
    )
      raise ArgumentError, "reorderable_collection requires a content block" unless block

      collection = workflow_bounded_collection(items)
      layout_name = workflow_enum!(layout, REORDER_LAYOUTS, "reorder layout")
      http_method = workflow_enum!(method, REORDER_METHODS, "reorder method")
      drag_enabled = workflow_boolean!(drag, "drag")
      action = workflow_same_origin_path!(move_path, "move_path")
      field_prefix = workflow_field_prefix!(param)
      accessible_label = workflow_bounded_text!(label, "collection label", 160)
      root_id = id ? workflow_dom_id!(id, "collection id") : workflow_next_id("reorder")
      keyed_items = workflow_keyed_items(collection, key, item_label)

      attrs[:id] = root_id
      attrs[:role] ||= "list"
      attrs[:aria] = workflow_merge_attributes(attrs[:aria], label: accessible_label)
      attrs[:class] = class_names(workflow_reorder_classes(layout_name), attrs[:class])
      if layout_name == :grid
        count = workflow_integer!(columns, "grid columns", 1..12)
        attrs[:style] = workflow_merge_styles(
          attrs[:style],
          "grid-template-columns: repeat(#{count}, minmax(0, 1fr))"
        )
      end
      attrs[:data] = workflow_data(
        attrs[:data],
        sui_workflow: JSON.generate(
          kind: "reorder",
          layout: layout_name,
          drag: drag_enabled
        )
      )

      create_element(:div, nil, **attrs) do
        keyed_items.each_with_index do |entry, index|
          item, stable_key, item_name, item_id = entry.values_at(:item, :key, :label, :id)
          item_data = {
            sui_workflow_role: "reorder-item",
            sui_workflow_key: stable_key
          }

          create_element(
            :div,
            nil,
            id: "#{root_id}-#{item_id}",
            role: "listitem",
            draggable: ("true" if drag_enabled),
            class: "swift-ui-reorder-item",
            data: item_data
          ) do
            create_element(:div, nil, class: "swift-ui-reorder-content") do
              instance_exec(item, index, &block)
            end
            create_element(
              :div,
              nil,
              role: "group",
              aria: { label: "Reorder #{item_name}" },
              class: "swift-ui-reorder-controls mt-3 flex flex-wrap gap-2"
            ) do
              workflow_reorder_button(
                "Move up",
                item_name: item_name,
                stable_key: stable_key,
                direction: "up",
                disabled: index.zero?,
                action: action,
                method: http_method,
                field_prefix: field_prefix
              )
              workflow_reorder_button(
                "Move down",
                item_name: item_name,
                stable_key: stable_key,
                direction: "down",
                disabled: index == keyed_items.length - 1,
                action: action,
                method: http_method,
                field_prefix: field_prefix
              )
            end
          end
        end

        workflow_drag_form(
          action: action,
          method: http_method,
          field_prefix: field_prefix
        ) if drag_enabled && keyed_items.length > 1
      end
    end

    # Creates a declarative, route-backed swipe action. Pass the returned value
    # to swipe_actions; raw hashes are not accepted so every route/method/tone
    # crosses the same validation boundary.
    def swipe_action(label, action:, method: :post, tone: :neutral, **attrs)
      workflow_reject_attributes!(attrs, SWIPE_FORBIDDEN_ATTRIBUTES, "swipe action")
      SwipeActionDefinition.new(
        label: workflow_bounded_text!(label, "swipe action label", 80),
        action: workflow_same_origin_path!(action, "swipe action path"),
        method: workflow_enum!(method, SWIPE_METHODS, "swipe action method"),
        tone: workflow_enum!(tone, SWIPE_TONES.keys, "swipe action tone"),
        attributes: attrs
      ).freeze
    end

    # Pointer movement only reveals/announces the action rail. It never submits
    # an action. The real Rails form buttons remain visible and focusable for
    # keyboard, switch, voice, pointer, and no-JavaScript users.
    def swipe_actions(label:, actions:, edge: :trailing, threshold: 72, **attrs, &block)
      raise ArgumentError, "swipe_actions requires a content block" unless block

      definitions = Array(actions)
      unless definitions.length.between?(1, MAX_SWIPE_ACTIONS) &&
          definitions.all? { |definition| definition.is_a?(SwipeActionDefinition) }
        raise ArgumentError, "actions must contain 1 to #{MAX_SWIPE_ACTIONS} values returned by swipe_action"
      end

      accessible_label = workflow_bounded_text!(label, "swipe row label", 160)
      swipe_edge = workflow_enum!(edge, SWIPE_EDGES, "swipe edge")
      swipe_threshold = workflow_integer!(threshold, "swipe threshold", 24..240)
      attrs[:role] ||= "group"
      attrs[:aria] = workflow_merge_attributes(attrs[:aria], label: accessible_label)
      attrs[:class] = class_names("swift-ui-swipe-actions", attrs[:class])
      attrs[:style] = workflow_merge_styles(attrs[:style], "touch-action: pan-y")
      attrs[:data] = workflow_data(
        attrs[:data],
        sui_workflow: JSON.generate(
          kind: "swipe",
          edge: swipe_edge,
          threshold: swipe_threshold,
          label: accessible_label
        )
      )

      create_element(:div, nil, **attrs) do
        create_element(
          :div,
          nil,
          class: "swift-ui-swipe-actions-content",
          data: { sui_workflow_role: "swipe-content" },
          &block
        )
        create_element(
          :span,
          "",
          role: "status",
          aria: { live: "polite" },
          class: "sr-only",
          data: { sui_workflow_role: "swipe-status" }
        )
        create_element(
          :div,
          nil,
          role: "group",
          aria: { label: "#{accessible_label} actions" },
          class: "swift-ui-swipe-actions-buttons",
          data: { sui_workflow_role: "swipe-buttons" }
        ) do
          definitions.each { |definition| workflow_render_swipe_action(definition) }
        end
      end
    end

    def document_workflow(label:, id: nil, **attrs, &block)
      raise ArgumentError, "document_workflow requires a block" unless block

      attrs[:id] = id ? workflow_dom_id!(id, "document workflow id") : workflow_next_id("documents")
      attrs[:role] ||= "region"
      attrs[:aria] = workflow_merge_attributes(
        attrs[:aria],
        label: workflow_bounded_text!(label, "document workflow label", 160)
      )
      attrs[:class] = class_names("swift-ui-document-workflow", attrs[:class])
      create_element(:section, nil, **attrs, &block)
    end

    # Multipart import form with signed creation provenance. Direct Upload is
    # optional; when enabled, Active Storage's native direct-upload events feed
    # the progress element. A normal multipart submit reports indeterminate
    # progress because browsers do not expose navigation upload bytes.
    def document_import(
      action:,
      name: "document[file]",
      label: "Choose document",
      accept:,
      max_bytes:,
      source: :import,
      metadata: {},
      submit_label: "Import",
      method: :post,
      multiple: false,
      max_files: nil,
      required: true,
      direct_upload: false,
      direct_upload_url: nil,
      creation_context_name: "document[creation_context]",
      expires_in: 1.hour,
      id: nil,
      **attrs,
      &block
    )
      upload_action = workflow_same_origin_path!(action, "document import action")
      http_method = workflow_enum!(method, REORDER_METHODS, "document import method")
      input_name = workflow_field_name!(name, "document input name")
      context_name = workflow_field_name!(creation_context_name, "creation context name")
      input_label = workflow_bounded_text!(label, "document input label", 160)
      button_label = workflow_bounded_text!(submit_label, "document submit label", 80)
      accepts = workflow_accept_values(accept)
      limit = DocumentWorkflow.max_bytes!(max_bytes)
      multiple_value = workflow_boolean!(multiple, "multiple")
      file_limit = max_files.nil? ? (multiple_value ? DocumentWorkflow::MAX_UPLOAD_FILES : 1) :
        workflow_integer!(max_files, "max_files", 1..DocumentWorkflow::MAX_UPLOAD_FILES)
      if !multiple_value && file_limit != 1
        raise ArgumentError, "max_files must be 1 when multiple is false"
      end
      input_name = "#{input_name}[]" if multiple_value && !input_name.end_with?("[]")
      required_value = workflow_boolean!(required, "required")
      direct_upload_value = workflow_boolean!(direct_upload, "direct_upload")
      source_value = DocumentWorkflow.creation_source!(source)
      token = DocumentWorkflow.sign_creation_context(
        source: source_value,
        metadata: metadata,
        expires_in: expires_in
      )
      form_id = id ? workflow_dom_id!(id, "document import id") : workflow_next_id("document-import")
      file_id = "#{form_id}-file"
      progress_id = "#{form_id}-progress"

      input_data = {
        sui_workflow_role: "file-input"
      }
      if direct_upload_value
        input_data[:direct_upload_url] = workflow_direct_upload_path!(direct_upload_url)
      end

      attrs[:id] = form_id
      attrs[:enctype] = "multipart/form-data"
      attrs[:class] = class_names("swift-ui-document-import", attrs[:class])
      attrs[:data] = workflow_data(
        attrs[:data],
        turbo: false,
        sui_workflow: JSON.generate(
          kind: "document",
          maxBytes: limit,
          maxFiles: file_limit,
          directUpload: direct_upload_value,
          source: source_value
        )
      )

      workflow_mutation_form(action: upload_action, method: http_method, **attrs) do
        create_element(:input, nil, type: "hidden", name: context_name, value: token, autocomplete: "off")
        instance_eval(&block) if block
        create_element(
          :label,
          input_label,
          for: file_id,
          class: "swift-ui-document-import-label block font-semibold"
        )
        create_element(
          :input,
          nil,
          id: file_id,
          type: "file",
          name: input_name,
          accept: accepts.join(","),
          multiple: multiple_value,
          required: required_value,
          aria: { describedby: progress_id },
          class: "swift-ui-document-file block w-full rounded-lg border border-slate-300 bg-white p-2 text-slate-950",
          data: input_data
        )
        create_element(
          :progress,
          "0%",
          id: progress_id,
          max: 100,
          value: 0,
          hidden: true,
          aria: { label: "Upload progress" },
          class: "swift-ui-document-progress block w-full",
          data: { sui_workflow_role: "upload-progress" }
        )
        create_element(
          :span,
          "No upload in progress",
          role: "status",
          aria: { live: "polite" },
          class: "swift-ui-document-status block text-sm text-slate-400",
          data: { sui_workflow_role: "upload-status" }
        )
        create_element(
          :button,
          button_label,
          type: "submit",
          class: "swift-ui-document-submit rounded-xl bg-blue-600 px-4 py-2 font-bold text-white disabled:opacity-50",
          data: { sui_workflow_role: "upload-submit" }
        )
      end
    end

    # POST-backed document creation for new/template/duplicate/generated
    # sources. The context is signed and expiring; controllers verify it with
    # DocumentWorkflow.verify_creation_context! before using the metadata.
    def document_creation_action(
      label,
      action:,
      source: :new,
      metadata: {},
      method: :post,
      creation_context_name: "document[creation_context]",
      expires_in: 1.hour,
      **attrs
    )
      create_action = workflow_same_origin_path!(action, "document creation action")
      http_method = workflow_enum!(method, REORDER_METHODS, "document creation method")
      context_name = workflow_field_name!(creation_context_name, "creation context name")
      token = DocumentWorkflow.sign_creation_context(
        source: source,
        metadata: metadata,
        expires_in: expires_in
      )
      button_label = workflow_bounded_text!(label, "document creation label", 80)

      attrs[:class] = class_names("swift-ui-document-creation", attrs[:class])
      workflow_mutation_form(action: create_action, method: http_method, **attrs) do
        create_element(:input, nil, type: "hidden", name: context_name, value: token, autocomplete: "off")
        create_element(
          :button,
          button_label,
          type: "submit",
          class: "swift-ui-document-create-button rounded-xl bg-blue-600 px-4 py-2 font-bold text-white"
        )
      end
    end

    # A streaming export is a plain same-origin GET link with Turbo disabled;
    # the Rails action remains responsible for authorization, Content-Type,
    # Content-Disposition, caching, and send_data/send_file/enumerator output.
    def document_export(
      label = nil,
      destination:,
      filename: nil,
      content_type: nil,
      download: true,
      **attrs,
      &block
    )
      if label.nil? && !block
        raise ArgumentError, "document_export requires a label or block"
      end

      attrs[:href] = workflow_same_origin_path!(destination, "document export destination")
      attrs[:download] = workflow_download_value(filename, download)
      attrs[:type] = workflow_mime_type!(content_type) if content_type
      attrs[:class] = class_names("swift-ui-document-export", attrs[:class])
      attrs[:data] = workflow_data(
        attrs[:data],
        turbo: false,
        document_export: "stream"
      )

      block ? create_element(:a, nil, **attrs, &block) : create_element(:a, label, **attrs)
    end

    private

    def workflow_bounded_collection(items)
      unless items.respond_to?(:each) && !items.is_a?(String)
        raise ArgumentError, "items must be an enumerable collection"
      end

      output = []
      items.each do |item|
        output << item
        break if output.length > MAX_REORDER_ITEMS
      end
      raise ArgumentError, "reorderable collections support at most #{MAX_REORDER_ITEMS} items" if output.length > MAX_REORDER_ITEMS

      output
    end

    def workflow_keyed_items(collection, key, item_label)
      seen = {}
      collection.map do |item|
        raw_key = workflow_extract_item_value(item, key, "key")
        stable_key = workflow_stable_key!(raw_key)
        raise ArgumentError, "reorder keys must be unique" if seen.key?(stable_key)

        seen[stable_key] = true
        raw_label = if item_label.nil?
          stable_key
        else
          workflow_extract_item_value(item, item_label, "item_label")
        end

        {
          item: item,
          key: stable_key,
          label: workflow_bounded_text!(raw_label, "item label", 160),
          id: "item-#{Digest::SHA256.hexdigest(stable_key)[0, 24]}"
        }
      end
    end

    def workflow_extract_item_value(item, extractor, name)
      if extractor.respond_to?(:call)
        extractor.call(item)
      elsif extractor.is_a?(String) || extractor.is_a?(Symbol)
        key_name = extractor.to_sym
        key_candidates = [extractor, key_name, extractor.to_s].uniq
        matching_key = if item.respond_to?(:key?)
          key_candidates.find { |candidate| item.key?(candidate) }
        end
        if matching_key
          item[matching_key]
        elsif item.respond_to?(key_name) && item.method(key_name).arity.zero?
          item.public_send(key_name)
        else
          raise ArgumentError, "#{name} cannot be read from an item"
        end
      else
        raise ArgumentError, "#{name} must be a field name or callable"
      end
    end

    def workflow_stable_key!(value)
      unless value.is_a?(String) || value.is_a?(Symbol) || value.is_a?(Numeric)
        raise ArgumentError, "reorder keys must be strings, symbols, or numbers"
      end

      key = value.to_s
      if !key.valid_encoding? || key.empty? || key.bytesize > 256 || key.match?(/[\u0000-\u001f\u007f]/)
        raise ArgumentError, "reorder key must contain 1 to 256 non-control bytes"
      end

      key
    end

    def workflow_reorder_classes(layout)
      case layout
      when :list then "swift-ui-reorderable-list"
      when :grid then "swift-ui-reorderable-grid grid"
      else "swift-ui-reorderable-custom"
      end
    end

    def workflow_reorder_button(label, item_name:, stable_key:, direction:, disabled:, action:, method:, field_prefix:)
      workflow_mutation_form(action: action, method: method, class: "swift-ui-reorder-form") do
        create_element(
          :input,
          nil,
          type: "hidden",
          name: "#{field_prefix}[item_key]",
          value: stable_key,
          autocomplete: "off"
        )
        create_element(
          :input,
          nil,
          type: "hidden",
          name: "#{field_prefix}[direction]",
          value: direction,
          autocomplete: "off"
        )
        create_element(
          :button,
          label,
          type: "submit",
          disabled: disabled,
          aria: { label: "#{label} #{item_name}" },
          class: class_names(
            "swift-ui-reorder-button swift-ui-reorder-#{direction}",
            "rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-sm font-semibold text-slate-800",
            "disabled:cursor-not-allowed disabled:opacity-40"
          )
        )
      end
    end

    def workflow_drag_form(action:, method:, field_prefix:)
      workflow_mutation_form(
        action: action,
        method: method,
        hidden: true,
        class: "swift-ui-reorder-drag-form",
        data: { sui_workflow_role: "drag-form" }
      ) do
        create_element(
          :input,
          nil,
          type: "hidden",
          name: "#{field_prefix}[item_key]",
          data: { sui_workflow_role: "drag-item-key" }
        )
        create_element(
          :input,
          nil,
          type: "hidden",
          name: "#{field_prefix}[target_key]",
          data: { sui_workflow_role: "drag-target-key" }
        )
        create_element(
          :input,
          nil,
          type: "hidden",
          name: "#{field_prefix}[placement]",
          value: "before",
          data: { sui_workflow_role: "drag-placement" }
        )
      end
    end

    def workflow_render_swipe_action(definition)
      button_attrs = definition.attributes.dup
      button_attrs[:type] = "submit"
      button_attrs[:class] = class_names(
        "swift-ui-swipe-action",
        SWIPE_TONES.fetch(definition.tone),
        button_attrs[:class]
      )

      workflow_mutation_form(
        action: definition.action,
        method: definition.method,
        class: "swift-ui-swipe-action-form"
      ) do
        create_element(:button, definition.label, **button_attrs)
      end
    end

    def workflow_mutation_form(action:, method:, **attrs, &block)
      attrs[:action] = action
      attrs[:method] = "post"
      attrs[:accept_charset] ||= "UTF-8"
      attrs[:data] = workflow_data(attrs[:data], turbo: false)

      create_element(:form, nil, **attrs) do
        workflow_render_csrf_protection
        if method.to_sym != :post
          create_element(:input, nil, type: "hidden", name: "_method", value: method, autocomplete: "off")
        end
        create_element(:input, nil, type: "hidden", name: "utf8", value: "✓", autocomplete: "off")
        instance_eval(&block) if block
      end
    end

    def workflow_same_origin_path!(value, name)
      source = value.to_s
      if !source.valid_encoding? || source.empty? || source.bytesize > 2048 ||
          source.match?(/[\u0000-\u0020\u007f\\]/) ||
          source.match?(/%(?:0[0-9a-f]|1[0-9a-f]|2f|5c|7f)/i) ||
          !source.start_with?("/") || source.start_with?("//")
        raise ArgumentError, "#{name} must be a same-origin absolute path"
      end

      uri = URI.parse(source)
      unless uri.relative? && uri.host.nil? && uri.scheme.nil? && uri.fragment.nil?
        raise ArgumentError, "#{name} must be a same-origin absolute path without a fragment"
      end

      safe = Security::URLValidator.validate_link_href(source, fallback: nil)
      raise ArgumentError, "#{name} is unsafe" unless safe == source

      source
    rescue URI::InvalidURIError
      raise ArgumentError, "#{name} is invalid"
    end

    def workflow_render_csrf_protection
      helper = if respond_to?(:view_context) && view_context.respond_to?(:form_authenticity_token, true)
        view_context
      elsif respond_to?(:form_authenticity_token, true)
        self
      end
      return unless helper && workflow_forgery_protection_enabled?

      token = helper.send(:form_authenticity_token)
      param = ActionController::Base.request_forgery_protection_token || :authenticity_token
      create_element(
        :input,
        nil,
        type: "hidden",
        name: param.to_s,
        value: token,
        autocomplete: "off"
      )
    end

    def workflow_forgery_protection_enabled?
      defined?(ActionController::Base) &&
        ActionController::Base.respond_to?(:allow_forgery_protection) &&
        ActionController::Base.allow_forgery_protection
    end

    def workflow_dom_id!(value, name)
      token = value.to_s
      return token if token.valid_encoding? && token.match?(/\A[a-zA-Z][a-zA-Z0-9_-]{0,127}\z/)

      raise ArgumentError, "#{name} must be a valid DOM identifier"
    end

    def workflow_field_prefix!(value)
      token = value.to_s
      return token if token.valid_encoding? && token.match?(/\A[a-zA-Z][a-zA-Z0-9_]{0,63}\z/)

      raise ArgumentError, "reorder param must be a simple field name"
    end

    def workflow_field_name!(value, name)
      token = value.to_s
      pattern = /\A[a-zA-Z][a-zA-Z0-9_]*(?:\[[a-zA-Z][a-zA-Z0-9_]*\])*(?:\[\])?\z/
      return token if token.valid_encoding? && token.match?(pattern) && token.bytesize <= 160

      raise ArgumentError, "#{name} is invalid"
    end

    def workflow_bounded_text!(value, name, maximum)
      text = value.to_s
      if !text.valid_encoding? || text.strip.empty? || text.length > maximum ||
          text.match?(/[\u0000-\u001f\u007f]/)
        raise ArgumentError, "#{name} must contain 1 to #{maximum} printable characters"
      end

      text
    end

    def workflow_enum!(value, allowed, name)
      normalized = value.to_s.downcase
      if normalized.valid_encoding? && normalized.bytesize <= 64
        match = allowed.find { |candidate| candidate.to_s == normalized }
        return match if match
      end

      raise ArgumentError, "unknown #{name}: #{value.inspect}"
    end

    def workflow_boolean!(value, name)
      return value if value == true || value == false

      raise ArgumentError, "#{name} must be true or false"
    end

    def workflow_integer!(value, name, range)
      number = if value.is_a?(Integer)
        value
      elsif value.is_a?(String) && value.match?(/\A[0-9]+\z/)
        value.to_i
      else
        raise ArgumentError, "#{name} must be an integer"
      end
      return number if range.cover?(number)

      raise ArgumentError, "#{name} must be between #{range.begin} and #{range.end}"
    rescue TypeError, ArgumentError => error
      raise error if error.is_a?(ArgumentError) && error.message.start_with?(name)

      raise ArgumentError, "#{name} must be an integer"
    end

    def workflow_accept_values(values)
      normalized = Array(values).map { |value| value.to_s.downcase.strip }.uniq
      valid = normalized.length.between?(1, 20) && normalized.all? do |value|
        value.valid_encoding? && (value.match?(/\A\.[a-z0-9][a-z0-9.+_-]{0,15}\z/) ||
          value.match?(%r{\A[a-z0-9][a-z0-9!#$&^_.+-]{0,63}/(?:[a-z0-9][a-z0-9!#$&^_.+-]{0,63}|\*)\z})
        )
      end
      raise ArgumentError, "accept must contain 1 to 20 file extensions or MIME types" unless valid

      normalized
    end

    def workflow_direct_upload_path!(configured_path)
      path = configured_path
      if path.nil?
        helpers = Rails.application.routes.url_helpers
        path = helpers.rails_direct_uploads_path if helpers.respond_to?(:rails_direct_uploads_path)
      end
      unless path
        raise ArgumentError, "direct_upload requires Active Storage routes or direct_upload_url"
      end

      workflow_same_origin_path!(path, "direct upload URL")
    end

    def workflow_download_value(filename, download)
      enabled = workflow_boolean!(download, "download")
      return nil unless enabled
      return true if filename.nil?

      value = filename.to_s
      if !value.valid_encoding? || value.empty? || value.bytesize > 255 || value != File.basename(value) ||
          value.match?(/[\u0000-\u001f\u007f\\\/]/)
        raise ArgumentError, "download filename is invalid"
      end

      value
    end

    def workflow_mime_type!(value)
      type = value.to_s.downcase
      pattern = %r{\A[a-z0-9][a-z0-9!#$&^_.+-]{0,63}/[a-z0-9][a-z0-9!#$&^_.+-]{0,63}\z}
      return type if type.valid_encoding? && type.match?(pattern)

      raise ArgumentError, "content_type must be a concrete MIME type"
    end

    def workflow_next_id(prefix)
      @_swift_ui_workflow_sequence = instance_variable_get(:@_swift_ui_workflow_sequence).to_i + 1
      "swift-ui-#{prefix}-#{@_swift_ui_workflow_sequence}"
    end

    def workflow_merge_attributes(existing, additions)
      (existing || {}).merge(additions) do |_key, original, required|
        original.nil? ? required : original
      end
    end

    def workflow_data(existing, additions)
      result = (existing || {}).dup
      additions.compact.each do |key, value|
        key_string = key.to_s
        existing_key = result.keys.find { |candidate| candidate.to_s == key_string }

        result[existing_key || key] = value
      end
      result
    end

    def workflow_merge_styles(*styles)
      styles.compact.map(&:to_s).map { |style| style.strip.sub(/;\z/, "") }.reject(&:empty?).join("; ")
    end

    def workflow_reject_attributes!(attributes, forbidden, name)
      dangerous = attributes.keys.map { |key| key.to_s.downcase.delete("_-") } & forbidden
      return if dangerous.empty?

      raise ArgumentError, "#{name} cannot override form routing attributes"
    end
  end
end
