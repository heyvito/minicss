# frozen_string_literal: true

module MiniCSS
  module CSS
    module AST
      class DeclarationList < Array
        def kind = :declaration_list
      end
    end
  end
end
