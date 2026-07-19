# Security Documentation - SwiftUI Rails

## Critical Security Fixes: Remote Code Execution Prevention

### Vulnerability Summary
Four critical RCE vulnerabilities were discovered and fixed:

1. **ReactiveController RCE**
   - **Type**: Remote Code Execution (RCE) via Unsafe Constantize
   - **Severity**: CRITICAL (CVSS 9.8)
   - **CWE**: CWE-470 (Use of Externally-Controlled Input to Select Classes)
   - **Location**: `lib/swift_ui_rails/reactive/rendering.rb:142` (now fixed)

2. **swift_component Helper RCE**
   - **Type**: Remote Code Execution (RCE) via Unsafe Constantize
   - **Severity**: CRITICAL (CVSS 9.1)
   - **CWE**: CWE-470 (Use of Externally-Controlled Input to Select Classes)
   - **Location**: `lib/swift_ui_rails/helpers.rb:24-27` (now fixed)

3. **ActionsController RCE**
   - **Type**: Remote Code Execution (RCE) via Unsafe Constantize with CSRF Disabled
   - **Severity**: CRITICAL (CVSS 9.8)
   - **CWE**: CWE-470 (Use of Externally-Controlled Input to Select Classes)
   - **Location**: `test_app/app/controllers/swift_ui/actions_controller.rb:39` (now fixed)

4. **StorySession RCE**
   - **Type**: Remote Code Execution (RCE) via Unsafe Constantize
   - **Severity**: HIGH (CVSS 8.1)
   - **CWE**: CWE-470 (Use of Externally-Controlled Input to Select Classes)
   - **Location**: `test_app/app/services/story_session.rb:49,149` (now fixed)

### Vulnerability Details
All vulnerabilities used `constantize` on user-controlled input without validation:

```ruby
# ReactiveController vulnerability
component_class = params[:component_class].constantize  # VULNERABLE

# swift_component helper vulnerability  
component_class = "#{name.to_s.camelize}Component".constantize  # VULNERABLE

# ActionsController vulnerability (with CSRF disabled!)
skip_before_action :verify_authenticity_token
component_class = action_data[:component_class].constantize  # VULNERABLE

# StorySession vulnerability
story_class = "#{story_name.camelize}Stories".constantize  # VULNERABLE
```

This allowed attackers to instantiate arbitrary Ruby classes, potentially leading to:
- Remote code execution
- Data exfiltration
- System compromise
- Denial of service

### Security Fix Implementation

#### 1. Component Whitelist
A strict whitelist of allowed components has been implemented:
```ruby
ALLOWED_COMPONENTS = Set.new(%w[
  ButtonComponent
  CardComponent
  ModalComponent
  CounterComponent
  ProductCardComponent
  ProductListComponent
  AuthFormComponent
  # ... other approved components
]).freeze
```

#### 2. Multi-Layer Validation
The fix implements defense-in-depth with multiple security layers:

1. **Whitelist Check**: Only components in ALLOWED_COMPONENTS can be instantiated
2. **Type Validation**: Ensures the class is a valid SwiftUI Rails component
3. **Props Sanitization**: Removes potentially dangerous prop values
4. **Request Validation**: Ensures requests come from valid sources (XHR/Turbo)

#### 3. Audit Logging
All component instantiation attempts are logged:
- Successful updates are logged for audit trail
- Failed/malicious attempts trigger security alerts
- IP addresses and user agents are captured

### Security Best Practices

#### Adding New Components
When adding new components to the whitelist:
1. Security review the component code
2. Ensure no dangerous methods are exposed
3. Add to both:
   - `ALLOWED_COMPONENTS` constant in `ReactiveController`
   - `allowed_components` in `SwiftUIRails.configuration`
4. Document the security review

#### Using swift_component Helper
The `swift_component` helper is now secure by default:
```ruby
# Safe usage - component name is validated
<%= swift_component :button, text: "Click me" %>
<%= swift_component "card", title: "Product" %>

# These will raise SecurityError
<%= swift_component "Kernel" %>  # Dangerous class
<%= swift_component "evil" %>    # Not in whitelist
```

To add custom components:
```ruby
# In an initializer
SwiftUIRails.configure do |config|
  config.allowed_components << "MyCustom"
end
```

#### Props Validation
The system automatically sanitizes props to prevent:
- Method invocation (`__send__`, `send`)
- Code evaluation (`eval`, `instance_eval`)
- System commands (`system`, `exec`, backticks)
- Dynamic constant loading (`constantize`)

#### CSRF Protection
- CSRF protection is now enforced (removed `skip_before_action`)
- All requests must include valid CSRF tokens
- XHR/Turbo Stream format is required

### Testing Security

