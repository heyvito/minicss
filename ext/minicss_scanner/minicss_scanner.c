#include "ruby.h"
#include "ruby/encoding.h"
#include <stdint.h>
#include <string.h>

#include "minicss_scanner.h"

#include <ctype.h>
#include <stdlib.h>

static VALUE cPosition;
static VALUE cToken;


// ASCII helpers ---------------------------------------------------------------

/**
 * is_digit - Check if code point is an ASCII decimal digit.
 *
 * @cp: Unicode code point.
 *
 * Returns non-zero if @cp is '0'..'9' (U+0030–U+0039), else 0.
 */
static inline int is_digit(const int cp) { return cp >= 0x30 && cp <= 0x39; }

/**
 * is_hex - Check if code point is a valid ASCII hexadecimal digit.
 *
 * @cp: Unicode code point.
 *
 * Returns non-zero if @cp is '0'..'9', 'A'..'F', or 'a'..'f'.
 */
static inline int is_hex(const int cp) {
    return is_digit(cp)
           || (cp >= 0x41 && cp <= 0x46)
           || (cp >= 0x61 && cp <= 0x66);
}

/**
 * is_upper - Check if code point is an uppercase ASCII letter.
 *
 * @cp: Unicode code point.
 *
 * Returns non-zero if @cp is 'A'..'Z' (U+0041–U+005A).
 */
static inline int is_upper(const int cp) {
    return cp >= 0x41 && cp <= 0x5A;
}

/**
 * is_lower - Check if code point is a lowercase ASCII letter.
 *
 * @cp: Unicode code point.
 *
 * Returns non-zero if @cp is 'a'..'z' (U+0061–U+007A).
 */
static inline int is_lower(const int cp) {
    return cp >= 0x61 && cp <= 0x7A;
}

/**
 * is_letter - Check if code point is an ASCII letter.
 *
 * @cp: Unicode code point.
 *
 * Returns non-zero if @cp is 'A'..'Z' or 'a'..'z'.
 */
static inline int is_letter(const int cp) {
    return is_upper(cp) || is_lower(cp);
}

/**
 * is_newline - Check if code point is a newline.
 *
 * @cp: Unicode code point.
 *
 * Returns non-zero if @cp equals NEWLINE (implementation-defined value).
 */
static inline int is_newline(const int cp) {
    return cp == NEWLINE;
}

/**
 * is_ws - Check if code point is a CSS whitespace character.
 *
 * @cp: Unicode code point.
 *
 * Returns non-zero if @cp is NEWLINE, horizontal tab (U+0009), or space (U+0020).
 */
static inline int is_ws(const int cp) {
    return cp == NEWLINE || cp == 0x09 || cp == 0x20;
}

/**
 * ident_start - Check if code point can start a CSS identifier.
 *
 * @cp: Unicode code point.
 *
 * Returns non-zero if @cp is an ASCII letter, underscore ('_'),
 * non-ASCII character (>= U+0080), or both.
 */
static inline bool ident_start(const int cp) {
    return is_letter(cp) || cp >= 0x80 || cp == 0x5F;
}

/**
 * ident_point - Check if code point can appear in a CSS identifier after the first character.
 *
 * @cp: Unicode code point.
 *
 * Returns non-zero if @cp is a valid ident_start, an ASCII digit ('0'..'9'),
 * or a hyphen-minus ('-').
 */
static inline int ident_point(const int cp) {
    return ident_start(cp) || is_digit(cp) || cp == 0x2D;
}

/**
 * next_utf8_cp - Decode the next UTF-8 code point from a byte stream.
 *
 * @p:   Pointer to a pointer to the current byte. This pointer will be
 *       advanced past the consumed sequence on success or error.
 * @end: Pointer to one past the last valid byte in the buffer.
 *
 * Returns:
 *   - A valid Unicode code point (U+0000..U+10FFFF) if decoding succeeds.
 *   - 0xFFFD (replacement character) if the sequence is malformed
 *     (invalid continuation, overlong encoding, surrogate, or out-of-range).
 *   - EOF_CP if @p has reached or passed @end (no more input).
 *
 * Behavior:
 *   - Handles 1–4 byte UTF-8 sequences.
 *   - Performs boundary checks to avoid reading past @end.
 *   - Rejects overlong encodings and surrogate code points (U+D800..U+DFFF).
 *   - Does not allocate memory; operates directly on caller-provided buffer.
 *
 * Example:
 *   const uint8_t *ptr = buf, *end = buf + len;
 *   int cp;
 *   while ((cp = next_utf8_cp(&ptr, end)) != EOF_CP) {
 *       if (cp == 0xFFFD) { handle invalid sequence }
 *       else { process code point }
 *   }
 */
static inline int next_utf8_cp(const uint8_t **p, const uint8_t *end) {
    if (*p >= end) return EOF_CP;

    const uint8_t b0 = **p;
    (*p)++;

    if (b0 < 0x80) return b0;

    if ((b0 & 0xE0) == 0xC0) {
        // 2 bytes
        if (*p >= end) return EOF_CP;

        const uint8_t b1 = **p;
        (*p)++;
        if ((b1 & 0xC0) != 0x80) return 0xFFFD;

        const int cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
        return cp < 0x80 ? 0xFFFD : cp;
    }

    if ((b0 & 0xF0) == 0xE0) {
        // 3 bytes
        if (*p + 1 >= end) return EOF_CP;

        const uint8_t b1 = **p;
        const uint8_t b2 = *(*p + 1);
        (*p) += 2;
        if ((b1 & 0xC0) != 0x80 || (b2 & 0xC0) != 0x80) return 0xFFFD;

        const int cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);

        // exclude surrogates
        if (cp >= 0xD800 && cp <= 0xDFFF) return 0xFFFD;

        return cp < 0x800 ? 0xFFFD : cp;
    }

    if ((b0 & 0xF8) == 0xF0) {
        // 4 bytes
        if (*p + 2 >= end) return EOF_CP;

        const uint8_t b1 = **p;
        const uint8_t b2 = *(*p + 1);
        const uint8_t b3 = *(*p + 2);
        (*p) += 3;

        if ((b1 & 0xC0) != 0x80 || (b2 & 0xC0) != 0x80 || (b3 & 0xC0) != 0x80) return 0xFFFD;

        const int cp = ((b0 & 0x07) << 18)
                       | ((b1 & 0x3F) << 12)
                       | ((b2 & 0x3F) << 6)
                       | (b3 & 0x3F);
        if (cp > 0x10FFFF) return 0xFFFD;

        return cp < 0x10000 ? 0xFFFD : cp;
    }

    return 0xFFFD; // invalid leading byte
}

