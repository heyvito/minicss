# frozen_string_literal: true

module TinyCSS
  module CSS
    module AST
      class SimpleBlock
        attr_accessor :associated_token, :value

        def initialize(associated_token:)
          @associated_token = associated_token
          @value = []
        end

        def kind = :simple_block

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

        def literal
          [left_token, @value.map(&:literal), right_token].join
        end
      end
    end
  end
end
