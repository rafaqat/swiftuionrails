# Safe DSL Parser for SwiftUI Rails

This document explains the safe DSL parser implementation that allows executing user-provided DSL code without using `eval` or `instance_eval`.

## Overview

The safe DSL parser provides a secure way to execute SwiftUI Rails DSL code by:

1. **Tokenizing** - Breaking the code into tokens (identifiers, strings, numbers, symbols, etc.)
2. **Parsing** - Building an Abstract Syntax Tree (AST) from the tokens
3. **Validating** - Checking all method calls against a whitelist
4. **Executing** - Running the AST in a controlled manner without eval

## Architecture

### 1. Token-Based Parser (`TokenParser`)

The parser uses a hand-written tokenizer and recursive descent parser to convert DSL code into an AST:

```ruby
code = 'text("Hello").font_size("xl").text_color("blue")'
parser = SwiftUIRails::Playground::TokenParser.new(code)
ast = parser.parse
```

**Supported Syntax:**
- Method calls: `text("Hello")`
- Method chains: `.font_size("xl").text_color("blue")`
- Blocks: `vstack do ... end`
- Named arguments: `vstack(spacing: 16, alignment: :center)`
- Literals: strings, numbers, symbols, booleans, nil

### 2. AST Structure

The parser produces a simple AST with these node types:

```ruby
# Method call node
{
  type: :method_call,
  receiver: <ast_node>,  # nil for top-level calls
  method: "method_name",
  args: [<ast_nodes>],
  block: <block_node>    # optional
}

# Block node
{
  type: :block,
  statements: [<ast_nodes>]
}

# Literal node
{
  type: :literal,
  value: <ruby_value>
}

# Named argument node
{
  type: :named_arg,
  key: :symbol,
  value: <ast_node>
}
```

### 3. AST Executor (`ASTExecutor`)

The executor walks the AST and executes it safely:

```ruby
executor = SwiftUIRails::Playground::ASTExecutor.new(context)
result = executor.execute(ast)
```

## Security Features

### Method Whitelisting

Only pre-approved DSL methods are allowed:

```ruby
DSL_METHODS = %w[
  swift_ui vstack hstack zstack grid
  text label button link input textfield
  card list scroll_view image icon
  # ... etc
]

MODIFIER_METHODS = %w[
  bg background text_color font_size
  padding margin width height
  rounded shadow border hover
  # ... etc
]
```

### No Dynamic Code Execution

- No `eval`, `instance_eval`, `class_eval`, or `module_eval`
- No `send`, `public_send`, or `__send__`
- No constant access or method introspection
- No file system or network access

### Input Validation

The parser validates all input before execution:
- Rejects dangerous patterns in the validation phase
- Only allows safe literal types (String, Integer, Float, Symbol, etc.)
- Sanitizes string content

## Usage Examples

### Basic DSL

```ruby
code = <<~RUBY
  swift_ui do
    vstack(spacing: 16) do
      text("Hello World")
        .font_size("2xl")
        .text_color("blue-600")
      
      button("Click Me")
        .bg("blue-500")
        .attr("data-action", "click->controller#method")
    end
  end
RUBY

executor = SwiftUIRails::Playground::Executor.new(session_id, view_context)
result = executor.execute(code)
```

### Complex Layouts

```ruby
code = <<~RUBY
  vstack(spacing: 4) do
    hstack do
      image(src: "/logo.png", alt: "Logo")
        .w(12)
        .h(12)
      
      text("My App")
        .font_size("xl")
        .font_weight("bold")
    end
    
    divider
    
    grid(columns: 3, spacing: 2) do
      card do
        text("Card 1")
      end
      card do
        text("Card 2")
      end
      card do
        text("Card 3")
      end
    end
  end
RUBY
```

## Alternative Implementations

### 1. Prism Parser (Ruby 3.3+)

For Ruby 3.3+, you can use the built-in Prism parser:

```ruby
require 'prism'

result = Prism.parse(code)
ast = result.value
# Validate and transform the Prism AST
```

### 2. Parser Gem

For older Ruby versions, use the parser gem:

```ruby
require 'parser/current'

buffer = Parser::Source::Buffer.new('(dsl)')
buffer.source = code
ast = Parser::CurrentRuby.new.parse(buffer)
# Validate and transform the Parser AST
```

### 3. Basic Regex Parser

For simple cases, a regex-based parser is included as a fallback.

## Testing

```ruby
# Test parsing
parser = SwiftUIRails::Playground::TokenParser.new(code)
ast = parser.parse

# Test execution
context = MyDSLContext.new
executor = SwiftUIRails::Playground::ASTExecutor.new(context)
result = executor.execute(ast)

# Test security
unsafe_code = 'eval("dangerous")'
assert_raises(SecurityError) { parser.parse }
```

## Performance Considerations

- Token parsing is fast for small DSL snippets
- AST execution has minimal overhead
- No runtime code compilation needed
- Can be cached for repeated execution

## Future Enhancements

1. **Error Recovery** - Better error messages with line/column info
2. **AST Optimization** - Optimize common patterns
3. **Type Checking** - Validate argument types before execution
4. **Sandbox Improvements** - Additional security layers
5. **Performance Monitoring** - Track execution time and resource usage

## Comparison with eval-based Approaches

| Feature | eval/instance_eval | Safe Parser |
|---------|-------------------|-------------|
| Security | ❌ Dangerous | ✅ Safe |
| Performance | ✅ Fast | ✅ Fast enough |
| Flexibility | ✅ Full Ruby | ⚠️ Limited to DSL |
| Error Messages | ✅ Native | ⚠️ Custom |
| Debugging | ✅ Standard | ⚠️ Custom tools |

## Conclusion

The safe DSL parser provides a secure way to execute user-provided DSL code without the security risks of eval. While it requires more implementation work than instance_eval, it provides complete control over what code can be executed, making it suitable for untrusted input scenarios like playgrounds, visual builders, or user-provided configurations.