/*
 * Build this source as a mock EGL/X11 backend, caller library, and test driver.
 * It reproduces libxcast.so's default-display routing without the shim, then
 * verifies that the shim selects X11 for libxcast.so while preserving other
 * callers.
 */

#define _GNU_SOURCE
#define EGL_EGLEXT_PROTOTYPES

#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <X11/Xlib.h>

#define DEFAULT_RESULT ((EGLDisplay)(uintptr_t)0x2001)
#define PLATFORM_RESULT ((EGLDisplay)(uintptr_t)0x2002)
#define EXT_RESULT ((EGLDisplay)(uintptr_t)0x2003)
#define X_DISPLAY ((Display *)(uintptr_t)0x3001)
#define CALLER_PLATFORM ((EGLenum)0x4001)
#define CALLER_NATIVE_DISPLAY ((void *)(uintptr_t)0x4002)

struct backend_state {
    unsigned int default_calls;
    unsigned int platform_calls;
    unsigned int ext_calls;
    unsigned int x_open_calls;
    EGLNativeDisplayType default_native_display;
    EGLenum platform;
    void *platform_native_display;
    int platform_had_attributes;
    EGLenum ext_platform;
    void *ext_native_display;
    int ext_had_attributes;
};

#if defined(TEST_BACKEND)

struct backend_state camera_test_backend_state;

EGLDisplay eglGetDisplay(EGLNativeDisplayType native_display)
{
    camera_test_backend_state.default_calls++;
    camera_test_backend_state.default_native_display = native_display;
    return DEFAULT_RESULT;
}

EGLDisplay eglGetPlatformDisplay(EGLenum platform, void *native_display,
                                 const EGLAttrib *attributes)
{
    camera_test_backend_state.platform_calls++;
    camera_test_backend_state.platform = platform;
    camera_test_backend_state.platform_native_display = native_display;
    camera_test_backend_state.platform_had_attributes = attributes != NULL;
    return PLATFORM_RESULT;
}

EGLDisplay eglGetPlatformDisplayEXT(EGLenum platform, void *native_display,
                                    const EGLint *attributes)
{
    camera_test_backend_state.ext_calls++;
    camera_test_backend_state.ext_platform = platform;
    camera_test_backend_state.ext_native_display = native_display;
    camera_test_backend_state.ext_had_attributes = attributes != NULL;
    return EXT_RESULT;
}

Display *XOpenDisplay(const char *display_name)
{
    (void)display_name;
    camera_test_backend_state.x_open_calls++;
    return X_DISPLAY;
}

#elif defined(TEST_CALLER)

EGLDisplay camera_test_get_display(void)
{
    return eglGetDisplay(EGL_DEFAULT_DISPLAY);
}

EGLDisplay camera_test_get_platform_display(void)
{
    const EGLAttrib attributes[] = { EGL_NONE };

    return eglGetPlatformDisplay(CALLER_PLATFORM, CALLER_NATIVE_DISPLAY,
                                 attributes);
}

EGLDisplay camera_test_get_platform_display_ext(void)
{
    const EGLint attributes[] = { EGL_NONE };

    return eglGetPlatformDisplayEXT(CALLER_PLATFORM, CALLER_NATIVE_DISPLAY,
                                    attributes);
}

#elif defined(TEST_MAIN)

#ifndef EGL_PLATFORM_X11_KHR
#define EGL_PLATFORM_X11_KHR 0x31D5
#endif

typedef EGLDisplay (*display_call)(void);

static void *required_symbol(void *handle, const char *name)
{
    void *symbol;
    const char *error;

    dlerror();
    symbol = dlsym(handle, name);
    error = dlerror();
    if (error) {
        fprintf(stderr, "dlsym(%s): %s\n", name, error);
        exit(EXIT_FAILURE);
    }
    return symbol;
}

#define CHECK(expression)                                                      \
    do {                                                                       \
        if (!(expression)) {                                                   \
            fprintf(stderr, "%s:%d: check failed: %s\n", __FILE__, __LINE__,  \
                    #expression);                                              \
            exit(EXIT_FAILURE);                                                \
        }                                                                      \
    } while (0)

int main(int argc, char **argv)
{
    void *caller;
    struct backend_state *state;
    display_call get_display;
    display_call get_platform_display;
    display_call get_platform_display_ext;
    EGLDisplay default_result;
    EGLDisplay platform_result;
    EGLDisplay ext_result;
    int expect_forced;

    if (argc != 3 ||
        (strcmp(argv[2], "passthrough") != 0 &&
         strcmp(argv[2], "forced") != 0)) {
        fprintf(stderr, "usage: %s CALLER.so passthrough|forced\n", argv[0]);
        return EXIT_FAILURE;
    }
    expect_forced = strcmp(argv[2], "forced") == 0;

    caller = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (!caller) {
        fprintf(stderr, "dlopen(%s): %s\n", argv[1], dlerror());
        return EXIT_FAILURE;
    }
    state = required_symbol(RTLD_DEFAULT, "camera_test_backend_state");
    get_display = (display_call)required_symbol(caller, "camera_test_get_display");
    get_platform_display =
        (display_call)required_symbol(caller, "camera_test_get_platform_display");
    get_platform_display_ext = (display_call)required_symbol(
        caller, "camera_test_get_platform_display_ext");

    memset(state, 0, sizeof(*state));
    default_result = get_display();
    platform_result = get_platform_display();
    ext_result = get_platform_display_ext();

    if (expect_forced) {
        CHECK(default_result == PLATFORM_RESULT);
        CHECK(platform_result == PLATFORM_RESULT);
        CHECK(ext_result == PLATFORM_RESULT);
        CHECK(state->default_calls == 0);
        CHECK(state->platform_calls == 1);
        CHECK(state->ext_calls == 0);
        CHECK(state->x_open_calls == 1);
        CHECK(state->platform == EGL_PLATFORM_X11_KHR);
        CHECK(state->platform_native_display == X_DISPLAY);
        CHECK(!state->platform_had_attributes);
    } else {
        CHECK(default_result == DEFAULT_RESULT);
        CHECK(platform_result == PLATFORM_RESULT);
        CHECK(ext_result == EXT_RESULT);
        CHECK(state->default_calls == 1);
        CHECK(state->platform_calls == 1);
        CHECK(state->ext_calls == 1);
        CHECK(state->x_open_calls == 0);
        CHECK(state->default_native_display == EGL_DEFAULT_DISPLAY);
        CHECK(state->platform == CALLER_PLATFORM);
        CHECK(state->platform_native_display == CALLER_NATIVE_DISPLAY);
        CHECK(state->platform_had_attributes);
        CHECK(state->ext_platform == CALLER_PLATFORM);
        CHECK(state->ext_native_display == CALLER_NATIVE_DISPLAY);
        CHECK(state->ext_had_attributes);
    }

    printf("%s: %s EGL routing verified\n", argv[1], argv[2]);
    dlclose(caller);
    return EXIT_SUCCESS;
}

#else
#error "Define exactly one test role"
#endif
