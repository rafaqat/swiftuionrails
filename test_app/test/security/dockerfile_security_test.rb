# Copyright 2025
require "test_helper"

class DockerfileSecurityTest < ActiveSupport::TestCase
  def setup
    @dockerfile_path = Rails.root.join("Dockerfile")
    @dockerfile_content = File.read(@dockerfile_path) if File.exist?(@dockerfile_path)
    skip "Dockerfile not found" unless @dockerfile_content
  end

  test "excludes test dependencies in production" do
    # Check that BUNDLE_WITHOUT includes test
    assert_match(/BUNDLE_WITHOUT=["']?development:test["']?/, @dockerfile_content,
      "SECURITY: Dockerfile should exclude test dependencies with BUNDLE_WITHOUT=\"development:test\"")

    # Should not include only development
    assert_no_match(/BUNDLE_WITHOUT=["']?development["']?\s*$/, @dockerfile_content,
      "SECURITY: BUNDLE_WITHOUT should include both development and test")
  end

  test "creates non-root user with proper configuration" do
    # Check for user creation
    assert_match(/useradd\s+rails/, @dockerfile_content,
      "SECURITY: Dockerfile should create a non-root 'rails' user")

    # Check for --no-log-init flag
    assert_match(/useradd.*--no-log-init/, @dockerfile_content,
      "SECURITY: useradd should include --no-log-init to prevent log injection")

    # Check for USER directive
    assert_match(/USER\s+1000:1000/, @dockerfile_content,
      "SECURITY: Dockerfile should switch to non-root user with USER directive")
  end

  test "sets proper file permissions" do
    # Check for directory creation
    assert_match(/mkdir\s+-p\s+db\s+log\s+storage\s+tmp/, @dockerfile_content,
      "SECURITY: Dockerfile should explicitly create required directories")

    # Check for chmod commands
    assert_match(/chmod\s+750\s+db\s+log\s+storage\s+tmp/, @dockerfile_content,
      "SECURITY: Directories should have restrictive permissions (750)")

    # Check for home directory permissions
    assert_match(/chmod\s+700\s+\/home\/rails/, @dockerfile_content,
      "SECURITY: User home directory should be protected (700)")
  end

  test "implements privilege escalation prevention" do
    # Check for sudoers configuration
    assert_match(/\/etc\/sudoers\.d\/rails/, @dockerfile_content,
      "SECURITY: Should configure sudoers to prevent privilege escalation")

    # Check for setuid/setgid removal
    assert_match(/find.*-perm.*\/4000.*chmod\s+u-s/, @dockerfile_content,
      "SECURITY: Should remove setuid binaries")

    assert_match(/find.*-perm.*\/2000.*chmod\s+g-s/, @dockerfile_content,
      "SECURITY: Should remove setgid binaries")
  end

  test "uses security-enhanced process management" do
    # Check for dumb-init
    assert_match(/apt-get\s+install.*dumb-init/, @dockerfile_content,
      "SECURITY: Should install dumb-init for proper signal handling")

    assert_match(/ENTRYPOINT.*dumb-init/, @dockerfile_content,
      "SECURITY: Should use dumb-init in ENTRYPOINT")
  end

  test "exposes unprivileged port" do
    # Should not expose port 80
    assert_no_match(/EXPOSE\s+80(?:\s|$)/, @dockerfile_content,
      "SECURITY: Should not expose privileged port 80")

    # Should expose port 3000 or another high port
    assert_match(/EXPOSE\s+(3000|8080|8000)/, @dockerfile_content,
      "SECURITY: Should expose unprivileged port (3000, 8080, or 8000)")
  end

  test "includes health check" do
    assert_match(/HEALTHCHECK/, @dockerfile_content,
      "SECURITY: Dockerfile should include HEALTHCHECK for monitoring")

    # Check for proper health check configuration
    assert_match(/HEALTHCHECK.*--interval/, @dockerfile_content,
      "SECURITY: HEALTHCHECK should specify interval")

    assert_match(/HEALTHCHECK.*--timeout/, @dockerfile_content,
      "SECURITY: HEALTHCHECK should specify timeout")
  end

  test "uses multi-stage build" do
    # Check for multiple FROM statements
    from_count = @dockerfile_content.scan(/^FROM\s+/i).count
    assert from_count >= 2,
      "SECURITY: Should use multi-stage build (found #{from_count} FROM statements, expected >= 2)"

    # Check for build stage
    assert_match(/FROM.*AS\s+build/i, @dockerfile_content,
      "SECURITY: Should have a build stage")
  end

  test "minimizes installed packages" do
    # Check for --no-install-recommends
    assert_match(/apt-get\s+install.*--no-install-recommends/, @dockerfile_content,
      "SECURITY: Should use --no-install-recommends to minimize packages")

    # Check for apt cleanup
    assert_match(/rm\s+-rf.*\/var\/lib\/apt\/lists/, @dockerfile_content,
      "SECURITY: Should clean up apt lists after installation")
  end

  test "dockerignore includes sensitive files" do
    dockerignore_path = Rails.root.join(".dockerignore")
    skip ".dockerignore not found" unless File.exist?(dockerignore_path)

    dockerignore_content = File.read(dockerignore_path)

    sensitive_patterns = [
      "*.key",
      "*.pem",
      ".env",
      "/test/",
      "/spec/",
      "/config/master.key",
      "/config/credentials/*.key"
    ]

    sensitive_patterns.each do |pattern|
      assert dockerignore_content.include?(pattern),
        "SECURITY: .dockerignore should exclude #{pattern}"
    end
  end

  test "docker-compose security file exists" do
    compose_security_path = Rails.root.join("docker-compose.security.yml")

    assert File.exist?(compose_security_path),
      "SECURITY: docker-compose.security.yml should exist for production hardening"

    if File.exist?(compose_security_path)
      compose_content = File.read(compose_security_path)

      # Check for security options
      assert_match(/security_opt:/, compose_content,
        "SECURITY: docker-compose.security.yml should include security_opt")

      assert_match(/no-new-privileges:true/, compose_content,
        "SECURITY: Should prevent privilege escalation")

      assert_match(/cap_drop:\s*\n\s*-\s*ALL/, compose_content,
        "SECURITY: Should drop all capabilities by default")

      assert_match(/read_only:\s*true/, compose_content,
        "SECURITY: Should use read-only root filesystem")
    end
  end

  test "no hardcoded secrets in Dockerfile" do
    # Check for common secret patterns
    secret_patterns = [
      /ENV.*SECRET.*=.*[a-zA-Z0-9]{16,}/,
      /ENV.*PASSWORD.*=.*\w+/,
      /ENV.*KEY.*=.*[a-zA-Z0-9]{16,}/,
      /ENV.*TOKEN.*=.*[a-zA-Z0-9]{16,}/,
      /COPY.*master\.key/,
      /ADD.*\.env/
    ]

    secret_patterns.each do |pattern|
      assert_no_match pattern, @dockerfile_content,
        "SECURITY: Dockerfile appears to contain hardcoded secrets"
    end
  end
end
# Copyright 2025
