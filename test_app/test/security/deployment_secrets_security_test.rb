require "test_helper"

class DeploymentSecretsSecurityTest < ActiveSupport::TestCase
  test "kamal secrets file does not contain hardcoded master key" do
    secrets_file = Rails.root.join(".kamal/secrets")
    
    if File.exist?(secrets_file)
      content = File.read(secrets_file)
      
      # Check for direct file reading of master.key
      assert_no_match(/cat\s+config\/master\.key/, content,
        "SECURITY: .kamal/secrets contains hardcoded master key reference")
      
      # Check for other dangerous patterns
      assert_no_match(/cat\s+.*\.key/, content,
        "SECURITY: .kamal/secrets reads key files directly")
      
      # Check for hardcoded credentials
      assert_no_match(/RAILS_MASTER_KEY\s*=\s*['"][a-f0-9]{32}['"]/, content,
        "SECURITY: .kamal/secrets contains hardcoded Rails master key")
      
      # Ensure proper environment variable usage
      if content.include?("RAILS_MASTER_KEY")
        assert_match(/RAILS_MASTER_KEY.*\$\{RAILS_MASTER_KEY\}/, content,
          "RAILS_MASTER_KEY should read from environment variable")
      end
    end
  end
  
  test "master.key is not committed to git" do
    # Check if we're in a git repository
    if system("git rev-parse --git-dir > /dev/null 2>&1")
      master_key_tracked = system("git ls-files --error-unmatch config/master.key > /dev/null 2>&1")
      assert_not master_key_tracked, 
        "SECURITY: config/master.key is tracked in git - it should be in .gitignore"
    end
  end
  
  test "environment files are not committed to git" do
    if system("git rev-parse --git-dir > /dev/null 2>&1")
      env_files = %w[.env .env.production .env.staging .env.local]
      
      env_files.each do |env_file|
        env_tracked = system("git ls-files --error-unmatch #{env_file} > /dev/null 2>&1")
        assert_not env_tracked,
          "SECURITY: #{env_file} is tracked in git - it should be in .gitignore"
      end
    end
  end
  
  test "gitignore includes sensitive files" do
    # Check both root and test_app gitignore
    gitignore_paths = [
      Rails.root.join(".gitignore"),
      Rails.root.join("../.gitignore")
    ]
    
    gitignore_found = false
    gitignore_paths.each do |gitignore_path|
      next unless File.exist?(gitignore_path)
      
      gitignore_found = true
      gitignore_content = File.read(gitignore_path)
      
      sensitive_patterns = [
        "master.key",
        ".env",
        "*.key"
      ]
      
      sensitive_patterns.each do |pattern|
        assert gitignore_content.include?(pattern),
          "SECURITY: #{gitignore_path} should include #{pattern}"
      end
    end
    
    assert gitignore_found, "SECURITY: No .gitignore file found"
  end
  
  test "deployment scripts use secure secret handling" do
    deployment_files = Dir.glob(Rails.root.join(".kamal/**/*"))
    
    deployment_files.each do |file|
      next unless File.file?(file) && File.readable?(file)
      
      content = File.read(file)
      
      # Check for exposed secrets in logs (exclude error messages)
      lines = content.split("\n")
      lines.each_with_index do |line, index|
        # Skip error message lines
        next if line.include?("ERROR:") || line.include?(">&2")
        
        if line =~ /echo.*RAILS_MASTER_KEY/ && line !~ /echo\s+"ERROR:/
          assert false, "SECURITY: #{file}:#{index+1} may expose RAILS_MASTER_KEY in logs"
        end
      end
      
      # Check for secrets in process listings
      assert_no_match(/RAILS_MASTER_KEY=['"]\w+['"]/, content,
        "SECURITY: #{file} may expose secrets in process listings")
    end
  end
  
  test "secure deployment documentation exists" do
    secure_deploy_doc = Rails.root.join("docs/SECURE_DEPLOYMENT.md")
    
    assert File.exist?(secure_deploy_doc),
      "SECURITY: Secure deployment guide should exist at docs/SECURE_DEPLOYMENT.md"
    
    if File.exist?(secure_deploy_doc)
      content = File.read(secure_deploy_doc)
      
      # Ensure documentation covers key security topics
      required_topics = [
        "Environment Variables",
        "1Password",
        "AWS Secrets Manager",
        "HashiCorp Vault"
      ]
      
      required_topics.each do |topic|
        assert content.include?(topic),
          "SECURITY: Deployment guide should cover #{topic}"
      end
    end
  end
  
  test "verification script exists and is executable" do
    verify_script = Rails.root.join("scripts/verify_deployment_secrets.sh")
    
    assert File.exist?(verify_script),
      "SECURITY: Deployment verification script should exist"
    
    if File.exist?(verify_script)
      assert File.executable?(verify_script),
        "SECURITY: Verification script should be executable"
      
      # Test script content
      content = File.read(verify_script)
      assert content.include?("RAILS_MASTER_KEY"),
        "SECURITY: Verification script should check RAILS_MASTER_KEY"
    end
  end
  
  test "no hardcoded API keys or tokens" do
    # Scan all Ruby and YAML files for potential hardcoded secrets
    files_to_scan = Dir.glob(Rails.root.join("**/*.{rb,yml,yaml}"))
    
    # Common patterns for API keys and tokens
    secret_patterns = [
      /api[_-]?key\s*[:=]\s*["'][a-zA-Z0-9]{20,}["']/i,
      /secret[_-]?key\s*[:=]\s*["'][a-zA-Z0-9]{20,}["']/i,
      /access[_-]?token\s*[:=]\s*["'][a-zA-Z0-9]{20,}["']/i,
      /private[_-]?key\s*[:=]\s*["'][a-zA-Z0-9]{20,}["']/i,
      /bearer\s+[a-zA-Z0-9\-._~+\/]{20,}/i
    ]
    
    files_to_scan.each do |file|
      next if file.include?("test/") || file.include?("spec/")
      next unless File.readable?(file)
      
      content = File.read(file)
      
      secret_patterns.each do |pattern|
        assert_no_match pattern, content,
          "SECURITY: Potential hardcoded secret found in #{file}"
      end
    end
  end
end