# frozen_string_literal: true

module SwiftUIRails
  module Component
    module Composed
      module Layout
        # HeroLandingComponent - A hero landing page section (toolbar now in application layout)
        #
        # Features:
        # - Hero section with call-to-action
        # - Responsive design
        # - Gradient backgrounds and modern styling
        #
        # Usage:
        #   <%= render SwiftUIRails::Component::Composed::Layout::HeroLandingComponent.new %>
        class HeroLandingComponent < SwiftUIRails::Component::Base
          
          # Props for configuration
          prop :brand_name, type: String, default: "SwiftUI Rails"
          prop :brand_emoji, type: String, default: "🌊"
          prop :headline, type: String, default: "Data to enrich your"
          prop :headline_accent, type: String, default: "online business"
          prop :description, type: String, default: "Build modern Rails applications with SwiftUI-inspired components. Create beautiful, responsive interfaces with our comprehensive component library."
          prop :announcement, type: String, default: "Announcing our next round of funding."
          prop :announcement_link_text, type: String, default: "Read more →"
          prop :announcement_link_url, type: String, default: "#"
          
          swift_ui do
            # Hero Section (toolbar now in application layout)
            div.min_h("screen").bg("white") do
              section.py(5).tw("bg-gradient-to-br from-purple-50 via-blue-50 to-indigo-50") do
              div.max_w("4xl").mx("auto").px(6).text_center do
                # Announcement Banner
                if announcement.present?
                  div.mb(8) do
                    text(announcement + " ").text_color("gray-600")
                    link(announcement_link_text, destination: announcement_link_url)
                      .text_color("blue-600").hover_text_color("blue-700").font_weight("medium")
                  end
                end
                
                # Main Headline with Line Break
                h1.text_6xl.tw("lg:text-7xl").font_weight("bold").text_color("gray-900").tw("leading-tight").mb(6) do
                  text(headline)
                  br
                  text(headline_accent)
                end
                
                # Description
                paragraph.text_xl.text_color("gray-500").max_w("2xl").mx("auto").mb(8).tw("leading-relaxed") do
                  text(description)
                end
                
                # CTA Buttons
                div.flex.items_center.justify_center.space_x(4) do
                  button("Get started")
                    .bg("blue-600")
                    .text_color("white")
                    .px(6)
                    .py(3)
                    .rounded("md")
                    .font_weight("semibold")
                    .hover_bg("blue-700")
                    .transition
                    .shadow("sm")
                  
                  link("Learn more →", destination: "#")
                    .text_color("gray-700")
                    .hover_text_color("gray-900")
                    .font_weight("medium")
                    .ml(4)
                end
              end
            end
            end
          end
        end
      end
    end
  end
end