Run security tests with:
```bash
rails test test/security/reactive_controller_security_test.rb
```

The security test suite verifies:
- Malicious class names are rejected
- Only whitelisted components are allowed
- Dangerous props are sanitized
- Invalid request formats are blocked
- Security events are properly logged

### Monitoring and Alerts

#### Log Monitoring
Monitor logs for security events:
```bash
grep "\[SECURITY\]" log/production.log
grep "\[SECURITY AUDIT\]" log/production.log
```

#### Alert Patterns
Set up alerts for:
- Multiple failed instantiation attempts from same IP
- Attempts to instantiate system classes (Kernel, File, etc.)
- Unusual prop patterns that may indicate attacks

### Incident Response

If a security incident is detected:
1. Check logs for `[SECURITY]` entries
2. Identify attack patterns and source IPs
3. Block malicious IPs at network level if needed
4. Review component whitelist for any additions
5. Audit recent component updates

### Future Security Enhancements

Consider implementing:
1. **Rate Limiting**: Limit component update requests per IP
2. **Request Signing**: Add cryptographic signatures to requests
3. **Component Sandboxing**: Run components in restricted contexts
4. **Runtime Protection**: Deploy RASP solutions for additional monitoring

### Security Contact

Report security vulnerabilities to: security@swiftuirails.com

### Changelog

- **2025-01-04**: Fixed critical RCE vulnerabilities
  - **ReactiveController** (`lib/swift_ui_rails/reactive/rendering.rb:142`)
    - Added component whitelist
    - Implemented props sanitization
    - Added comprehensive audit logging
    - Re-enabled CSRF protection
  - **swift_component helper** (`lib/swift_ui_rails/helpers.rb:24-27`)
    - Added centralized allowed_components configuration
    - Implemented component name validation
    - Added inheritance verification
    - Added security event logging
  - **ActionsController** (`test_app/app/controllers/swift_ui/actions_controller.rb:39`)
    - Re-enabled CSRF protection
    - Added component whitelist validation
    - Implemented security audit logging
    - Added request format verification
  - **StorySession** (`test_app/app/services/story_session.rb:49,149`)
    - Added story class whitelist
    - Implemented story name validation
    - Added inheritance verification for Stories classes
    - Added security logging

5. **Code Injection in ERB Template Generator**
   - **Type**: Code Injection via Template Generation
   - **Severity**: HIGH (CVSS 8.8)
   - **CWE**: CWE-94 (Improper Control of Generation of Code)
   - **Location**: `lib/generators/swift_ui_rails/component/templates/component.rb.erb` (now fixed)

6. **Hardcoded Secrets in Deployment Scripts**
   - **Type**: Use of Hard-coded Credentials
   - **Severity**: CRITICAL (CVSS 8.6)
   - **CWE**: CWE-798 (Use of Hard-coded Credentials)
   - **Location**: `test_app/.kamal/secrets:16-17` (now fixed)

### Additional Vulnerability Details

#### 5. Code Injection in ERB Template Generator
The generator allowed unsanitized user input in ERB templates:

```ruby
# Vulnerable code
class <%= component_class_name %> < ApplicationComponent
<% parsed_props.each do |prop| -%>
  prop :<%= prop[:name] %>, type: <%= prop[:type] %>  # User input directly in template!
<% end -%>
```

**Attack Vector**: Malicious component names like `Evil"; system("rm -rf /"); "` would execute during generation.

**Fixes Applied**:
- **Input Validation**: Component names must match `/\A[a-zA-Z][a-zA-Z0-9_]*\z/`
- **Keyword Blocking**: Rejects dangerous keywords (system, exec, eval, etc.)
- **Prop Validation**: Validates all prop names and types
- **Path Traversal Protection**: Prevents directory traversal attacks
- **Security Tests**: Comprehensive test coverage in `test/security/component_generator_security_test.rb`

#### 6. Hardcoded Secrets in Deployment Scripts
The Kamal deployment configuration exposed the Rails master key:

```bash
# Vulnerable code
RAILS_MASTER_KEY=$(cat config/master.key)  # Exposes in process listings!
```

**Attack Vectors**:
- Process listings (`ps aux`) expose the master key
- Shell history retains sensitive values
- CI/CD logs may capture secrets

**Fixes Applied**:
- **Environment Variable Support**: Reads from `$RAILS_MASTER_KEY` environment variable
- **Secrets Manager Integration**: Support for 1Password, AWS Secrets Manager, HashiCorp Vault
- **Fail-Safe Behavior**: Script exits with error if secrets not properly configured
- **Verification Script**: `scripts/verify_deployment_secrets.sh` validates configuration
- **Security Documentation**: Comprehensive guide in `docs/SECURE_DEPLOYMENT.md`

### Security Testing

