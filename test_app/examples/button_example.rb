# Example of a button with teal background and yellow text
# using the SwiftUI Rails DSL

# Basic button without wrapper
button("Hello World")
  .bg("teal")
  .text_color("yellow")
  .px(4).py(2)
  .rounded("lg")

# Or with swift_ui wrapper for use in components:
swift_ui do
  button("Hello World")
    .bg("teal")
    .text_color("yellow")
    .px(4).py(2)
    .rounded("lg")
end

# With hover effects:
button("Hello World")
  .bg("teal")
  .text_color("yellow")
  .px(4).py(2)
  .rounded("lg")
  .hover_bg("teal-600")
  .transition

# With click action (using Stimulus):
button("Hello World")
  .bg("teal")
  .text_color("yellow")
  .px(4).py(2)
  .rounded("lg")
  .data(action: "click->my-controller#handleClick")

# Using proper Tailwind spacing:
# - px(4) = 16px horizontal padding (4 * 0.25rem * 16px/rem)
# - py(2) = 8px vertical padding (2 * 0.25rem * 16px/rem)
# - px(16) would now correctly convert to px-4
# - py(8) would now correctly convert to py-2