# SwiftUI Rails Playground

⚠️ **SECURITY WARNING: DEVELOPMENT ONLY** ⚠️

**This application contains intentional code execution capabilities for development purposes and should NEVER be deployed to production or exposed to untrusted networks. It executes arbitrary Ruby code and poses severe security risks if misused.**

---

An interactive playground for experimenting with the SwiftUI Rails DSL. This app provides a live code editor where you can write SwiftUI-style Ruby code and see the results instantly.

## Features

- **Live Code Editor**: Write SwiftUI Rails DSL code and see results in real-time
- **Component Library**: Browse and explore available DSL components
- **Code Templates**: Quick-start templates for common UI patterns
- **Responsive Preview**: See how your components look on different screen sizes
- **Error Handling**: Clear error messages when something goes wrong

## Setup

⚠️ **SECURITY REQUIREMENTS** ⚠️

- **Development environment only** - Never deploy to production
- **Isolated network** - Run only on localhost or completely isolated networks
- **Trusted users only** - Only allow access to developers you trust completely
- **No sensitive data** - Never use with real user data or credentials

1. Make sure you have Ruby 3.2+ installed
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Start the development server:
   ```bash
   bin/dev
   ```

4. Visit http://localhost:3000

**⚠️ NEVER expose this application to the internet or untrusted networks ⚠️**

## Usage

The playground provides an interactive environment where you can:

1. **Write Code**: Use the Monaco editor on the left to write SwiftUI Rails DSL code
2. **Run Code**: Click "Run Code" or press Cmd+Enter to execute your code
3. **See Results**: The preview panel on the right shows the rendered output
4. **Browse Components**: Use the sidebar to explore available components and examples

### Example Code

```ruby
swift_ui do
  vstack(spacing: 4) do
    text("Welcome to SwiftUI Rails!")
      .font_size("2xl")
      .font_weight("bold")
      .text_color("blue-600")
    
    text("Build beautiful UIs with Ruby")
      .text_color("gray-600")
    
    button("Get Started")
      .bg("blue-600")
      .text_color("white")
      .px(6).py(3)
      .rounded("lg")
      .hover("bg-blue-700")
  end
end
```

## Architecture

The playground is built as a separate Rails application that depends on the `swift_ui_rails` gem. This separation allows for:

- Clean separation of concerns between the DSL framework and the playground
- **Security isolation** - Keeps intentional RCE capabilities separate from the main gem
- Independent development and testing

### Security Architecture

⚠️ **INTENTIONAL SECURITY VULNERABILITIES** ⚠️

This application intentionally includes:
- **Remote Code Execution (RCE)** via `class_eval` of user input
- **Dynamic file loading** for component exploration
- **Unrestricted Ruby execution** for DSL experimentation

These are **intentional features** for development, not security bugs. The application is designed to execute arbitrary Ruby code for DSL development and testing purposes.

## Development

To work on the playground:

1. Make changes to the playground components in `app/components/playground/`
2. Update JavaScript controllers in `app/javascript/controllers/`
3. Test your changes by running the server and using the playground

## Testing

### Running Tests

Run all tests:
```bash
bin/rails test
```

Run system tests:
```bash
bin/rails test:system
```

### Component Showcase Tests

After making major code changes to the DSL or core functionality, run the comprehensive component showcase tests:

```bash
# Run all showcase tests with combined report
ruby test/system/run_all_showcase_tests.rb

# Or run individual category tests
bin/rails test test/system/marketing_components_showcase_test.rb
bin/rails test test/system/application_ui_components_showcase_test.rb  
bin/rails test test/system/ecommerce_components_showcase_test.rb
```

These tests create 50+ real-world components with:
- **Marketing Components**: Hero sections, pricing tables, testimonials, newsletters, footers
- **Application UI**: Data tables with sorting, kanban boards, modals, sidebars, notifications
- **E-commerce**: Product grids with filters, shopping carts with calculations, checkout forms, product detail pages

Each test:
- Types complex DSL code with dynamic data into the Monaco editor
- Clicks Run to render the component
- Verifies the output is correct
- Takes screenshots of successful renders
- Generates an HTML report with visual results

The tests use real-world patterns like:
- Dynamic data arrays with `.each` loops
- Complex layouts with nested grids and flexbox
- Form validation and error states
- Interactive elements with hover states
- Responsive design with breakpoints
- State management patterns

**When to run these tests:**
- After upgrading Rails or major gems
- After modifying the DSL core functionality
- Before releasing new versions of the gem
- When adding new DSL methods or modifiers
- To identify gaps or bugs in the DSL that need refactoring

Screenshots and reports are saved to `tmp/component_showcase/[timestamp]/` with:
- Individual PNG screenshots for each component
- `test_report.html` - Comprehensive visual report showing all results

The tests are designed to exercise the full complexity of the DSL and help identify areas that need improvement or refactoring.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is part of SwiftUI Rails and shares the same license.
