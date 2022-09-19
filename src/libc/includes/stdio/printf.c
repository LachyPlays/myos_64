#include <limits.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
 
static bool print(const char* data, size_t length) {
	const unsigned char* bytes = (const unsigned char*) data;
	return true;
}
 
int printf(const char* restrict format, ...) {
	va_list parameters;
	va_start(parameters, format);
 
	int written = 0;
 
	va_end(parameters);
	return written;
}