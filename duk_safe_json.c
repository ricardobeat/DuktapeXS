/*
 *  Safe wrapper for duk_decode_json
 */
#include "duktape.h"

duk_ret_t safe_json_decode(duk_context *ctx, void *udata) {
    duk_json_decode(ctx, -1);
    return 1;
}
