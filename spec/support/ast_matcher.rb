require_relative 'rspec_helpers'
require_relative 'body_matcher'
require_relative 'block_prelude_matcher'
require_relative 'linear_matcher'

class ASTMatcher
  include RSpecHelpers

  def initialize(ast)
    @ast = ast
    @idx = 0
  end

  def peek = @ast[@idx]

  def consume = peek.tap { @idx += 1 }

  def empty!
    expect(@ast).to be_empty
  end

  def decl(name, important:, &)
    match_decl peek, name, important, &
  end

  def dimension(val, type, unit)
    expect(peek).to be_a(TinyCSS::AST::Dimension), "Expected #{val.class} to be a Dimension at index #{@idx}"
    expect(peek.value).to be_within(0.01).of(val)
    expect(peek.type).to eq type
    expect(peek.unit).to eq unit
    consume
  end

  def string(val)
    debugger unless peek.is_a?(TinyCSS::AST::StringToken)
    expect(peek).to be_a(TinyCSS::AST::StringToken), "Expected StringToken, but found #{peek.class} instead at index #{@idx}"
    expect(peek.value).to eq(val), "Expected #{peek.inspect} to match #{val.inspect} at index #{@idx}"
    consume
  end

  def ident(val)
    debugger unless peek.is_a?(String)
    expect(peek).to be_a(String), "Expected String, but found #{peek.class} instead at index #{@idx}"
    expect(peek).to eq(val), "Expected #{peek.inspect} to match #{val.inspect} at index #{@idx}"
    consume
  end

  def delim(val)
    debugger unless peek.is_a?(String)
    expect(peek).to be_a(String), "Expected String, but found #{peek.class} instead at index #{@idx}"
    expect(peek).to eq(val), "Expected #{peek.inspect} to match #{val.inspect} at index #{@idx}"
    consume
  end

  def match_decl(val, name, important, &)
    case val
    when TinyCSS::AST::DeclList
      obj = val.find { it.name == name }
      expect(obj).not_to be_nil {
        "Expected #{val} to contain a Decl named #{name.inspect} at index #{@idx}"
      }
      match_decl(obj, name, important, &)

    when TinyCSS::AST::Decl
      expect(val.name).to eq name
      expect(val.important).to eq important
      BodyMatcher.match(val.value, &)
      consume
    end
  end

  def at_rule(name, &)
    expect(peek).to be_a(TinyCSS::AST::AtRule), "expected #{peek.class} to be an AtRule at index #{@idx}"
    expect(peek.name).to eq name
    BlockPreludeMatcher.match(peek, &)
    consume
  end

  def q_rule(&)
    expect(peek).to be_a(TinyCSS::AST::Rule), "expected #{peek.class} to be a Rule at index #{@idx}"
    BlockPreludeMatcher.match(peek, &)
    consume
  end

  def function(name, &)
    expect(peek).to be_a(TinyCSS::AST::Function), "expected #{peek.class} to be a Function at index #{@idx}"
    debugger if peek.name != name
    expect(peek.name).to eq name
    ASTMatcher.new(peek.value).instance_exec(&)
    consume
  end

  def number(value, type)
    expect(peek).to be_a(TinyCSS::AST::Number), "expected #{peek.class} to be a Number at index #{@idx}"
    expect(peek.value).to be_within(0.001).of(value)
    expect(peek.type).to eq type
    consume
  end

  def block(sep, &)
    token = case sep
    when "("
      :left_parenthesis
    when "["
      :left_square_bracket
    when "{"
      :left_curly
    else
      fail("Unexpected separator type #{sep.dump} at index #{@idx}")
    end

    expect(peek).to be_a(TinyCSS::AST::Block), "expected #{peek.class} to be a Block at index #{@idx}"
    expect(peek.associated_token).to eq token
    ASTMatcher.new(peek.value).instance_exec(&)
    consume
  end

  def at_keyword(name)
    expect(peek.gsub(/^@/, '')).to eq name
    consume
  end

  def hash_keyword(name)
    expect(peek.gsub(/^#/, '')).to eq name
    consume
  end

  def consume_error(kind)
    return if ["eof-in-string", "eof-in-url", "invalid"].include? kind
    debugger if peek.nil?
    unless [TinyCSS::AST::BadToken, TinyCSS::AST::SyntaxError].include?(peek.class)
      fail "expected #{peek.class} to be either BadToken or SyntaxError at index #{@idx}"
    end

    case peek
    when TinyCSS::AST::BadToken
      expect(peek.kind).to eq kind.gsub(/-/, '_').to_sym
    when TinyCSS::AST::SyntaxError
      expect(peek.reason).to eq kind
    end
    consume
  end

  def url(value)
    expect(peek).to be_a(TinyCSS::AST::URL), "expected #{peek.class} to be a URL at index #{@idx}"
    expect(peek.value).to eq value
    consume
  end

  def percentage(value, kind)
    expect(peek).to be_a(TinyCSS::AST::Percentage), "expected #{peek.class} to be a Percentage at index #{@idx}"
    expect(peek.value).to be_within(0.01).of(value)
    expect(peek.type).to eq kind
    consume
  end

  def unicode_range(start, finish)
    expect(peek).to be_a(TinyCSS::AST::UnicodeRange), "expected #{peek.class} to be a UnicodeRange at index #{@idx}"
    expect(peek.range_start).to eq(start), "expected unicode range to start at #{start}, but found #{peek.range_start} instead at index #{@idx}"
    expect(peek.range_end).to eq(finish), "expected unicode range to end at #{finish}, but found #{peek.range_end} instead at index #{@idx}"
    consume
  end
end
