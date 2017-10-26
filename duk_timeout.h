#ifndef H_DUK_TIMEOUT

#include "duktape.h"

extern void start_exec_timeout(void);
extern void clear_exec_timeout(void);
extern void set_exec_timeout(int seconds);
extern duk_bool_t exec_timeout_check(void *udata);

#define H_DUK_TIMEOUT
#endif