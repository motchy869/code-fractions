#include <array>

/**
 * @brief Return the data size in bytes of a "std::array<T, N>" object "array"
 *
 * @tparam T "T"
 * @tparam N "N"
 * @param[in] array array object
 * @return the data size in bytes
 */
template <typename T, std::size_t N>
constexpr size_t stdArrayDataSize(const std::array<T, N> &array) {
    return array.size()*sizeof(decltype(array[0]));
}
