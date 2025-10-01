# frozen_string_literal: true

module TinyCSS
  module AST
    class URL
      attr_accessor :value

      def initialize(value)
        @value = value
      end
    end
  end
end
