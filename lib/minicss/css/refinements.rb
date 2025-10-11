# frozen_string_literal: true

module MiniCSS
  module CSS
    module StringRefinements
      refine Integer do
        # EOF sentinel check
        def eof? = (self == -1)

        # ASCII digit / hex
        def digit?     = (0x30..0x39).cover?(self)
        def hex?       = digit? || (0x61..0x66).cover?(self) || (0x41..0x46).cover?(self)
        def uppercase? = (0x41..0x5A).cover?(self)
        def lowercase? = (0x61..0x7A).cover?(self)
        def letter?    = uppercase? || lowercase?
        def one_of?(*what) = what.include?(self)

        # Ident start/point rules
        def ident_start? = letter? || self >= 0x80 || self == 0x5F
        def ident_point? = ident_start? || digit? || self == 0x2D

        # Non-printable checks
        def non_printable?
          (0x0000..0x0008).cover?(self) ||
            self == 0x000B ||
            (0x000C..0x001F).cover?(self) ||
            self == 0x007F
        end

        # Whitespace / newline
        def newline?    = (self == 0x0A)
        def whitespace? = newline? || self == 0x09 || self == 0x20
      end
    end
  end
end
