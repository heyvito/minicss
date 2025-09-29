# frozen_string_literal: true

module TinyCSS
  module CSS
    module AST
      class Stylesheet
        attr_accessor :rules

        def initialize(rules: nil)
          @rules = rules || []
        end

        def kind = :stylesheet
      end
    end
  end
end
