#include <sys/mman.h>
#include <stdint.h>

int removeramlimits(uint64_t address,uint64_t length, int protection) {
return mprotect((void *)(address&0xFFFFFFFFFFFFF000),length,protection);
}
