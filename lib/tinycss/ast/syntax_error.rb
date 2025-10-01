# frozen_string_literal: true

module TinyCSS
  module AST
    class SyntaxError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
      end
    end
  end
end
