//
// Created by Artur Twardzik on 09/04/2026.
//

#include "gpio.h"
#include "spi.h"
#include "time.h"

#include <stddef.h>
#include <stdint.h>

static constexpr int SD_CS = 13;

static constexpr uint8_t CMD0 = 0;
static constexpr uint8_t CMD8 = 8;
static constexpr uint8_t CMD17 = 17;
static constexpr uint8_t CMD24 = 24;
static constexpr uint8_t CMD55 = 55;
static constexpr uint8_t CMD58 = 58;
static constexpr uint8_t ACMD41 = 41;


static void sd_write_cmd(uint8_t cmd, uint32_t argument, uint8_t crc) {
        spi_tx_rx(cmd | 0x40);

        spi_tx_rx((argument >> 24) & 0xff);
        spi_tx_rx((argument >> 16) & 0xff);
        spi_tx_rx((argument >> 8) & 0xff);
        spi_tx_rx(argument & 0xff);

        spi_tx_rx(crc | 0x01);
}

static uint8_t sd_read_res1(void) {
        uint8_t i = 0;
        uint8_t res1;

        // keep polling until actual data received
        while ((res1 = spi_tx_rx(0xff)) == 0xff) {
                i++;

                // if no data received for 8 bytes, break
                if (i > 8) {
                        break;
                }
        }

        return res1;
}


int sd_card_read512_block(const uint32_t block_number, char *buffer) {
        spi_tx_rx(0xff);
        clr_pin(SD_CS);

        sd_write_cmd(CMD17, block_number, 0);
        if (sd_read_res1() == 0xff) {
                return -1; // not read
        }

        while (spi_tx_rx(0xff) != 0xfe) {}

        for (int i = 0; i < 512; ++i) {
                buffer[i] = spi_tx_rx(0xff);
        }

        // ignore crc
        spi_tx_rx(0xff);
        spi_tx_rx(0xff);

        set_pin(SD_CS);

        return 0;
}

// FIXME: deassert CS on failure
int init_sd_card(void) {
        spi_set_baudrate(2, 191); // 150[MHz] / 2(1+191) = 390.625[kHz]

        // Power up
        set_pin(SD_CS);
        delay_ms(2);
        for (int i = 0; i < 10; ++i) { // 8 bits * 10 = 80 clock pulses
                spi_tx_rx(0xff);
        }

        // Reset into SPI mode
        clr_pin(SD_CS);
        spi_tx_rx(0xff);
        sd_write_cmd(CMD0, 0, 0x95);
        int i = 0;
        while (spi_tx_rx(0xff) != 0x01) {
                if (++i > 30) {
                        goto error_ret; // timeout
                }
        }

        // v2 card
        sd_write_cmd(CMD8, 0x000001AA, 0x86);
        i = 0;
        uint8_t r1 = 0xff;
        while ((r1 = spi_tx_rx(0xff)) == 0xff) {
                if (++i > 30) {
                        goto error_ret; // timeout
                }
        }
        if (r1 != 0x01) {
                goto error_ret; // not a valid v2 card
        }

        uint8_t r7[4];
        for (int j = 0; j < 4; ++j) {
                r7[j] = spi_tx_rx(0xff);
        }
        if (r7[2] != 0x01 || r7[3] != 0xAA) {
                goto error_ret; // bad echo
        }

        //
        i = 0;
        while (1) {
                spi_tx_rx(0xff);
                sd_write_cmd(CMD55, 0, 0x65);
                int k = 0;
                while (spi_tx_rx(0xff) == 0xff) {
                        if (++k > 30) {
                                goto error_ret; // timeout
                        }
                }

                spi_tx_rx(0xff);
                sd_write_cmd(ACMD41, 0x40000000, 0x77);
                k = 0;
                uint8_t acmd_r1 = 0xff;
                while ((acmd_r1 = spi_tx_rx(0xff)) == 0xff) {
                        if (++k > 30) {
                                goto error_ret; // timeout
                        }
                }

                if (acmd_r1 == 0x00) {
                        break; // card initialized
                }
                if (acmd_r1 != 0x01) {
                        goto error_ret;
                }

                if (++i > 100) {
                        goto error_ret; // timeout
                }
                delay_ms(10);
        }

        // read OCR, check CCS bit to confirm SDHC/SDXC
        spi_tx_rx(0xff);
        sd_write_cmd(CMD58, 0, 0xFD);

        i = 0;
        while (spi_tx_rx(0xff) != 0x00) {
                if (++i > 30) {
                        goto error_ret; // timeout
                }
        }

        uint8_t ocr[4];
        for (int j = 0; j < 4; ++j) {
                ocr[j] = spi_tx_rx(0xff);
        }

        if (!(ocr[0] & 0x80)) {
                goto error_ret; // power not up yet, shouldn't happen
        }

        bool is_sdhc = (ocr[0] & 0x40) != 0;

        set_pin(SD_CS);

        spi_set_baudrate(2, 3); // 150[MHz] / 2(1+3) = 18.75[MHz]


        return 0;

error_ret:
        set_pin(SD_CS);
        return -1;
}
