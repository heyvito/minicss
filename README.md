# MiniCSS

MiniCSS is a pure Ruby implementation of the CSS Syntax Level 3 tokenizer,
parser, serializer, and selector toolkit. It provides fast, dependency-free
primitives for building linters, minifiers, and other CSS-aware tooling
without reaching for native extensions.

## Features

- Pure Ruby tokenizer and parser with zero native dependencies and support
for Ruby 3.4+.
- Battle-tested against the JSON-based `css-parsing-tests` suite for
standards-compliant parsing.
- High-level AST wrappers (`MiniCSS::AST::Rule`, `Decl`, `AtRule`, `Function`,
`Number`, and more) ready for programmatic inspection.
- Bidirectional selector helpers (`MiniCSS::Sel`) for tokenizing, walking,
computing specificity, and turning selector ASTs back into strings.
- Serializer that converts AST nodes back into normalized CSS, enabling
round-tripping and rewrites.
- Accepts either strings or IO objects, with optional Unicode range
tokenization via `allow_unicode_ranges`.

## Installation

Add MiniCSS to your project with Bundler:

```bash
bundle add minicss
```

Or install it directly:

```bash
gem install minicss
```

## Quick Start

```ruby
require "minicss"

css = <<~CSS
  @media (min-width: 768px) {
    .button.primary {
      color: #fff;
      background: rgb(0 0 0 / 80%);
    }
  }
CSS

sheet = MiniCSS.parse(css)

sheet.each do |node|
  case node
  when MiniCSS::AST::AtRule
    puts "At-rule: @#{node.name} #{MiniCSS.serialize(node.prelude)}"
    node.child_rules.each { puts "  Child: #{MiniCSS.serialize(_1)}" }
  when MiniCSS::AST::Rule
    selector = MiniCSS::Sel.stringify(node.selector)
    puts "Rule: #{selector}"
    node.decls.each do |decl|
      value = MiniCSS.serialize(decl.value)
      important = decl.important? ? " !important" : ""
      puts "  #{decl.name}: #{value}#{important}"
    end
  when MiniCSS::AST::SyntaxError
    warn "Syntax error: #{node.reason}"
  end
end
```

## Tokenizing CSS

```ruby
tokens = MiniCSS.tokenize(".btn { color: #fff; }")
tokens.map { |token| [token.kind, token.literal] }
# => [[:delim, "."], [:ident, "btn"], [:whitespace, " "], [:left_curly, "{"],
#     [:whitespace, " "], [:ident, "color"], [:colon, ":"], [:whitespace, " "],
#     [:hash, "#fff"], [:semicolon, ";"], [:whitespace, " "], [:right_curly, "}"]]

unicode_tokens = MiniCSS.tokenize("div { content: U+4E00-9FFF; }", allow_unicode_ranges: true)
```

Every token carries positional information via `token.pos_start` and
`token.pos_end`, making it easy to surface diagnostics.

## Working with Selectors

```ruby
selector_ast = MiniCSS::Sel.parse("button#primary.action:hover")
MiniCSS::Sel.specificity(selector_ast)
# => [1, 2, 1]

MiniCSS::Sel.walk(selector_ast) do |token, parent|
  puts "#{token[:type]} → #{token[:content]}"
end
# id → #primary
# class → .action
# pseudo-class → :hover
# type → button

MiniCSS::Sel.stringify(selector_ast)
# => "button#primary.action:hover"
```

Selectors are represented as nested hashes and arrays, mirroring the structure
produced by Lea Verou’s parsel, which `MiniCSS::Sel` is based on.

## Serializing CSS

`MiniCSS.serialize` accepts any AST node (or array of nodes) returned by
`MiniCSS.parse`:

```ruby
ast = MiniCSS.parse(".card { margin: 1rem; padding: 1rem; }")
MiniCSS.serialize(ast)
# => ".card{margin:1rem;padding:1rem;}"
```

This makes it easy to transform stylesheets and emit normalized output.

## Handling Errors

When the parser encounters invalid input it emits `MiniCSS::AST::SyntaxError`
nodes alongside the rest of the AST:

```ruby
errors = MiniCSS.parse("p { color: }").grep(MiniCSS::AST::SyntaxError)
errors.each { warn _1.reason }
# Syntax error details, including source offsets, are preserved from the tokenizer.
```

You can introspect the original token stream to report accurate diagnostics.

## Development

- Install dependencies: `bundle install`
- Run the test suite: `bundle exec rspec`
- Check style and linting: `bundle exec rubocop`
- Run everything: `bundle exec rake`

Helpful utilities:

- `bin/console` starts an IRB session with MiniCSS preloaded.
- `bin/gen-specs.rb` regenerates the specs under `spec/parsing_tests` from the
external `css-parsing-tests` fixtures.

## Contributing

Bug reports, feature requests, and pull requests are welcome. By participating
you agree to abide by the project’s Code of Conduct (see CODE_OF_CONDUCT.md).
Please include tests whenever you add or change behavior.

## License

```
The MIT License (MIT)

Copyright (c) 2025 Vito Sartori

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
