# frozen_string_literal: true

module MiniCSS
  module AST
    class AtRule
      attr_accessor :name, :prelude, :child_rules

      def initialize(rule)
        @name = rule.name.literal.gsub(/^@/, "")
        @prelude = rule.prelude.map { AST.convert(it) }
        @prelude.pop while @prelude.last == " "
        @prelude.shift while @prelude.first == " "
        @child_rules = rule.child_rules.map { AST.convert it }
      end
    end
  end
end
