# frozen_string_literal: true

module TinyCSS
  module AST
    class Block
      RIGHT_TOKENS = {
        left_parenthesis: ")",
        left_curly: "}",
        left_square_bracket: "]"
      }.freeze

      LEFT_TOKENS = {
        left_parenthesis: "(",
        left_curly: "{",
        left_square_bracket: "["
      }.freeze

      attr_accessor :associated_token, :value

      def initialize(css)
        @associated_token = css.associated_token
        @value = css.value.map { AST.convert(it) }
      end

      def right_token = RIGHT_TOKENS[@associated_token]
      def left_token = LEFT_TOKENS[@associated_token]
    end
  end
end
