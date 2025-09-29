# frozen_string_literal: true

require_relative "ast/rule"
require_relative "ast/decl"
require_relative "ast/at_rule"
require_relative "ast/function"
require_relative "ast/block"

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
      when CSS::AST::DeclarationList, Array
        css.map { convert(it) }
      when CSS::AST::Function
        Function.new(css)
      when CSS::Token
        css.literal
      when CSS::AST::SimpleBlock
        Block.new(css)
      else
        debugger
        raise "Unexpected input type #{css.class} for conversion"
      end
    end
  end
end
