# Changelog

All notable changes to SwiftUI Rails will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-01-03

### Added
- Initial release of SwiftUI Rails gem
- DSL-FIRST component architecture
- SwiftUI-inspired declarative syntax for Rails views
- ViewComponent integration with `swift_ui do...end` blocks
- Comprehensive Tailwind CSS DSL modifiers
- Interactive Storybook with live controls
- Enhanced authentication components:
  - `EnhancedLoginComponent` - Modern login form with social auth
  - `EnhancedRegisterComponent` - Multi-step registration flow
  - `AuthErrorComponent` - Elegant error states (404, 401, 403, 500)
  - `AuthLayoutComponent` - Flexible auth page layouts
- Core DSL elements:
  - Layout components: `vstack`, `hstack`, `zstack`, `grid`
  - UI elements: `text`, `button`, `image`, `link`, `input`, `form`
  - Container elements: `div`, `span`, `section`
  - Typography: `h1` through `h6`, `p`
- Chainable Tailwind modifiers for styling
- Stimulus.js integration for client-side interactivity
- Turbo support for smooth page updates

### Fixed
- Component rendering issues with empty content
- Missing DSL methods (`grid`, `line_clamp`, `group_hover_opacity`, etc.)
- Syntax errors in DSL element chaining
- ViewComponent slot integration
- HTML escaping in Stimulus data attributes

### Changed
- Converted all components to pure DSL (no raw HTML)
- Improved error handling and nil safety
- Enhanced storybook with source code display
- Optimized DSL method resolution

### Developer Experience
- Comprehensive documentation in CLAUDE.md
- Interactive storybook for component development
- E2E test suite for regression testing
- Rails 8 compatibility
- Ruby 3.2+ support

[0.0.1]: https://github.com/yourusername/swift_ui_rails/releases/tag/v0.0.1