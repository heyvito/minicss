#include "ruby.h"
#include "ruby/encoding.h"
#include <stdint.h>
#include <string.h>

#define DEFINE_REUSABLE_SYMBOL(name) static ID id_type_##name; static VALUE sym_##name;
#define INITIALIZE_REUSABLE_SYMBOL(name) id_type_##name = rb_intern(#name); sym_##name = ID2SYM(id_type_##name);

DEFINE_REUSABLE_SYMBOL(whitespace);
DEFINE_REUSABLE_SYMBOL(eof);
static VALUE cTokenClass;

typedef struct {
    VALUE eof;
    VALUE tokens;
    int tokens_idx;
    long tokens_len;
    VALUE look[2];
    int marks[128];
    int marks_idx;
} stream_t;

static void stream_free(void *ptr) {
    xfree(ptr);
}

static size_t stream_memsize(const void *ptr) {
    return sizeof(stream_t);
}

static void stream_mark(void *ptr) {
    const stream_t *s = ptr;
    if (s->tokens) rb_gc_mark(s->tokens);
    if (s->eof) rb_gc_mark(s->eof);
}

static const rb_data_type_t stream_type = {
    "MiniCSS::CSS::TokenStream",
    {stream_mark, stream_free, stream_memsize,},
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE stream_alloc(const VALUE klass) {
    stream_t *s = ALLOC(stream_t);
    memset(s, 0, sizeof(stream_t));
    return TypedData_Wrap_Struct(klass, &stream_type, s);
}

static VALUE stream_initialize(const VALUE self, VALUE tokens) {
    Check_Type(tokens, T_ARRAY);
    stream_t *s;
    TypedData_Get_Struct(self, stream_t, &stream_type, s);
    s->tokens = tokens;
    s->tokens_idx = 0;
    s->marks_idx = 0;
    s->tokens_len = RARRAY_LEN(tokens);
    s->eof = rb_const_get(cTokenClass, rb_intern("EOF"));

    // prime lookahead
    s->look[0] = s->tokens_len >= 1 ? rb_ary_entry(tokens, 0) : s->eof;
    s->look[1] = s->tokens_len >= 2 ? rb_ary_entry(tokens, 1) : s->eof;
    return self;
}

static void rotate(stream_t *s) {
    s->look[0] = s->look[1];
    s->look[1] = s->tokens_idx + 1 < s->tokens_len ? rb_ary_entry(s->tokens, s->tokens_idx + 1) : s->eof;
}

#define UNWRAP_STREAM stream_t *s; TypedData_Get_Struct(self, stream_t, &stream_type, s);

static VALUE stream_peek(const VALUE self) {
    UNWRAP_STREAM;
    return s->look[0];
}

static void stream_consume_c(stream_t *s) {
    if (s->tokens_idx < s->tokens_len && s->tokens_idx + 1 < s->tokens_len) {
        s->tokens_idx++;
    }
    rotate(s);
}

static VALUE stream_consume(const VALUE self) {
    UNWRAP_STREAM;
    const VALUE peek = s->look[0];
    stream_consume_c(s);
    return peek;
}

static VALUE stream_discard(const VALUE self) {
    UNWRAP_STREAM;
    stream_consume_c(s);
    return Qnil;
}

static VALUE stream_discard_whitespace(const VALUE self) {
    UNWRAP_STREAM;
    for (;;) {
        const VALUE k = rb_funcall(s->look[0], rb_intern("kind"), 0);
        Check_Type(k, T_SYMBOL);
        if (rb_sym2id(k) != id_type_whitespace) break;
        stream_consume_c(s);
    }
    return Qnil;
}

static VALUE stream_create_mark(const VALUE self) {
    UNWRAP_STREAM;
    if (s->marks_idx >= 127) {
        rb_raise(rb_eRuntimeError, "Too many marks in stream");
    }

    s->marks[s->marks_idx++] = s->tokens_idx;
    return Qnil;
}

static VALUE stream_mark_restore(const VALUE self) {
    UNWRAP_STREAM;
    if (s->marks_idx == 0) {
        rb_raise(rb_eRuntimeError, "BUG: No mark to restore");
    }
    const int mark = s->marks[s->marks_idx - 1];
    s->tokens_idx = mark;
    s->look[0] = s->tokens_len > mark ? rb_ary_entry(s->tokens, mark) : s->eof;
    s->look[1] = s->tokens_len > mark + 1 ? rb_ary_entry(s->tokens, mark + 1) : s->eof;
    s->marks_idx--;
    return Qnil;
}

static VALUE stream_mark_pop(const VALUE self) {
    UNWRAP_STREAM;
    if (s->marks_idx == 0) {
        rb_raise(rb_eRuntimeError, "BUG: No mark to pop");
    }
    s->marks_idx--;
    return Qnil;
}

static bool is_eof(const VALUE v) {
    const VALUE k = rb_funcall(v, rb_intern("kind"), 0);
    Check_Type(k, T_SYMBOL);
    return rb_sym2id(k) == id_type_eof;
}

static VALUE stream_is_empty(const VALUE self) {
    UNWRAP_STREAM;
    if (s->tokens_idx >= s->tokens_len || is_eof(s->look[0]))
        return Qtrue;
    return Qfalse;
}

static VALUE stream_peek_kind(const VALUE self) {
    UNWRAP_STREAM;
    const VALUE k = rb_funcall(s->look[0], rb_intern("kind"), 0);
    Check_Type(k, T_SYMBOL);
    return k;
}

static VALUE stream_status(const VALUE self) {
    UNWRAP_STREAM;
    const VALUE h = rb_hash_new();
    rb_hash_aset(h, ID2SYM(rb_intern("eof")), s->eof);
    rb_hash_aset(h, ID2SYM(rb_intern("tokens")), s->tokens);
    rb_hash_aset(h, ID2SYM(rb_intern("tokens_idx")), INT2NUM(s->tokens_idx));
    rb_hash_aset(h, ID2SYM(rb_intern("tokens_len")), INT2NUM((int)s->tokens_len));
    rb_hash_aset(h, ID2SYM(rb_intern("look0")), s->look[0]);
    rb_hash_aset(h, ID2SYM(rb_intern("look1")), s->look[1]);
    rb_hash_aset(h, ID2SYM(rb_intern("marks_idx")), INT2NUM(s->marks_idx));
    return h;
}

void Init_minicss_token_stream(void) {
    const VALUE mMiniCSS = rb_define_module("MiniCSS");
    const VALUE mCSS = rb_define_module_under(mMiniCSS, "CSS");
    const VALUE cStream = rb_define_class_under(mCSS, "TokenStream", rb_cObject);
    cTokenClass = rb_path2class("MiniCSS::CSS::Token");

    INITIALIZE_REUSABLE_SYMBOL(whitespace);
    INITIALIZE_REUSABLE_SYMBOL(eof);

    rb_define_alloc_func(cStream, stream_alloc);
    rb_define_method(cStream, "initialize", stream_initialize, 1);
    rb_define_method(cStream, "peek", stream_peek, 0);
    rb_define_method(cStream, "peek_kind", stream_peek_kind, 0);
    rb_define_method(cStream, "consume", stream_consume, 0);
    rb_define_method(cStream, "discard_whitespace", stream_discard_whitespace, 0);
    rb_define_method(cStream, "discard", stream_discard, 0);

    rb_define_method(cStream, "mark", stream_create_mark, 0);
    rb_define_method(cStream, "restore", stream_mark_restore, 0);
    rb_define_method(cStream, "pop", stream_mark_pop, 0);
    rb_define_method(cStream, "empty?", stream_is_empty, 0);
    rb_define_method(cStream, "status", stream_status, 0);
}
