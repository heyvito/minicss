# frozen_string_literal: true

require_relative "minicss/version"
require_relative "minicss/errors"
require_relative "minicss/css"
require_relative "minicss/sel"
require_relative "minicss/ast"
require_relative "minicss/serializer"

# MiniCSS exposes the library’s public API. It bundles high-level helpers for
# tokenizing raw CSS, parsing it into MiniCSS::AST nodes, and serializing AST
# structures back to CSS.
module MiniCSS
  module_function

  # Tokenize a CSS source string or IO.
  #
  # @param input [String, #read] Raw CSS, or an IO-like object that responds to
  #   `#read`. Invalid UTF-8 bytes will be replaced with U+FFFD, and all line
  #   endings are normalized before tokenization.
  # @param allow_unicode_ranges [Boolean] When true, Unicode range tokens are
  #   retained rather than downgraded to generic identifiers.
  # @return [Array<MiniCSS::CSS::Token>] Tokens annotated with positional
  #   metadata (`pos_start`, `pos_end`, and `literal`).
  def tokenize(input, allow_unicode_ranges: false)
    tok = CSS::Tokenizer.new(input, allow_unicode_ranges:)
    tok.tokenize
    tok.tokens
  end

  # Parse CSS into MiniCSS AST nodes.
  #
  # @param input [String, #read] The stylesheet text or an IO-like object.
  # @param allow_unicode_ranges [Boolean] Passed through to {#tokenize}.
  # @return [Array<MiniCSS::AST::Rule, MiniCSS::AST::AtRule,
  #   MiniCSS::AST::SyntaxError, Object>] A stylesheet represented as MiniCSS
  #   AST nodes; syntax issues surface as {MiniCSS::AST::SyntaxError} entries.
  def parse(input, allow_unicode_ranges: false)
    toks = tokenize(input, allow_unicode_ranges:)
    pars = CSS::Parser.new(toks)
    sheet = pars.parse_stylesheet
    AST.convert(sheet)
  end

  # Serialize MiniCSS AST nodes back into CSS.
  #
  # @param ast [MiniCSS::AST::Rule, MiniCSS::AST::Decl, Array<Object>] Any AST
  #   node—or array of nodes—produced by {#parse} or the lower-level
  #   MiniCSS::AST conversion helpers.
  # @return [String] Normalized CSS suitable for writing back to disk or the
  #   network.
  def serialize(ast) = Serializer.serialize(ast)
end
