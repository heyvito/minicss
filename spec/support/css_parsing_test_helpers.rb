# frozen_string_literal: true

require_relative "ast_matcher"

module CSSParsingTestHelpers
  def match_ast(ast, &)
    matcher = ASTMatcher.new(ast)
    matcher.instance_exec(&)
  end
end
