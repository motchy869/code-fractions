#include <cstdint>
#include <cstdlib>
#include <cstdio>
#include <type_traits>

/**
 * @brief Prints a given unsigned integer in binary format.
 *
 * @tparam T the type of the input unsigned integer value
 * @param[in] v the input unsigned integer value
 * @param[in] n the number of the LSB bits to display, default to `sizeof(T)*CHAR_BIT`
 * @param[in] withPrefix whether to add prefix "0b", default to `true`
 */
template <typename T>
void printb(T v, uint8_t n=sizeof(T)*CHAR_BIT, bool withPrefix=true) {
    static_assert(std::is_unsigned<T>(), "T must be unsigned integer");

    if (withPrefix) {
        printf("0b");
    }

    for (T mask = static_cast<T>(1) << (n-1); (mask!=0) && n>0; mask>>=1, --n) {
        putchar('0' + (0 != (mask & v)));
    }
}

int main() {
    constexpr uint8_t A = 123;
    printb(A);
    return EXIT_SUCCESS;
}
