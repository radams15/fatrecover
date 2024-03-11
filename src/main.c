#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

struct DirectoryEntry {
    union {
        struct {
            uint8_t name[8];
            uint8_t ext[3];
        };
        uint8_t fullname[11];
    };
    uint8_t reserved;
    uint8_t attrib;
    uint8_t userattrib;

    uint16_t createtime;
    uint16_t createdate;
    uint16_t accessdate;
    uint16_t clusterhigh;

    uint16_t modifiedtime;
    uint16_t modifieddate;
    uint16_t cluster;
    uint16_t filesize[2];
} __attribute__((packed));

int main(int argc, char** argv) {
    const char *memblock;
    int fd;
    struct stat sb;

    fd = open("test.img", O_RDONLY);
    fstat(fd, &sb);
    printf("Size: %lu\n", (uint64_t)sb.st_size);

    memblock = mmap(NULL, sb.st_size, PROT_WRITE, MAP_PRIVATE, fd, 0);
    if (memblock == MAP_FAILED){
        fprintf(stderr, "Failed: mmap\n");
        return 1;
    }


    int addr = 0x204000 + sizeof(struct DirectoryEntry);

    for(int i=0 ; i<8 ; i++) {
        struct DirectoryEntry* dirent = &memblock[addr];
        addr += sizeof(struct DirectoryEntry);

        if(dirent->cluster == 0)
            continue;

        if(dirent->fullname[0] == 0xe5)
            printf("Deleted: ");
        printf("%s 0=%x\n", dirent->fullname, dirent->fullname[0]);
    }

    printf("\n");
    return 0;
}
