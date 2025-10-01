# frozen_string_literal: true

module MiniCSS
  module AST
    class Number
      attr_accessor :raw, :value, :type, :sign

      def initialize(css)
        @raw = css.literal
        @value, @type, @sign = css.opts.slice(:value, :type, :sign_character).values
      end
    end
  end
end
