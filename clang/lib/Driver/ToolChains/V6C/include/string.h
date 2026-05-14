/*===---- string.h - V6C freestanding subset ------------------------------===
 *
 * V6C resource-dir <string.h>. Declares the subset of <string.h> backed by
 * the assembled helpers in compiler-rt/lib/builtins/v6c/memory.s.
 *
 * The V6C calling convention places the first three i16 arguments in HL,
 * DE, BC respectively, which exactly matches the register layout each
 * helper expects, so the prototypes below produce ordinary CALL sites
 * that dispatch directly to the assembled symbols.
 *
 *===-----------------------------------------------------------------------===
 */

#ifndef __V6C_STRING_H
#define __V6C_STRING_H

#ifndef __V6C__
#error "<string.h> from the V6C resource dir is V6C-specific"
#endif

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

void *memcpy(void *__dst, const void *__src, size_t __n);
void *memset(void *__dst, int __val, size_t __n);
void *memmove(void *__dst, const void *__src, size_t __n);

size_t strlen(const char *__s);
int    strcmp(const char *__a, const char *__b);
char  *strcpy(char *__dst, const char *__src);

#ifdef __cplusplus
}
#endif

#endif /* __V6C_STRING_H */
