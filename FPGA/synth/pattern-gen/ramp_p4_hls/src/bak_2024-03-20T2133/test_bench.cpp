#include "ramp_p4.hpp"

using namespace ramp_p4;

int main() {
    /*!< easy case */
    const InWavParam wavParam_0 = {
        .initVal = 0,
        .incVal = 3,
        .treadLen = 1,
        .numTreads = 12
    };

    /*!< hard case */
    const InWavParam wavParam_3 = {
        .initVal = 0,
        .incVal = 3,
        .treadLen = 3,
        .numTreads = 5
    };

    OutChunk chunk = {.chunkElemCnt=0, .chunk = {}};

    ramp_p4_hls_v0_1_0(wavParam_3, chunk);

    return EXIT_SUCCESS;
}
