#include <gavl/gavl.h>
#include <gavl/http.h>
#include <inttypes.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    const struct {
        int64_t time;
        const char *expected;
    } cases[] = {
        {0, "Thu, 01 Jan 1970 00:00:00 GMT"},
        {-1, "Wed, 31 Dec 1969 23:59:59 GMT"},
        {INT64_C(2208988800), "Sun, 01 Jan 2040 00:00:00 GMT"},
    };
    gavl_dictionary_t header;
    gavl_dictionary_init(&header);
    for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
        gavl_http_header_set_time(&header, "Date", cases[i].time);
        const char *actual = gavl_dictionary_get_string(&header, "Date");
        if (!actual || strcmp(actual, cases[i].expected) != 0) {
            fprintf(stderr, "time=%" PRId64 ": expected %s, got %s\n",
                    cases[i].time, cases[i].expected, actual ? actual : "NULL");
            return 1;
        }
        if (gavl_http_header_get_time(&header, "Date") != cases[i].time) {
            fprintf(stderr, "HTTP timestamp round-trip failed\n");
            return 1;
        }
        puts(actual);
    }
    gavl_dictionary_free(&header);
    return 0;
}
