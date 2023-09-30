#include <sys/mman.h>
#include <mach/mach.h>

#import "RSBypass.h"

// Added for find_remote_image_load_address
#include <mach-o/dyld_images.h>
#include <mach-o/dyld.h>
#include <mach/mach_vm.h>


//function prototype definition
uint64_t find_image_load_address(void);
uint64_t find_segment_length(uint64_t segment_address);


typedef uint64_t DWORD;
typedef int8_t  BYTE;



// Mac OS 64 Bit
// These numbers come from otool -lv
// const DWORD  segStart = 0x001000;
// const size_t segLen   = 0x013ce000;
//const size_t segLen   = 0x013CE9BC1;

// Could be made more general to bypass all signature checks
// including ini files...
// For the time being only patches the sig verif of sng files
// const char*  hint     = "\x0f\x84\xc6\x0a\x00\x00";
// const char*  hint     = "\x84\xdb\x0f\x84\xde\x0a\x00\x00";
const char*  hint     = "\x45\x84\xF6\x0F\x84\xCF\x0A\x00\x00";


bool bCompare(const BYTE* pData, const BYTE * bMask, const char* szMask) {
    for (; *szMask; ++szMask, ++pData, ++bMask) {
        if (*szMask == 'x' && *pData != *bMask) {
            return 0;
        }
    }
    return (*szMask) == 0;
}

void* FindPattern(DWORD dwAddress, size_t dwLen, BYTE* bMask, char* szMask) {
    for (DWORD i = 0; i < dwLen; i++) {
        if (bCompare((BYTE*)(dwAddress + i), bMask, szMask)) {
            return (void*)(dwAddress + i);
        }
    }
    return NULL;
}

@implementation RSBypass
+(void)load
{
    NSLog(@"RSBypass: load()");
    
    uint64_t segment_address = find_image_load_address() + 0x1510;
    uint64_t segment_length = find_segment_length(segment_address);

    NSLog(@"Addr=%llu", segment_address);
    NSLog(@"SegmentLength=%llu", segment_address);
    
    if (segment_address) {

        void *ptr = FindPattern(segment_address, segment_length, (BYTE*)hint, "xxxxxxxxx");

        if (ptr) {
            
            long page_size = sysconf(_SC_PAGESIZE);
            NSLog(@"System Conf page size: %ld", page_size);
            void *page_start = (long)ptr & -page_size;
            
            NSLog(@"Attempting Removing memory protection");
            if(mprotect(page_start, page_size, PROT_READ | PROT_WRITE) == 0){
                NSLog(@"RSInjector: Bypassing signature check at %p", ptr);
                memset(ptr, 0x90, 9);
                msync(ptr, 9, MS_SYNC);
                
                NSLog(@"Resetting to read/execute");
                mprotect(page_start, page_size, PROT_READ | PROT_EXEC);
            }else{
                NSLog(@"Memory Operation failed: \nmprotect: %s\n", strerror(errno));
            }

        }
    }
}

uint64_t find_segment_length(uint64_t segment_address) {
  // Get the Mach header for the segment
    struct mach_header *mach_header_ptr = (struct mach_header *)segment_address;

  // Find the load command for the segment
  struct load_command *load_command_ptr = NULL;
  for (int i = 0; i < mach_header_ptr->ncmds; i++) {
    load_command_ptr = (struct load_command *)((uint64_t)mach_header_ptr + sizeof(struct mach_header) + i * sizeof( struct load_command));

    if (load_command_ptr->cmd == LC_SEGMENT) {
      // Found the load command for the segment
      break;
    }
  }

  if (load_command_ptr == NULL) {
    // Could not find the load command for the segment
    return 0;
  }

  // Get the segment length
  return load_command_ptr->cmdsize - sizeof(struct segment_command);
}

uint64_t find_image_load_address() {
    //uint64_t addr = 0; unused
    kern_return_t kret;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    struct task_dyld_info info;
    struct dyld_all_image_infos* all_image_infos;
    struct dyld_image_info* image_info;
    mach_port_t task = mach_task_self();

    kret = task_info(task, TASK_DYLD_INFO, (task_info_t)&info, &count);
    if (kret != KERN_SUCCESS) {
        // printf("task_info() failed, error %d - %s\n", kret, mach_error_string(kret));
        return 0;
    }
    all_image_infos = (struct dyld_all_image_infos*)info.all_image_info_addr;
    image_info = (struct dyld_image_info*)all_image_infos->aotInfoArray;

    return (uint64_t)image_info->imageLoadAddress;
}


@end
