# frozen_string_literal: true

module TinyCSS
  module CSS
    module AST
      class Declaration
        attr_accessor :name, :value, :important, :original_text

        def initialize(name: "", value: nil)
          @value = value || []
          @name = name
          @important = false
          @original_text = nil
        end

        def important? = @important
        def kind = :declaration
      end
    end
  end
end
