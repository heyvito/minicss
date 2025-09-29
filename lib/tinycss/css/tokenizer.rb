# frozen_string_literal: true

module TinyCSS
  module CSS
    class Tokenizer
      CARRIAGE_RETURN = "\u000D"
      FORM_FEED = "\u000C"
      LINE_FEED = "\u000A"
      NULL = "\u0000"
      REPLACEMENT_CHARACTER = "\uFFFD"
      MAXIMUM_ALLOWED_CODEPOINT = "\u{10FFFF}"
      SOLIDUS = "\u002F"
      ASTERISK = "\u002A"
      QUOTATION_MARK = "\u0022"
      NUMBER_SIGN = "\u0023"
      APOSTROPHE = "\u0027"
      LEFT_PARENTHESIS = "\u0028"
      RIGHT_PARENTHESIS = "\u0029"
      PLUS_SIGN = "\u002B"
      COMMA = "\u002C"
      HYPHEN_MINUS = "\u002D"
      FULL_STOP = "\u002E"
      COLON = "\u003A"
      SEMICOLON = "\u003B"
      LESS_THAN = "\u003C"
      COMMERCIAL_AT = "\u0040"
      LEFT_SQUARE_BRACKET = "\u005B"
      REVERSE_SOLIDUS = "\u005C"
      RIGHT_SQUARE_BRACKET = "\u005D"
      LEFT_CURLY = "\u007B"
      RIGHT_CURLY = "\u007D"
      PERCENTAGE_SIGN = "\u0025"
      GREATER_THAN = "\u003E"
      QUESTION_MARK = "\u003F"

      attr_reader :unicode_ranges_allowed, :tokens
      alias unicode_ranges_allowed? unicode_ranges_allowed

      using StringRefinements

      def initialize(input, allow_unicode_ranges: false)
        @input = (input.is_a?(IO) ? input.read : input.to_s)
                 .encode("UTF-8", invalid: :replace, undef: :replace, replace: "\uFFFD")
                 .gsub("\r\n", "\n")
                 .gsub("\u000C", "\n")
                 .gsub("\u0000", "\uFFFD")
                 .chars
        @len = @input.length
        @unicode_ranges_allowed = allow_unicode_ranges
        @line = 1
        @column = 1
        @idx = 0
        @tokens = []
      end

      def eof? = @idx >= @len
      def peek = (eof? ? EOF.instance : @input[@idx])
      def peek1 = (@idx + 1 >= @len ? EOF.instance : @input[@idx + 1])
      def last = @input[@idx - 1]
      def consumed_len = @idx - @token_start[:offset]

      def consume
        peek.tap do |v|
          next if eof?

          @idx += 1
          if v.newline?
            @line += 1
            @column = 1
          else
            @column += 1
          end
        end
      end

      def start_token!
        @token_start = pos
      end

      def pos = { offset: @idx, line: @line, column: @column }

      # push_token pushes a token to the token list.
      def push_token(type, **)
        pos_start = Position.new(*@token_start.values)
        pos_end = Position.new(*pos.values)

        @tokens << Token.new(type, pos_start, pos_end, **)
      end

      def valid_escape?(value = nil)
        p1, p2 = value || [peek, peek1]
        p1 == REVERSE_SOLIDUS && !p2&.newline?
      end

      def consume_escaped_code_point
        p = peek
        result = []
        return REPLACEMENT_CHARACTER if p.eof?
        return consume unless p.hex?

        max = 6
        while peek.hex? && max.positive?
          result << consume
          max -= 1
        end
        consume if peek.whitespace?
        val = result.join.hex
        return REPLACEMENT_CHARACTER if val.zero? || val.surrogate? || val.overflows_maximum_codepoint?

        [val].pack("U")
      end

      def ident_sequence_start?
        val = @input[@idx...(@idx + 3)]
        if val[0] == HYPHEN_MINUS
          (val[1]&.ident_start? || val[1] == HYPHEN_MINUS) || valid_escape?(val[1...])
        elsif val[0]&.ident_start?
          true
        elsif val[0] == REVERSE_SOLIDUS
          valid_escape?(val)
        else
          false
        end
      end

      def consume_ident_sequence
        result = []
        until eof?
          if peek.ident_point?
            result << consume
          elsif valid_escape?
            consume
            result << consume_escaped_code_point
          else
            break
          end
        end

        result.join
      end

      def unicode_range_start?
        chars = @input[@idx...(@idx + 3)]

        (chars[0]&.downcase == "u" &&
          chars[1] == PLUS_SIGN &&
          chars[2] == QUESTION_MARK) || chars[2]&.hex?
      end

      def hydrate_tokens
        @tokens.each do |tok|
          tok.literal = @input[tok.pos_start.offset...tok.pos_end.offset].join
        end
      end

      # ------- Parser starts here.

      def tokenize
        consume_token until eof?
        hydrate_tokens
        nil
      end

      def consume_token
        consume_comments
        consume_whitespace
        case peek
        when QUOTATION_MARK
          consume_string_token

        when NUMBER_SIGN
          start_token!
          if !peek1.ident_point? && !valid_escape?
            consume
            push_token(:delim)
            return
          end

          consume
          flag = ident_sequence_start? ? :id : :unrestricted
          value = consume_ident_sequence
          push_token(:hash, value:, flag:)

        when APOSTROPHE
          consume_string_token

        when LEFT_PARENTHESIS
          start_token!
          consume
          push_token(:left_parenthesis)

        when RIGHT_PARENTHESIS
          start_token!
          consume
          push_token(:right_parenthesis)

        when PLUS_SIGN
          if peek1.digit?
            consume_numeric_token
          else
            start_token!
            consume
            push_token(:delim)
          end

        when COMMA
          start_token!
          consume
          push_token(:comma)

        when HYPHEN_MINUS
          if peek1.digit?
            consume_numeric_token
            return
          end

          nexts = @input[@idx...(@idx + 3)]
          if nexts[1] == HYPHEN_MINUS && nexts[2] == GREATER_THAN
            start_token!
            3.times { consume }
            push_token(:cdc)
            return
          end

          if ident_sequence_start?
            consume_ident_like_token
            return
          end

          start_token!
          consume
          push_token(:delim)

        when FULL_STOP
          return consume_numeric_token if peek1.digit?

          start_token!
          consume
          push_token(:delim)

        when COLON
          start_token!
          consume
          push_token(:colon)

        when SEMICOLON
          start_token!
          consume
          push_token(:semicolon)

        when LESS_THAN
          start_token!
          if @input[@idx...(@idx + 4)].join == "<!--"
            4.times { consume }
            push_token(:cdo)
            return
          end

          consume
          push_token(:delim)

        when COMMERCIAL_AT
          start_token!
          consume

          if ident_sequence_start?
            consume_ident_sequence
            push_token(:at_keyword)
            return
          end

          push_token(:delim)

        when LEFT_SQUARE_BRACKET
          start_token!
          consume
          push_token(:left_square_bracket)

        when REVERSE_SOLIDUS
          return consume_ident_like_token if valid_escape?

          start_token!
          consume
          push_token(:delim)

        when RIGHT_SQUARE_BRACKET
          start_token!
          consume
          push_token(:right_square_bracket)

        when LEFT_CURLY
          start_token!
          consume
          push_token(:left_curly)

        when RIGHT_CURLY
          start_token!
          consume
          push_token(:right_curly)

        when "u", "U"
          return consume_unicode_range if unicode_ranges_allowed? && unicode_range_start?

          consume_ident_like_token

        else
          return if peek.eof?
          return consume_whitespace if peek.whitespace?
          return consume_numeric_token if peek.digit?
          return consume_ident_like_token if peek.ident_start?

          start_token!
          consume
          push_token(:delim)
        end
      end

      def consume_unicode_range
        2.times { consume }
        tmp = []
        tmp << consume while peek.hex? && tmp.length <= 6
        tmp << consume while peek == QUESTION_MARK && tmp.length <= 6
        end_range = 0

        if tmp.include? QUESTION_MARK
          start_range = tmp.map { it == QUESTION_MARK ? "0" : it }.join.hex
          end_range = tmp.map { it == QUESTION_MARK ? "F" : it }.join.hex
          return push_token(:unicode_range, start: start_range, end: end_range)
        end

        start_range = tmp.join.hex
        if peek == HYPHEN_MINUS && peek1.hex?
          tmp.clear
          tmp << consume while peek.hex? && tmp.length <= 6
          end_range = tmp.join.hex
        else
          end_range = start_range
        end

        push_token(:unicode_range, start: start_range, end: end_range)
      end

      # consume_comments consumes all comments until either something that's not
      # a comment is found, or the input stream ends.
      def consume_comments
        loop do
          return unless peek == SOLIDUS && peek1 == ASTERISK

          2.times { consume }

          until peek == ASTERISK && peek1 == SOLIDUS
            return if peek.eof?

            consume
          end

          2.times { consume }
        end
      end

      # consume_whitespace consumes all possible whitespaces
      def consume_whitespace
        saw_whitespace = false

        loop do
          # comments should be treated like whitespace
          if peek == SOLIDUS && peek1 == ASTERISK
            start_token! unless saw_whitespace
            saw_whitespace = true
            consume_comments
            next
          end

          break unless peek.whitespace?

          start_token! unless saw_whitespace
          saw_whitespace = true
          consume
        end

        push_token(:whitespace) if saw_whitespace
      end

      # consume_string_token consumes a given string token until its closing token
      # is encountered, or EOF is reached
      def consume_string_token(closing_token = nil)
        closing_token ||= consume
        start_token!

        until eof?
          char = peek
          case char
          when closing_token
            break
          when REVERSE_SOLIDUS
            p1 = peek1
            if p1.eof?
              consume # Consume REVERSE_SOLIDUS
              next
            elsif p1.newline?
              2.times { consume } # Consume REVERSE_SOLIDUS + NEWLINE
            elsif valid_escape?
              consume # consume REVERSE_SOLIDUS
              consume_escaped_code_point
            end
          else
            if char.newline?
              push_token(:bad_string)
              return
            end

            consume
          end
        end

        push_token(:string)
        consume unless eof? # Consume closing_token
      end

      def consume_numeric_token
        start_token!
        number = consume_number

        if ident_sequence_start?
          unit = consume_ident_sequence
          push_token(:dimension, unit:, **number)
        elsif peek == PERCENTAGE_SIGN
          consume # Consume PERCENTAGE_SIGN
          push_token(:percentage, **number)
        else
          push_token(:number, **number)
        end
      end

      def consume_number
        type = :integer
        number_part = []
        exponent_part = []
        sign_character = nil

        if [PLUS_SIGN, HYPHEN_MINUS].include?(peek)
          sign_character = consume
          number_part << sign_character
        end

        number_part << consume while peek.digit?

        if peek == FULL_STOP && peek1.digit?
          number_part << consume
          number_part << consume if peek.digit?
          type = :number
        end

        nexts = @input[@idx..(@idx + 3)]
        if nexts[0]&.downcase == "e" &&
            (([HYPHEN_MINUS, PLUS_SIGN].include?(nexts[1]) && nexts[2]&.digit?) \
              || nexts[1]&.digit?)
          consume # consume E or e
          exponent_part << consume if [HYPHEN_MINUS, PLUS_SIGN].include? peek
          exponent_part << consume while peek.digit?
          type = :number
        end

        value = number_part.join.to_i(10)

        unless exponent_part.empty?
          exponent = 10 ** exponent_part.join.to_i(10)
          value *= exponent
        end

        { value:, type:, sign_character: }
      end

      def consume_ident_like_token
        start_token!
        str = consume_ident_sequence
        if str.downcase == "url" && peek == LEFT_PARENTHESIS
          consume # consume LEFT_PARENTHESIS
          consume while peek.whitespace? && peek1.whitespace?
          if peek.one_of?(QUOTATION_MARK, APOSTROPHE) || (peek.whitespace? && peek1.one_of?(QUOTATION_MARK, APOSTROPHE))
            push_token(:function, value: str)
            return
          end

          return consume_url_token
        end

        if peek == LEFT_PARENTHESIS
          consume
          push_token(:function, value: str)
          return
        end

        push_token(:ident, value: str)
      end

      def consume_url_token
        data = []
        consume while peek.whitespace?

        loop do
          p = peek
          if p == RIGHT_PARENTHESIS
            consume
            push_token(:url, value: data.join)
            return
          end

          return push_token(:url, value: data.join) if p.eof?

          if p.whitespace?
            consume while peek.whitespace?
            if peek == RIGHT_PARENTHESIS
              consume
              return push_token(:url, value: data.join)
            elsif eof?
              return push_token(:url, value: data.join)
            else
              consume_bad_url
              return push_token(:bad_url)
            end
          end

          if p.one_of?(QUOTATION_MARK, APOSTROPHE, LEFT_PARENTHESIS) || p.non_printable?
            consume_bad_url
            return push_token(:bad_url)
          end

          if p == REVERSE_SOLIDUS
            if valid_escape?
              consume
              data << consume_escaped_code_point
              next
            else
              consume_bad_url
              return push_token(:bad_url)
            end
          end

          data << consume
        end
      end

      def consume_bad_url
        until eof?
          if peek == RIGHT_PARENTHESIS
            consume
            return
          elsif valid_escape?
            consume
            consume_escaped_code_point
          else
            consume
          end
        end
      end
    end
  end
end
