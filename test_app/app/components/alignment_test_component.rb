class AlignmentTestComponent < ApplicationComponent
  swift_ui do
    div.p(8).bg("gray-100").min_h("screen") do
      vstack(spacing: 8) do
        text("HStack and VStack Alignment Test")
          .font_size("3xl")
          .font_weight("bold")
          .text_center
          .mb(8)
        
        # HStack Tests
        text("HStack Alignment Tests")
          .font_size("2xl")
          .font_weight("semibold")
          .mb(4)
        
        # HStack with different alignments
        hstack_alignment_tests
        
        # VStack Tests
        text("VStack Alignment Tests")
          .font_size("2xl")
          .font_weight("semibold")
          .mb(4)
          .mt(12)
        
        # VStack with different alignments
        vstack_alignment_tests
        
        # Complex nested alignment tests
        text("Complex Nested Alignment Tests")
          .font_size("2xl")
          .font_weight("semibold")
          .mb(4)
          .mt(12)
        
        complex_nested_tests
      end
    end
  end
  
  private
  
  def hstack_alignment_tests
    vstack(spacing: 6) do
      # HStack with top alignment
      test_container("HStack - Top Alignment") do
        hstack(spacing: 4, alignment: :top) do
          colored_box("Small", "blue-500", height: 40)
          colored_box("Medium", "green-500", height: 80)
          colored_box("Large", "red-500", height: 120)
        end
      end
      
      # HStack with center alignment (default)
      test_container("HStack - Center Alignment") do
        hstack(spacing: 4, alignment: :center) do
          colored_box("Small", "blue-500", height: 40)
          colored_box("Medium", "green-500", height: 80)
          colored_box("Large", "red-500", height: 120)
        end
      end
      
      # HStack with bottom alignment
      test_container("HStack - Bottom Alignment") do
        hstack(spacing: 4, alignment: :bottom) do
          colored_box("Small", "blue-500", height: 40)
          colored_box("Medium", "green-500", height: 80)
          colored_box("Large", "red-500", height: 120)
        end
      end
      
      # HStack with justify options
      test_container("HStack - Leading Justify") do
        hstack(spacing: 4, justify: :start) do
          colored_box("1", "purple-500")
          colored_box("2", "yellow-500")
          colored_box("3", "pink-500")
        end
      end
      
      test_container("HStack - Center Justify") do
        hstack(spacing: 4, justify: :center) do
          colored_box("1", "purple-500")
          colored_box("2", "yellow-500")
          colored_box("3", "pink-500")
        end
      end
      
      test_container("HStack - Trailing Justify") do
        hstack(spacing: 4, justify: :end) do
          colored_box("1", "purple-500")
          colored_box("2", "yellow-500")
          colored_box("3", "pink-500")
        end
      end
      
      test_container("HStack - Space Between") do
        hstack(spacing: 4, justify: :between) do
          colored_box("1", "purple-500")
          colored_box("2", "yellow-500")
          colored_box("3", "pink-500")
        end
      end
      
      test_container("HStack - Space Around") do
        hstack(spacing: 4, justify: :around) do
          colored_box("1", "purple-500")
          colored_box("2", "yellow-500")
          colored_box("3", "pink-500")
        end
      end
    end
  end
  
  def vstack_alignment_tests
    hstack(spacing: 8) do
      # VStack with leading alignment
      test_container("VStack - Leading Alignment") do
        vstack(spacing: 4, alignment: :start) do
          colored_box("Short", "blue-500", width: 60)
          colored_box("Medium Width", "green-500", width: 120)
          colored_box("Very Long Width", "red-500", width: 180)
        end
      end
      
      # VStack with center alignment (default)
      test_container("VStack - Center Alignment") do
        vstack(spacing: 4, alignment: :center) do
          colored_box("Short", "blue-500", width: 60)
          colored_box("Medium Width", "green-500", width: 120)
          colored_box("Very Long Width", "red-500", width: 180)
        end
      end
      
      # VStack with trailing alignment
      test_container("VStack - Trailing Alignment") do
        vstack(spacing: 4, alignment: :end) do
          colored_box("Short", "blue-500", width: 60)
          colored_box("Medium Width", "green-500", width: 120)
          colored_box("Very Long Width", "red-500", width: 180)
        end
      end
    end
  end
  
  def complex_nested_tests
    vstack(spacing: 8) do
      # Complex nested alignment - Card-like layouts
      test_container("Complex Card Layout") do
        vstack(spacing: 4, alignment: :start) do
          # Header with space between
          hstack(justify: :between) do
            vstack(alignment: :start) do
              text("Card Title").font_weight("bold").font_size("lg")
              text("Subtitle").text_color("gray-600").font_size("sm")
            end
            colored_box("Badge", "green-500", width: 60, height: 24)
          end
          
          # Content area
          hstack(spacing: 4, alignment: :top) do
            colored_box("Image", "blue-500", width: 80, height: 80)
            vstack(alignment: :start, spacing: 2) do
              text("Description text that wraps")
                .text_color("gray-700")
                .font_size("sm")
              text("Additional details")
                .text_color("gray-500")
                .font_size("xs")
            end
          end
          
          # Footer with actions
          hstack(justify: :end, spacing: 2) do
            colored_box("Cancel", "gray-400", width: 60, height: 32)
            colored_box("Save", "blue-500", width: 60, height: 32)
          end
        end
      end
      
      # Dashboard-style layout
      test_container("Dashboard Layout") do
        vstack(spacing: 6) do
          # Top metrics row
          hstack(justify: :around) do
            metric_card("Users", "1,234", "green")
            metric_card("Revenue", "$56,789", "blue")
            metric_card("Orders", "890", "purple")
          end
          
          # Content area with sidebar
          hstack(spacing: 6, alignment: :top) do
            # Sidebar
            vstack(alignment: :start, spacing: 2) do
              text("Navigation").font_weight("semibold").mb(2)
              nav_item("Dashboard", active: true)
              nav_item("Users", active: false)
              nav_item("Settings", active: false)
            end
            .w(48)
            
            # Main content
            vstack(spacing: 4, alignment: :start) do
              hstack(justify: :between) do
                text("Main Content").font_weight("semibold")
                colored_box("Action", "blue-500", width: 80, height: 32)
              end
              
              colored_box("Content Area", "gray-200", width: 400, height: 200)
            end
            .flex_1
          end
        end
      end
    end
  end
  
  def test_container(title, &block)
    div.border.border_color("gray-300").rounded("lg").p(4).bg("white") do
      text(title).font_weight("medium").mb(3).text_color("gray-700")
      div.border.border_color("gray-200").rounded.p(4).bg("gray-50") do
        yield
      end
    end
  end
  
  def colored_box(label, color, width: 80, height: 60)
    div.bg(color).rounded.flex.items_center.justify_center do
      text(label).text_color("white").font_weight("medium").text_sm
    end
    .w(width).h(height)
  end
  
  def metric_card(label, value, color)
    div.bg("white").border.rounded("lg").p(4).text_center do
      text(value).font_size("2xl").font_weight("bold").text_color("#{color}-600")
      text(label).text_color("gray-600").font_size("sm")
    end
    .w(32)
  end
  
  def nav_item(label, active: false)
    div.p(2).rounded do
      text(label).text_color(active ? "blue-600" : "gray-700")
    end
    .bg(active ? "blue-50" : "transparent")
    .hover_bg("gray-100")
  end
end