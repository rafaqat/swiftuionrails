class StackTestPlaygroundComponent < ApplicationComponent
  swift_ui do
    div.p(8).bg("gray-100").min_h("screen") do
      vstack(spacing: 8) do
        # Header
        text("SwiftUI Rails Stack Testing Playground")
          .font_size("4xl")
          .font_weight("bold")
          .text_center
          .mb(8)
        
        # VStack Tests
        vstack_tests
        
        # HStack Tests  
        hstack_tests
        
        # Nested Stack Tests
        nested_stack_tests
        
        # Real-world Examples
        real_world_examples
      end
    end
  end
  
  private
  
  def vstack_tests
    test_section("VStack Feature Tests") do
      grid(columns: 2, gap: 8) do
        # Basic VStack
        test_card("Basic VStack") do
          vstack(spacing: 4) do
            sample_box("Item 1", "blue-500")
            sample_box("Item 2", "green-500")
            sample_box("Item 3", "red-500")
          end
        end
        
        # VStack with different spacing
        test_card("VStack Spacing Variations") do
          vstack(spacing: 0) do
            text("No Spacing").mb(0)
            vstack(spacing: 2) do
              sample_box("Tight", "purple-400", height: 30)
              sample_box("Spacing", "purple-400", height: 30)
            end
            vstack(spacing: 8) do
              sample_box("Normal", "blue-400", height: 30)
              sample_box("Spacing", "blue-400", height: 30)
            end
            vstack(spacing: 16) do
              sample_box("Wide", "green-400", height: 30)
              sample_box("Spacing", "green-400", height: 30)
            end
          end
        end
        
        # VStack alignment options
        test_card("VStack Alignment: Start") do
          vstack(spacing: 4, alignment: :start) do
            sample_box("Short", "blue-500", width: 60)
            sample_box("Medium Length", "green-500", width: 120)
            sample_box("Very Long Content", "red-500", width: 200)
          end
        end
        
        test_card("VStack Alignment: Center") do
          vstack(spacing: 4, alignment: :center) do
            sample_box("Short", "blue-500", width: 60)
            sample_box("Medium Length", "green-500", width: 120)
            sample_box("Very Long Content", "red-500", width: 200)
          end
        end
        
        test_card("VStack Alignment: End") do
          vstack(spacing: 4, alignment: :end) do
            sample_box("Short", "blue-500", width: 60)
            sample_box("Medium Length", "green-500", width: 120)
            sample_box("Very Long Content", "red-500", width: 200)
          end
        end
        
        # VStack with conditional content
        test_card("VStack with Conditional Content") do
          vstack(spacing: 4) do
            sample_box("Always Visible", "blue-500")
            
            # Conditional rendering
            if true
              sample_box("Conditionally True", "green-500")
            end
            
            if false
              sample_box("Conditionally False", "red-500")
            end
            
            sample_box("Always Visible 2", "purple-500")
          end
        end
        
        # VStack with mixed content types
        test_card("VStack Mixed Content") do
          vstack(spacing: 4) do
            text("Text Element").font_weight("bold")
            sample_box("Box Element", "blue-500", height: 40)
            
            hstack(spacing: 2) do
              sample_box("H1", "green-400", width: 30, height: 30)
              sample_box("H2", "green-400", width: 30, height: 30)
            end
            
            text("Another Text").text_color("gray-600")
            sample_box("Final Box", "red-500", height: 40)
          end
        end
        
        # VStack with dynamic content
        test_card("VStack Dynamic Content") do
          vstack(spacing: 4) do
            text("Dynamic Items:").font_weight("semibold")
            
            # Dynamic list rendering
            (1..3).each do |i|
              sample_box("Dynamic Item #{i}", "indigo-#{400 + i * 100}", height: 35)
            end
            
            text("Generated: #{Time.current.strftime('%H:%M:%S')}")
              .text_color("gray-500")
              .text_sm
          end
        end
      end
    end
  end
  
  def hstack_tests
    test_section("HStack Feature Tests") do
      vstack(spacing: 8) do
        # Basic HStack
        test_card("Basic HStack") do
          hstack(spacing: 4) do
            sample_box("Item 1", "blue-500")
            sample_box("Item 2", "green-500")
            sample_box("Item 3", "red-500")
          end
        end
        
        # HStack spacing variations
        test_card("HStack Spacing Variations") do
          vstack(spacing: 4) do
            text("No Spacing").font_weight("medium")
            hstack(spacing: 0) do
              sample_box("A", "red-400", width: 40, height: 40)
              sample_box("B", "red-400", width: 40, height: 40)
              sample_box("C", "red-400", width: 40, height: 40)
            end
            
            text("Small Spacing (2px)").font_weight("medium")
            hstack(spacing: 2) do
              sample_box("A", "blue-400", width: 40, height: 40)
              sample_box("B", "blue-400", width: 40, height: 40)
              sample_box("C", "blue-400", width: 40, height: 40)
            end
            
            text("Large Spacing (16px)").font_weight("medium")
            hstack(spacing: 16) do
              sample_box("A", "green-400", width: 40, height: 40)
              sample_box("B", "green-400", width: 40, height: 40)
              sample_box("C", "green-400", width: 40, height: 40)
            end
          end
        end
        
        # HStack alignment options
        grid(columns: 3, gap: 6) do
          test_card("HStack Alignment: Top") do
            hstack(spacing: 4, alignment: :top) do
              sample_box("Small", "blue-500", height: 40)
              sample_box("Medium", "green-500", height: 80)
              sample_box("Large", "red-500", height: 120)
            end
          end
          
          test_card("HStack Alignment: Center") do
            hstack(spacing: 4, alignment: :center) do
              sample_box("Small", "blue-500", height: 40)
              sample_box("Medium", "green-500", height: 80)
              sample_box("Large", "red-500", height: 120)
            end
          end
          
          test_card("HStack Alignment: Bottom") do
            hstack(spacing: 4, alignment: :bottom) do
              sample_box("Small", "blue-500", height: 40)
              sample_box("Medium", "green-500", height: 80)
              sample_box("Large", "red-500", height: 120)
            end
          end
        end
        
        # HStack justify options
        test_card("HStack Justify Options") do
          vstack(spacing: 6) do
            text("Justify Start").font_weight("medium")
            hstack(spacing: 4, justify: :start) do
              sample_box("1", "purple-500", width: 60)
              sample_box("2", "purple-500", width: 60)
              sample_box("3", "purple-500", width: 60)
            end
            
            text("Justify Center").font_weight("medium")
            hstack(spacing: 4, justify: :center) do
              sample_box("1", "blue-500", width: 60)
              sample_box("2", "blue-500", width: 60)
              sample_box("3", "blue-500", width: 60)
            end
            
            text("Justify End").font_weight("medium")
            hstack(spacing: 4, justify: :end) do
              sample_box("1", "green-500", width: 60)
              sample_box("2", "green-500", width: 60)
              sample_box("3", "green-500", width: 60)
            end
            
            text("Justify Between").font_weight("medium")
            hstack(spacing: 0, justify: :between) do
              sample_box("1", "red-500", width: 60)
              sample_box("2", "red-500", width: 60)
              sample_box("3", "red-500", width: 60)
            end
            
            text("Justify Around").font_weight("medium")
            hstack(spacing: 0, justify: :around) do
              sample_box("1", "yellow-500", width: 60)
              sample_box("2", "yellow-500", width: 60)
              sample_box("3", "yellow-500", width: 60)
            end
          end
        end
        
        # HStack with mixed content
        test_card("HStack Mixed Content Types") do
          hstack(spacing: 4, alignment: :center) do
            text("Label:").font_weight("semibold")
            sample_box("Value", "blue-500", width: 80)
            text("•").text_color("gray-400")
            sample_box("Status", "green-500", width: 60)
            text("→").text_color("gray-400")
            sample_box("Action", "red-500", width: 70)
          end
        end
        
        # HStack with responsive behavior
        test_card("HStack Responsive Content") do
          hstack(spacing: 4) do
            sample_box("Fixed", "blue-500", width: 80)
            sample_box("Flexible", "green-500")
              .flex_1  # Takes remaining space
            sample_box("Fixed", "red-500", width: 80)
          end
        end
      end
    end
  end
  
  def nested_stack_tests
    test_section("Nested Stack Combinations") do
      grid(columns: 2, gap: 8) do
        # VStack containing HStacks
        test_card("VStack → HStack") do
          vstack(spacing: 4) do
            text("Header").font_weight("bold").text_center
            
            hstack(spacing: 4) do
              sample_box("A", "blue-500", width: 50)
              sample_box("B", "green-500", width: 50)
              sample_box("C", "red-500", width: 50)
            end
            
            hstack(spacing: 4) do
              sample_box("D", "purple-500", width: 50)
              sample_box("E", "yellow-500", width: 50)
              sample_box("F", "pink-500", width: 50)
            end
            
            text("Footer").font_weight("bold").text_center
          end
        end
        
        # HStack containing VStacks
        test_card("HStack → VStack") do
          hstack(spacing: 4) do
            vstack(spacing: 2) do
              sample_box("1", "blue-500", height: 40)
              sample_box("2", "blue-600", height: 40)
              sample_box("3", "blue-700", height: 40)
            end
            
            vstack(spacing: 2) do
              sample_box("A", "green-500", height: 40)
              sample_box("B", "green-600", height: 40)
              sample_box("C", "green-700", height: 40)
            end
            
            vstack(spacing: 2) do
              sample_box("X", "red-500", height: 40)
              sample_box("Y", "red-600", height: 40)
              sample_box("Z", "red-700", height: 40)
            end
          end
        end
        
        # Complex nested structure
        test_card("Complex Nesting") do
          vstack(spacing: 4) do
            hstack(spacing: 4, justify: :between) do
              text("Title").font_weight("bold")
              sample_box("Badge", "blue-500", width: 50, height: 20)
            end
            
            hstack(spacing: 4, alignment: :top) do
              sample_box("Icon", "gray-400", width: 40, height: 40)
              
              vstack(spacing: 2, alignment: :start) do
                text("Content Title").font_weight("medium")
                text("Subtitle text").text_color("gray-600").text_sm
                
                hstack(spacing: 2) do
                  sample_box("Tag1", "green-400", width: 40, height: 20)
                  sample_box("Tag2", "blue-400", width: 40, height: 20)
                end
              end
            end
            
            hstack(spacing: 2, justify: :end) do
              sample_box("Cancel", "gray-400", width: 60, height: 30)
              sample_box("Save", "blue-500", width: 60, height: 30)
            end
          end
        end
        
        # Grid-like layout with stacks
        test_card("Grid-like with Stacks") do
          vstack(spacing: 4) do
            # Row 1
            hstack(spacing: 4) do
              sample_box("1,1", "blue-500", width: 60, height: 40)
              sample_box("1,2", "green-500", width: 60, height: 40)
              sample_box("1,3", "red-500", width: 60, height: 40)
            end
            
            # Row 2
            hstack(spacing: 4) do
              sample_box("2,1", "purple-500", width: 60, height: 40)
              sample_box("2,2", "yellow-500", width: 60, height: 40)
              sample_box("2,3", "pink-500", width: 60, height: 40)
            end
            
            # Row 3 - different sizes
            hstack(spacing: 4) do
              sample_box("3,1", "indigo-500", width: 80, height: 40)
              sample_box("3,2", "teal-500", width: 40, height: 40)
              sample_box("3,3", "orange-500", width: 100, height: 40)
            end
          end
        end
      end
    end
  end
  
  def real_world_examples
    test_section("Real-world Stack Examples") do
      grid(columns: 2, gap: 8) do
        # Card layout
        test_card("Card Layout") do
          vstack(spacing: 4, alignment: :start) do
            # Header
            hstack(justify: :between) do
              vstack(spacing: 1, alignment: :start) do
                text("Product Card").font_weight("bold").font_size("lg")
                text("Premium Quality").text_color("gray-600").text_sm
              end
              sample_box("$99", "green-500", width: 50, height: 30)
            end
            
            # Content
            hstack(spacing: 4, alignment: :top) do
              sample_box("IMG", "blue-500", width: 60, height: 60)
              vstack(spacing: 2, alignment: :start) do
                text("Product description goes here")
                text("Additional details").text_color("gray-500").text_sm
              end
            end
            
            # Actions
            hstack(spacing: 2, justify: :end) do
              sample_box("♡", "gray-400", width: 40, height: 32)
              sample_box("Add to Cart", "blue-500", width: 80, height: 32)
            end
          end
        end
        
        # Navigation layout
        test_card("Navigation Layout") do
          vstack(spacing: 0) do
            # Top nav
            hstack(spacing: 4, justify: :between) do
              sample_box("Logo", "blue-600", width: 60, height: 40)
              
              hstack(spacing: 2) do
                sample_box("Home", "gray-300", width: 50, height: 30)
                sample_box("About", "gray-300", width: 50, height: 30)
                sample_box("Contact", "gray-300", width: 50, height: 30)
              end
              
              sample_box("Profile", "green-500", width: 60, height: 40)
            end
            
            # Breadcrumb
            hstack(spacing: 2, alignment: :center) do
              text("Home").text_sm
              text("→").text_color("gray-400")
              text("Products").text_sm
              text("→").text_color("gray-400")
              text("Details").text_sm.font_weight("medium")
            end
            
            # Content area
            sample_box("Main Content Area", "gray-100", height: 100)
          end
        end
        
        # Form layout
        test_card("Form Layout") do
          vstack(spacing: 4, alignment: :start) do
            text("Contact Form").font_weight("bold").font_size("lg")
            
            # Name fields
            hstack(spacing: 4) do
              vstack(spacing: 2, alignment: :start) do
                text("First Name").font_weight("medium").text_sm
                sample_box("Input", "gray-200", height: 40)
              end
              
              vstack(spacing: 2, alignment: :start) do
                text("Last Name").font_weight("medium").text_sm
                sample_box("Input", "gray-200", height: 40)
              end
            end
            
            # Email field
            vstack(spacing: 2, alignment: :start) do
              text("Email").font_weight("medium").text_sm
              sample_box("Input", "gray-200", height: 40)
            end
            
            # Message field
            vstack(spacing: 2, alignment: :start) do
              text("Message").font_weight("medium").text_sm
              sample_box("Textarea", "gray-200", height: 80)
            end
            
            # Submit button
            hstack(justify: :end) do
              sample_box("Submit", "blue-500", width: 80, height: 40)
            end
          end
        end
        
        # Dashboard layout
        test_card("Dashboard Layout") do
          vstack(spacing: 4) do
            # Stats row
            hstack(spacing: 4) do
              metric_card("Users", "1,234", "blue")
              metric_card("Sales", "$56K", "green")
              metric_card("Orders", "890", "purple")
            end
            
            # Charts row
            hstack(spacing: 4, alignment: :top) do
              # Chart 1
              vstack(spacing: 2) do
                text("Revenue").font_weight("medium").text_sm
                sample_box("Chart", "blue-100", height: 80)
              end
              
              # Chart 2
              vstack(spacing: 2) do
                text("Traffic").font_weight("medium").text_sm
                sample_box("Chart", "green-100", height: 80)
              end
            end
            
            # Recent activity
            vstack(spacing: 2, alignment: :start) do
              text("Recent Activity").font_weight("medium")
              
              (1..3).each do |i|
                hstack(spacing: 3, alignment: :center) do
                  sample_box("•", "gray-400", width: 8, height: 8)
                  text("Activity item #{i}").text_sm
                  text("2m ago").text_color("gray-500").text_xs
                end
              end
            end
          end
        end
      end
    end
  end
  
  # Helper methods
  def test_section(title, &block)
    vstack(spacing: 6) do
      text(title)
        .font_size("2xl")
        .font_weight("semibold")
        .text_color("gray-800")
        .mb(4)
      
      yield
    end
    .mb(12)
  end
  
  def test_card(title, &block)
    vstack(spacing: 4, alignment: :start) do
      text(title)
        .font_weight("medium")
        .text_color("gray-700")
        .text_sm
      
      div do
        yield
      end
      .p(4)
      .bg("white")
      .border
      .border_color("gray-200")
      .rounded("lg")
      .shadow("sm")
    end
  end
  
  def sample_box(label, color, width: 80, height: 50)
    div do
      text(label)
        .text_color("white")
        .font_weight("medium")
        .text_sm
    end
    .bg(color)
    .rounded("md")
    .flex
    .items_center
    .justify_center
    .w(width)
    .h(height)
    .shadow("sm")
  end
  
  def metric_card(label, value, color)
    vstack(spacing: 1) do
      text(value)
        .font_size("2xl")
        .font_weight("bold")
        .text_color("#{color}-600")
      text(label)
        .text_color("gray-600")
        .text_sm
    end
    .bg("white")
    .border
    .border_color("gray-200")
    .rounded("lg")
    .p(4)
    .text_center
    .shadow("sm")
    .flex_1
  end
end