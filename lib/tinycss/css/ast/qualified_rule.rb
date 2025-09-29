# frozen_string_literal: true

module TinyCSS
  module CSS
    module AST
      class QualifiedRule
        attr_accessor :prelude, :decls, :child_rules

        def initialize(prelude: nil, decls: nil, child_rules: nil)
          @prelude = prelude || []
          @decls = decls || []
          @child_rules = child_rules || []
        end

        def kind = :qualified_rule
      end
    end
  end
end
