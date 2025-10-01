# frozen_string_literal: true

module MiniCSS
  module CSS
    module AST
      class SimpleBlock
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

        def initialize(associated_token:)
          @associated_token = associated_token
          @value = []
        end

        def kind = :simple_block

        def right_token = RIGHT_TOKENS[associated_token]
        def left_token = LEFT_TOKENS[associated_token]

        def literal
          [left_token, @value.map(&:literal), right_token].join
        end
      end
    end
  end
end
