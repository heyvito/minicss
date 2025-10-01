# frozen_string_literal: true

module MiniCSS
  module AST
    class Function
      attr_accessor :raw_name, :name, :value

      def initialize(func)
        @raw_name = func.name.literal
        @name = raw_name.strip.gsub(/\($/, "")
        @value = func.value.map { AST.convert(it) }
      end
    end
  end
end
