#include <sys/mman.h>
#include <mach/mach.h>
#include <string.h>

#import "RSBypass.h"

// Added for find_remote_image_load_address
#include <mach-o/dyld_images.h>
#include <mach-o/dyld.h>
#include <mach/mach_vm.h>

//function prototype definition
NSMutableArray *find_image_load_addresses(void);


typedef uint64_t DWORD;
typedef int8_t  BYTE;

// Mac OS 64 Bit
// These numbers come from otool -lv
// const DWORD  segStart = 0x001000;
 const size_t segLen   = 0x013ce000 ;
//const size_t segLen   = 0x013CE9BC1;

// Could be made more general to bypass all signature checks
// including ini files...
// For the time being only patches the sig verif of sng files
// const char*  hint     = "\x0f\x84\xc6\x0a\x00\x00";
 const char*  hintold     = "\x84\xdb\x0f\x84\xde\x0a\x00\x00";
const char*  hint     = "\x45\x84\xF6\x0F\x84\xCF\x0A\x00\x00";


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

long FindLongPattern(DWORD dwAddress, size_t dwLen, BYTE* bMask, char* szMask) {
    for (DWORD i = 0; i < dwLen; i++)
        if (bCompare((BYTE*)(dwAddress + i), bMask, szMask))
            return (long) (dwAddress + i);
    return 0;
}

@implementation RSBypass
+(void)load
{
    NSLog(@"RSBypass: load()");

    // Grab all of the dlyd address with 'Rocksmith' in dyld path.
    NSMutableArray *addresses = find_image_load_addresses();
    NSEnumerator *enumerator = [addresses objectEnumerator];
    struct mach_header *anAddress;
    NSValue *aWrappedAddress;
    
    // Interate and unwrap each mach header.
    while (aWrappedAddress = [enumerator nextObject]) {
        [aWrappedAddress getValue:&anAddress];
        
        uint64_t addr = anAddress;
        uint64_t segStart = addr; //  + 0x1500;
        size_t segLen = anAddress->sizeofcmds;
        // These aren't large.  I'm not sure about sizeofcmds, but 0x13ce900 for segLen was SIGSEGVing.
        // Or possibly check longer using vm_read() as per https://gist.github.com/xcxcxc/989018646b1f0f2f31f0873a32c4a658 .
        
        NSLog(@"Addr=%p Len=%lu\n", addr, segLen);
        
        if (addr) {
            void* ptr = FindPattern(segStart, segLen, (BYTE*)hint, "xxxxxxxxx");
            NSLog(@"Ptr=%p", ptr);
            if (ptr) {
                
                long page_size = sysconf(_SC_PAGESIZE);
                
                void* page_start = (long)ptr & -page_size;
                
                NSLog(@"Attempting Removing memory protection");
                if(mprotect(page_start, page_size, PROT_READ | PROT_WRITE) == 0){
                    
                    NSLog(@"RSInjector: Bypassing signature check at %p", ptr);
                    memset(ptr, 0x90, 9);
                    msync(ptr, 9, MS_SYNC);
                    
                    mprotect(page_start, page_size, PROT_READ | PROT_EXEC);
                    break; // Never gotten this far!
                }else{
                    NSLog(@"Memory Operation failed: \nmprotect: %s\n", strerror(errno));
                }
            }
        }
    }
}
/*
@implementation RSBypass
+(void)load
{
    NSLog(@"RSBypass: load()");

    uint64_t addr = find_image_load_address();
    uint64_t segStart = addr + 0x1000;

    NSLog(@"Addr=%llu", addr);
    
    if (addr) {
        long ptr = FindLongPattern(segStart, segLen, (BYTE*)hint, "xxxxxxxxx");
        if (ptr) {
            
            long page_size = sysconf(_SC_PAGESIZE);
            long page_start = ptr & -page_size;
            
            NSLog(@"Attempting Removing memory protection");
            if(mprotect((voidPtr)page_start, page_size, PROT_READ | PROT_WRITE) == 0){
            	
 NSLog(@"RSInjector: Bypassing signature check at %ld", ptr);
            memset((voidPtr)ptr, 0x90, 9);
            msync((voidPtr)ptr, 9, MS_SYNC);
            
            mprotect((voidPtr)page_start, page_size, PROT_READ | PROT_EXEC);
            }else{
                NSLog(@"Memory Operation failed: \nmprotect: %s\n", strerror(errno));
            }
        }
    }
}
*/

