/* Compiled and tested on:
 * language: C++14
 * processor: TMS320C6748 */

#include <climits>
#include <type_traits>

/**
 * @brief Sets given specific bits in a given target to a given source.
 * @details If the access range is out of the target bit field, nothing is done and simply returns the given targget.
 *
 * @tparam T1 the integer type of the target value
 * @tparam T2 the integer type of the source value
 * @param[in] dst target value
 * @param[in] src source value
 * @param[in] offset the offset of the target bits
 * @param[in] windowLen the number of the contiguous bits in the specific target bit range
 * @return a calculation result
 */
template <typename T1, typename T2>
T1 setBits(T1 dst, T2 src, unsigned int offset, unsigned int windowLen) {
    static_assert(std::is_integral<T1>::value && std::is_integral<T2>::value, "T1 and T2 must be integer type.");
    static_assert(sizeof(T1) >= sizeof(T2), "sizeof(T1) must be greater than or equal to sizeof(T2).");
    if (windowLen + offset > CHAR_BIT*sizeof(T1)) {
        return dst;
    }
    const T1 mask1 = ((1<<windowLen)-1)<<offset;
    const T1 mask2 = ~mask1;
    return (dst&mask2) | (src<<offset)&mask1;
}
