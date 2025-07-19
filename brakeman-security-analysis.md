# Brakeman Security Analysis Report

## Summary
- **Total Security Warnings**: 17
- **High Confidence**: 2 warnings
- **Medium Confidence**: 4 warnings
- **Weak Confidence**: 11 warnings

## Critical Security Issues (High Confidence)

### 1. Dangerous Code Evaluation (HIGH RISK)
**Files**: `app/controllers/playground_v2_controller.rb` (lines 40, 48)
**Issue**: Direct evaluation of user input without sanitization
**Risk**: Remote Code Execution (RCE)
**Code**: 
```ruby
class_eval("def call\n#{params[:code]}\nend")
```
**CWE**: 913 (Improper Control of Dynamically-Managed Code Resources), 95 (Improper Neutralization of Directives)

## Medium Confidence Issues

### 2. Unsafe Reflection Method Calls
**File**: `app/controllers/storybook_controller.rb` (lines 105, 122, 211, 221)
**Issue**: Using `safe_constantize` on parameter values
**Risk**: Remote Code Execution
**Code Examples**:
```ruby
"#{sanitize_story_name(params[:story]).camelize}Stories".safe_constantize
"#{sanitize_story_name(params[:story]).gsub(/_component(_stories)?$/, "")}_component".camelize.safe_constantize
```

### 3. Session Manipulation
**File**: `app/controllers/swift_ui/actions_controller.rb` (line 73)
**Issue**: Parameter value used as key in session hash
**Risk**: Session hijacking/manipulation
**Code**: `session["component_#{params[:component_id]}"]`

## Weak Confidence Issues (11 total)

### 4. Cross-Site Scripting (XSS)
**Files**: 
- `app/views/playground/_preview.html.erb` (line 1)
- `app/views/playground_v2/_preview.html.erb` (line 1)
**Issue**: Unescaped parameter values in output
**Risk**: XSS attacks

### 5. Dynamic Render Path Issues (5 instances)
**File**: `app/views/stateless_demo/index.html.erb` (lines 11, 25, 36, 67, 135)
**Issue**: Parameter values used in render paths
**Risk**: Path traversal
**Parameters**: `params[:tab]`, `params[:filters]`, `params[:q]`, `params[:modal]`

### 6. File Access Issues (2 instances)
**File**: `app/controllers/storybook_controller.rb` (lines 92, 202)
**Issue**: Parameter values used in file names
**Risk**: Directory traversal
**Code**: `load(Rails.root.join("test/components/stories/#{sanitize_story_name(params[:story])}_stories.rb"))`

### 7. Dangerous Eval in Sandbox
**File**: `app/services/playground/sandbox_executor.rb` (line 49)
**Issue**: Dynamic code evaluation
**Code**: `create_sandbox_binding.eval(code)`

## Files That Need Immediate Attention

### Critical Priority (Fix First)
1. **`app/controllers/playground_v2_controller.rb`** - High confidence RCE vulnerabilities
2. **`app/controllers/storybook_controller.rb`** - Multiple unsafe reflection calls

### Medium Priority
3. **`app/controllers/swift_ui/actions_controller.rb`** - Session manipulation
4. **`app/views/playground/_preview.html.erb`** - XSS vulnerability
5. **`app/views/playground_v2/_preview.html.erb`** - XSS vulnerability

### Lower Priority (Review & Harden)
6. **`app/views/stateless_demo/index.html.erb`** - Multiple dynamic render path issues
7. **`app/services/playground/sandbox_executor.rb`** - Eval usage (intentional but needs review)

## Recommended Actions

### Immediate (High Risk)
1. **Sanitize code evaluation**: Add proper input validation and sandboxing for playground controllers
2. **Secure story loading**: Implement allowlisting for story names instead of dynamic constantization
3. **Fix session keys**: Use validated/hashed component IDs for session storage

### Short Term
4. **Escape output**: Ensure all user input is properly escaped in views
5. **Validate parameters**: Add strict parameter validation for all dynamic renders
6. **Audit file access**: Review file loading patterns for path traversal risks

### Long Term
7. **Security review**: Conduct full security audit of playground and storybook features
8. **Input validation**: Implement comprehensive input validation framework
9. **Sandbox hardening**: Review and harden code execution sandbox

## Notes
- Most playground-related warnings are expected due to the intentional code execution features
- The key is to ensure proper sandboxing and input validation
- Storybook controller needs the most attention for production security