//unsigned long find_remote_image_load_address(mach_port_t task) {
//    unsigned long addr = 0;
//    kern_return_t kret;
//    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
//    struct task_dyld_info info;
//    struct dyld_all_image_infos* all_image_infos;
//    struct dyld_image_info* image_info;
//    pointer_t buffer_pointer;
//    uint32_t sz;
//
//    kret = task_info(task, TASK_DYLD_INFO, (task_info_t)&info, &count);
//    if (kret != KERN_SUCCESS) {
//        printf("task_info() failed, error %d - %s\n", kret, mach_error_string(kret));
//        exit(10);
//    }
//
//    kret = vm_read(task, info.all_image_info_addr, info.all_image_info_size, &buffer_pointer,  &sz);
//    if (kret != KERN_SUCCESS) {
//        printf("vm_read() failed, error %d -> %s\n", kret, mach_error_string(kret));
//        exit(11);
//    }
//    all_image_infos = (struct dyld_all_image_infos*)malloc(sz);
//    if (all_image_infos == NULL) {
//        printf("malloc(0x%lx) failed", (unsigned long)sz);
//        exit(12);
//    }
//    memcpy(all_image_infos, (const void*)buffer_pointer, sz);
//
//
//    kret = vm_read(task, (vm_address_t)all_image_infos->infoArray, sizeof(struct dyld_image_info) * all_image_infos->infoArrayCount, &buffer_pointer,  &sz);
//    if (kret != KERN_SUCCESS) {
//        printf("vm_read() failed, error %d -> %s\n", kret, mach_error_string(kret));
//        exit(13);
//    }
//    image_info = (struct dyld_image_info*)malloc(sz);
//    if (image_info == NULL) {
//        printf("malloc(0x%lx) failed", (unsigned long)sz);
//        exit(14);
//    }
//    memcpy(image_info, (const void*)buffer_pointer, sz);
//
//    printf("image load address: %llX\n", (uint64_t)image_info->imageLoadAddress);
//
//    return (unsigned long)image_info->imageLoadAddress;
//}

/**
  There are hundreds of dylds.  Can't just check the first one.
  Refactored this to return the mach headers of all dyld with the word "Rocksmith" in the path.
 */
NSMutableArray *find_image_load_addresses(void) {
    kern_return_t kret;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    struct task_dyld_info info;
    struct dyld_all_image_infos* all_image_infos;
    struct dyld_image_info image_info;
    mach_port_t task = mach_task_self();
    NSMutableArray *addresses = [NSMutableArray arrayWithCapacity:5];
    
    kret = task_info(task, TASK_DYLD_INFO, (task_info_t)&info, &count);
    if (kret != KERN_SUCCESS) {
        printf("task_info() failed, error %d - %s\n", kret, mach_error_string(kret));
        return 0;
    }
    
    all_image_infos = (struct dyld_all_image_infos*)info.all_image_info_addr;
    
    for (int i = 0 ; i < all_image_infos->infoArrayCount ; i++) {
        image_info = all_image_infos->infoArray[i];
        char *found = strstr(image_info.imageFilePath, "Rocksmith");
        
        if (found) {
            const struct mach_header *address = image_info.imageLoadAddress;
//            printf("address: %p\n", address);
            NSValue *value = [NSValue valueWithPointer:address];
            [addresses addObject:value];
        }
    }
    
    return addresses;
}

//@implementation RSBypass
//+(void)load
//{
////    NSLog(@"RSBypass: load()");
//
//    void* ptr = FindPattern(find_image_load_address()  + 0x1510, segLen,
//                            (BYTE*)hint, "xxxxxxxx");
//    if (ptr) {
//
//        long page_size = sysconf(_SC_PAGESIZE);
//        void* page_start = (long)ptr & -page_size;
//
////        NSLog(@"Removing memory protection");
//        mprotect(page_start, page_size, PROT_READ | PROT_WRITE | PROT_EXEC);
//
////        NSLog(@"RSInjector: Bypassing signature check at %p", ptr);
//        memset(ptr, 0x90, 8);
//        msync(ptr, 8, MS_SYNC);
//
//        // Restoring memory protection
//        mprotect(page_start, page_size, PROT_READ | PROT_EXEC);
//
//    }
//}
@end
