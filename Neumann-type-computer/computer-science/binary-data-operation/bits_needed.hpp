#include <cstdint>
#include <type_traits>

/* Confirmed to work on C++23 */

template <typename T>
constexpr int flog2(const T x) {
    static_assert(std::is_integral<T>::value, "x must be integral type");
    return x == 1 ? 0 : 1+flog2(x >> 1);
}

template <typename T>
constexpr int clog2(const T x) {
    static_assert(std::is_integral<T>::value, "x must be integral type");
    return x == 1 ? 0 : flog2(x - 1) + 1;
}

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
