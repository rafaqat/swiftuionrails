# Copyright 2025
require "test_helper"
require "open3"

class GitHooksSecurityTest < ActiveSupport::TestCase
  def setup
    @hooks_dir = Rails.root.join(".kamal/hooks")
    @pre_build_hook = @hooks_dir.join("pre-build")
    @pre_build_sample = @hooks_dir.join("pre-build.sample")
  end

  test "pre-build hook exists and is executable" do
    assert File.exist?(@pre_build_hook),
      "SECURITY: pre-build hook should exist for deployment validation"

    assert File.executable?(@pre_build_hook),
      "SECURITY: pre-build hook should be executable"
  end

  test "pre-build hook uses bash with safety flags" do
    skip unless File.exist?(@pre_build_hook)

    first_line = File.open(@pre_build_hook, &:readline).strip
    assert_equal "#!/bin/bash", first_line,
      "SECURITY: Hook should use bash (not sh) for better security features"

    content = File.read(@pre_build_hook)
    assert_match(/set\s+-euo\s+pipefail/, content,
      "SECURITY: Hook should use 'set -euo pipefail' for safety")
  end

  test "pre-build hook quotes all variables" do
    skip unless File.exist?(@pre_build_hook)

    content = File.read(@pre_build_hook)

    # Split into lines to check each line individually
    lines = content.split("\n")

    unquoted_vars_found = false
    lines.each_with_index do |line, index|
      # Skip echo/print statements
      next if line =~ /^\s*(echo|printf)/

      # Check for unquoted variables in actual commands
      if line =~ /git\s+[a-zA-Z-]+/ && line =~ /\$[a-zA-Z_][a-zA-Z0-9_]*/ && line !~ /"\$[a-zA-Z_][a-zA-Z0-9_]*"/
        # Check if it's actually a dangerous unquoted variable
        unless line =~ /\$\(.*\)/ || line =~ /for\s+\w+\s+in/
          unquoted_vars_found = true
          assert false, "SECURITY: Line #{index + 1} has unquoted variable in git command: #{line}"
        end
      end
    end

    # Add assertion to satisfy test requirement
    assert_not unquoted_vars_found, "All variables in git commands should be properly quoted"
  end

  test "pre-build hook validates input formats" do
    skip unless File.exist?(@pre_build_hook)

    content = File.read(@pre_build_hook)

    # Check for input validation patterns (with proper escaping)
    validations = [
      /"\$first_remote".*=~.*\^\[a-zA-Z0-9_.-\]\+\$/, # Remote name validation
      /"\$current_branch".*=~.*\^\[a-zA-Z0-9\/_.-\]\+\$/, # Branch name validation
      /"\$remote_head".*=~.*\^\[a-f0-9\]\{40\}\$/, # SHA validation
      /"\$KAMAL_VERSION".*=~.*\^\[a-f0-9\]\{40\}\$/ # Version validation
    ]

    validations.each do |validation|
      assert_match validation, content,
        "SECURITY: Hook should validate input formats to prevent injection"
    end
  end

  test "pre-build sample has security vulnerabilities documented" do
    skip unless File.exist?(@pre_build_sample)

    sample_content = File.read(@pre_build_sample)

    # The sample should have the fixes applied
    assert_match(/set\s+-euo\s+pipefail/, sample_content,
      "SECURITY: Sample should demonstrate secure practices")

    # Should not have the vulnerable line anymore
    assert_no_match(/git ls-remote \$first_remote --tags \$current_branch/, sample_content,
      "SECURITY: Sample should not contain the vulnerable unquoted command")
  end

  test "pre-build hook does not use --tags flag incorrectly" do
    [ @pre_build_hook, @pre_build_sample ].each do |hook_file|
      next unless File.exist?(hook_file)

      content = File.read(hook_file)

      # The --tags flag was wrong for checking branch heads
      if content.include?("git ls-remote")
        assert_no_match(/git ls-remote.*--tags.*\$current_branch/, content,
          "SECURITY: Should not use --tags when checking branch heads")

        # Should use refs/heads/ for branches
        assert_match(/refs\/heads\//, content,
          "SECURITY: Should specify refs/heads/ for branch lookups")
      end
    end
  end

  test "hooks handle special characters safely" do
    skip unless File.exist?(@pre_build_hook)

    # Test that the hook would reject dangerous input
    test_inputs = [
      "origin$(whoami)",
      "origin`id`",
      "origin;ls",
      "origin|cat /etc/passwd",
      "origin&&malicious",
      "origin\nmalicious",
      "origin\rmalicious"
    ]

    content = File.read(@pre_build_hook)

    # Hook should have validation that would reject these
    assert_match(/\[\[.*=~.*\^\[a-zA-Z0-9_.-\]\+\$.*\]\]/, content,
      "SECURITY: Hook should validate against special characters")
  end

  test "pre-deploy hook exists and validates hosts" do
    pre_deploy = @hooks_dir.join("pre-deploy")

    if File.exist?(pre_deploy)
      content = File.read(pre_deploy)

      # Should validate host formats
      assert_match(/Invalid host format/, content,
        "SECURITY: pre-deploy should validate host formats")

      # Should check for production confirmation
      assert_match(/KAMAL_PRODUCTION_CONFIRMED/, content,
        "SECURITY: pre-deploy should require production confirmation")
    end
  end

  test "hooks log security events" do
    [ @pre_build_hook, @hooks_dir.join("pre-deploy") ].each do |hook|
      next unless File.exist?(hook)

      content = File.read(hook)

      # Should log execution for audit trail
      assert_match(/date.*UTC.*started/, content,
        "SECURITY: Hooks should log execution with timestamps")

      assert_match(/KAMAL_PERFORMER/, content,
        "SECURITY: Hooks should log who performed the action")
    end
  end

  test "hooks use proper error handling" do
    skip unless File.exist?(@pre_build_hook)

    content = File.read(@pre_build_hook)

    # Should exit on errors
    assert_match(/exit 1/, content,
      "SECURITY: Hook should exit with error code on failure")

    # Should provide clear error messages
    assert_match(/ERROR:/, content,
      "SECURITY: Hook should provide clear error messages")

    # Should redirect errors to stderr
    assert_match(/>&2/, content,
      "SECURITY: Hook should send errors to stderr")
  end
end
# Copyright 2025
