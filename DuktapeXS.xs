#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "duktape.h"

MODULE = DuktapeXS      PACKAGE = DuktapeXS

PROTOTYPES: DISABLE

SV *js_eval(const char *code)
    PREINIT:
        int ln;
        const char *value;
        SV* output;
    CODE:
        duk_context *ctx = duk_create_heap_default();
        duk_push_string(ctx, code);
        duk_peval(ctx);
        value = duk_safe_to_string(ctx, -1);
        ln = strlen(value);
        output = newSV(ln);
        sv_setpvn(output, value, ln);
        RETVAL = output;
        # unless the string is duplicated here, duk_destroy_heap() eventually mangles
        # RETVAL and the output ends up containing extra bytes
        # RETVAL = strdup(output);
        duk_destroy_heap(ctx);
    OUTPUT:
        RETVAL
