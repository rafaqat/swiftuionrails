# SwiftUI Rails Security Guide

This guide covers the comprehensive security features built into SwiftUI Rails and best practices for secure component development.

## Table of Contents

1. [Security Overview](#security-overview)
2. [Built-in Security Features](#built-in-security-features)
3. [XSS Prevention](#xss-prevention)
4. [CSRF Protection](#csrf-protection)
5. [URL and CSS Injection Prevention](#url-and-css-injection-prevention)
6. [Rate Limiting](#rate-limiting)
7. [Content Security Policy](#content-security-policy)
8. [Secure Development Practices](#secure-development-practices)
9. [Security Testing](#security-testing)
10. [Security Checklist](#security-checklist)

## Security Overview

SwiftUI Rails implements defense-in-depth security with multiple layers:

1. **Input Validation**: All user inputs are validated and sanitized
2. **Output Encoding**: Automatic HTML escaping prevents XSS
3. **URL Validation**: Prevents javascript: and data: URL attacks
4. **CSS Validation**: Blocks expression() and other CSS-based attacks
5. **Rate Limiting**: Prevents abuse and brute force attacks
6. **CSP Headers**: Restricts resource loading and script execution
7. **CSRF Protection**: Automatic token generation and validation

## Built-in Security Features

### Automatic HTML Escaping

All text content is automatically escaped:

```ruby
# User input is safely escaped
text(user_input)  # <script> becomes &lt;script&gt;

# Even in complex compositions
vstack do
  text("Welcome, #{@user.name}")  # Name is escaped
  text(@comment.body)              # Comment is escaped
end
```

### Validated Attributes

All attributes that could contain dangerous content are validated:

```ruby
# URLs are validated
link("Click", destination: user_url)     # Blocks javascript: URLs
image(src: user_image)                   # Blocks data: URLs with scripts

# CSS is validated  
div.style("color: #{user_color}")       # Blocks expression() attacks

# Classes are sanitized
div(class: user_classes)                 # Prevents attribute breaking
```

### Secure Form Helpers

Forms automatically include CSRF tokens:

```ruby
secure_form(action: "/submit", method: "post") do
  textfield(name: "email", type: "email")
  button("Submit", type: "submit")
end

# Generates hidden authenticity_token field
```

## XSS Prevention

### Text Content Protection

```ruby
# Safe by default
text("<script>alert('XSS')</script>")
# Renders: &lt;script&gt;alert('XSS')&lt;/script&gt;

# Complex content is also safe
card do
  text(@user.bio)  # User bio is escaped
  div do
    text("Posted by #{@comment.author}")  # Author is escaped
  end
end
```

### Attribute Protection

```ruby
# Dangerous event handlers are blocked
button("Click", onclick: "alert('XSS')")  # onclick is filtered

# Data attributes are escaped
div.data(message: "<script>alert('XSS')</script>")
# Renders: data-message="&lt;script&gt;alert('XSS')&lt;/script&gt;"
```

### When You Need Raw HTML

Only use `raw` with trusted content:

```ruby
# DANGER: Only use with content you absolutely trust
raw(@article.sanitized_html)  # Must be pre-sanitized

# Better approach: Use markdown with sanitization
text(markdown_to_html(@article.content, sanitize: true))
```

## CSRF Protection

### Automatic Token Generation

All forms automatically include CSRF tokens:

```ruby
# secure_form helper adds token automatically
secure_form(action: "/api/update", method: "post") do
  textfield(name: "title", value: @post.title)
  button("Update", type: "submit")
end
```

### Manual Token Addition

For custom forms or AJAX requests:

```ruby
# Get CSRF token
token = form_authenticity_token

# Add to custom form
form(action: "/submit", method: "post") do
  hidden_field_tag("authenticity_token", token)
  # form fields
end

# For AJAX requests
div.data(
  controller: "form",
  "form-csrf-token-value": token
)
```

### Configuration

CSRF protection can be configured in your Rails application:

```ruby
# config/application.rb
config.force_ssl = true  # Enforce HTTPS
config.ssl_options = { hsts: { subdomains: true } }
```

## URL and CSS Injection Prevention

### URL Validation

The URL validator blocks dangerous protocols:

```ruby
# These are blocked:
# - javascript:alert(1)
# - vbscript:msgbox(1)
# - data:text/html,<script>alert(1)</script>
# - file:///etc/passwd
# - about:blank
# - chrome://settings

# Safe URLs are allowed:
# - https://example.com
# - /relative/path
# - #anchor
# - mailto:user@example.com
# - tel:+1234567890

# Example usage
link("Profile", destination: user_provided_url)  # Automatically validated
```

### CSS Validation

The CSS validator prevents:

```ruby
# These attacks are blocked:
# - expression(alert('XSS'))
# - url('javascript:alert(1)')
# - @import url('evil.css')
# - behavior: url('evil.htc')
# - -moz-binding: url('evil.xml')

# Safe CSS is allowed:
div.style("color: #{user_color}")         # Validates color
div.style("background: #{user_bg}")       # Validates background
div.style("font-size: #{user_size}px")    # Validates size
```

### Custom Validation

You can manually validate inputs:

```ruby
# URL validation
validator = SwiftUIRails::Security::UrlValidator.new
if validator.validate_url(user_input)
  link("Safe Link", destination: user_input)
else
  text("Invalid URL provided")
end

# CSS validation
css_validator = SwiftUIRails::Security::CssValidator.new
safe_color = css_validator.safe_css_value(user_color, fallback: "black")
div.style("color: #{safe_color}")
```

## Rate Limiting

### Built-in Rate Limiter

Protect actions from abuse:

```ruby
class CommentComponent < SwiftUIRails::Component::Base
  def handle_submit
    # Check rate limit
    unless rate_limiter.check("comment_submit_#{current_user.id}")
      return error_response("Too many requests. Please try again later.")
    end
    
    # Process comment
    create_comment
  end
  
  private
  
  def rate_limiter
    SwiftUIRails::Security::RateLimiter.instance
  end
end
```

### Configuration

Configure rate limiting in initializer:

```ruby
# config/initializers/swift_ui_rails.rb
SwiftUIRails.configure do |config|
  config.rate_limit_actions = true
  config.rate_limit_threshold = 10  # Requests per window
  config.rate_limit_window = 60     # Window in seconds
end
```

### Custom Rate Limits

Apply different limits for different actions:

```ruby
# Strict limit for password resets
rate_limiter.check("password_reset_#{ip}", threshold: 3, window: 3600)

# Looser limit for searches  
rate_limiter.check("search_#{user_id}", threshold: 30, window: 60)

# API endpoint protection
rate_limiter.check("api_#{api_key}", threshold: 100, window: 60)
```

## Content Security Policy

### Automatic CSP Headers

SwiftUI Rails can automatically add CSP headers:

```ruby
class ApplicationController < ActionController::Base
  before_action :set_csp_header
  
  private
  
  def set_csp_header
    csp = SwiftUIRails::Security::ContentSecurityPolicy.new
    response.headers['Content-Security-Policy'] = csp.header_value
  end
end
```

### Default Policy

The default CSP is restrictive:

```
default-src 'self';
script-src 'self' 'nonce-{random}';
style-src 'self' 'nonce-{random}';
img-src 'self' data: https:;
font-src 'self';
connect-src 'self';
frame-ancestors 'none';
base-uri 'self';
form-action 'self';
```

### Customizing CSP

```ruby
# Add approved CDNs
csp = SwiftUIRails::Security::ContentSecurityPolicy.new
csp.script_src = "'self' https://cdn.jsdelivr.net"
csp.style_src = "'self' https://cdn.tailwindcss.com"

# For development with webpack-dev-server
if Rails.env.development?
  csp.connect_src = "'self' ws://localhost:3035"
end
```

### Using Nonces

For inline scripts and styles:

```ruby
# Generate nonce
nonce = SecureRandom.base64(16)

# Add to CSP
csp.script_src = "'self' 'nonce-#{nonce}'"

# Use in component
swift_ui do
  script(nonce: nonce) do
    "console.log('This inline script is allowed');"
  end
end
```

## Secure Development Practices

### 1. Never Trust User Input

Always validate and sanitize:

```ruby
# Bad
div.style("color: #{params[:color]}")

# Good
validator = SwiftUIRails::Security::CssValidator.new
safe_color = validator.safe_css_value(params[:color])
div.style("color: #{safe_color}")
```

### 2. Use Type-Safe Props

Define strict prop types:

```ruby
class UserCardComponent < SwiftUIRails::Component::Base
  # Type validation prevents injection
  prop :name, type: String, required: true
  prop :age, type: Integer, required: true
  prop :admin, type: [TrueClass, FalseClass], default: false
  
  # This would raise an error if passed malicious data
  # UserCardComponent.new(name: "<script>", age: "injection")
end
```

### 3. Validate URLs from External Sources

```ruby
class LinkListComponent < SwiftUIRails::Component::Base
  prop :links, type: Array, required: true
  
  swift_ui do
    vstack do
      links.each do |link_data|
        # Validate each URL
        if valid_url?(link_data[:url])
          link(link_data[:text], destination: link_data[:url])
        else
          text("#{link_data[:text]} (Invalid URL)")
        end
      end
    end
  end
  
  private
  
  def valid_url?(url)
    SwiftUIRails::Security::UrlValidator.new.validate_url(url)
  end
end
```

### 4. Secure File Uploads

```ruby
class FileUploadComponent < SwiftUIRails::Component::Base
  ALLOWED_TYPES = %w[image/jpeg image/png image/gif].freeze
  MAX_SIZE = 5.megabytes
  
  def validate_upload(file)
    # Check file type
    unless ALLOWED_TYPES.include?(file.content_type)
      return error("Invalid file type")
    end
    
    # Check file size
    if file.size > MAX_SIZE
      return error("File too large")
    end
    
    # Scan for malware (integrate with antivirus)
    if virus_detected?(file)
      return error("Security threat detected")
    end
    
    true
  end
end
```

### 5. Implement Proper Authentication

```ruby
class SecureComponent < SwiftUIRails::Component::Base
  prop :user, type: User, required: true
  
  swift_ui do
    if user.authenticated?
      render_secure_content
    else
      render_login_prompt
    end
  end
  
  private
  
  def render_secure_content
    # Only show to authenticated users
    vstack do
      text("Welcome #{user.name}")
      text("Account balance: #{user.balance}")
    end
  end
end
```

### 6. Log Security Events

```ruby
class AuditedComponent < SwiftUIRails::Component::Base
  def handle_sensitive_action
    # Log the attempt
    Rails.logger.info "[SECURITY] Sensitive action attempted by user #{current_user.id}"
    
    # Check permissions
    unless current_user.can?(:perform_sensitive_action)
      Rails.logger.warn "[SECURITY] Unauthorized attempt by user #{current_user.id}"
      return error_response("Unauthorized")
    end
    
    # Perform action
    perform_action
    
    # Log success
    Rails.logger.info "[SECURITY] Sensitive action completed by user #{current_user.id}"
  end
end
```

## Security Testing

### Unit Tests for Security

```ruby
RSpec.describe "Component Security" do
  describe "XSS Prevention" do
    it "escapes user input in text" do
      component = MyComponent.new(title: "<script>alert('XSS')</script>")
      rendered = component.call
      
      expect(rendered).not_to include("<script>")
      expect(rendered).to include("&lt;script&gt;")
    end
    
    it "validates URLs" do
      component = LinkComponent.new(url: "javascript:alert('XSS')")
      rendered = component.call
      
      expect(rendered).not_to include("javascript:")
      expect(rendered).to include('href="#"')
    end
  end
  
  describe "CSRF Protection" do
    it "includes authenticity token in forms" do
      component = FormComponent.new
      rendered = component.call
      
      expect(rendered).to include("authenticity_token")
    end
  end
end
```

### Integration Tests

```ruby
class SecurityIntegrationTest < ActionDispatch::IntegrationTest
  test "rate limiting prevents abuse" do
    # Exceed rate limit
    11.times do
      post "/comments", params: { comment: { body: "Test" } }
    end
    
    # Should be rate limited
    assert_response 429
    assert_match "Too many requests", response.body
  end
  
  test "CSP headers are set" do
    get "/"
    
    assert response.headers["Content-Security-Policy"].present?
    assert_match "default-src 'self'", response.headers["Content-Security-Policy"]
  end
end
```

### Security Scanning

Use automated tools:

```bash
# Ruby security scanner
bundle exec brakeman

# Dependency vulnerability scanner
bundle exec bundler-audit

# JavaScript security scanner
npm audit

# OWASP dependency check
dependency-check --project MyApp --scan .
```

## Security Checklist

### Component Development

- [ ] All user inputs are validated
- [ ] Text content uses `text()` helper (auto-escaped)
- [ ] URLs are validated before use
- [ ] CSS values are validated
- [ ] Forms use `secure_form` helper
- [ ] Props have strict type definitions
- [ ] No use of `raw()` with user content
- [ ] No use of `html_safe` with user content

### Application Security

- [ ] HTTPS is enforced in production
- [ ] CSP headers are configured
- [ ] Rate limiting is enabled
- [ ] CSRF protection is active
- [ ] Sessions timeout appropriately
- [ ] Passwords are hashed with bcrypt
- [ ] API tokens are securely stored
- [ ] File uploads are validated

### Testing

- [ ] Security tests for XSS prevention
- [ ] Tests for SQL injection prevention
- [ ] Tests for CSRF protection
- [ ] Tests for rate limiting
- [ ] Tests for authorization
- [ ] Regular dependency updates
- [ ] Security scanning in CI/CD

### Monitoring

- [ ] Security events are logged
- [ ] Anomaly detection is configured
- [ ] Failed login attempts are tracked
- [ ] Rate limit violations are monitored
- [ ] Error tracking includes security context
- [ ] Regular security audits scheduled

### Incident Response

- [ ] Security contact is defined
- [ ] Incident response plan exists
- [ ] Vulnerability disclosure process
- [ ] Security patches are prioritized
- [ ] Post-incident reviews conducted

## Reporting Security Issues

If you discover a security vulnerability:

1. **Do NOT** open a public issue
2. Email security@example.com with details
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We follow responsible disclosure and will:
- Respond within 48 hours
- Work on a fix immediately
- Credit researchers (if desired)
- Publish security advisories

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Content Security Policy Reference](https://content-security-policy.com/)
- [CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)