# frozen_string_literal: true

module TinyCSS
  module AST
    class BadToken
      attr_accessor :kind, :value

      def initialize(css)
        @kind = css.kind
        @value = css.literal
      end
    end
  end
end
