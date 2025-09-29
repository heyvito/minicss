# frozen_string_literal: true

module TinyCSS
  module CSS
    class Token
      attr_reader :kind, :pos_start, :pos_end, :opts
      attr_writer :literal

      def initialize(kind, pos_start, pos_end, **opts)
        @kind = kind
        @pos_start = pos_start
        @pos_end = pos_end
        @opts = opts.empty? ? nil : opts
      end

      def literal
        return " " if kind == :whitespace

        @literal
      end

      def eof? = @kind == :eof

      EOF = Token.new(:eof, nil, nil)
    end
  end
end
