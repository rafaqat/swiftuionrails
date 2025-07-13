# frozen_string_literal: true

# Copyright 2025

# This demonstrates the elegance of the SwiftUI-like preview DSL
class SwiftuiPreviewDemoStories < ViewComponent::Storybook::Stories
  include SwiftUIRails::DSL
  include SwiftUIRails::Helpers

  def hero_section
    swift_ui do
      # Build complex UIs naturally with composition
      vstack(spacing: 24, alignment: :center) do
        # Hero content
        vstack(spacing: 16, alignment: :center) do
          text("Welcome to SwiftUI Rails")
            .font_size("4xl")
            .font_weight("bold")
            .text_color("gray-900")

          text("Build beautiful, interactive UIs with a familiar SwiftUI-like syntax")
            .font_size("lg")
            .text_color("gray-600")
            .max_w("2xl")
            .text_center

          # CTA buttons
          hstack(spacing: 4) do
            button("Get Started")
              .bg("blue-600")
              .text_color("white")
              .px(8).py(3)
              .rounded("lg")
              .font_weight("medium")
              .hover_bg("blue-700")
              .hover_scale("105")
              .transition
              .shadow("lg")

            button("Learn More")
              .bg("white")
              .text_color("gray-700")
              .border
              .border_color("gray-300")
              .px(8).py(3)
              .rounded("lg")
              .font_weight("medium")
              .hover_bg("gray-50")
              .transition
          end
        end

        # Feature cards
        grid(cols: 3, gap: 8) do
          # Feature 1
          card(elevation: 1) do
            vstack(spacing: 4, alignment: :center) do
              div.w(12).h(12).bg("blue-100").rounded("full").flex.items_center.justify_center do
                text("🚀").text_size("2xl")
              end

              text("Fast Development")
                .font_size("lg")
                .font_weight("semibold")
                .text_color("gray-900")

              text("Build UIs rapidly with our intuitive DSL")
                .text_size("sm")
                .text_color("gray-600")
                .text_center
            end
          end.bg("white").hover_shadow("lg").hover_scale("105").transition

          # Feature 2
          card(elevation: 1) do
            vstack(spacing: 4, alignment: :center) do
              div.w(12).h(12).bg("green-100").rounded("full").flex.items_center.justify_center do
                text("✨").text_size("2xl")
              end

              text("Beautiful by Default")
                .font_size("lg")
                .font_weight("semibold")
                .text_color("gray-900")

              text("Tailwind-powered styling that looks great")
                .text_size("sm")
                .text_color("gray-600")
                .text_center
            end
          end.bg("white").hover_shadow("lg").hover_scale("105").transition

          # Feature 3
          card(elevation: 1) do
            vstack(spacing: 4, alignment: :center) do
              div.w(12).h(12).bg("purple-100").rounded("full").flex.items_center.justify_center do
                text("🎯").text_size("2xl")
              end

              text("Type Safe")
                .font_size("lg")
                .font_weight("semibold")
                .text_color("gray-900")

              text("Props validation keeps your components reliable")
                .text_size("sm")
                .text_color("gray-600")
                .text_center
            end
          end.bg("white").hover_shadow("lg").hover_scale("105").transition
        end
      end
      .p(8)
      .bg("gray-50")
      .rounded("xl")
    end
  end

  def interactive_form
    swift_ui do
      card(elevation: 3) do
        vstack(spacing: 0) do
          # Header
          div.px(24).py(16).border_b do
            text("Create New Project")
              .font_size("xl")
              .font_weight("semibold")
              .text_color("gray-900")
          end

          # Content
          div.px(24).py(24) do
            vstack(spacing: 24) do
              # Project name field
              vstack(spacing: 8, alignment: :start) do
                label("Project Name")
                  .text_size("sm")
                  .font_weight("medium")
                  .text_color("gray-700")

                input(
                  type: "text",
                  placeholder: "Enter project name"
                ).w("full").px(12).py(8).border.border_color("gray-300").rounded("md").focus_ring(2).focus_ring_color("blue-500")
              end

              # Description field
              vstack(spacing: 8, alignment: :start) do
                label("Description")
                  .text_size("sm")
                  .font_weight("medium")
                  .text_color("gray-700")

                textarea(
                  placeholder: "Describe your project",
                  rows: 3
                ).w("full").px(12).py(8).border.border_color("gray-300").rounded("md").focus_ring(2).focus_ring_color("blue-500")
              end

              # Project type
              vstack(spacing: 8, alignment: :start) do
                label("Project Type")
                  .text_size("sm")
                  .font_weight("medium")
                  .text_color("gray-700")

                hstack(spacing: 16) do
                  [ "Web App", "Mobile App", "API" ].each do |type|
                    label.flex.items_center.gap(8) do
                      input(type: "radio", name: "project_type", value: type.downcase.gsub(" ", "_"))
                      text(type).text_size("sm").text_color("gray-700")
                    end
                  end
                end
              end
            end
          end

          # Footer
          div.px(24).py(16).bg("gray-50").border_t do
            hstack(spacing: 12, alignment: :center).justify_end do
              button("Cancel")
                .bg("white")
                .text_color("gray-700")
                .border
                .border_color("gray-300")
                .px(16).py(8)
                .rounded("md")
                .hover_bg("gray-50")
                .transition

              button("Create Project")
                .bg("blue-600")
                .text_color("white")
                .px(16).py(8)
                .rounded("md")
                .hover_bg("blue-700")
                .transition
                .data(controller: "project-form", action: "click->project-form#submit")
            end
          end
        end
      end
      .max_w("lg")
      .mx("auto")
    end
  end

  def data_list
    swift_ui do
      # Sample data
      users = [
        { name: "Sarah Chen", role: "Designer", status: "active" },
        { name: "Mike Johnson", role: "Developer", status: "active" },
        { name: "Emma Davis", role: "Product Manager", status: "away" }
      ]

      vstack(spacing: 16) do
        # Header
        hstack(alignment: :center) do
          text("Team Members")
            .font_size("lg")
            .font_weight("semibold")
            .text_color("gray-900")
            .flex_1

          button("Add Member")
            .bg("blue-600")
            .text_color("white")
            .px(12).py(4)
            .text_size("sm")
            .rounded("md")
            .hover_bg("blue-700")
            .transition
        end

        # List
        vstack(spacing: 12) do
          users.each_with_index do |user, index|
            div
              .bg("white")
              .border
              .border_color("gray-200")
              .rounded("lg")
              .p(16)
              .hover_shadow("md")
              .transition do
                hstack(alignment: :center) do
                  # Avatar
                  div
                    .w(40).h(40)
                    .bg("gray-300")
                    .rounded("full")
                    .flex.items_center.justify_center do
                      text(user[:name].split.map(&:first).join)
                        .text_color("white")
                        .font_weight("medium")
                    end

                  # User info
                  vstack(spacing: 0, alignment: :start).flex_1 do
                    text(user[:name])
                      .font_weight("medium")
                      .text_color("gray-900")

                    text(user[:role])
                      .text_size("sm")
                      .text_color("gray-600")
                  end

                  # Status badge
                  div
                    .px(8).py(4)
                    .bg(user[:status] == "active" ? "green-100" : "yellow-100")
                    .rounded("full") do
                      text(user[:status].capitalize)
                        .text_size("xs")
                        .text_color(user[:status] == "active" ? "green-800" : "yellow-800")
                    end
                end
              end
          end
        end
      end
      .p(24)
      .bg("gray-50")
      .rounded("xl")
    end
  end

  def default
    # Default story shows the hero section
    hero_section
  end
end
# Copyright 2025
