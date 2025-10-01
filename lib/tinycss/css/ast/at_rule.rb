# frozen_string_literal: true

module TinyCSS
  module CSS
    module AST
      class AtRule
        attr_accessor :name, :prelude, :child_rules

        def initialize(name:, prelude: nil, child_rules: nil)
          @name = name
          @prelude = prelude || []
          @child_rules = child_rules || []
        end

        def kind = :at_rule
      end
    end
  end
end
