/**
 * @brief Print formatted string in Vitis serial console via vsnprintf.
 * Floating point number is supported.
 *
 * @tparam N the temporary buffer size
 * @param[in] format
 * @param[in] ...
 */
template <size_t N=256>
void xil_printf_ext(const char *format, ...) {
    char buf[N];
    va_list args;
    va_start (args, format);
    vsnprintf(buf, N, format, args);
    va_end(args);
    xil_printf("%s", buf);
}
