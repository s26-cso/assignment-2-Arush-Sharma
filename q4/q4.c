#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

int main() {
    char op[10];
    int a, b;
    char lib_name[32];

    while (scanf("%s %d %d", op, &a, &b) != EOF) {
        // Construct the library name: "lib<op>.so"
        snprintf(lib_name, sizeof(lib_name), "./lib%s.so", op);

        // Open the shared library
        void *handle = dlopen(lib_name, RTLD_LAZY);
        if (!handle) {
            // If the library isn't found, skip and wait for next input
            continue;
        }

        // Define a function pointer type matching int func(int, int)
        typedef int (*operation_func)(int, int);
        
        // Find the symbol (function) with the name <op> inside the loaded library
        operation_func func = (operation_func) dlsym(handle, op);
        
        if (func) {
            // Execute the loaded function and print the result
            int result = func(a, b);
            printf("%d\n", result);
        }

        // Close the library immediately
        dlclose(handle);
    }

    return 0;
}
