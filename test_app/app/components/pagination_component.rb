# frozen_string_literal: true

class PaginationComponent < SwiftUIRails::Component::Base
  prop :current_page, type: Integer, required: true
  prop :total_pages, type: Integer, required: true
  prop :base_url, type: String, required: true
  prop :turbo_frame, type: String, default: nil
  
  swift_ui do
    nav(aria: { label: "Pagination" }) do
      hstack(spacing: 2) do
        # Previous button
        if current_page > 1
          link("← Previous", 
               destination: url_with_page(current_page - 1),
               data: turbo_frame ? { turbo_frame: turbo_frame } : {})
            .button_style(:secondary)
            .button_size(:sm)
        else
          span("← Previous")
            .button_style(:secondary)
            .button_size(:sm)
            .opacity(50)
            .cursor_not_allowed
        end
        
        # Page numbers (show 5 pages max)
        page_range.each do |page|
          if page == "..."
            span("...")
              .padding_x(3)
              .text_color("gray-500")
          elsif page == current_page
            span(page.to_s)
              .padding_x(3)
              .padding_y(2)
              .background("blue-500")
              .text_color("white")
              .corner_radius("md")
              .font_weight("medium")
          else
            link(page.to_s, 
                 destination: url_with_page(page),
                 data: turbo_frame ? { turbo_frame: turbo_frame } : {})
              .padding_x(3)
              .padding_y(2)
              .hover_background("gray-100")
              .corner_radius("md")
          end
        end
        
        # Next button
        if current_page < total_pages
          link("Next →", 
               destination: url_with_page(current_page + 1),
               data: turbo_frame ? { turbo_frame: turbo_frame } : {})
            .button_style(:secondary)
            .button_size(:sm)
        else
          span("Next →")
            .button_style(:secondary)
            .button_size(:sm)
            .opacity(50)
            .cursor_not_allowed
        end
      end
    end
  end
  
  private
  
  def url_with_page(page)
    uri = URI.parse(base_url)
    params = Rack::Utils.parse_query(uri.query)
    params["page"] = page.to_s
    uri.query = params.to_query
    uri.to_s
  end
  
  def page_range
    return (1..total_pages).to_a if total_pages <= 7
    
    if current_page <= 3
      [1, 2, 3, 4, "...", total_pages]
    elsif current_page >= total_pages - 2
      [1, "...", total_pages - 3, total_pages - 2, total_pages - 1, total_pages]
    else
      [1, "...", current_page - 1, current_page, current_page + 1, "...", total_pages]
    end
  end
end