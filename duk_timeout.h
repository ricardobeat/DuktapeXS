
int exec_timeout_seconds = 2; /* default 2 seconds */
time_t curr_pcall_start = 0;
long exec_timeout_check_counter = 0;

inline void start_exec_timeout(void) {
    curr_pcall_start = time(NULL);
}

inline void clear_exec_timeout(void) {
    curr_pcall_start = 0;
}

inline void set_exec_timeout(int seconds) {
    exec_timeout_seconds = seconds;
}

inline duk_bool_t exec_timeout_check(void *udata) {
    time_t now = time(NULL);
    time_t diff = now - curr_pcall_start;
    (void) udata;  /* not needed */
    exec_timeout_check_counter++;
    if (curr_pcall_start == 0) return 0; /* protected call not yet running */
    if (diff > exec_timeout_seconds) return 1;
    return 0;
}