static double u32_chars_to_double(const uint32_t *buf, const size_t len) {
    if (len == 0) return 0.0;

    // stack buffer for small numbers, fallback if huge
    char tmp_stack[64];
    char *tmp;
    if (len < sizeof(tmp_stack)) {
        tmp = tmp_stack;
    } else {
        tmp = ALLOC_N(char, len + 1);
    }

    size_t out_len = 0;

    for (size_t i = 0; i < len; i++) {
        uint32_t cp = buf[i];
        if ((cp >= '0' && cp <= '9') || cp == '+' || cp == '-' || cp == '.') {
            tmp[out_len++] = (char) cp;
        } else {
            break; // stop on first invalid character
        }
    }

    tmp[out_len] = '\0';

    // normalize "-.34" -> "-0.34"  and "+.34" -> "+0.34"
    if ((tmp[0] == '-' || tmp[0] == '+') && tmp[1] == '.') {
        // shift right to make room for '0'
        memmove(&tmp[2], &tmp[1], out_len - 1);
        tmp[1] = '0';
        out_len++;
        tmp[out_len] = '\0';
    }
    // also handle ".34" -> "0.34"
    else if (tmp[0] == '.') {
        memmove(&tmp[1], &tmp[0], out_len);
        tmp[0] = '0';
        out_len++;
        tmp[out_len] = '\0';
    }

    char *end_ptr;
    errno = 0;
    double val = strtod(tmp, &end_ptr);

    // Must consume entire string, otherwise reject
    if (end_ptr != tmp + out_len) {
        val = 0.0;
    }

    if (tmp != tmp_stack)
        xfree(tmp);
    return val;
}

/**
 * rb_str_cat_codepoint - Append a Unicode code point to a Ruby String.
 *
 * @str: Ruby String VALUE (must be mutable).
 * @cp:  Unicode code point to append (U+0000..U+10FFFF).
 *
 * Behavior:
 *   - Encodes @cp into its UTF-8 representation (1–4 bytes).
 *   - Writes the encoded bytes into a temporary buffer.
 *   - Calls rb_str_cat to append the buffer contents to @str.
 *
 * Encoding rules:
 *   - cp < 0x80       → 1 byte: 0xxxxxxx
 *   - cp < 0x800      → 2 bytes: 110xxxxx 10xxxxxx
 *   - cp < 0x10000    → 3 bytes: 1110xxxx 10xxxxxx 10xxxxxx
 *   - cp <= 0x10FFFF  → 4 bytes: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
 *
 * Notes:
 *   - Does not validate @cp for invalid ranges (e.g. UTF-16 surrogates).
 *     Caller must ensure only valid code points are passed.
 *   - Designed for efficiency inside the tokenizer and other code
 *     that needs to build Ruby strings from decoded code points.
 *
 * Example:
 *   VALUE out = rb_str_new("", 0);
 *   rb_str_cat_codepoint(out, 'A');       // appends "A"
 *   rb_str_cat_codepoint(out, 0x03C0);    // appends "π"
 */
static void rb_str_cat_codepoint(const VALUE str, const uint32_t cp) {
    char buf[4];
    int n = 0;

    if (cp < 0x80) {
        buf[0] = (char) cp;
        n = 1;
    } else if (cp < 0x800) {
        buf[0] = (char) (0xC0 | (cp >> 6));
        buf[1] = (char) (0x80 | (cp & 0x3F));
        n = 2;
    } else if (cp < 0x10000) {
        buf[0] = (char) (0xE0 | (cp >> 12));
        buf[1] = (char) (0x80 | ((cp >> 6) & 0x3F));
        buf[2] = (char) (0x80 | (cp & 0x3F));
        n = 3;
    } else {
        buf[0] = (char) (0xF0 | (cp >> 18));
        buf[1] = (char) (0x80 | ((cp >> 12) & 0x3F));
        buf[2] = (char) (0x80 | ((cp >> 6) & 0x3F));
        buf[3] = (char) (0x80 | (cp & 0x3F));
        n = 4;
    }
    rb_str_cat(str, buf, n);
}

#define APPEND_REPLACEMENT(str) rb_str_cat((str), "\xEF\xBF\xBD", 3)

// Scanner allocation, memory and gc stuff -------------------------------------

/**
 * scanner_free - Free a scanner_t.
 *
 * Called by Ruby’s GC when a Scanner object is collected.
 * Uses `xfree` to release the memory allocated for the scanner_t.
 */
static void scanner_free(void *ptr) {
    xfree(ptr);
}

/**
 * scanner_memsize - Report memory size of a scanner_t.
 *
 * Required by Ruby’s GC for accounting purposes.
 * Always returns sizeof(scanner_t).
 */
static size_t scanner_memsize(const void *ptr) {
    return sizeof(scanner_t);
}

static void scanner_mark(void *ptr) {
    scanner_t *sc = ptr;
    if (sc->owner) {
        rb_gc_mark(sc->owner);
    }
    if (sc->tokens) {
        rb_gc_mark(sc->tokens);
    }
}

/**
 * scanner_type - Data type definition for MiniCSS::CSS::Scanner.
 *
 * Provides Ruby with type information, free function, and
 * memory size function for scanner_t objects.
 *
 * RUBY_TYPED_FREE_IMMEDIATELY indicates the object can be
 * immediately freed without finalizer deferral.
 */
