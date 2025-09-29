# frozen_string_literal: true

module TinyCSS
  module AST
    class Block
      attr_accessor :associated_token, :value
      def initialize(css)
        @associated_token = css.associated_token
        @value = css.value
      end
    end
  end
end
