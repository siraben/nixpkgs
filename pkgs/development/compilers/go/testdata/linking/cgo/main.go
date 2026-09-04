package main

/*
#include <stdlib.h>
*/
import "C"

func main() {
	ptr := C.malloc(1)
	C.free(ptr)
}
