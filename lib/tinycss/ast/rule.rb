# frozen_string_literal: true

module TinyCSS
  module AST
    class Rule
      attr_accessor :selector, :child_rules, :decls, :raw_selector

      def initialize(struct)
        raise "Expected CSS::AST::QualifiedRule, found #{struct.class}" unless struct.is_a? CSS::AST::QualifiedRule

        @raw_selector = struct.prelude.map(&:literal).join
        begin
          @selector = Sel.parse(raw_selector)
          @valid_selector = true
        rescue StandardError => e
          pos = struct.prelude.first.pos_start
          @selector = "Failed parsing selector at #{pos.line}:#{pos.column}: #{e}"
          @valid_selector = false
        end

        @child_rules = struct.child_rules.map { AST.convert(it) }
        @decls = struct.decls.map { AST.convert(it) }
      end

      def valid_selector? = @valid_selector
    end
  end
end
