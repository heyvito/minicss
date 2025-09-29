# frozen_string_literal: true

module TinyCSS
  module CSS
    module AST
      class Function
        attr_accessor :name, :value

        def initialize(name: "", value: nil)
          @value = value || []
          @name = name
        end

        def kind = :function

        def literal = [name.literal, value.map(&:literal)].join
      end
    end
  end
end
