// Compatibility shim for linking V8 libraries built with newer Visual Studio versions
// when using Visual Studio 2017. These symbols are internal to the MSVC runtime.

extern "C" {

// Required by V8 libraries built with VS 2019+ when linking with VS 2017
#ifdef _WIN64
    // Thread-local storage guard for dynamic initialization
    unsigned long long __tls_guard = 0;
    
    // Dynamic TLS initialization guard
    unsigned long long __dyn_tls_on_demand_init = 0;
#else
    // 32-bit versions
    unsigned int __tls_guard = 0;
    unsigned int __dyn_tls_on_demand_init = 0;
#endif

}
