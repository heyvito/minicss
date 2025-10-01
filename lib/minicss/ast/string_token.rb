# frozen_string_literal: true

module MiniCSS
  module AST
    class StringToken
      attr_accessor :value, :quoting

      def initialize(css)
        @value = css.literal
        @quoting = css.opts[:quoting]
      end
    end
  end
end
