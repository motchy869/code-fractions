#pragma once

#include <cstdint>

struct FwVersion {
	uint8_t major;
	uint8_t minor;
	uint8_t patch;

    uint16_t compactExpression() const {
        return (major << 8) | (minor << 4) | patch;
    }
};
