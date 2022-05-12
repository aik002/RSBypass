#include <sys/mman.h>
#include <mach/mach.h>

#import "RSBypass.h"


typedef uint32_t DWORD;
typedef int8_t  BYTE;

// Mac OS 32 Bit
// These numbers come from otool -lv
const DWORD  segStart = 0x001000;
const size_t segLen   = 0x013ce000;

// Could be made more general to bypass all signature checks
// including ini files...
// For the time being only patches the sig verif of sng files
// const char*  hint     = "\x0f\x84\xc6\x0a\x00\x00";
const char*  hint     = "\x84\xdb\x0f\x84\xde\x0a\x00\x00";


bool bCompare(const BYTE* pData, const BYTE * bMask, const char* szMask) {
    for (; *szMask; ++szMask, ++pData, ++bMask)
        if (*szMask == 'x' && *pData != *bMask)
            return 0;
    return (*szMask) == 0;
}

void* FindPattern(DWORD dwAddress, size_t dwLen, BYTE* bMask, char* szMask) {
    for (DWORD i = 0; i < dwLen; i++)
        if (bCompare((BYTE*)(dwAddress + i), bMask, szMask))
            return (void*)(dwAddress + i);
    return NULL;
}


@implementation RSBypass
+(void)load
{
//    NSLog(@"RSBypass: load()");

    void* ptr = FindPattern(segStart, segLen,
                            (BYTE*)hint, "xxxxxxxx");
    if (ptr) {
        
        long page_size = sysconf(_SC_PAGESIZE);
        void* page_start = (long)ptr & -page_size;
        
//        NSLog(@"Removing memory protection");
        mprotect(page_start, page_size, PROT_READ | PROT_WRITE | PROT_EXEC);
        
//        NSLog(@"RSInjector: Bypassing signature check at %p", ptr);
        memset(ptr, 0x90, 8);
        msync(ptr, 8, MS_SYNC);
        
        // Restoring memory protection
        mprotect(page_start, page_size, PROT_READ | PROT_EXEC);
        
    }
}
@end
