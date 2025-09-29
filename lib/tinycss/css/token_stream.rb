# frozen_string_literal: true

module TinyCSS
  module CSS
    class TokenStream
      using StringRefinements

      def initialize(tokens)
        @tokens = tokens
        @idx = 0
        @marks = []
      end

      def peek
        token = @tokens[@idx]
        return Token::EOF unless token

        token
      end

      def peek1
        token = @tokens[@idx + 1]
        return Token::EOF unless token

        token
      end

      def empty? = peek.eof?

      def consume
        peek.tap { @idx += 1 }
      end

      def discard
        @idx += 1 unless empty?
        nil
      end

      def mark
        @marks << @idx
      end

      def restore
        @idx = pop
      end

      def pop
        @marks.pop
      end

      def discard_whitespace
        discard while peek.kind == :whitespace
      end
    end
  end
end
