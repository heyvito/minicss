# frozen_string_literal: true

module TinyCSS
  module AST
    class UnicodeRange
      attr_accessor :range_start, :range_end

      def initialize(css)
        @range_start, @range_end = css.opts.slice(:start, :end).values
      end
    end
  end
end
