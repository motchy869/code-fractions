#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fcntl.h>
#include <signal.h>
#include <sys/mman.h>
#include <unistd.h>

namespace {
    volatile sig_atomic_t shouldExit = 0; // flag to indicate whether the program should exit
    const char *devFilePath_uio0 = "/dev/uio0"; // device file path for uio0
    const size_t size_uio0 = 0x10000; // region size of uio0

    struct __attribute__((__packed__)) Csr_axi_gpio_0 {
        struct __attribute__((__packed__)) LED {
            unsigned int B: 1;
            unsigned int G: 1;
            unsigned int R: 1;
        } LED;
    };

    /**
     * @brief Signal handler for SIGINT.
     *
     * @param[in] sigNo Signal number.
     */
    void sigIntHandler(const int sigNo __attribute__((unused))) {
        shouldExit = 1;
    }
}

int main(const int argc __attribute__((unused)), const char **argv __attribute__((unused))) {
    int fd_uio0; // file descriptor for uio0
    void *start_addr_uio0; // start address of uio0
    volatile Csr_axi_gpio_0 *csr_axi_gpio_0; // pointer to the CSR of axi_gpio_0

    if (signal(SIGINT, sigIntHandler) == SIG_ERR) {
        fprintf(stderr, "Failed to set signal handler for SIGINT.\n");
        return EXIT_FAILURE;
    }

    printf("This is an example using UIO to access the CSR in PL from PS.\n");

    /* Open the device file to access uio0. */
    fd_uio0 = open(devFilePath_uio0, O_RDWR | O_SYNC);
    if (fd_uio0 < 0) {
        fprintf(stderr, "Failed to open %s\n", devFilePath_uio0);
        return EXIT_FAILURE;
    }

    /* Map the uio0 to virtual address. */
    start_addr_uio0 = mmap(NULL, size_uio0, PROT_READ | PROT_WRITE, MAP_SHARED, fd_uio0, 0);
    if (start_addr_uio0 == MAP_FAILED) {
        fprintf(stderr, "Failed to map %s\n", devFilePath_uio0);
        close(fd_uio0);
        return EXIT_FAILURE;
    }

    csr_axi_gpio_0 = reinterpret_cast<volatile Csr_axi_gpio_0 *>(start_addr_uio0);

    for (uint8_t ledPtn=0; ;) {
        constexpr useconds_t blinkInterval = 1'000'000;
        constexpr useconds_t sigIntCheckInterval = 100'000;

        /* Set the LED pattern. */
        csr_axi_gpio_0->LED.R = (ledPtn & 0b001);
        csr_axi_gpio_0->LED.G = (ledPtn & 0b010) >> 1;
        csr_axi_gpio_0->LED.B = (ledPtn & 0b100) >> 2;

        /* Wait for the next time to set LED pattern. */
        for (int i=0; i<static_cast<int>(blinkInterval/sigIntCheckInterval); ++i) {
            usleep(sigIntCheckInterval);
            if (shouldExit) {
                break;
            }
        }

        /* Determine the next lightning pattern. */
        switch (ledPtn) {
            case 0b000:
                ledPtn = 0b001;
                break;
            case 0b001:
                ledPtn = 0b010;
                break;
            case 0b010:
                ledPtn = 0b100;
                break;
            case 0b100:
                ledPtn = 0b111;
                break;
            case 0b111:
                ledPtn = 0b000;
                break;
            default:
                fprintf(stderr, "Invalid LED pattern: %d, maybe a bug.\n", ledPtn);
                break;
        }

        if (shouldExit) {
            break;
        }
    }

    /* Turn off all LEDs. */
    csr_axi_gpio_0->LED.R = 0;
    csr_axi_gpio_0->LED.G = 0;
    csr_axi_gpio_0->LED.B = 0;

    return EXIT_SUCCESS;
};
