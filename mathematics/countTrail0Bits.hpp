/* Compiled and tested on:
 * language: C++14
 * processor: TMS320C6748 */

#include <climits>
#include <type_traits>

/**
 * @brief Counts tail 0 bits in a given integer "x".
 *
 * @tparam T The type of the number, must be integer.
 * @param x "x"
 * @return the number of tail 0 bits in "x".
 */
template <typename T>
T countTail0Bits(T x) {
    static_assert(std::is_integral<T>::value, "T must be an integral type.");
    constexpr T numBits = static_cast<T>(sizeof(T)*CHAR_BIT);
    T count;
    for (int i=0; i<numBits; ++i) {
        if (x&0b01 != 0) {
            break;
        }
        x >>= 1;
        ++count;
    }
    return count;
}