All fixes include comprehensive security tests:
- `test/security/reactive_controller_security_test.rb`
- `test/security/swift_component_helper_security_test.rb`  
- `test/security/actions_controller_security_test.rb`
- `test/security/story_session_security_test.rb`
- `test/security/component_generator_security_test.rb`
- `test/security/stories_generator_security_test.rb`
- `test/security/deployment_secrets_security_test.rb`
- `test/security/websocket_security_test.rb`

### WebSocket Security Vulnerability

7. **Remote Code Execution via WebSocket**
   - **Type**: Deserialization of Untrusted Data / RCE
   - **Severity**: CRITICAL (CVSS 8.1)
   - **CWE**: CWE-502 (Deserialization of Untrusted Data)
   - **Location**: `lib/swift_ui_rails/reactive/rendering.rb:307-348` (now fixed)

#### Vulnerability Details
The WebSocket channel allowed user-controlled component class names without validation:

```ruby
# Vulnerable code
def request_update(data)
  ReactiveUpdateJob.perform_later(
    data["component_class"],  # User input directly used!
    data["component_id"],
    data["props"]
  )
end
```

**Attack Vector**: Malicious WebSocket messages with arbitrary class names could lead to RCE.

**Fixes Applied**:
- **Component Registry**: Uses a safe registry instead of constantize
- **Input Validation**: Validates component class against whitelist
- **ID Format Validation**: Ensures component IDs match expected pattern
- **Props Sanitization**: Sanitizes all props to prevent XSS
- **Job Validation**: Background job also validates all inputs
- **Security Logging**: Logs all unauthorized attempts

### Container Security

8. **Container Privilege Escalation**
   - **Type**: Execution with Unnecessary Privileges
   - **Severity**: HIGH (CVSS 7.8)
   - **CWE**: CWE-250 (Execution with Unnecessary Privileges)
   - **Location**: `test_app/Dockerfile:23-26, 62-65` (now fixed)

#### Vulnerability Details
The container configuration had several security issues:

```dockerfile
# Vulnerable configuration
ENV BUNDLE_WITHOUT="development"  # test group included
RUN chown -R rails:rails db log storage tmp  # May fail if dirs don't exist
USER 1000:1000  # No privilege restrictions
```

**Attack Vectors**:
- Test dependencies in production increase attack surface
- Missing privilege restrictions enable escalation
- Privileged port 80 requires root capabilities

**Fixes Applied**:
- **Dependency Minimization**: `BUNDLE_WITHOUT="development:test"`
- **Non-root User**: Created with `--no-log-init` to prevent log injection
- **Directory Security**: Explicit creation with restrictive permissions (750)
- **Privilege Prevention**: Removed setuid/setgid binaries, disabled sudo
- **Process Management**: Added dumb-init for proper signal handling
- **Unprivileged Port**: Changed from port 80 to 3000
- **Health Checks**: Added container health monitoring
- **Read-only Filesystem**: Configured in docker-compose.security.yml
- **Capability Dropping**: Removed all unnecessary Linux capabilities

Additional security files created:
- `docker-compose.security.yml` - Production-ready security configuration
- `docs/CONTAINER_SECURITY.md` - Comprehensive container security guide
- Enhanced `.dockerignore` - Prevents sensitive files in images
- Hardened `bin/docker-entrypoint` - Secure startup script

### Git Hooks Security

9. **Git Command Injection**
   - **Type**: OS Command Injection
   - **Severity**: HIGH (CVSS 7.2)
   - **CWE**: CWE-78 (OS Command Injection)
   - **Location**: `test_app/.kamal/hooks/pre-build.sample:39-40` (now fixed)

#### Vulnerability Details
The Kamal pre-build hook had unquoted variables in git commands:

```bash
# Vulnerable code
remote_head=$(git ls-remote $first_remote --tags $current_branch | cut -f1)
```

**Attack Vectors**:
- Malicious remote names: `origin$(whoami)`
- Malicious branch names: `main;rm -rf /`
- Command injection via special characters

**Fixes Applied**:
- **Shell Safety**: Using `bash` with `set -euo pipefail`
- **Input Validation**: Regex validation for remote/branch names
- **Variable Quoting**: All variables properly quoted
- **Git Command Fix**: Removed incorrect `--tags` flag
- **SHA Validation**: Validates git SHA format
- **Audit Logging**: Logs all hook executions
- **Error Handling**: Proper error messages to stderr

Additional security files created:
- `.kamal/hooks/pre-build` - Secure pre-build hook
- `.kamal/hooks/pre-deploy` - Secure pre-deploy hook
- `docs/GIT_HOOKS_SECURITY.md` - Git hooks security guide
- `test/security/git_hooks_security_test.rb` - Security tests