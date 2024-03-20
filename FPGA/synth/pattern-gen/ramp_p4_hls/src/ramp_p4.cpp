/**
 * @brief HLS approach to ramp_p4
 * Details of specification are described in RTL version.
 *
 * @author M.K.
 */

#include "ramp_p4.hpp"
#include "hls_print.h"

using namespace ramp_p4;

namespace {
    #ifndef __SYNTHESIS__
    void printChunk(const OutChunk &chunk) {
        printf("chunkElemCnt: %d\n", chunk.chunkElemCnt);
        printf("elems: ");
        for (int i=0; i<chunk.chunkElemCnt; ++i) {
            printf("%d ", chunk.chunk[i].to_int());
        }
        printf("\n");
    }
    #endif
}

void ramp_p4_hls_v0_1_0(
    const InWavParam &wavParam, /*!< Input waveform parameters */
    OutChunk &chunk /*!< Output chunk */
) {
    #pragma HLS interface mode=ap_none port=wavParam name=i_wav_param
    #pragma HLS interface mode=ap_fifo port=chunk name=o_chunk

    #pragma HLS stable variable=wavParam

    OutChunk chunkBuf = {.chunkElemCnt=0, .chunk = {}}; /*!< temporary buffer for the output chunk */

    /* Check input waveform parameters. */
    if (wavParam.numTreads < 1 || wavParam.treadLen < 1) {
        return;
    }

    ap_uint<BW_SEQ_CONT> treadIdx = 0; /*!< current tread index */
    ap_uint<BW_SEQ_CONT> intraTreadElemIdx = 0; /*!< current index of the element in the current tread */
    ap_uint<BW_VAL> currElemVal = wavParam.initVal; /*!< current element value */

    TREADS_LOOP: while (treadIdx < wavParam.numTreads) {
        CHUNK_LOOP: for (ap_uint<BW_CHUNK_ELEM_COUNT> intraChunkElemIdx=0; intraChunkElemIdx<P; ++intraChunkElemIdx) {
            #pragma HLS unroll factor=P
            #pragma HLS loop_flatten off
            #pragma HLS pipeline II=1

            chunkBuf.chunk[intraChunkElemIdx] = currElemVal;
            ++chunkBuf.chunkElemCnt;
            ++intraTreadElemIdx;

            if (intraTreadElemIdx == wavParam.treadLen) {
                ++treadIdx;
                intraTreadElemIdx = 0;
                currElemVal += wavParam.incVal;
                if (treadIdx == wavParam.numTreads) {
                    break;
                }
            }
        }
        #ifndef __SYNTHESIS__
            printChunk(chunkBuf);
        #endif
        chunk = chunkBuf;
        chunkBuf.chunkElemCnt = 0;
    }
}
