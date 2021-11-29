#include <cstddef>

/**
    * @brief Write a scalar value to the given address.
    * @details Let `t` be the target address and `v` be the source value.
    * The operation `t[i] = (v>>(i*8))&0xFF` is performed for `i=0,1, ..., sizeof(v)-1`
    *
    * @tparam T_dst the data type of destination buffer
    * @tparam T_src the data type of the source value
    * @param[out] addr the destination address
    * @param[in] val the source value
    * @param[in] srcSize The size of the source value. If 0, the size of the source value is determined by the type of the source value.
    */
template <typename T_dst, typename T_src>
static void putScalarToByteArray(T_dst *addr, const T_src val, const size_t srcSize=0) {
    char *addr2 = reinterpret_cast<char *>(addr);
    const size_t dataSize = (srcSize == 0) ? sizeof(T_src) : srcSize;
    for (size_t i = 0; i < dataSize; i++) {
        addr2[i] = (val >> (i * 8)) & 0xFF;
    }
}
