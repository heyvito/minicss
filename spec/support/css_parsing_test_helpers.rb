require_relative "ast_matcher"

module CSSParsingTestHelpers
  def match_ast(ast, &block)
    matcher = ASTMatcher.new(ast)
    matcher.instance_exec(&block)
  end
end
