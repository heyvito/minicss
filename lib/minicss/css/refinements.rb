# frozen_string_literal: true

module MiniCSS
  module CSS
    module StringRefinements
      refine String do
        def eof? = false
        def digit? = between?("0", "9")
        def hex? = digit? || between?("a", "f") || between?("A", "F")
        def uppercase? = between?("A", "Z")
        def lowercase? = between?("a", "z")
        def letter? = uppercase? || lowercase?
        def one_of?(*what) = what.include?(self)

        def non_ascii_ident?
          self == "\u00B7" \
          || between?("\u00C0", "\u00D6") \
          || between?("\u00D8", "\u00F6") \
          || between?("\u00F8", "\u037D") \
          || between?("\u037F", "\u1FFF") \
          || self == "\u200C" \
          || self == "\u200D" \
          || self == "\u203F" \
          || self == "\u2040" \
          || between?("\u2070", "\u218F") \
          || between?("\u2C00", "\u2FEF") \
          || between?("\u3001", "\uD7FF") \
          || between?("\uF900", "\uFDCF") \
          || between?("\uFDF0", "\uFFFD") \
          || self >= "\u{10000}"
        end

        def uni = unpack1("U")
        def ident_start? = letter? || uni >= 0x80 || self == "_"
        def ident_point? = ident_start? || digit? || uni == 0x2D

        def non_printable?
          between?("\u0000", "\u0008") \
          || self == "\u000B" \
          || between?("\u000B", "\u001F") \
          || self == "\u007F"
        end

        def newline? = (self == "\n")
        def whitespace? = newline? || self == "\u0009" || self == "\u0020"
      end

      refine Integer do
        def surrogate_leading? = between?(0xD800, 0xDBFF)
        def surrogate_trailing? = between?(0xDC00, 0xDFFF)

        def surrogate? = surrogate_leading? || surrogate_trailing?
        def overflows_maximum_codepoint? = self > 0x10FFFF
      end
    end

    class EOF
      def self.instance
        @instance ||= new
      end

      def eof? = true
      def digit? = false
      def hex? = false
      def uppercase? = false
      def lowercase? = false
      def letter? = false
      def one_of?(*) = false
      def non_ascii_ident? = false
      def uni = 0
      def ident_start? = false
      def ident_point? = false
      def non_printable? = false
      def newline? = false
      def whitespace? = false
    end
  end
end
