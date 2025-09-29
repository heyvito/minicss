# frozen_string_literal: true

module TinyCSS
  module CSS
    module AST
      class DeclarationList < Array
        def kind = :declaration_list
      end
    end
  end
end
