#include <string.h>
#include "duktape.h"

inline bool str_endswith(const char *str, const char *end){
    if (!str || !end) return false;
    if (strlen(str) < strlen(end)) return false;
    const char *start = str + strlen(str) - strlen(end);
    return strcmp(start, end) == 0;
}

inline static duk_ret_t cb_resolve_module(duk_context *ctx) {
    const char *module_id;
    const char *parent_id;
    char *resolved_id;

    module_id = duk_require_string(ctx, 0);
    parent_id = duk_require_string(ctx, 1);

    resolved_id = strdup(module_id);
    if (!str_endswith(module_id, ".js")) strcat(resolved_id, ".js");

    duk_push_string(ctx, resolved_id);

    return 1;
}

inline static char *read_file(const char *filename){
   char *buffer = NULL;
   int string_size, read_size;
   FILE *handler = fopen(filename, "r");

   if (handler) {
       fseek(handler, 0, SEEK_END);
       string_size = ftell(handler);
       rewind(handler);

       buffer = (char*) malloc(sizeof(char) * (string_size + 1) );
       read_size = fread(buffer, sizeof(char), string_size, handler);

       // fread doesn't set it so put a \0 in the last position
       // and buffer is now officially a string
       buffer[string_size] = '\0';

       if (string_size != read_size){
           free(buffer);
           buffer = NULL;
       }

       fclose(handler);
    }

    return buffer;
}

inline static duk_ret_t cb_load_module(duk_context *ctx) {
    const char *filename;
    const char *module_id;

    module_id = duk_require_string(ctx, 0);
    duk_get_prop_string(ctx, 2, "filename");
    filename = duk_require_string(ctx, -1);

    // fprintf(stderr, "load_cb: id:'%s', filename:'%s'\n", module_id, filename);
    const char *module_source = read_file(filename);

    if (module_source != NULL) {
        duk_push_string(ctx, module_source);
    } else {
        (void) duk_generic_error(ctx, "cannot find module: %s", module_id);
    }

    return 1;
}
