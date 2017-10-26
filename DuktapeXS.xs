#define PERL_NO_GET_CONTEXT__THIS_BREAKS_INCLUDES
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <string.h>

#include "duktape.h"
#include "duk_console.h"
#include "duk_module_node.h"
#include "duk_module_loader.h"
#include "duk_timeout.h"
#include "duk_safe_json.h"

#define puts(...) fprintf(stderr, ">> "); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n");

// call_perl
// bridge to call &call_perl_sub passing arguments
static char *call_perl(const char *name, const char *args[]) {
    SV *ret_sv;                                  // return value scalar
    char *out;                                   // return value as string
    dSP;                                         // declare SP variable used by PUSHMARK
    ENTER; SAVETMPS;                             // start new scope

    PUSHMARK(SP);                                // prepare to push arguments
    EXTEND(SP, 2);                               // 2 of them
    XPUSHs(sv_2mortal(newSVpv(name, 0)));        // push sub name
    while (*args) {                              // loop until NULL is found
        XPUSHs(sv_2mortal(newSVpv(*args++, 0)));
    }
    PUTBACK;                                     // done with arguments

    int count = call_pv("call_perl_sub", G_SCALAR);

    SPAGAIN;                                     // refresh SP (doc says its necessary, but it breaks)

    if (count == 1) {                            // if we got results
        ret_sv = POPs;                           // get return value
        out = strdup((char*) SvRV(ret_sv));      // copy to char* (has to happen before FREE)
    }

    FREETMPS; LEAVE;                             // end scope, free variables

    return out;
}

// duk_call_perl
// bridge to execute &call_perl from duktape JS context
// this is added through duk_push_c_function
static duk_ret_t duk_call_perl(duk_context *ctx) {
    const char *sub;
    char *result;
    int i;
    long ln;

    sub = duk_get_string(ctx, 0);
    puts("pushing sub name: %s", sub);

    // collect all arguments
    ln = (long) duk_get_top(ctx) - 1;
    const char *args[ln];
    for (i=0; i < ln; i++) {
        args[i] = duk_safe_to_string(ctx, i + 1);
        // if type == object convert to json?
        // or just make all the interfaces only
        // communicate using objects/json, thinking of future
        // network service?
        puts("pushing arg %d: %s", i, args[i]);
    }
    args[ln] = NULL; // signal end of args

    result = call_perl(sub, args); // TODO: use duk_safe_call() here
    puts("Result of %s: %s", sub, result);
    duk_push_string(ctx, result);

    return 1;
}

MODULE = DuktapeXS PACKAGE = DuktapeXS
PROTOTYPES: DISABLE

SV *duktape_eval(const char *code, const char *json_payload, SV *methods)
    PREINIT:
        int ln;
        const char *value;
        SV* output;

        duk_context *ctx;
        duk_int_t decode_success;

    CODE:
        // create new VM context
        ctx = duk_create_heap_default();

        SV* hash_ref = SvRV(methods);
        HV* hash;
        if (hash_ref != NULL && SvTYPE(hash_ref) == SVt_PVHV) {
            hash = (HV*) hash_ref;
        }

        if (hash != NULL) {
            // create a js function for every given sub
            (void) hv_iterinit(hash);
            HE* entry;
            while ((entry = hv_iternext(hash))) {
                SV *sv_key = hv_iterkeysv(entry);
                SV *sv_val = HeVAL(entry);
                svtype type = SvTYPE(sv_val);
                if (type == SVt_IV) {
                    const char *key = (char*) SvRV(sv_key);
                    const char *val = (char*) SvRV(sv_val);
                    char fn[256];
                    sprintf(fn, "(function %s() { return __call_func.apply(null, ['%s'].concat(Array.prototype.slice.call(arguments))) })", key, key);
                    if (duk_peval_string(ctx, fn) == DUK_EXEC_SUCCESS) {
                        duk_put_global_string(ctx, key);
                    };
                }
            }
            duk_push_c_lightfunc(ctx, duk_call_perl, DUK_VARARGS, 2, 0);
            duk_put_global_string(ctx, "__call_func");
        }

        // receive json payload
        if (strncmp(json_payload, "", 1)) {
            duk_push_string(ctx, json_payload);
            if (duk_safe_call(ctx, safe_json_decode, NULL, 0, 1) == DUK_EXEC_SUCCESS) {
                duk_put_global_string(ctx, "DATA");
            } else {
                fprintf(stderr, "JSON parsing failed: %s\n", json_payload);
            }
        }

        // initialize module system
        duk_push_object(ctx);
        duk_push_c_function(ctx, cb_resolve_module, DUK_VARARGS);
        duk_put_prop_string(ctx, -2, "resolve");
        duk_push_c_function(ctx, cb_load_module, DUK_VARARGS);
        duk_put_prop_string(ctx, -2, "load");
        duk_module_node_init(ctx);

        // initialize console object
        duk_console_init(ctx, DUK_CONSOLE_PROXY_WRAPPER | DUK_CONSOLE_FLUSH);

        // evaluate source
        start_exec_timeout();
        duk_peval_string(ctx, code);
        clear_exec_timeout();
        value = duk_safe_to_string(ctx, -1);

        // prepare output
        // must return a copy of output string, duk_destroy_heap() eventually mangles RETVAL
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