static const rb_data_type_t scanner_type = {
    "MiniCSS::CSS::Scanner",
    {scanner_mark, scanner_free, scanner_memsize,},
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

/**
 * scanner_alloc - Allocate and wrap a scanner_t.
 *
 * @klass: The Ruby class (MiniCSS::CSS::Scanner).
 *
 * Allocates a zero-initialized scanner_t and wraps it as a
 * Ruby object of type @klass. The object is associated with
 * `scanner_type` so Ruby’s GC can manage its lifetime.
 *
 * Returns a Ruby VALUE wrapping the scanner_t pointer.
 */
static VALUE scanner_alloc(const VALUE klass) {
    scanner_t *sc = ALLOC(scanner_t);
    memset(sc, 0, sizeof(scanner_t));
    return TypedData_Wrap_Struct(klass, &scanner_type, sc);
}

/**
 * scanner_initialize - Ruby constructor for MiniCSS::CSS::Scanner
 *
 * Ruby signature:
 *   Scanner#initialize(str)
 *
 * @self: The Ruby scanner object being initialized.
 * @str:  A Ruby String containing UTF-8 CSS source text.
 *
 * Behavior:
 *   - Validates that @str is a Ruby String (raises TypeError otherwise).
 *   - Duplicates @str to ensure scanner owns a stable buffer.
 *   - Initializes scanner_t fields:
 *       * str   = duplicated Ruby String (kept alive by GC)
 *       * p     = pointer to start of string bytes
 *       * end   = pointer to one past last byte
 *       * idx_cp = 0 (start of code point stream)
 *       * line   = 1 (1-based for error reporting)
 *       * col    = 1 (1-based for error reporting)
 *   - Primes the lookahead buffer (look[0..3]) by decoding
 *     the first four UTF-8 code points from the string.
 *
 * Returns:
 *   The initialized Ruby object (self).
 *
 * Notes:
 *   - After initialization, the scanner is ready to be used
 *     by tokenizer methods, with look[0] representing the next
 *     code point to consume.
 *   - The lookahead mechanism allows token classification
 *     without repeatedly decoding UTF-8.
 */
static VALUE scanner_initialize(const VALUE self, VALUE str, VALUE allow_unicode_ranges) {
    Check_Type(str, T_STRING);
    scanner_t *sc;
    TypedData_Get_Struct(self, scanner_t, &scanner_type, sc);

    str = rb_str_dup(str);
    sc->str = str;
    sc->p = (const uint8_t *) RSTRING_PTR(str);
    sc->end = sc->p + RSTRING_LEN(str);
    sc->idx_cp = 0;
    sc->line = 1;
    sc->col = 1;
    sc->allow_unicode_ranges = RTEST(allow_unicode_ranges);
    sc->tokens = rb_ary_new();

    // prime lookahead
    sc->look[0] = next_utf8_cp(&sc->p, sc->end);
    sc->look[1] = next_utf8_cp(&sc->p, sc->end);
    sc->look[2] = next_utf8_cp(&sc->p, sc->end);
    sc->look[3] = next_utf8_cp(&sc->p, sc->end);

    return self;
}

// -----------------------------------------------------------------------------

/**
 * rotate - Advance lookahead buffer after consuming one code point.
 *
 * @sc: Scanner state.
 *
 * Shifts the lookahead window left by one:
 *   - look[0] takes the value of look[1]
 *   - look[1] takes the value of look[2]
 *   - look[2] takes the value of look[3]
 *   - look[3] is filled with the next UTF-8 code point from the input
 *
 * Effectively, this "consumes" look[0] and refreshes the buffer so
 * future peeks remain valid without re-decoding the input stream.
 *
 * Typical usage:
 *   - Called after a token consumes the current code point.
 *   - Keeps `look[]` in sync with `sc->p` as the scanner progresses.
 */
static inline void rotate(scanner_t *sc) {
    sc->look[0] = sc->look[1];
    sc->look[1] = sc->look[2];
    sc->look[2] = sc->look[3];
    sc->look[3] = next_utf8_cp(&sc->p, sc->end);
}

static VALUE scanner_start_token(scanner_t *sc) {
    sc->start_token_offset = sc->idx_cp;
    sc->start_token_line = sc->line;
    sc->start_token_column = sc->col;
    return Qnil;
}

static void scanner_consume(scanner_t *sc) {
    const int v = sc->look[0];
    if (v == EOF_CP) return;

    sc->idx_cp += 1;
    if (v == NEWLINE) {
        sc->line += 1;
        sc->col = 1;
    } else {
        sc->col += 1;
    }

    rotate(sc);
}

// -----------------------------------------------------------------------------

static uint32_t decode_escape(scanner_t *sc) {
    const int p0 = sc->look[0];
    if (p0 == EOF_CP) return 0xFFFD;

    if (is_hex(p0)) {
        int max = 6;
        uint32_t val = 0;
        int consumed = 0;
        while (is_hex(sc->look[0]) && max-- > 0) {
            const int h = sc->look[0];
            scanner_consume(sc);
            consumed = 1;

            if (h >= '0' && h <= '9') {
                val = (val << 4) | (h - '0');
            } else if (h >= 'A' && h <= 'F') {
                val = (val << 4) | (h - 'A' + 10);
            } else if (h >= 'a' && h <= 'f') {
                val = (val << 4) | (h - 'a' + 10);
            }
        }

        if (is_ws(sc->look[0])) scanner_consume(sc);

        if (!consumed
            || val == 0
            || val > 0x10FFFF
            || (val >= 0xD800 && val <= 0xDFFF)) {
            return 0xFFFD;
        }

        return val;
    }

    if (!is_newline(p0)) {
        scanner_consume(sc);
        return p0;
    }

    return 0xFFFD; // backslash + newline
}

static bool scanner_valid_escape_c(const char cp1, const char cp2) {
    return cp1 == 0x5C /* REVERSE_SOLIDUS */ && !is_newline(cp2);
}

#define scanner_valid_escape scanner_valid_escape_c(sc->look[0], sc->look[1])

static bool scanner_ident_sequence_start(const scanner_t *sc) {
    const int p0 = sc->look[0], p1 = sc->look[1], p2 = sc->look[2];
    if (p0 == 0x2D /* '-' */) {
        if (ident_start(p1) || p1 == 0x2D) return true;
        if (p1 == 0x5C /* '\' */ && !is_newline(p2)) return true;
        return false;
    }

    if (ident_start(p0)) {
        return true;
    }

    if (p0 == 0x5C) {
        return !is_newline(p1);
    }

    return false;
}

static VALUE scanner_unicode_range_start(const scanner_t *sc) {
    const int p0 = sc->look[0], p1 = sc->look[1], p2 = sc->look[2];
    if ((p0 == 0x75 || p0 == 0x55) && p1 == 0x2B /* '+' */) {
        if (p2 == 0x3F /* '?' */ || is_hex(p2)) return Qtrue;
    }
    return Qfalse;
}

static VALUE scanner_consume_ident_sequence(scanner_t *sc) {
    const VALUE out = rb_str_new("", 0);
    rb_enc_associate_index(out, rb_utf8_encindex());

    for (;;) {
        const int p0 = sc->look[0];
        if (p0 == EOF_CP) break;

        if (ident_point(p0)) {
            rb_str_cat_codepoint(out, p0);
            (void) scanner_consume(sc);
            continue;
        }

        if (p0 == 0x5C /* '\' */) {
            const int p1 = sc->look[1];
            if (p1 == EOF_CP) {
                (void) scanner_consume(sc); // consume '\'
                APPEND_REPLACEMENT(out);
                continue;
            }
            if (!is_newline(p1)) {
                (void) scanner_consume(sc); // consume '\'
                const uint32_t val = decode_escape(sc);
                rb_str_cat_codepoint(out, val);
                continue;
            }
        }

        break; // neither ident_point nor valid escape
    }

    return out;
}

static VALUE scanner_consume_escaped_code_point(scanner_t *sc) {
    const int p = sc->look[0];

    if (p == EOF_CP) {
        return INT2NUM(0xFFFD);
    }

    if (is_hex(p)) {
        int max = 6;
        uint32_t val = 0;
        int consumed = 0;
        while (is_hex(sc->look[0]) && max-- > 0) {
            const int h = sc->look[0];
            scanner_consume(sc);
            consumed = 1;
            if (h >= '0' && h <= '9') {
                val = (val << 4) | (h - '0');
            } else if (h >= 'A' && h <= 'F') {
                val = (val << 4) | (h - 'A' + 10);
            } else if (h >= 'a' && h <= 'f') {
                val = (val << 4) | (h - 'a' + 10);
            }
        }

        if (is_ws(sc->look[0])) scanner_consume(sc);

        if (!consumed || val == 0 || val > 0x10FFFF || (val >= 0xD800 && val <= 0xDFFF)) {
            return INT2NUM(0xFFFD);
        }

        return INT2NUM((int) val);
    }

    if (!is_newline(p)) {
        (void) scanner_consume(sc);
        return INT2NUM(p);
    }

    // backslash followed by newline → error
    return INT2NUM(0xFFFD);
}

static void scanner_push_token_opts(const scanner_t *sc, const VALUE type, const VALUE opts) {
    const VALUE pos_start = rb_funcall(cPosition, id_type_new, 3,
                                       LONG2NUM(sc->start_token_offset),
                                       LONG2NUM(sc->start_token_line),
                                       LONG2NUM(sc->start_token_column));
    const VALUE pos_end = rb_funcall(cPosition, id_type_new, 3,
                                     LONG2NUM(sc->idx_cp),
                                     LONG2NUM(sc->line),
                                     LONG2NUM(sc->col));

    const VALUE tokenArgv[4] = {type, pos_start, pos_end, opts};
    const VALUE token = rb_funcallv_kw(cToken, id_type_new, 4, tokenArgv,
                                       RB_PASS_KEYWORDS);
    rb_ary_push(sc->tokens, token);
}

static void scanner_push_token_simple(const scanner_t *sc, const VALUE type) {
    const VALUE pos_start = rb_funcall(cPosition, id_type_new, 3,
                                       LONG2NUM(sc->start_token_offset),
                                       LONG2NUM(sc->start_token_line),
                                       LONG2NUM(sc->start_token_column));
    const VALUE pos_end = rb_funcall(cPosition, id_type_new, 3,
                                     LONG2NUM(sc->idx_cp),
                                     LONG2NUM(sc->line),
                                     LONG2NUM(sc->col));

    const VALUE tokenArgv[4] = {type, pos_start, pos_end};
    const VALUE token = rb_funcallv(cToken, id_type_new, 3, tokenArgv);
    rb_ary_push(sc->tokens, token);
}

static void scanner_consume_unicode_range(scanner_t *sc) {
    // consume 'U+' or 'u+'
    scanner_consume(sc);
    scanner_consume(sc);

    uint32_t buf[6];
    int len = 0;

    // collect up to 6 hex digits
    while (is_hex(sc->look[0]) && len < 6) {
        buf[len++] = sc->look[0];
        scanner_consume(sc);
    }
    // then collect up to 6 question marks
    while (sc->look[0] == 0x3F /* '?' */ && len < 6) {
        buf[len++] = sc->look[0];
        scanner_consume(sc);
    }

    uint32_t start_range = 0;
    uint32_t end_range = 0;

    int has_qm = 0;
    for (int i = 0; i < len; i++) {
        if (buf[i] == 0x3F) {
            has_qm = 1;
            break;
        }
    }

    if (has_qm) {
        // replace ? with 0 for start, F for end
        for (int i = 0; i < len; i++) {
            start_range <<= 4;
            end_range <<= 4;
            if (buf[i] == 0x3F) {
                start_range |= 0x0;
                end_range |= 0xF;
            } else if (buf[i] >= '0' && buf[i] <= '9') {
                start_range |= (buf[i] - '0');
                end_range |= (buf[i] - '0');
            } else if (buf[i] >= 'A' && buf[i] <= 'F') {
                start_range |= (buf[i] - 'A' + 10);
                end_range |= (buf[i] - 'A' + 10);
            } else if (buf[i] >= 'a' && buf[i] <= 'f') {
                start_range |= (buf[i] - 'a' + 10);
                end_range |= (buf[i] - 'a' + 10);
            }
        }
    } else {
        for (int i = 0; i < len; i++) {
            start_range <<= 4;
            if (buf[i] >= '0' && buf[i] <= '9') start_range |= (buf[i] - '0');
            else if (buf[i] >= 'A' && buf[i] <= 'F') start_range |= (buf[i] - 'A' + 10);
            else if (buf[i] >= 'a' && buf[i] <= 'f') start_range |= (buf[i] - 'a' + 10);
        }
        end_range = start_range;

        if (sc->look[0] == '-' && is_hex(sc->look[1])) {
            scanner_consume(sc); // consume '-'
            len = 0;
            while (is_hex(sc->look[0]) && len < 6) {
                buf[len++] = sc->look[0];
                scanner_consume(sc);
            }
            end_range = 0;
            for (int i = 0; i < len; i++) {
                end_range <<= 4;
                if (buf[i] >= '0' && buf[i] <= '9') end_range |= (buf[i] - '0');
                else if (buf[i] >= 'A' && buf[i] <= 'F') end_range |= (buf[i] - 'A' + 10);
                else if (buf[i] >= 'a' && buf[i] <= 'f') end_range |= (buf[i] - 'a' + 10);
            }
        }
    }

    const VALUE hash = rb_hash_new();
    rb_hash_aset(hash, sym_start, UINT2NUM(start_range));
    rb_hash_aset(hash, sym_end, UINT2NUM(end_range));
    scanner_push_token_opts(sc, sym_unicode_range, hash);
}

static void scanner_consume_comments(scanner_t *sc) {
    for (;;) {
        // need a lookahead of "/*"
        if (!(sc->look[0] == 0x2F /* '/' */ && sc->look[1] == 0x2A /* '*' */)) {
            return;
        }

        // consume "/*"
        scanner_consume(sc);
        scanner_consume(sc);

        // scan until "*/" or EOF
        for (;;) {
            if (sc->look[0] == 0x2A /* '*' */ && sc->look[1] == 0x2F /* '/' */) {
                // consume "*/"
                scanner_consume(sc);
                scanner_consume(sc);
                break; // done with this comment, restart outer loop
            }
            if (sc->look[0] == EOF_CP) {
                return; // unterminated comment → stop
            }
            scanner_consume(sc);
        }
    }
}

static void scanner_consume_whitespace(scanner_t *sc) {
    int saw = 0;

    for (;;) {
        // comments count as whitespace
        if (sc->look[0] == 0x2F /* '/' */ && sc->look[1] == 0x2A /* '*' */) {
            if (!saw) {
                scanner_start_token(sc);
                saw = 1;
            }
            scanner_consume_comments(sc);
            continue;
        }

        // not whitespace? stop
        if (!is_ws(sc->look[0])) break;

        if (!saw) {
            scanner_start_token(sc);
            saw = 1;
        }
        (void) scanner_consume(sc);
    }

    if (saw) {
        scanner_push_token_simple(sc, sym_whitespace);
    }
}

static void scanner_consume_string_token_c(scanner_t *sc, const int closing_token) {
    scanner_start_token(sc);

    const VALUE str = rb_str_new("", 0);
    rb_enc_associate_index(str, rb_utf8_encindex());

    for (;;) {
        const int char_cp = sc->look[0];
        if (char_cp == EOF_CP) break;

        if (char_cp == closing_token) {
            break; // found closing
        }

        if (char_cp == REVERSE_SOLIDUS) {
            // '\'
            const int p1 = sc->look[1];
            if (p1 == EOF_CP) {
                scanner_consume(sc);
                continue;
            }

            if (is_newline(p1)) {
                scanner_consume(sc);
                scanner_consume(sc);
                continue;
            }

            if (scanner_valid_escape) {
                scanner_consume(sc);
                const VALUE cp_val = scanner_consume_escaped_code_point(sc);
                if (!NIL_P(cp_val)) {
                    const uint32_t cp = NUM2UINT(cp_val);
                    rb_str_cat_codepoint(str, cp);
                }
                continue;
            }
            // fallthrough: bad escape treated like normal char
        }

        if (is_newline(char_cp)) {
            scanner_push_token_simple(sc, sym_bad_string);
            return;
        }

        // normal consume
        scanner_consume(sc);
        rb_str_cat_codepoint(str, char_cp);
    }

    // quoting = [closing_token].pack("U*")
    char buf[4];
    int n = 0;
    if (closing_token < 0x80) {
        buf[0] = (char) closing_token;
        n = 1;
    } else if (closing_token < 0x800) {
        buf[0] = (char) (0xC0 | (closing_token >> 6));
        buf[1] = (char) (0x80 | (closing_token & 0x3F));
        n = 2;
    } else if (closing_token < 0x10000) {
        buf[0] = (char) (0xE0 | (closing_token >> 12));
        buf[1] = (char) (0x80 | ((closing_token >> 6) & 0x3F));
        buf[2] = (char) (0x80 | (closing_token & 0x3F));
        n = 3;
    } else {
        buf[0] = (char) (0xF0 | (closing_token >> 18));
        buf[1] = (char) (0x80 | ((closing_token >> 12) & 0x3F));
        buf[2] = (char) (0x80 | ((closing_token >> 6) & 0x3F));
        buf[3] = (char) (0x80 | (closing_token & 0x3F));
        n = 4;
    }
    const VALUE quoting = rb_utf8_str_new(buf, n);

    // push_token(:string, literal: str, quoting: quoting)
    const VALUE kwargs = rb_hash_new();
    rb_hash_aset(kwargs, sym_literal, str);
    rb_hash_aset(kwargs, sym_quoting, quoting);
    scanner_push_token_opts(sc, sym_string, kwargs);

    if (sc->look[0] != EOF_CP) {
        scanner_consume(sc);
    }
}

typedef struct numeric_repr {
    char type; // `i` for integer, or `n` for numeric
    char sign; // `+`, `-`, or `\0' for none.
    double value;
} numeric_repr_t;

static void scanner_read_numeric_token(scanner_t *sc, numeric_repr_t *out) {
    scanner_start_token(sc);
    out->type = 'i';
    uint32_t number_part[128];
    int number_part_idx = 0;
    uint32_t exponent_part[128];
    int exponent_part_idx = 0;
    out->sign = 0x00;

    // Sign
    if (sc->look[0] == PLUS_SIGN || sc->look[0] == HYPHEN_MINUS) {
        out->sign = (char) sc->look[0];
        scanner_consume(sc);
        number_part[number_part_idx++] = (unsigned char) out->sign;
    }

    // Digits
    while (is_digit(sc->look[0])) {
        number_part[number_part_idx++] = sc->look[0];
        scanner_consume(sc);
    }

    // fractional
    if (sc->look[0] == FULL_STOP && is_digit(sc->look[1])) {
        number_part[number_part_idx++] = sc->look[0]; // the `.`
        scanner_consume(sc);
        while (is_digit(sc->look[0])) {
            number_part[number_part_idx++] = sc->look[0];
            scanner_consume(sc);
        }
        out->type = 'n';
    }

    // exponent
    const uint32_t p = sc->look[0];
    const uint32_t p1 = sc->look[1];
    const uint32_t p2 = sc->look[2];
    if (
        (p == 0x45 || p == 0x65) &&
        (((p1 == HYPHEN_MINUS || p1 == PLUS_SIGN) && is_digit((int) p2)) || is_digit((int) p1))
    ) {
        scanner_consume(sc); // consume 'e' or 'E'
        if (sc->look[0] == HYPHEN_MINUS || sc->look[0] == PLUS_SIGN) {
            exponent_part[exponent_part_idx++] = sc->look[0];
            scanner_consume(sc);
        }
        while (is_digit(sc->look[0])) {
            exponent_part[exponent_part_idx++] = sc->look[0];
            scanner_consume(sc);
        }
        out->type = 'n';
    }

    double value = u32_chars_to_double(number_part, number_part_idx);
    if (exponent_part_idx != 0) {
        const double exponent = u32_chars_to_double(exponent_part, exponent_part_idx);
        value *= powf(10, (float_t) exponent);
    }

    out->value = value;
}

static void scanner_consume_numeric_token(scanner_t *sc) {
    numeric_repr_t num;
    scanner_read_numeric_token(sc, &num);
    const VALUE number = rb_hash_new();
    rb_hash_aset(number, sym_value, DBL2NUM(num.value));
    rb_hash_aset(number, sym_type,
                 num.type == 'i' ? sym_integer : sym_number);
    if (num.sign != 0x00) {
        char sign_char[2] = {num.sign, 0x00};
        rb_hash_aset(number, sym_sign_character,rb_utf8_str_new(sign_char, 1));
    }
    if (scanner_ident_sequence_start(sc)) {
        const VALUE unit = scanner_consume_ident_sequence(sc);
        rb_hash_aset(number, sym_unit, unit);
        scanner_push_token_opts(sc, sym_dimension, number);
    } else if (sc->look[0] == PERCENTAGE_SIGN) {
        scanner_consume(sc);
        scanner_push_token_opts(sc, sym_percentage, number);
    } else {
        scanner_push_token_opts(sc, sym_number, number);
    }
}

static inline bool is_url(const char *str) {
    return str[0] && str[1] && str[2] &&
           tolower((unsigned char) str[0]) == 'u' &&
           tolower((unsigned char) str[1]) == 'r' &&
           tolower((unsigned char) str[2]) == 'l' &&
           str[3] == '\0';
}

static void scanner_consume_ident_like_token(scanner_t *sc) {
    scanner_start_token(sc);
    VALUE str = scanner_consume_ident_sequence(sc);
    const char *cstr = rb_string_value_cstr(&str);

    const VALUE push_opts = rb_hash_new();
    rb_hash_aset(push_opts, sym_value, str);

    if (rb_str_strlen(str) >= 3 && is_url(cstr) && sc->look[0] == LEFT_PARENTHESIS) {
        scanner_consume(sc); // consume '('
        while (is_ws(sc->look[0]) && is_ws(sc->look[1])) {
            scanner_consume(sc);
        }

        if ((sc->look[0] == QUOTATION_MARK || sc->look[0] == APOSTROPHE) ||
            (is_ws(sc->look[0]) && (sc->look[1] == QUOTATION_MARK || sc->look[1] == APOSTROPHE))) {
            scanner_push_token_opts(sc, sym_function, push_opts);
            return;
        }

        scanner_consume_url_token(sc);
        return;
    }

    if (sc->look[0] == LEFT_PARENTHESIS) {
        scanner_consume(sc);
        const VALUE value = rb_str_dup(str);
        rb_str_cat_cstr(value, "(");
        rb_hash_aset(push_opts, sym_literal, value);
        rb_hash_aset(push_opts, sym_name, str);
        rb_hash_delete(push_opts, sym_value);
        scanner_push_token_opts(sc, sym_function, push_opts);
        return;
    }

    rb_hash_aset(push_opts, sym_literal, str);
    rb_hash_delete(push_opts, sym_value);
    scanner_push_token_opts(sc, sym_ident, push_opts);
}

static void scanner_consume_url_token(scanner_t *sc) {
    scanner_start_token(sc);

    const VALUE data = rb_str_new("", 0);
    rb_enc_associate_index(data, rb_utf8_encindex());

    // consume leading whitespace
    while (is_ws(sc->look[0])) {
        scanner_consume(sc);
    }

    for (;;) {
        const int p = sc->look[0];

        if (p == 0x29 /* ')' */) {
            scanner_consume(sc);
            const VALUE kwargs = rb_hash_new();
            rb_hash_aset(kwargs, sym_value, data);
            scanner_push_token_opts(sc, sym_url, kwargs);
            return;
        }

        if (p == EOF_CP) {
            const VALUE kwargs = rb_hash_new();
            rb_hash_aset(kwargs, sym_value, data);
            scanner_push_token_opts(sc, sym_url, kwargs);
            return;
        }

        if (is_ws(p)) {
            while (is_ws(sc->look[0])) scanner_consume(sc);

            if (sc->look[0] == 0x29 /* ')' */) {
                scanner_consume(sc);
                const VALUE kwargs = rb_hash_new();
                rb_hash_aset(kwargs, sym_value, data);
                scanner_push_token_opts(sc, sym_url, kwargs);
                return;
            } else if (sc->look[0] == EOF_CP) {
                VALUE kwargs = rb_hash_new();
                rb_hash_aset(kwargs, sym_value, data);
                scanner_push_token_opts(sc, sym_url, kwargs);
                return;
            } else {
                scanner_consume_bad_url(sc);
                scanner_push_token_simple(sc, sym_bad_url);
                return;
            }
        }

        if (p == QUOTATION_MARK || p == APOSTROPHE || p == 0x28 /* '(' */ ||
            (p <= 0x1F || p == 0x7F)) {
            // non-printable
            scanner_consume_bad_url(sc);
            scanner_push_token_simple(sc, sym_bad_url);
            return;
        }

        if (p == REVERSE_SOLIDUS) {
            if (scanner_valid_escape) {
                scanner_consume(sc); // consume '\'
                const VALUE cp_val = scanner_consume_escaped_code_point(sc);
                if (!NIL_P(cp_val)) {
                    const uint32_t cp = NUM2UINT(cp_val);
                    rb_str_cat_codepoint(data, cp);
                }
                continue;
            } else {
                scanner_consume_bad_url(sc);
                scanner_push_token_simple(sc, sym_bad_url);
                return;
            }
        }

        // normal char
        const int consumed = sc->look[0];
        scanner_consume(sc);
        rb_str_cat_codepoint(data, consumed);
    }
}

static void scanner_consume_bad_url(scanner_t *sc) {
    while (sc->look[0] != EOF) {
        if (sc->look[0] == RIGHT_PARENTHESIS) {
            scanner_consume(sc);
            return;
        }

        if (scanner_valid_escape) {
            scanner_consume(sc);
            scanner_consume_escaped_code_point(sc);
        } else {
            scanner_consume(sc);
        }
    }
}

static VALUE scanner_consume_token(const VALUE self) {
    scanner_t *sc;
    TypedData_Get_Struct(self, scanner_t, &scanner_type, sc);

    scanner_consume_comments(sc);
    scanner_consume_whitespace(sc);

    switch (sc->look[0]) {
        case QUOTATION_MARK:
        case APOSTROPHE: {
            const int p = sc->look[0];
            scanner_consume(sc);
            scanner_consume_string_token_c(sc, p);
            return Qtrue;
        }

        case NUMBER_SIGN: {
            scanner_start_token(sc);
            const char cp1 = (char) sc->look[1], cp2 = (char) sc->look[2];

            if (ident_point(sc->look[1]) || scanner_valid_escape_c(cp1, cp2)) {
                scanner_consume(sc);
                const VALUE flag = ident_start(sc->look[0]) ? rb_intern("id") : rb_intern("unrestricted");
                const VALUE value = scanner_consume_ident_sequence(sc);
                VALUE newValue = rb_str_new_cstr("#");
                newValue = rb_str_append(newValue, value);

                const VALUE push_token_opts = rb_hash_new();
                rb_hash_aset(push_token_opts, sym_flag, flag);
                rb_hash_aset(push_token_opts, sym_literal, newValue);
                scanner_push_token_opts(sc, sym_hash, push_token_opts);
                return Qnil;
            }
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_delim);
            return Qnil;
        }

        case LEFT_PARENTHESIS: {
            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_left_parenthesis);
            return Qnil;
        }

        case RIGHT_PARENTHESIS: {
            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_right_parenthesis);
            return Qnil;
        }

        case PLUS_SIGN: {
            const char p1 = (char) sc->look[1], p2 = (char) sc->look[2];
            if (is_digit(p1) || p1 == FULL_STOP && is_digit(p2)) {
                scanner_consume_numeric_token(sc);
                return Qnil;
            }

            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_delim);
            return Qnil;
        }

        case COMMA: {
            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_comma);
            return Qnil;
        }

        case HYPHEN_MINUS: {
            if (is_digit(sc->look[1]) || (sc->look[1] == FULL_STOP && is_digit(sc->look[2]))) {
                scanner_consume_numeric_token(sc);
                return Qnil;
            }

            if (sc->look[1] == HYPHEN_MINUS && sc->look[2] == GREATER_THAN) {
                scanner_start_token(sc);
                scanner_consume(sc); // -
                scanner_consume(sc); // -
                scanner_consume(sc); // >
                scanner_push_token_simple(sc, sym_cdc);
                return Qnil;
            }

            if (scanner_ident_sequence_start(sc)) {
                scanner_consume_ident_like_token(sc);
                return Qnil;
            }

            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_delim);
            return Qnil;
        }

        case FULL_STOP: {
            if (is_digit(sc->look[1])) {
                scanner_consume_numeric_token(sc);
                return Qnil;
            }

            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_delim);
            return Qnil;
        }

        case COLON: {
            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_colon);
            return Qnil;
        }

        case SEMICOLON: {
            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_semicolon);
            return Qnil;
        }

        case LESS_THAN: {
            scanner_start_token(sc);
            if (sc->look[0] == LESS_THAN &&
                sc->look[1] == EXCLAMATION_MARK &&
                sc->look[2] == HYPHEN_MINUS &&
                sc->look[3] == HYPHEN_MINUS) {
                scanner_consume(sc); // <
                scanner_consume(sc); // !
                scanner_consume(sc); // -
                scanner_consume(sc); // -
                scanner_push_token_simple(sc, sym_cdo);
                return Qnil;
            }

            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_delim);
            return Qnil;
        }

        case COMMERCIAL_AT: {
            scanner_start_token(sc);
            scanner_consume(sc);

            if (scanner_ident_sequence_start(sc)) {
                const VALUE raw_val = scanner_consume_ident_sequence(sc);
                const VALUE val = rb_str_new_cstr("@");
                rb_str_append(val, raw_val);
                const VALUE push_opts = rb_hash_new();
                rb_hash_aset(push_opts, sym_literal, val);
                scanner_push_token_opts(sc, sym_at_keyword, push_opts);
                return Qnil;
            }

            scanner_push_token_simple(sc, sym_delim);
            return Qnil;
        }

        case LEFT_SQUARE_BRACKET: {
            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_left_square_bracket);
            return Qnil;
        }

        case REVERSE_SOLIDUS: {
            if (scanner_valid_escape) {
                scanner_consume_ident_like_token(sc);
                return Qnil;
            }

            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_delim);
            return Qnil;
        }

        case RIGHT_SQUARE_BRACKET: {
            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_right_square_bracket);
            return Qnil;
        }

        case LEFT_CURLY: {
            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_left_curly);
            return Qnil;
        }

        case RIGHT_CURLY: {
            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_right_curly);
            return Qnil;
        }

        case 0x75:
        case 0x55:
            if (sc->allow_unicode_ranges && scanner_unicode_range_start(sc) == Qtrue) {
                scanner_consume_unicode_range(sc);
                return Qnil;
            }

            scanner_consume_ident_like_token(sc);
            return Qnil;

        default: {
            if (sc->look[0] == EOF) {
                return Qnil;
            }

            if (is_ws(sc->look[0])) {
                scanner_consume_whitespace(sc);
                return Qnil;
            }

            if (is_digit(sc->look[0])) {
                scanner_consume_numeric_token(sc);
                return Qnil;
            }

            if (ident_start(sc->look[0])) {
                scanner_consume_ident_like_token(sc);
                return Qnil;
            }

            scanner_start_token(sc);
            scanner_consume(sc);
            scanner_push_token_simple(sc, sym_delim);
            return Qnil;
        }
    }
}

