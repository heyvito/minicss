# frozen_string_literal: true

module MiniCSS
  module CSS
    class TokenStream
      using StringRefinements

      def initialize(tokens)
        @tokens = tokens
        @idx = 0
        @marks = []
        @peek = tokens[0] || Token::EOF
        @peek1 = tokens[1] || Token::EOF
      end

      attr_reader :peek, :peek1

      def empty? = peek.eof?

      def consume
        v = @peek
        @idx += 1
        @peek = @peek1
        @peek1 = @tokens[@idx + 1] || Token::EOF
        v
      end

      def discard
        unless empty?
          @idx += 1
          @peek = @peek1
          @peek1 = @tokens[@idx + 1] || Token::EOF
        end
        nil
      end

      def mark
        @marks << @idx
      end

      def restore
        @idx = pop
        @peek = @tokens[@idx] || Token::EOF
        @peek1 = @tokens[@idx + 1] || Token::EOF
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
