# frozen_string_literal: true

module TinyCSS
  module AST
    class Dimension < Number
      attr_accessor :unit

      def initialize(css)
        super(css)
        @unit = css.opts[:unit]
      end
    end
  end
end