static VALUE scanner_tokens(const VALUE self) {
    scanner_t *sc;
    TypedData_Get_Struct(self, scanner_t, &scanner_type, sc);
    return sc->tokens;
}

static VALUE scanner_at_eof(const VALUE self) {
    scanner_t *sc;
    TypedData_Get_Struct(self, scanner_t, &scanner_type, sc);
    return sc->look[0] == EOF ? Qtrue : Qfalse;
}

void Init_minicss_scanner(void) {
    const VALUE mMiniCSS = rb_define_module("MiniCSS");
    const VALUE mCSS = rb_define_module_under(mMiniCSS, "CSS");
    const VALUE cScanner = rb_define_class_under(mCSS, "Scanner", rb_cObject);

    cPosition = rb_path2class("MiniCSS::CSS::Position");
    cToken = rb_path2class("MiniCSS::CSS::Token");

    // Initialize values reused across functions
    INITIALIZE_REUSABLE_SYMBOL(line);
    INITIALIZE_REUSABLE_SYMBOL(column);
    INITIALIZE_REUSABLE_SYMBOL(offset);
    INITIALIZE_REUSABLE_SYMBOL(whitespace);
    INITIALIZE_REUSABLE_SYMBOL(start);
    INITIALIZE_REUSABLE_SYMBOL(end);
    INITIALIZE_REUSABLE_SYMBOL(unicode_range);
    INITIALIZE_REUSABLE_SYMBOL(new);
    INITIALIZE_REUSABLE_SYMBOL(bad_string);
    INITIALIZE_REUSABLE_SYMBOL(literal);
    INITIALIZE_REUSABLE_SYMBOL(quoting);
    INITIALIZE_REUSABLE_SYMBOL(string);
    INITIALIZE_REUSABLE_SYMBOL(value);
    INITIALIZE_REUSABLE_SYMBOL(type);
    INITIALIZE_REUSABLE_SYMBOL(integer);
    INITIALIZE_REUSABLE_SYMBOL(number);
    INITIALIZE_REUSABLE_SYMBOL(sign_character);
    INITIALIZE_REUSABLE_SYMBOL(unit);
    INITIALIZE_REUSABLE_SYMBOL(dimension);
    INITIALIZE_REUSABLE_SYMBOL(percentage);
    INITIALIZE_REUSABLE_SYMBOL(function);
    INITIALIZE_REUSABLE_SYMBOL(name);
    INITIALIZE_REUSABLE_SYMBOL(ident);
    INITIALIZE_REUSABLE_SYMBOL(url);
    INITIALIZE_REUSABLE_SYMBOL(bad_url);
    INITIALIZE_REUSABLE_SYMBOL(flag);
    INITIALIZE_REUSABLE_SYMBOL(hash);
    INITIALIZE_REUSABLE_SYMBOL(delim);
    INITIALIZE_REUSABLE_SYMBOL(left_parenthesis);
    INITIALIZE_REUSABLE_SYMBOL(right_parenthesis);
    INITIALIZE_REUSABLE_SYMBOL(comma);
    INITIALIZE_REUSABLE_SYMBOL(cdc);
    INITIALIZE_REUSABLE_SYMBOL(colon);
    INITIALIZE_REUSABLE_SYMBOL(semicolon);
    INITIALIZE_REUSABLE_SYMBOL(cdo);
    INITIALIZE_REUSABLE_SYMBOL(at_keyword);
    INITIALIZE_REUSABLE_SYMBOL(left_square_bracket);
    INITIALIZE_REUSABLE_SYMBOL(right_square_bracket);
    INITIALIZE_REUSABLE_SYMBOL(left_curly);
    INITIALIZE_REUSABLE_SYMBOL(right_curly);

    rb_define_alloc_func(cScanner, scanner_alloc);
    rb_define_method(cScanner, "initialize", scanner_initialize, 2);

    rb_define_method(cScanner, "eof?", scanner_at_eof, 0);
    rb_define_method(cScanner, "tokens", scanner_tokens, 0);
    rb_define_method(cScanner, "consume_token", scanner_consume_token, 0);
}
