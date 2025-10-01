# frozen_string_literal: true

module MiniCSS
  module CSS
    class Position
      attr_reader :offset, :line, :column

      def initialize(offset, line, column)
        @offset = offset
        @line = line
        @column = column
      end
    end
  end
end
