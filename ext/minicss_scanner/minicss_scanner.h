//
// Created by Vito Sartori on 11/10/25.
//

#ifndef MINICSS_SCANNER_MINICSS_SCANNER_H
#define MINICSS_SCANNER_MINICSS_SCANNER_H

#define EOF_CP   (-1)
#define NEWLINE  0x0A
#define CP(c)    ((int)(c))
#define REVERSE_SOLIDUS '\\'
#define QUOTATION_MARK '"'
#define APOSTROPHE '\''
#define NUMBER_SIGN '#'
#define LEFT_PARENTHESIS '('
#define RIGHT_PARENTHESIS ')'
#define PLUS_SIGN '+'
#define FULL_STOP '.'
#define HYPHEN_MINUS '-'
#define PERCENTAGE_SIGN '%'
#define COMMA ','
#define GREATER_THAN '>'
#define COLON ':'
#define SEMICOLON ';'
#define LESS_THAN '<'
#define EXCLAMATION_MARK '!'
#define COMMERCIAL_AT '@'
#define LEFT_SQUARE_BRACKET '['
#define RIGHT_SQUARE_BRACKET ']'
#define LEFT_CURLY '{'
#define RIGHT_CURLY '}'

#define DEFINE_REUSABLE_SYMBOL(name) static ID id_type_##name; static VALUE sym_##name;
#define INITIALIZE_REUSABLE_SYMBOL(name) id_type_##name = rb_intern(#name); sym_##name = ID2SYM(id_type_##name);

DEFINE_REUSABLE_SYMBOL(line);
DEFINE_REUSABLE_SYMBOL(column);
DEFINE_REUSABLE_SYMBOL(offset);
DEFINE_REUSABLE_SYMBOL(whitespace);
DEFINE_REUSABLE_SYMBOL(start);
DEFINE_REUSABLE_SYMBOL(end);
DEFINE_REUSABLE_SYMBOL(unicode_range);
DEFINE_REUSABLE_SYMBOL(new);
DEFINE_REUSABLE_SYMBOL(bad_string);
DEFINE_REUSABLE_SYMBOL(literal);
DEFINE_REUSABLE_SYMBOL(quoting);
DEFINE_REUSABLE_SYMBOL(string);
DEFINE_REUSABLE_SYMBOL(value);
DEFINE_REUSABLE_SYMBOL(type);
DEFINE_REUSABLE_SYMBOL(integer);
DEFINE_REUSABLE_SYMBOL(number);
DEFINE_REUSABLE_SYMBOL(sign_character);
DEFINE_REUSABLE_SYMBOL(unit);
DEFINE_REUSABLE_SYMBOL(dimension);
DEFINE_REUSABLE_SYMBOL(percentage);
DEFINE_REUSABLE_SYMBOL(function);
DEFINE_REUSABLE_SYMBOL(name);
DEFINE_REUSABLE_SYMBOL(ident);
DEFINE_REUSABLE_SYMBOL(url);
DEFINE_REUSABLE_SYMBOL(bad_url);
DEFINE_REUSABLE_SYMBOL(flag);
DEFINE_REUSABLE_SYMBOL(hash);
DEFINE_REUSABLE_SYMBOL(delim);
DEFINE_REUSABLE_SYMBOL(left_parenthesis);
DEFINE_REUSABLE_SYMBOL(right_parenthesis);
DEFINE_REUSABLE_SYMBOL(comma);
DEFINE_REUSABLE_SYMBOL(cdc);
DEFINE_REUSABLE_SYMBOL(colon);
DEFINE_REUSABLE_SYMBOL(semicolon);
DEFINE_REUSABLE_SYMBOL(cdo);
DEFINE_REUSABLE_SYMBOL(at_keyword);
DEFINE_REUSABLE_SYMBOL(left_square_bracket);
DEFINE_REUSABLE_SYMBOL(right_square_bracket);
DEFINE_REUSABLE_SYMBOL(left_curly);
DEFINE_REUSABLE_SYMBOL(right_curly);

// Definitions -----------------------------------------------------------------

/**
 * scanner_t - State for a CSS tokenizer scanner.
 *
 * Holds the current position, lookahead, and bookkeeping needed to
 * tokenize a UTF-8 encoded CSS source string. This structure is the
 * central state passed around by the tokenizer.
 *
 * Fields:
 *   str   - Ruby String VALUE containing the source (kept alive
 *           to ensure the underlying buffer remains valid).
 *
 *   p     - Current byte pointer into the UTF-8 source.
 *   end   - Pointer to one past the last byte of the source.
 *
 *   idx_cp - Index of the current code point (0-based).
 *   line   - Current line number (1-based, for error reporting).
 *   col    - Current column number (1-based, for error reporting).
 *
 *   look  - Lookahead buffer of decoded code points:
 *             look[0] = next code point (peek)
 *             look[1] = second ahead
 *             look[2] = third ahead
 *             look[3] = fourth ahead
 *           Used for disambiguating tokens (e.g. distinguishing
 *           between `--ident` and `-->`).
 *
 * Notes:
 *   - `p` is advanced as tokens are consumed.
 *   - `line` and `col` are updated to provide CSS-spec-compliant
 *     source location information.
 *   - Lookahead avoids re-decoding UTF-8 sequences during parsing.
 */
typedef struct {
    VALUE str;
    VALUE owner;
    VALUE tokens;
    bool allow_unicode_ranges;
    const uint8_t *p;
    const uint8_t *end;
    long idx_cp;
    long line;
    long col;
    int look[4];
    long start_token_offset;
    long start_token_line;
    long start_token_column;
} scanner_t;

// Forward definitions ---------------------------------------------------------
static void scanner_consume_ident_like_token(scanner_t *sc);
static void scanner_consume_url_token(scanner_t *sc);
static void scanner_consume_bad_url(scanner_t *sc);

#endif //MINICSS_SCANNER_MINICSS_SCANNER_H