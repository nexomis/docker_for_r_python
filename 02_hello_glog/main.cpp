// main.c
#include "hello.h"
#include <glog/logging.h>

int main(int argc, char* argv[]) {
    // Initialize Google’s logging library.
    google::InitGoogleLogging(argv[0]);

    // Ensures log messages are also sent to stderr.
    FLAGS_logtostderr = 1;

    // Call the print_hello function from hello.cpp
    print_hello();

    return 0;
}
