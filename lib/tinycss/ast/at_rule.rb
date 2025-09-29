# frozen_string_literal: true

module TinyCSS
  module AST
    class AtRule
      attr_accessor :name, :prelude, :child_rules

      def initialize(rule)
        @name = rule.name.literal.gsub(/^@/, "")
        @prelude = rule.prelude.map(&:literal)
        @prelude.pop while @prelude.last&.strip&.empty?
        @prelude.shift while @prelude.first&.strip&.empty?
        @prelude = @prelude.join
        @child_rules = rule.child_rules.map { AST.convert it }
      end
    end
  end
end
