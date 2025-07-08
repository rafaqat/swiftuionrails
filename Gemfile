# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.0.0'

gemspec

# Runtime dependencies
gem 'concurrent-ruby', '~> 1.2' # For thread-safe data structures

group :development, :test do
  gem 'debug'
  gem 'puma'
  gem 'sqlite3'
  gem 'tailwindcss-rails'

  # SECURITY: Add security linting and scanning tools
  gem 'bundler-audit', '~> 0.9', require: false # Dependency security scanner
  gem 'rubocop', '~> 1.50', require: false
  gem 'rubocop-rails', '~> 2.19', require: false
  gem 'rubocop-rails-omakase', require: false
  gem 'rubocop-thread_safety', '~> 0.5', require: false # Thread safety analysis
end
