# frozen_string_literal: true

require_relative "tinycss/version"
require_relative "tinycss/errors"
require_relative "tinycss/css"
require_relative "tinycss/sel"
require_relative "tinycss/ast"
require_relative "tinycss/serializer"

module TinyCSS
  module_function

  def tokenize(input, allow_unicode_ranges: false)
    tok = CSS::Tokenizer.new(input,allow_unicode_ranges:)
    tok.tokenize
    tok.tokens
  end

  def parse(input, allow_unicode_ranges: false)
    toks = tokenize(input, allow_unicode_ranges:)
    pars = CSS::Parser.new(toks)
    sheet = pars.parse_stylesheet
    AST.convert(sheet)
  end

  def serialize(ast)
    Serializer.serialize(ast)
  end
end
