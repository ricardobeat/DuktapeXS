#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "duktape.h"
#include "duk_console.h"
#include "duk_module_node.h"
#include "duk_module_loader.h"
#include "duk_timeout.h"

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

        # initialize module system
        duk_push_object(ctx);
        duk_push_c_function(ctx, cb_resolve_module, DUK_VARARGS);
        duk_put_prop_string(ctx, -2, "resolve");
        duk_push_c_function(ctx, cb_load_module, DUK_VARARGS);
        duk_put_prop_string(ctx, -2, "load");
        duk_module_node_init(ctx);

        # initialize console object
        duk_console_init(ctx, DUK_CONSOLE_PROXY_WRAPPER | DUK_CONSOLE_FLUSH);

        # evaluate source
        start_exec_timeout();
        duk_peval_string(ctx, code);
        clear_exec_timeout();
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

void *set_timeout(int seconds)
    CODE:
        set_exec_timeout(seconds);
