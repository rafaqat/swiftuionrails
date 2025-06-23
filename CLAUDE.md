# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Gem Development
```bash
# Install gem dependencies
bundle install

# Run gem tests (RSpec)
bundle exec rake spec

# Run code linter (Standard)
bundle exec rake standard

# Run both tests and linter (default task)
bundle exec rake

# Open console with gem loaded
bundle exec rake console

# Build gem
gem build swift_ui_rails.gemspec
```

### Test Application Development
```bash
# Navigate to test app
cd test_app

# Initial setup (installs deps, prepares DB, starts server)
bin/setup

# Start development server (Rails + Tailwind watcher)
bin/dev

# Start interactive storybook server on port 3030
bin/rails server -p 3030

# Run Rails tests
bin/rails test
bin/rails test:system  # System tests with Capybara

# Code quality checks
bin/rubocop
bin/brakeman  # Security scan

# Database commands
bin/rails db:migrate
bin/rails db:seed

# Rails console
bin/rails console
```

### Component Development
```bash
# Generate new component
rails generate swift_ui_rails:component ComponentName prop:type

# Generate component stories for Storybook
rails generate swift_ui_rails:stories ComponentName story_names

# Access Storybook (after starting server)
# Visit: http://localhost:3000/rails/stories
```

## ViewComponent Storybook (Rails 8 Fork)

This project includes a local fork of `view_component-storybook` in the `view_component_storybook_rails8/` directory, as the official gem doesn't support Rails 8 yet.

### Local Fork Modifications
- Removed YARD dependency that caused Rails 8 compatibility issues
- Fixed autoload_paths freezing by using eager_load_paths instead
- Simplified Ruby file parsing without YARD dependency
- Maintained the same API as the original gem

### Interactive Storybook System

1. **Access Interactive Storybook**: Visit `http://localhost:3030/storybook/index` when the server is running

2. **Create Component Stories with Interactive Controls**:
   ```ruby
   # test/components/stories/card_component_stories.rb
   class CardComponentStories < ViewComponent::Storybook::Stories
     include SwiftUIRails::DSL
     include SwiftUIRails::Helpers
     
     # Define interactive controls
     control :elevation, as: :select, options: [0, 1, 2, 3, 4], default: 1
     control :background_color, as: :select, options: ["white", "gray-50", "blue-50"], default: "white"
     control :border, as: :boolean, default: false
     
     def default(elevation: 1, background_color: "white", border: false)
       swift_ui do
         card(elevation: elevation) do
           text("Card Content")
         end
         .background(background_color)
         .border if border
       end
     end
   end
   ```

3. **Interactive Features**:
   - **Real-time Property Updates**: Change component props and see instant visual feedback
   - **Live Code Generation**: View dynamic SwiftUI DSL code as you adjust controls
   - **Visual Controls**: Color swatches, dropdowns, toggles for all component properties
   - **State Persistence**: Component state maintained across property changes
   - **Anti-flash Rendering**: Smooth transitions without visual flickering

4. **Story Structure**: 
   - Stories are in `test/components/stories/`
   - Individual component stories for each DSL element (`vstack`, `hstack`, `text`, `button`, etc.)
   - Enhanced composite components with slots and animations

5. **Testing and Validation**:
   - **E2E Test Suite**: Comprehensive validation tests in `test/controllers/storybook_final_validation_test.rb`
   - **Regression Testing**: Automated checks for stimulus action escaping and control functionality
   - **Visual Testing**: Interactive component development and validation
   - **Component Documentation**: Stories serve as both documentation and test cases

6. **Technical Implementation**:
   - **Stimulus Controllers**: `live_story_controller.js` handles real-time interactions
   - **Turbo Streams**: Seamless component updates without page refresh
   - **Session Management**: Component state persistence across interactions
   - **HTML Safety**: Proper escaping of Stimulus actions and component content

## Architecture Overview

This is a Rails gem that brings SwiftUI-like declarative syntax to Rails views, built on top of ViewComponent.

### Core Structure

1. **Main Gem (`lib/swift_ui_rails/`)**
   - `component.rb`: Base component class extending ViewComponent
   - `dsl.rb`: SwiftUI-inspired DSL implementation
   - `engine.rb`: Rails engine configuration
   - `helpers.rb`: View helpers for `swift_ui` blocks
   - `tailwind.rb`: Tailwind CSS integration with chainable modifiers
   - `storybook.rb`: ViewComponent Storybook integration

2. **Component System**
   - Components inherit from `ApplicationComponent < SwiftUIRails::Component`
   - Props with type validation: `prop :name, type: String, required: true`
   - Reactive state management: `state :count, 0`
   - Computed properties: `computed :full_name { ... }`
   - Effects for side effects: `effect :state_var { |new_val| ... }`
   - Slots for composition: `slot :header`, `slot :content`

3. **DSL Pattern**
   - Components define views using `swift_ui do ... end` blocks
   - Layout components: `vstack`, `hstack`, `zstack`, `grid`
   - UI elements: `text`, `button`, `card`, `list`, etc.
   - Chainable Tailwind modifiers: `.bg("blue-500").text_color("white")`
   - Event handling: `.on_tap { ... }`, `.on_change { ... }`

4. **Test Application Structure**
   - Full Rails 8 application in `test_app/`
   - Demonstrates gem usage patterns
   - Includes component tests and system tests
   - Storybook stories in `test/components/stories/`

5. **Key Integration Points**
   - **ViewComponent**: Base component architecture
   - **Stimulus.js**: Client-side reactivity (via data attributes)
   - **Tailwind CSS**: Utility-first styling
   - **Turbo**: SPA-like navigation and updates
   - **Propshaft**: Rails 8 asset pipeline

### Development Workflow

1. Make changes to gem source in `lib/`
2. Test in the test application (`test_app/`)
3. Write/update tests in `spec/` (gem) or `test/` (app)
4. Create visual tests using Storybook stories
5. Run linters before committing

### Key Patterns

- **Props Validation**: Runtime type checking prevents errors
- **State Management**: Component-local state with Stimulus controllers
- **Composition**: Use slots for flexible component layouts
- **Styling**: Tailwind utilities exposed as Ruby methods
- **Testing**: Both unit tests (RSpec) and interactive visual tests (Storybook)

## Recent Improvements (June 2025)

### Interactive Storybook Enhancements
- **Fixed Interactive Controls**: Resolved HTML escaping issues in Stimulus actions across all components
- **Enhanced Error Handling**: Improved nil safety in DSL element rendering and view templates
- **Comprehensive Testing**: Added E2E validation test suite for regression testing
- **Visual Feedback**: Implemented anti-flash rendering for smooth property updates
- **Component Coverage**: Created individual stories for all DSL elements with interactive controls

### Technical Fixes
- **HTML Escaping**: Added `.html_safe` to all Stimulus data-action attributes in components
- **Nil Safety**: Protected against nil values in `content.html_safe` calls throughout the DSL
- **Session Handling**: Improved parameter validation and session management for interactive mode
- **Type Conversion**: Enhanced prop type conversion for integer and boolean controls
- **CSRF Protection**: Disabled CSRF tokens for storybook AJAX endpoints to enable testing

### Validation and Quality
- **Test Coverage**: Comprehensive E2E tests validate all interactive functionality
- **Performance**: Optimized rendering with Turbo streams and smooth transitions
- **User Experience**: Polished interactive controls with color swatches and visual feedback
- **Documentation**: Updated usage examples and technical implementation details