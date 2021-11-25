/**
 * @brief Write a scalar value to the given address.
 * @details Let `t` be the target address and `v` be the source value.
 * The operation `t[i] = (v>>(i*8))&0xFF` is performed for `i=0,1, ..., sizeof(v)-1`
 *
 * @tparam T_dst the data type of destination buffer
 * @tparam T_src the data type of the source value
 * @param[out] addr the destination address
 * @param[in] val the source value
 */
template <typename T_dst, typename T_src>
static void putScalarToByteArray(T_dst *addr, const T_src val) {
    char *addr2 = reinterpret_cast<char *>(addr);
    constexpr size_t dataSize = sizeof(T_src);
    for (size_t i = 0; i < dataSize; i++) {
        addr2[i] = (val >> (i * 8)) & 0xFF;
    }
}
