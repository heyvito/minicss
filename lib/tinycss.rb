# frozen_string_literal: true

require_relative "tinycss/version"
require_relative "tinycss/errors"
require_relative "tinycss/css"
require_relative "tinycss/sel"
require_relative "tinycss/ast"
require_relative "tinycss/serializer"

# TinyCSS exposes the library’s public API. It bundles high-level helpers for
# tokenizing raw CSS, parsing it into TinyCSS::AST nodes, and serializing AST
# structures back to CSS.
module TinyCSS
  module_function

  # Tokenize a CSS source string or IO.
  #
  # @param input [String, #read] Raw CSS, or an IO-like object that responds to
  #   `#read`. Invalid UTF-8 bytes will be replaced with U+FFFD, and all line
  #   endings are normalized before tokenization.
  # @param allow_unicode_ranges [Boolean] When true, Unicode range tokens are
  #   retained rather than downgraded to generic identifiers.
  # @return [Array<TinyCSS::CSS::Token>] Tokens annotated with positional
  #   metadata (`pos_start`, `pos_end`, and `literal`).
  def tokenize(input, allow_unicode_ranges: false)
    tok = CSS::Tokenizer.new(input, allow_unicode_ranges:)
    tok.tokenize
    tok.tokens
  end

  # Parse CSS into TinyCSS AST nodes.
  #
  # @param input [String, #read] The stylesheet text or an IO-like object.
  # @param allow_unicode_ranges [Boolean] Passed through to {#tokenize}.
  # @return [Array<TinyCSS::AST::Rule, TinyCSS::AST::AtRule,
  #   TinyCSS::AST::SyntaxError, Object>] A stylesheet represented as TinyCSS
  #   AST nodes; syntax issues surface as {TinyCSS::AST::SyntaxError} entries.
  def parse(input, allow_unicode_ranges: false)
    toks = tokenize(input, allow_unicode_ranges:)
    pars = CSS::Parser.new(toks)
    sheet = pars.parse_stylesheet
    AST.convert(sheet)
  end


  # Serialize TinyCSS AST nodes back into CSS.
  #
  # @param ast [TinyCSS::AST::Rule, TinyCSS::AST::Decl, Array<Object>] Any AST
  #   node—or array of nodes—produced by {#parse} or the lower-level
  #   TinyCSS::AST conversion helpers.
  # @return [String] Normalized CSS suitable for writing back to disk or the
  #   network.
  def serialize(ast) = Serializer.serialize(ast)
end
