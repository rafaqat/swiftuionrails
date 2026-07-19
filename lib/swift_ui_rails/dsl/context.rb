# frozen_string_literal: true

require "digest"

module SwiftUIRails
  # Context for executing DSL blocks and capturing elements
  class DSLContext
    include DSL
    
    attr_reader :view_context, :component, :layout_axis
    
    def initialize(view_context, layout_axis: nil, render_state: nil)
      @view_context = view_context
      @pending_elements = []
      @layout_axis = layout_axis
      @render_state = render_state || if view_context.is_a?(DSLContext)
        view_context.render_state
      else
        { action_sequence: 0 }
      end
      # SECURITY: Use public API instead of private access
      # Store the original component if view_context is already a DSLContext
      @component = if view_context.is_a?(DSLContext) && view_context.respond_to?(:component)
        view_context.component
      elsif view_context.respond_to?(:component_id)
        view_context
      else
        nil
      end
    end

    # Action identifiers must be unique across sibling elements, while also
    # remaining deterministic when a component is reconstructed for a server
    # action. Only an opaque digest enters the DOM; source paths, tag names,
    # and event names remain server-side implementation details.
    def next_action_id(tag_name, event_type, block = nil)
      @render_state[:action_sequence] += 1
      source = if block&.source_location
        file, line = block.source_location
        "#{file}:#{line}"
      else
        "anonymous"
      end
      fingerprint = Digest::SHA256.hexdigest(
        [source, @render_state[:action_sequence], tag_name, event_type].join("\0")
      ).first(32)

      "a_#{fingerprint}"
    end

    # Assigns stable identity to each direct root registered by the block.
    # Callers provide a deterministic semantic scope (for example, a
    # collection declaration plus its stable item key); raw scope values never
    # enter the DOM because only a SHA-256 fingerprint is exposed.
    def with_render_identity_scope(scope)
      value = scope.to_s
      raise ArgumentError, 'render identity scope cannot be empty' if value.empty?

      frame = { scope: value.freeze, root_index: 0 }
      render_identity_scopes << frame
      yield
    ensure
      render_identity_scopes.pop if frame
    end

    protected

    attr_reader :render_state

    public
    
    # Register an element for rendering
    def register_element(element)
      # Prevent duplicate registration
      unless @pending_elements.include?(element)
        assign_scoped_render_identity(element)
        Rails.logger.debug "DSLContext: Registering element #{element.tag_name} (#{element.object_id}), class: #{element.class.name}"
        @pending_elements << element
      else
        Rails.logger.debug "DSLContext: Skipping duplicate registration of #{element.tag_name} (#{element.object_id})"
      end
    end
    
    # Flush all pending elements as HTML
    def flush_elements
      Rails.logger.debug "DSLContext: Flushing #{@pending_elements.length} elements"
      
      html_parts = @pending_elements.map do |element|
        # Ensure view context is set
        element.view_context ||= @view_context
        Rails.logger.debug "DSLContext: Rendering element #{element.tag_name}"
        (element.to_s || "").html_safe
      end
      
      # Clear the pending elements after rendering
      @pending_elements.clear
      
      result = safe_join(html_parts)
      Rails.logger.debug "DSLContext: Flushed #{html_parts.length} elements, total length: #{result.to_s.length}"
      result
    end
    
    # Delegate component_id to the component if available
    def component_id
      if @component
        @component.component_id
      elsif @view_context.respond_to?(:component_id)
        @view_context.component_id
      else
        nil
      end
    end
    
    # Delegate class to the component for metadata
    def class
      # If we have a component, return its class
      # Otherwise if view_context is a component, return its class
      # Otherwise return our own class
      if @component
        @component.class
      elsif @view_context.respond_to?(:component_id)
        @view_context.class
      else
        super
      end
    end
    
    # Delegate view helpers to the view context
    def method_missing(method, *args, **kwargs, &block)
      # Check for both public and private methods since component methods are often private
      Rails.logger.debug "DSLContext.method_missing: #{method}, view_context: #{@view_context.class.name}"
      delegate = if @component&.respond_to?(method, true)
        @component
      elsif @view_context.respond_to?(method, true)
        @view_context
      end

      if delegate
        Rails.logger.debug "DSLContext.method_missing: Delegating #{method} to #{delegate.class.name}"

        # Component helper methods often build DSL elements themselves. Tell
        # create_element which nested context owns those elements so they are
        # not silently discarded as out-of-context content.
        had_context = delegate.instance_variable_defined?(:@_swift_ui_dsl_context)
        previous_context = delegate.instance_variable_get(:@_swift_ui_dsl_context)
        delegate.instance_variable_set(:@_swift_ui_dsl_context, self)

        begin
          delegate.send(method, *args, **kwargs, &block)
        ensure
          if had_context
            delegate.instance_variable_set(:@_swift_ui_dsl_context, previous_context)
          else
            delegate.remove_instance_variable(:@_swift_ui_dsl_context)
          end
        end
      else
        Rails.logger.debug "DSLContext.method_missing: #{method} not found on view_context"
        super
      end
    end
    
    def respond_to_missing?(method, include_private = false)
      @component&.respond_to?(method, include_private) ||
        @view_context.respond_to?(method, include_private) ||
        super
    end
    
    # Make sure view context methods are available
    def content_tag(*args, &block)
      @view_context.content_tag(*args, &block)
    end
    
    def tag(*args)
      @view_context.tag(*args)
    end
    
    def raw(content)
      @view_context.raw(content)
    end
    
    def capture(&block)
      @view_context.capture(&block)
    end
    
    def concat(content)
      @view_context.concat(content)
    end
    
    def class_names(*args)
      @view_context.class_names(*args)
    end
    
    # Renders through the underlying view context AND registers the result as
    # a child element, so `items.each { render ItemComponent.new(...) }`
    # composes multiple children inside a DSL block. The rendered string is
    # remembered by identity so Element#to_s does not append it a second time
    # when it is also the block's return value.
    def render(*args, &block)
      html = base_view_context.render(*args, &block)
      if html.respond_to?(:to_str)
        register_element(DSL::RawElement.new(html, self))
        rendered_children << html
      end
      html
    end

    # True when this exact string object was produced by #render and is
    # already registered as a child element of this context.
    def rendered_child?(candidate)
      rendered_children.any? { |child| child.equal?(candidate) }
    end

    # This context always has a #render delegator, but its eventual host may be
    # a pure DSL test object rather than an ActionView renderer.
    def render_available?
      if @view_context.respond_to?(:render_available?)
        @view_context.render_available?
      else
        @view_context.respond_to?(:render, true)
      end
    end

    private

    # Nested contexts chain @view_context through parent contexts. Walk to the
    # real renderer so a nested render does not re-register in every ancestor.
    def base_view_context
      context = @view_context
      context = context.view_context while context.is_a?(DSLContext)
      context
    end

    def rendered_children
      @rendered_children ||= []
    end

    def assign_scoped_render_identity(element)
      frame = render_identity_scopes.last
      return unless frame && element.respond_to?(:apply_scoped_render_identity, true)

      root_index = frame[:root_index]
      frame[:root_index] += 1
      fingerprint = Digest::SHA256.hexdigest("#{frame[:scope].bytesize}:#{frame[:scope]}:#{root_index}")
      element.send(:apply_scoped_render_identity, "swift-ui-ir-#{fingerprint.first(32)}")
    end

    def render_identity_scopes
      @render_identity_scopes ||= []
    end

    public
    
    # Use safe_join for combining HTML parts
    def safe_join(parts)
      @view_context.safe_join(parts)
    end
    
    # Make sure respond_to? works for component_id
    def respond_to?(method, include_private = false)
      if method.to_sym == :component_id
        true  # Always return true for component_id since we handle it in the method
      else
        super
      end
    end
  end
end
