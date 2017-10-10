#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "duktape.h"


MODULE = DuktapeXS PACKAGE = DuktapeXS
PROTOTYPES: DISABLE

SV *js_eval(const char *code)

    PREINIT:
        int ln;
        const char *value;
        SV* output;
        duk_context *ctx;

    CODE:
        # create new VM context
        ctx = duk_create_heap_default();

        # evaluate source
        duk_peval_string(ctx, code);
        value = duk_safe_to_string(ctx, -1);

        # prepare output
        # must return a copy of output string, duk_destroy_heap() eventually mangles RETVAL
        ln = strlen(value);
        output = newSV(ln);
        sv_setpvn(output, value, ln);
        RETVAL = output;

    OUTPUT:
        RETVAL

    CLEANUP:
        duk_destroy_heap(ctx);
