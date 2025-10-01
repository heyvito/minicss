# frozen_string_literal: true

module MiniCSS
  module AST
    class Dimension < Number
      attr_accessor :unit

      def initialize(css)
        super
        @unit = css.opts[:unit]
      end
    end
  end
end
