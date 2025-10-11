# frozen_string_literal: true

require_relative "../../minicss_scanner"

module MiniCSS
  module CSS
    class Tokenizer
      def initialize(input, allow_unicode_ranges: false)
        str = (input.is_a?(IO) ? input.read : input.to_s)
              .encode("UTF-8", invalid: :replace, undef: :replace, replace: "\uFFFD")
              .gsub("\r\n", "\n")
              .tr("\u000C", "\n")
              .tr("\u0000", "\uFFFD")
        @source_str = str
        @scanner = MiniCSS::CSS::Scanner.new(self, str, allow_unicode_ranges)
      end

      def tokens = @scanner.tokens

      def hydrate_tokens
        @scanner.tokens.each do |tok|
          tok.literal ||= @source_str[tok.pos_start.offset...tok.pos_end.offset]
        end
      end

      def tokenize
        @scanner.consume_token until @scanner.eof?
        hydrate_tokens
        nil
      end
    end
  end
end
