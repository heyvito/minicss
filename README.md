# MiniCSS

MiniCSS is a Ruby implementation of the CSS Syntax Level 3 tokenizer,
parser, serializer, and selector toolkit. It provides fast, dependency-free
primitives for building linters, minifiers, and other CSS-aware tooling.

## Features

- C tokenizer and parser for Ruby 3.4+.
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

- Clone the repository, and run `git submodule update --init` to fetch the
  required fixtures.
- Install dependencies: `bundle install`
- Compile native extensions: `bundle exec rake compile`
- Run the test suite: `bundle exec rspec`
- Check style and linting: `bundle exec rubocop`
- Run everything: `bundle exec rake`

Helpful utilities:

- `bin/console` starts an IRB session with MiniCSS preloaded.
- `bin/gen-specs.rb` regenerates the specs under `spec/parsing_tests` from the
external `css-parsing-tests` fixtures.
- `benchmarks/ruby_prof.rb` runs tokenization, parsing, and serialization against
ruby-prof for spotting slow code.
- `benchmarks/stylesheet.rb` runs a benchmark for each parsing and serialization
step against Crass.
- `benchmarks/selectors.rb` runs a benchmark for selector parsing, serialization,
and specificity.


## Benchmarks

As MiniCSS now relies on C extensions for performance, comparisons below are not
really fair, considering Crass is a pure-ruby solution. However, MiniCSS
provides support for extra CSS features and a different way of handling ASTs.

Results below are running MiniCSS and Crass on the Bootstrap 4 CSS on both
minified and unminified versions:

### Tokenizing

> [!WARNING]
> MiniCSS uses C extension for full tokenization. Comparisons below are not
> fair.

```
== Tokenize bootstrap-4.css ==
ruby 3.4.5 (2025-07-16 revision 20cda200d3) +PRISM [arm64-darwin24]
Warming up --------------------------------------
    MiniCSS tokenize     3.000 i/100ms
      Crass tokenize     1.000 i/100ms
Calculating -------------------------------------
    MiniCSS tokenize     31.449 (± 3.2%) i/s   (31.80 ms/i) -    159.000 in   5.058992s
      Crass tokenize     12.731 (± 0.0%) i/s   (78.55 ms/i) -     64.000 in   5.036126s

Comparison:
    MiniCSS tokenize:       31.4 i/s
      Crass tokenize:       12.7 i/s - 2.47x  slower

== Tokenize bootstrap-4.min.css ==
ruby 3.4.5 (2025-07-16 revision 20cda200d3) +PRISM [arm64-darwin24]
Warming up --------------------------------------
    MiniCSS tokenize     4.000 i/100ms
      Crass tokenize     1.000 i/100ms
Calculating -------------------------------------
    MiniCSS tokenize     39.820 (± 2.5%) i/s   (25.11 ms/i) -    200.000 in   5.026530s
      Crass tokenize     15.902 (± 6.3%) i/s   (62.89 ms/i) -     80.000 in   5.036493s

Comparison:
    MiniCSS tokenize:       39.8 i/s
      Crass tokenize:       15.9 i/s - 2.50x  slower
```

### Parsing

> [!NOTE]
> MiniCSS uses a pure-ruby implementation for this section, except for the
> `TokenStream` class, which relies on a C extension.

```
== Parse bootstrap-4.css ==
ruby 3.4.5 (2025-07-16 revision 20cda200d3) +PRISM [arm64-darwin24]
Warming up --------------------------------------
       MiniCSS parse     1.000 i/100ms
         Crass parse     1.000 i/100ms
Calculating -------------------------------------
       MiniCSS parse      7.837 (± 0.0%) i/s  (127.61 ms/i) -     40.000 in   5.105947s
         Crass parse      8.554 (±11.7%) i/s  (116.90 ms/i) -     43.000 in   5.061931s

Comparison:
         Crass parse:        8.6 i/s
       MiniCSS parse:        7.8 i/s - same-ish: difference falls within error

== Parse bootstrap-4.min.css ==
ruby 3.4.5 (2025-07-16 revision 20cda200d3) +PRISM [arm64-darwin24]
Warming up --------------------------------------
       MiniCSS parse     1.000 i/100ms
         Crass parse     1.000 i/100ms
Calculating -------------------------------------
       MiniCSS parse     10.086 (± 0.0%) i/s   (99.15 ms/i) -     51.000 in   5.058562s
         Crass parse     11.333 (± 0.0%) i/s   (88.24 ms/i) -     57.000 in   5.035570s

Comparison:
         Crass parse:       11.3 i/s
       MiniCSS parse:       10.1 i/s - 1.12x  slower
```

### Serializing

> [!NOTE]
> MiniCSS uses a pure-ruby implementaiton for this section. No C extensions are
> leveraged.

```
== Serialize bootstrap-4.css ==
ruby 3.4.5 (2025-07-16 revision 20cda200d3) +PRISM [arm64-darwin24]
Warming up --------------------------------------
   MiniCSS serialize    26.000 i/100ms
     Crass stringify    13.000 i/100ms
Calculating -------------------------------------
   MiniCSS serialize    267.680 (± 1.1%) i/s    (3.74 ms/i) -      1.352k in   5.051372s
     Crass stringify    134.551 (± 3.0%) i/s    (7.43 ms/i) -    676.000 in   5.028420s

Comparison:
   MiniCSS serialize:      267.7 i/s
     Crass stringify:      134.6 i/s - 1.99x  slower

== Serialize bootstrap-4.min.css ==
ruby 3.4.5 (2025-07-16 revision 20cda200d3) +PRISM [arm64-darwin24]
Warming up --------------------------------------
   MiniCSS serialize    26.000 i/100ms
     Crass stringify    18.000 i/100ms
Calculating -------------------------------------
   MiniCSS serialize    255.343 (± 5.1%) i/s    (3.92 ms/i) -      1.300k in   5.105550s
     Crass stringify    181.703 (± 5.0%) i/s    (5.50 ms/i) -    918.000 in   5.065818s

Comparison:
   MiniCSS serialize:      255.3 i/s
     Crass stringify:      181.7 i/s - 1.41x  slower
```



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
