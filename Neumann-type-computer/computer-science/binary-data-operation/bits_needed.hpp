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
