module SwiftUIDSL
  module Tailwind
    # Tailwind-specific modifiers for SwiftUI DSL
    module Modifiers
      # Spacing utilities
      def p(value)
        add_class("p-#{value}")
        self
      end
      
      def px(value)
        add_class("px-#{value}")
        self
      end
      
      def py(value)
        add_class("py-#{value}")
        self
      end
      
      def pt(value)
        add_class("pt-#{value}")
        self
      end
      
      def pr(value)
        add_class("pr-#{value}")
        self
      end
      
      def pb(value)
        add_class("pb-#{value}")
        self
      end
      
      def pl(value)
        add_class("pl-#{value}")
        self
      end
      
      def m(value)
        add_class("m-#{value}")
        self
      end
      
      def mx(value)
        add_class("mx-#{value}")
        self
      end
      
      def my(value)
        add_class("my-#{value}")
        self
      end
      
      def mt(value)
        add_class("mt-#{value}")
        self
      end
      
      def mr(value)
        add_class("mr-#{value}")
        self
      end
      
      def mb(value)
        add_class("mb-#{value}")
        self
      end
      
      def ml(value)
        add_class("ml-#{value}")
        self
      end
      
      # Layout utilities
      def w(value)
        add_class("w-#{value}")
        self
      end
      
      def h(value)
        add_class("h-#{value}")
        self
      end
      
      def min_w(value)
        add_class("min-w-#{value}")
        self
      end
      
      def min_h(value)
        add_class("min-h-#{value}")
        self
      end
      
      def max_w(value)
        add_class("max-w-#{value}")
        self
      end
      
      def max_h(value)
        add_class("max-h-#{value}")
        self
      end
      
      # Flexbox utilities
      def flex(value = nil)
        add_class(value ? "flex-#{value}" : "flex")
        self
      end
      
      def flex_col
        add_class("flex-col")
        self
      end
      
      def flex_row
        add_class("flex-row")
        self
      end
      
      def items(value)
        add_class("items-#{value}")
        self
      end
      
      def justify(value)
        add_class("justify-#{value}")
        self
      end
      
      def gap(value)
        add_class("gap-#{value}")
        self
      end
      
      def gap_x(value)
        add_class("gap-x-#{value}")
        self
      end
      
      def gap_y(value)
        add_class("gap-y-#{value}")
        self
      end
      
      # Grid utilities
      def grid_cols(value)
        add_class("grid-cols-#{value}")
        self
      end
      
      def col_span(value)
        add_class("col-span-#{value}")
        self
      end
      
      # Typography utilities
      def text(size)
        add_class("text-#{size}")
        self
      end
      
      def font_size(value)
        add_class("text-#{value}")
        self
      end
      
      def font_weight(value)
        add_class("font-#{value}")
        self
      end
      
      def text_color(value)
        add_class("text-#{value}")
        self
      end
      
      def leading(value)
        add_class("leading-#{value}")
        self
      end
      
      def tracking(value)
        add_class("tracking-#{value}")
        self
      end
      
      # Background utilities
      def bg(color)
        add_class("bg-#{color}")
        self
      end
      
      def bg_opacity(value)
        add_class("bg-opacity-#{value}")
        self
      end
      
      # Border utilities
      def border(width = nil)
        add_class(width ? "border-#{width}" : "border")
        self
      end
      
      def border_color(color)
        add_class("border-#{color}")
        self
      end
      
      def rounded(size = nil)
        add_class(size ? "rounded-#{size}" : "rounded")
        self
      end
      
      def rounded_t(size = nil)
        add_class(size ? "rounded-t-#{size}" : "rounded-t")
        self
      end
      
      def rounded_r(size = nil)
        add_class(size ? "rounded-r-#{size}" : "rounded-r")
        self
      end
      
      def rounded_b(size = nil)
        add_class(size ? "rounded-b-#{size}" : "rounded-b")
        self
      end
      
      def rounded_l(size = nil)
        add_class(size ? "rounded-l-#{size}" : "rounded-l")
        self
      end
      
      # Shadow utilities
      def shadow(size = nil)
        add_class(size ? "shadow-#{size}" : "shadow")
        self
      end
      
      # Effects utilities
      def opacity(value)
        add_class("opacity-#{value}")
        self
      end
      
      def blur(size = nil)
        add_class(size ? "blur-#{size}" : "blur")
        self
      end
      
      # Transform utilities
      def scale(value)
        add_class("scale-#{value}")
        self
      end
      
      def rotate(value)
        add_class("rotate-#{value}")
        self
      end
      
      def translate_x(value)
        add_class("translate-x-#{value}")
        self
      end
      
      def translate_y(value)
        add_class("translate-y-#{value}")
        self
      end
      
      # Transition utilities
      def transition(property = nil)
        add_class(property ? "transition-#{property}" : "transition")
        self
      end
      
      def duration(value)
        add_class("duration-#{value}")
        self
      end
      
      def ease(type)
        add_class("ease-#{type}")
        self
      end
      
      # State variants
      def hover(&block)
        add_hover_classes(block)
        self
      end
      
      def focus(&block)
        add_focus_classes(block)
        self
      end
      
      def active(&block)
        add_active_classes(block)
        self
      end
      
      def dark(&block)
        add_dark_classes(block)
        self
      end
      
      # Responsive modifiers
      def sm(&block)
        add_responsive_classes("sm", block)
        self
      end
      
      def md(&block)
        add_responsive_classes("md", block)
        self
      end
      
      def lg(&block)
        add_responsive_classes("lg", block)
        self
      end
      
      def xl(&block)
        add_responsive_classes("xl", block)
        self
      end
      
      def xxl(&block)
        add_responsive_classes("2xl", block)
        self
      end
      
      # Custom Tailwind class
      def tw(classes)
        add_class(classes)
        self
      end
      
      private
      
      def add_class(class_name)
        @attributes[:class] = [@attributes[:class], class_name].compact.join(" ")
      end
      
      def add_hover_classes(block)
        # This would need to parse the block and prefix with hover:
        # For now, just accept a string
        add_class("hover:#{block}") if block.is_a?(String)
      end
      
      def add_responsive_classes(breakpoint, block)
        # Similar to hover, prefix with breakpoint
        add_class("#{breakpoint}:#{block}") if block.is_a?(String)
      end
    end
    
    # Include Tailwind modifiers in Component class
    Component.include(Modifiers)
  end
end