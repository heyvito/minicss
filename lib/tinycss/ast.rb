# frozen_string_literal: true

require_relative "ast/rule"
require_relative "ast/decl"
require_relative "ast/decl_list"
require_relative "ast/at_rule"
require_relative "ast/function"
require_relative "ast/block"
require_relative "ast/number"
require_relative "ast/dimension"
require_relative "ast/percentage"
require_relative "ast/bad_token"
require_relative "ast/url"
require_relative "ast/unicode_range"
require_relative "ast/syntax_error"
require_relative "ast/string_token"

module TinyCSS
  module AST
    module_function

    def convert(css)
      case css
      when CSS::AST::Stylesheet
        css.rules.map { convert(it) }
      when CSS::AST::QualifiedRule
        Rule.new(css)
      when CSS::AST::Declaration
        Decl.new(css)
      when CSS::AST::AtRule
        AtRule.new(css)
      when CSS::AST::DeclarationList
        DeclList.new(css.map { convert(it) })
      when Array
        css.map { convert(it) }
      when CSS::AST::Function
        Function.new(css)
      when CSS::Token
        convert_token(css)
      when CSS::AST::SimpleBlock
        Block.new(css)
      when CSS::SyntaxError
        SyntaxError.new(css.message)
      else
        raise "Unexpected input type #{css.class} for conversion"
      end
    end

    def convert_token(css)
      case css.kind
      when :delim, :ident, :whitespace, :cdc, :at_keyword, :hash, :cdo, :colon, :comma, :semicolon, :right_square_bracket, :right_parenthesis
        css.literal
      when :dimension
        Dimension.new(css)
      when :number
        Number.new(css)
      when :percentage
        Percentage.new(css)
      when :bad_string, :bad_url
        BadToken.new(css)
      when :url
        URL.new(css.opts[:value])
      when :unicode_range
        UnicodeRange.new(css)
      when :string
        StringToken.new(css)
      else
        raise "Unexpected token in conversion pipeline: #{css.class} #{css.inspect}"
      end
    end
  end
end
