#if !defined(DUK_SAFE_JSON_H_INCLUDED)
#define DUK_SAFE_JSON_H_INCLUDED

#include "duktape.h"

extern duk_ret_t safe_json_decode(duk_context *ctx, void *udata);

#endif  /* DUK_SAFE_JSON_H_INCLUDED */