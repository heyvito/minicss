# frozen_string_literal: true

module TinyCSS
  module AST
    class Block
      attr_accessor :associated_token, :value
      def initialize(css)
        @associated_token = css.associated_token
        @value = css.value.map { AST.convert(it) }
      end

      def right_token
        case associated_token
        when :left_parenthesis then ")"
        when :left_curly then "}"
        when :left_square_bracket then "]"
        end
      end

      def left_token
        case associated_token
        when :left_parenthesis then "("
        when :left_curly then "{"
        when :left_square_bracket then "["
        end
      end
    end
  end
end
