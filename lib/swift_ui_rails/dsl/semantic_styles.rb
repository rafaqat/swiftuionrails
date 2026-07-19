# frozen_string_literal: true

module SwiftUIRails
  module DSL
    # SwiftUI-shaped, theme-aware styling roles. These modifiers deliberately
    # emit framework-owned classes rather than palette utilities so an
    # application can replace its visual language by overriding CSS variables.
    module SemanticStyleModifiers
      APPEARANCE_NAME = /\A[a-z][a-z0-9-]{0,63}\z/
      VISUALLY_HIDDEN_DEFAULT = Object.new.freeze

      FOREGROUND_STYLES = %i[
        primary secondary tertiary quaternary accent success warning danger
        on_accent
      ].freeze

      BACKGROUND_STYLES = %i[
        canvas surface elevated muted accent success warning danger
      ].freeze

      FONT_STYLES = %i[
        large_title title title2 title3 headline subheadline body callout
        footnote caption caption2
      ].freeze

      TEXT_STYLES = {
        title: { font: :title, foreground: :primary }.freeze,
        headline: { font: :headline, foreground: :primary }.freeze,
        body: { font: :body, foreground: :primary }.freeze,
        supporting: { font: :subheadline, foreground: :secondary }.freeze,
        metadata: { font: :footnote, foreground: :tertiary }.freeze,
        caption: { font: :caption, foreground: :secondary }.freeze
      }.freeze

      def foreground_style(role, &block)
        apply_semantic_foreground(normalize_semantic_role!(role, FOREGROUND_STYLES, :foreground_style))
        preserve_semantic_style_block(block)
      end

      def background_style(role, &block)
        normalized_role = normalize_semantic_role!(role, BACKGROUND_STYLES, :background_style)
        replace_modifier_classes(
          :background_style,
          [semantic_style_class('background', normalized_role)]
        )
        preserve_semantic_style_block(block)
      end

      def font(role, &block)
        apply_semantic_font(normalize_semantic_role!(role, FONT_STYLES, :font))
        preserve_semantic_style_block(block)
      end

      # A text style is a convenient preset, not a CSS-specific shortcut. It
      # owns a font and foreground facet so explicit modifiers can override
      # either facet later in the chain. Applying another text style resets
      # both facets to that preset.
      def text_style(role, &block)
        normalized_role = normalize_semantic_role!(role, TEXT_STYLES.keys, :text_style)
        preset = TEXT_STYLES.fetch(normalized_role)

        replace_modifier_classes(
          :semantic_text_style,
          [semantic_style_class('text-style', normalized_role)]
        )
        apply_semantic_font(preset.fetch(:font))
        apply_semantic_foreground(preset.fetch(:foreground))

        preserve_semantic_style_block(block)
      end

      # A semantic hook for application-defined view styles. This is the Ruby
      # equivalent of extracting a custom SwiftUI ViewModifier: component code
      # names the visual intent while CSS owns its platform implementation.
      # Unlike `class:` or `tw`, appearance names cannot contain utility lists
      # or arbitrary CSS syntax.
      def appearance(name, &block)
        unless name.is_a?(String) || name.is_a?(Symbol)
          raise ArgumentError, 'appearance name must be a String or Symbol'
        end

        normalized = name.to_s.tr('_', '-')
        unless normalized.match?(APPEARANCE_NAME)
          raise ArgumentError, 'appearance name must be a safe kebab-case identifier'
        end

        @attributes['data-swift-ui-appearance'] = normalized
        preserve_semantic_style_block(block)
      end

      # Keeps content available to assistive technology while removing it from
      # the visual layout. This is intentionally distinct from `hidden`, which
      # also removes a view from the accessibility tree.
      def visually_hidden(is_hidden = VISUALLY_HIDDEN_DEFAULT, &block)
        is_hidden = true if is_hidden.equal?(VISUALLY_HIDDEN_DEFAULT)
        raise ArgumentError, 'visually_hidden expects true or false' unless [true, false].include?(is_hidden)

        replace_modifier_classes(
          :visual_visibility,
          is_hidden ? ['swift-ui-visually-hidden'] : []
        )
        preserve_semantic_style_block(block)
      end

      private

      def apply_semantic_foreground(role)
        replace_modifier_classes(
          :foreground_style,
          [semantic_style_class('foreground', role)]
        )
      end

      def apply_semantic_font(role)
        replace_modifier_classes(
          :semantic_font,
          [semantic_style_class('font', role)]
        )
      end

      def normalize_semantic_role!(role, allowed_roles, modifier)
        unless role.is_a?(String) || role.is_a?(Symbol)
          raise ArgumentError, "#{modifier} role must be a String or Symbol"
        end

        role_name = role.to_s
        normalized_name = role_name.tr('-', '_') if role_name.bytesize <= 32
        normalized_role = allowed_roles.find { |allowed_role| allowed_role.to_s == normalized_name }
        return normalized_role if normalized_role

        raise ArgumentError,
              "unknown #{modifier} role; expected one of: #{allowed_roles.join(', ')}"
      end

      def semantic_style_class(facet, role)
        "swift-ui-#{facet}-#{role.to_s.tr('_', '-')}"
      end

      def preserve_semantic_style_block(block)
        @block = block if block
        self
      end
    end
  end
end
