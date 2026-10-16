//
// Created by Artur Twardzik on 24/01/2026.
//

#ifndef OS_SPI_H
#define OS_SPI_H

#include <stdint.h>

void spi_init(uint32_t prescaler, uint32_t post_divider, uint32_t operating_mode);

void spi_set_baudrate(uint32_t prescaller, uint32_t post_divider);

uint32_t spi_tx_rx(uint16_t data);

#endif // OS_SPI_H
