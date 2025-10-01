# frozen_string_literal: true

module MiniCSS
  module AST
    class DeclList < Array
      def initialize(old = nil)
        super()
        if old.is_a? Array
          append(*old)
        elsif old
          append(old)
        end
      end
    end
  end
end

# Feci quod potui, faciant meliora potentes.
