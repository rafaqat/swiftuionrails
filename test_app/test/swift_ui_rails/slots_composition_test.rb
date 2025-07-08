# Copyright 2025
require "test_helper"

class SwiftUIRails::SlotsCompositionTest < ViewComponent::TestCase
  # Basic component with single slot
  class CardWithHeaderComponent < SwiftUIRails::Component::Base
    renders_one :header

    def call
      content_tag(:div, class: "bg-white rounded-lg shadow-md p-4") do
        safe_join([
          header? ? content_tag(:div, header, class: "mb-4 pb-4 border-b") : nil,
          content_tag(:span, "Card body content")
        ].compact)
      end
    end
  end

  # Component with multiple slots
  class LayoutComponent < SwiftUIRails::Component::Base
    renders_one :header
    renders_one :sidebar
    renders_one :footer
    renders_many :content_sections

    def call
      content_tag(:div, class: "min-h-screen flex flex-col") do
        header_html = header? ? content_tag(:div, header, class: "bg-gray-100 p-4") : nil

        main_html = content_tag(:div, class: "flex flex-1") do
          sidebar_html = sidebar? ? content_tag(:div, sidebar, class: "w-64 bg-gray-50 p-4") : nil

          content_html = content_tag(:div, class: "flex-1 p-8") do
            safe_join(content_sections.map { |section| content_tag(:div, section, class: "mb-6") })
          end

          safe_join([ sidebar_html, content_html ].compact)
        end

        footer_html = footer? ? content_tag(:div, footer, class: "bg-gray-100 p-4 mt-auto") : nil

        safe_join([ header_html, main_html, footer_html ].compact)
      end
    end
  end

  # Component with typed slots
  class ArticleComponent < SwiftUIRails::Component::Base
    class AuthorComponent < SwiftUIRails::Component::Base
      prop :name, type: String, required: true
      prop :avatar_url, type: String

      def call
        content_tag(:div, class: "flex flex-row space-x-12") do
          safe_join([
            avatar_url ? tag(:img, src: avatar_url, class: "w-12 h-12 rounded-full") : nil,
            content_tag(:span, name, class: "font-semibold")
          ].compact)
        end
      end
    end

    renders_one :author, AuthorComponent
    renders_many :paragraphs
    renders_one :cta

    def call
      content_tag(:article, class: "max-w-3xl mx-auto p-6") do
        safe_join([
          # Author info
          if author?
            content_tag(:div, author, class: "mb-8")
          end,

          # Article content
          safe_join(paragraphs.map do |paragraph|
            content_tag(:div, paragraph, class: "mb-4")
          end),

          # CTA
          if cta?
            content_tag(:div, cta, class: "mt-8 p-6 bg-blue-50 rounded-lg")
          end
        ].compact)
      end
    end
  end

  # Component with lambda slots
  class ListWithActionsComponent < SwiftUIRails::Component::Base
    prop :items, type: Array, default: []

    renders_many :actions, ->(item:) do
      ActionButtonComponent.new(item: item)
    end

    class ActionButtonComponent < SwiftUIRails::Component::Base
      prop :item, required: true

      def call
        content_tag(:button, item.to_s.capitalize, class: "text-sm")
      end
    end

    def call
      content_tag(:ul) do
        safe_join(items.each_with_index.map do |item, index|
          content_tag(:li) do
            content_tag(:div, class: "flex flex-row justify-between") do
              safe_join([
                content_tag(:span, item),
                if index < actions.size && actions[index]
                  content_tag(:div, class: "flex flex-row space-x-8") do
                    actions[index].to_s
                  end
                end
              ].compact)
            end
          end
        end)
      end
    end
  end

  # Nested component composition
  class PageComponent < SwiftUIRails::Component::Base
    class HeroComponent < SwiftUIRails::Component::Base
      prop :title, type: String, required: true
      prop :subtitle, type: String

      def call
        content_tag(:div, class: "py-20 px-8 bg-gradient-to-r from-blue-500 to-purple-600 text-white") do
          content_tag(:div, class: "flex flex-col space-y-16 max-w-4xl mx-auto") do
            safe_join([
              content_tag(:span, title, class: "text-4xl font-bold"),
              subtitle ? content_tag(:span, subtitle, class: "text-xl opacity-90") : nil
            ].compact)
          end
        end
      end
    end

    class TextSectionComponent < SwiftUIRails::Component::Base
      prop :content, type: String, required: true

      def call
        content_tag(:div, class: "max-w-2xl mx-auto") do
          content_tag(:span, content)
        end
      end
    end

    class GallerySectionComponent < SwiftUIRails::Component::Base
      prop :images, type: Array, default: []

      def call
        content_tag(:div, class: "grid grid-cols-3 gap-4") do
          safe_join(images.map do |img|
            tag(:img, src: img, class: "w-full h-48 rounded-lg")
          end)
        end
      end
    end

    class CTASectionComponent < SwiftUIRails::Component::Base
      prop :text, type: String, required: true
      prop :button_text, type: String, default: "Learn More"

      def call
        content_tag(:div, class: "bg-white rounded-lg shadow-md p-8 text-center") do
          content_tag(:div, class: "flex flex-col space-y-16") do
            safe_join([
              content_tag(:span, text, class: "text-lg"),
              content_tag(:button, button_text, class: "bg-blue-600 text-white px-6 py-3 rounded-lg")
            ])
          end
        end
      end
    end

    renders_one :hero, HeroComponent
    renders_many :sections

    def call
      content_tag(:div) do
        safe_join([
          hero? ? hero : nil,
          content_tag(:div, class: "py-16") do
            safe_join(sections.map do |section|
              content_tag(:div, section.to_s, class: "mb-12")
            end)
          end
        ].compact)
      end
    end
  end

  # Test Basic Slots

  test "component with single slot renders correctly" do
    component = CardWithHeaderComponent.new

    render_inline(component) do |c|
      c.with_header do
        "<h3>Card Title</h3>".html_safe
      end
    end

    assert_selector "h3", text: "Card Title"
    assert_text "Card body content"
    assert_selector "div.mb-4.pb-4.border-b"
  end

  test "component without slot content renders without slot" do
    component = CardWithHeaderComponent.new
    render_inline(component)

    assert_text "Card body content"
    assert_no_selector "div.mb-4.pb-4.border-b"
  end

  # Test Multiple Slots

  test "component with multiple slots renders all slots" do
    component = LayoutComponent.new

    render_inline(component) do |c|
      c.with_header { "<h1>Page Header</h1>".html_safe }
      c.with_sidebar { "<nav>Navigation</nav>".html_safe }
      c.with_footer { "<p>Footer content</p>".html_safe }
      c.with_content_section { "<p>Section 1</p>".html_safe }
      c.with_content_section { "<p>Section 2</p>".html_safe }
    end

    assert_selector "h1", text: "Page Header"
    assert_selector "nav", text: "Navigation"
    assert_selector "p", text: "Footer content"
    assert_selector "p", text: "Section 1"
    assert_selector "p", text: "Section 2"
  end

  test "renders_many slots maintain order" do
    component = LayoutComponent.new

    render_inline(component) do |c|
      c.with_content_section { "<p>First</p>".html_safe }
      c.with_content_section { "<p>Second</p>".html_safe }
      c.with_content_section { "<p>Third</p>".html_safe }
    end

    sections = page.all("p")
    assert_equal "First", sections[0].text
    assert_equal "Second", sections[1].text
    assert_equal "Third", sections[2].text
  end

  # Test Typed Slots

  test "typed slots accept correct types" do
    component = ArticleComponent.new

    render_inline(component) do |c|
      c.with_author(name: "John Doe", avatar_url: "/avatar.jpg")
      c.with_paragraph { "<p>First paragraph</p>".html_safe }
      c.with_paragraph { "<p>Second paragraph</p>".html_safe }
      c.with_cta { "<button>Subscribe</button>".html_safe }
    end

    assert_text "John Doe"
    assert_selector "img[src='/avatar.jpg']"
    assert_selector "p", text: "First paragraph"
    assert_selector "p", text: "Second paragraph"
    assert_selector "button", text: "Subscribe"
  end

  # Test Lambda Slots

  test "lambda slots with arguments" do
    items = [ "apple", "banana", "cherry" ]
    component = ListWithActionsComponent.new(items: items)

    result = render_inline(component) do |c|
      items.each do |item|
        c.with_action(item: item)
      end
    end

    # puts "Lambda slots HTML: #{result.to_html}"

    assert_selector "li", count: 3
    assert_selector "button", text: "Apple"
    assert_selector "button", text: "Banana"
    assert_selector "button", text: "Cherry"
  end

  # Test Nested Component Composition

  test "deeply nested components with typed slots" do
    component = PageComponent.new

    render_inline(component) do |c|
      c.with_hero(title: "Welcome", subtitle: "To our site")
      c.with_section do
        render_component(PageComponent::TextSectionComponent.new(content: "This is a text section"))
      end
      c.with_section do
        render_component(PageComponent::GallerySectionComponent.new(images: [ "/img1.jpg", "/img2.jpg", "/img3.jpg" ]))
      end
      c.with_section do
        render_component(PageComponent::CTASectionComponent.new(text: "Ready to get started?", button_text: "Sign Up"))
      end
    end

    # Hero section
    assert_selector "div.py-20", text: "Welcome"
    assert_text "To our site"

    # Text section
    assert_text "This is a text section"

    # Gallery section
    assert_selector "img", count: 3

    # CTA section
    assert_text "Ready to get started?"
    assert_selector "button", text: "Sign Up"
  end

  # Test Slot Conditionals

  test "slot conditional methods work correctly" do
    # Without header
    component1 = CardWithHeaderComponent.new
    result = render_inline(component1)
    assert_no_selector "div.border-b"

    # With header
    component2 = CardWithHeaderComponent.new
    result_with_header = render_inline(component2) do |c|
      c.with_header { "Header" }
    end
    # puts "HTML with header: #{result_with_header.to_html}"
    assert_selector "div.border-b"
  end

  # Test Slot Content Types

  test "slots can contain SwiftUI DSL content" do
    component = CardWithHeaderComponent.new

    render_inline(component) do |c|
      c.with_header do
        helpers.swift_ui do
          hstack(spacing: 12) do
            icon("star")
            text("Featured").font_weight("bold")
          end
        end
      end
    end

    assert_selector "div.flex.flex-row"
    assert_text "Featured"
  end

  # Test Edge Cases

  test "empty slots render nothing" do
    component = LayoutComponent.new

    render_inline(component) do |c|
      c.with_header { "" }
    end

    # Header wrapper should still render but be empty
    assert_selector "div.bg-gray-100.p-4"
  end

  test "missing slots are handled gracefully" do
    component = ArticleComponent.new

    # No author provided
    render_inline(component) do |c|
      c.with_paragraph { "Content" }
    end

    # Should not crash, just not render author section
    assert_text "Content"
    assert_no_selector "div.mb-8"
  end

  private

  def helpers
    @helpers ||= Class.new do
      include SwiftUIRails::Helpers
      include ActionView::Helpers
    end.new
  end

  def render_component(component)
    test_controller = ApplicationController.new
    test_controller.request = ActionDispatch::TestRequest.create
    view_context = test_controller.view_context
    component.render_in(view_context)
  end
end
# Copyright 2025
