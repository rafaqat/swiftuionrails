# frozen_string_literal: true

require_relative "lib/swift_ui_rails/version"

Gem::Specification.new do |spec|
  spec.name = "swift_ui_rails"
  spec.version = SwiftUIRails::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your.email@example.com"]

  spec.summary = "SwiftUI-inspired DSL for building Rails views with Tailwind CSS"
  spec.description = "A declarative, component-based view system for Rails that combines SwiftUI's intuitive API with Tailwind CSS utilities and ViewComponent architecture"
  spec.homepage = "https://github.com/yourusername/swift_ui_rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yourusername/swift_ui_rails"
  spec.metadata["changelog_uri"] = "https://github.com/yourusername/swift_ui_rails/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "rails", ">= 6.1.0"
  spec.add_dependency "view_component", "~> 3.0"
  spec.add_dependency "stimulus-rails", "~> 1.0"
  spec.add_dependency "turbo-rails", ">= 1.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "standard", "~> 1.0"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "capybara", "~> 3.0"
end