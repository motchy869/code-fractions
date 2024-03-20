#pragma once

#include <cstdint>
#include <type_traits>
#include <ap_int.h>

namespace ramp_p4 {
    /**
     * @brief Compute the number of bits required to represent a given non-negative integer `n`.
     *
     * @tparam T the type of the argument `n`. Must be an integral type.
     * @param[in] n the non-negative integer
     * @param[in] callDepth the depth of the recursive call. This parameter is used for internal computation. Default is 0.
     * @return constexpr uint8_t the number of bits required to represent `n`.
     */
    template <typename T>
    constexpr uint8_t requiredBits(const T n, const uint8_t callDepth = 0) {
        static_assert(std::is_integral<T>::value, "argument type must be an integer type.");
        if (n == 0) {
            return callDepth == 0 ? 1 : 0;
        }
        return 1 + requiredBits(n >> 1, callDepth + 1);
    }

    constexpr int P = 4; /*!< processing parallelism */
    constexpr int BW_CHUNK_ELEM_COUNT = requiredBits(P); /*!< bit-width of the number of the valid elements in chunks */
    constexpr int BW_VAL = 16; /*!< bit-width of output numeric value */
    constexpr int BW_SEQ_CONT = 16; /*!< bit-width of sequence control data: tread length and the number of steps */

    struct InWavParam {
        ap_uint<BW_VAL> initVal; /*!< initial term value */
        ap_uint<BW_VAL> incVal; /*!< Increment value. The (n+1)-th tread value is larger than the n-th tread value by this value. */
        ap_uint<BW_SEQ_CONT> treadLen; /*!< Tread length. When this value is less than 1, no chunk is output. */
        ap_uint<BW_SEQ_CONT> numTreads; /*!< The number of treads. When this value is less than 1, no chunk is output. */
    };

    struct OutChunk {
        ap_uint<BW_CHUNK_ELEM_COUNT> chunkElemCnt; /*!< The number of the valid elements in the chunk. This value is 4 except for the last chunk (can be less than 4). */
        ap_uint<BW_VAL> chunk[P]; /*!< output chunk */
    };
}

void ramp_p4_hls_v0_1_0(
    const ramp_p4::InWavParam &wavParam, /*!< Input waveform parameters */
    ramp_p4::OutChunk &chunk /*!< Output chunk */
);
