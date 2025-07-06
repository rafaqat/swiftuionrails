# Security Guide for SwiftUI Rails

## Overview

SwiftUI Rails has been designed with security as a top priority. This guide outlines the security features and best practices for using the framework.

## Security Features

### 1. Content Security Policy (CSP)

SwiftUI Rails includes built-in CSP support to prevent XSS attacks:

```ruby
# Enabled by default in config/initializers/swift_ui_rails.rb
config.content_security_policy_enabled = true
```

The CSP headers restrict:
- Script sources to self and inline (for Stimulus)
- Style sources to self and inline (for Tailwind)
- Image sources to self and approved domains only
- Prevents framing (clickjacking protection)

### 2. URL Validation

All external URLs are validated against an approved domains list:

```ruby
# Add approved domains in your initializer
SwiftUIRails.configure do |config|
  config.add_approved_domain('cdn.myapp.com')
  config.add_approved_domain('assets.myapp.com')
end
```

The URL validator blocks:
- `javascript:` URLs
- `data:` URLs (except safe image formats)
- `vbscript:` and other dangerous schemes
- Unapproved external domains

### 3. CSS Injection Prevention

All CSS values are validated and sanitized:
- Whitelisted color values
- Validated spacing values
- Blocked dangerous CSS patterns
- Style strings are validated for injection attempts

### 4. Rate Limiting

Prevents abuse of action handlers:

```ruby
# Configure in initializer
config.rate_limit_actions = true
config.rate_limit_threshold = 30  # Max 30 actions
config.rate_limit_window = 60     # Per 60 seconds
```

### 5. Component Depth Limiting

Prevents stack overflow attacks:

```ruby
config.maximum_component_depth = 50
```

### 6. XSS Protection

- All user content is HTML escaped
- Rails' built-in sanitization is used
- CSRF tokens included in all forms
- Proper content type headers set

## Security Headers

The framework sets these security headers by default:

- `X-Frame-Options: DENY` - Prevents clickjacking
- `X-Content-Type-Options: nosniff` - Prevents MIME sniffing
- `X-XSS-Protection: 1; mode=block` - XSS protection
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy` - Restricts browser features

## Best Practices

### 1. Keep Dependencies Updated

Regularly update SwiftUI Rails and its dependencies:

```bash
bundle update swift_ui_rails
```

### 2. Configure Approved Domains

Only approve domains you trust:

```ruby
# Good - specific domains
config.add_approved_domain('cdn.mycompany.com')

# Bad - too broad
config.add_approved_domain('amazonaws.com')
```

### 3. Monitor Rate Limits

Adjust rate limits based on your application's needs:

```ruby
# For high-traffic apps
config.rate_limit_threshold = 100
config.rate_limit_window = 300  # 5 minutes
```

### 4. Use HTTPS

Always use HTTPS in production:

```ruby
# config/environments/production.rb
config.force_ssl = true
```

### 5. Regular Security Audits

Run security scans regularly:

```bash
# Check for vulnerable dependencies
bundle audit

# Run RuboCop with security cops
bundle exec rubocop
```

## Reporting Security Issues

If you discover a security vulnerability, please email security@swiftuirails.com with:

1. Description of the vulnerability
2. Steps to reproduce
3. Potential impact
4. Suggested fix (if any)

Do not open public issues for security vulnerabilities.

## Security Checklist

- [ ] CSP enabled in production
- [ ] All external domains approved
- [ ] Rate limiting configured appropriately
- [ ] HTTPS enforced in production
- [ ] Dependencies up to date
- [ ] Security headers verified
- [ ] Regular security scans scheduled

## A+ Security Rating

SwiftUI Rails achieves an A+ security rating by implementing:

1. **Defense in Depth**: Multiple layers of security
2. **Secure by Default**: Security features enabled out of the box
3. **Input Validation**: All user input is validated and sanitized
4. **Output Encoding**: All output is properly encoded
5. **Rate Limiting**: Protection against abuse
6. **Security Headers**: Comprehensive security headers
7. **Regular Updates**: Committed to security patches

For more information, see the [Security Module Documentation](lib/swift_ui_rails/security/).