# frozen_string_literal: true

module TinyCSS
  module AST
    class Decl
      attr_accessor :name, :value, :important

      def initialize(decl)
        @name = decl.name.literal
        @value = decl.value.map { AST.convert(it) }
        @important = decl.important
      end

      def important? = important
    end
  end
end
