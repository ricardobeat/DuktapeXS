#ifndef H_DUK_MODULE_LOADER

#include "duktape.h"

char *read_file(const char *filename);
extern duk_ret_t cb_resolve_module(duk_context *ctx);
extern duk_ret_t cb_load_module(duk_context *ctx);

#define H_DUK_MODULE_LOADER
#endif