# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[spec standard]

task :console do
  require "irb"
  require "swift_ui_rails"
  ARGV.clear
  IRB.start
end