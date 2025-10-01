# frozen_string_literal: true

module MiniCSS
  module AST
    class SyntaxError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
      end
    end
  end
end
