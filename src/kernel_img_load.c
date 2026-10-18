//
// Created by Artur Twardzik on 16/10/2026.
//

#include <stdint.h>

extern uint8_t __stack_start__[];
extern uint8_t __stack_end__[];

static uint8_t *const reserved_start = __stack_start__;
static uint8_t *const reserved_end = __stack_end__;

struct FAT16_BootRecord {
        uint8_t jump_code[3];
        const char oem_name[8];
        uint16_t bytes_per_sector;
        uint8_t sectors_per_cluster;
        uint16_t reserved_sectors;
        uint8_t FAT_copies;
        uint16_t max_root_dentries;
        uint16_t small_part_sectors_count;
        uint8_t media_descriptor;
        uint16_t sectors_per_FAT;
        uint16_t sectors_per_track;
        uint16_t heads_count;
        uint32_t hidden_sectors;
        uint32_t large_part_sectors_count;
        uint16_t drive_number;
        uint8_t extended_boot_signature;
        uint32_t volume_serial_number;
        const char volume_label[11];
        const char fs_type[8];
        uint8_t bootstrap_code[448];
        uint8_t boot_sector_signature;
} __attribute__((packed));

struct FAT16_DirectoryEntry {
        char filename[8];
        char extension[3];
        uint8_t attributes;
        uint8_t _reserved1;
        uint8_t c_milis;
        uint16_t c_time;
        uint16_t c_date;
        uint16_t a_time;
        uint16_t _reserved2;
        uint16_t m_time;
        uint16_t m_date;
        uint16_t first_cluster;
        uint32_t file_size;
} __attribute__((packed));

extern int sd_card_read512_block(const uint32_t block_number, char *buffer);

static constexpr char kernel_name[11] = {'K', 'E', 'R', 'N', 'E', 'L', 0x20, 0x20, 'I', 'M', 'G'};

static constexpr char file_system_type[8] = {'F', 'A', 'T', '1', '6', 0x20, 0x20, 0x20};


static char toupper(char c) {
        if (c >= 'a' && c <= 'z') {
                return c - 32;
        }

        return c;
}

static bool str_match(const char *s, const char *ref, int len) {
        for (int i = 0; i < len; ++i) {
                if (toupper(s[i]) != ref[i]) {
                        return false;
                }
        }

        return true;
}

void *load_img(const struct FAT16_BootRecord *boot_record, const uint32_t first_block) {
        if (boot_record->bytes_per_sector != 512 || !str_match(boot_record->fs_type, file_system_type, 8)) {
                return (void *) -1;
        }
        const uint32_t fat_base_sector = first_block + boot_record->reserved_sectors;
        const uint32_t root_base_sector = fat_base_sector
                                          + boot_record->FAT_copies * boot_record->sectors_per_FAT;
        const uint32_t data_region_base_sector = root_base_sector
                                                 + boot_record->max_root_dentries * 32 / 512;


        struct FAT16_DirectoryEntry dentries[16];
        sd_card_read512_block(root_base_sector, (char *) dentries);

        int i = 0;
        for (i = 0; i < 16; ++i) {
                if (str_match(dentries[i].filename, kernel_name, 11)) {
                        break;
                }
        }

        if (i >= 16) {
                return (void *) -2;
        }


        uint16_t fat[256];
        sd_card_read512_block(fat_base_sector, (char *) fat);
        uint16_t fat_cached_sector = 0;

        auto code_base = (void *) 0x2000'0000;
        uint32_t code_offset = 0;
        uint16_t cluster = dentries[i].first_cluster;
        while (cluster >= 3 && cluster < 0xfff0) {
                const uint16_t current_cluster_FAT_sector = cluster / 256;
                const uint16_t current_cluster_position_in_FAT_sector = cluster % 256;
                if (current_cluster_FAT_sector > fat_cached_sector) {
                        sd_card_read512_block(fat_base_sector + current_cluster_FAT_sector, (char *) fat);
                        fat_cached_sector = current_cluster_FAT_sector;
                }

                const uint16_t physical_sector = data_region_base_sector +
                                                 (cluster - 2) * boot_record->sectors_per_cluster;
                for (int j = 0; j < boot_record->sectors_per_cluster; ++j) {
                        const uint8_t *dest = (uint8_t *) code_base + code_offset;
                        if (dest + 512 < reserved_start || dest > reserved_end) {
                                sd_card_read512_block(physical_sector + j, (char *) code_base + code_offset);
                        }
                        code_offset += 512;
                }

                cluster = fat[current_cluster_position_in_FAT_sector];
        }

        return code_base;
}
