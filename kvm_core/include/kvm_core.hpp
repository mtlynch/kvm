// Copyright 2020 Christopher A. Taylor

/*
    Core tools used by multiple KVM sub-projects
*/

#pragma once

#include <cstdint>      // uint8_t etc types
#include <cstring>
#include <memory>       // std::unique_ptr, std::shared_ptr
#include <new>          // std::nothrow
#include <mutex>        // std::mutex
#include <vector>       // std::vector
#include <functional>   // std::function
#include <thread>       // std::thread
#include <string>

namespace kvm {


//------------------------------------------------------------------------------
// Constants

static const int kAppSuccess = 0;
static const int kAppFail = -1;


//------------------------------------------------------------------------------
// Portability Macros

#define CORE_ARRAY_COUNT(array) \
    static_cast<int>(sizeof(array) / sizeof(array[0]))

// Specify an intentionally unused variable (often a function parameter)
#define CORE_UNUSED(x) (void)(x);

// Compiler-specific debug break
#if defined(_DEBUG) || defined(DEBUG) || defined(CORE_DEBUG_IN_RELEASE)
    #define CORE_DEBUG
    #if defined(_WIN32)
        #define CORE_DEBUG_BREAK() __debugbreak()
    #else // _WIN32
        #define CORE_DEBUG_BREAK() __builtin_trap()
    #endif // _WIN32
    #define CORE_DEBUG_ASSERT(cond) { if (!(cond)) { CORE_DEBUG_BREAK(); } }
    #define CORE_IF_DEBUG(x) x;
#else // _DEBUG
    #define CORE_DEBUG_BREAK() ;
    #define CORE_DEBUG_ASSERT(cond) ;
    #define CORE_IF_DEBUG(x) ;
#endif // _DEBUG

// Compiler-specific force inline keyword
#if defined(_MSC_VER)
    #define CORE_INLINE inline __forceinline
#else // _MSC_VER
    #define CORE_INLINE inline __attribute__((always_inline))
#endif // _MSC_VER

// Compiler-specific align keyword
#if defined(_MSC_VER)
    #define CORE_ALIGNED(x) __declspec(align(x))
#else // _MSC_VER
    #define CORE_ALIGNED(x) __attribute__ ((aligned(x)))
#endif // _MSC_VER


//------------------------------------------------------------------------------
// C++ Convenience Classes

/// Calls the provided (lambda) function at the end of the current scope
class ScopedFunction
{
public:
    ScopedFunction(std::function<void()> func) {
        Func = func;
    }
    ~ScopedFunction() {
        if (Func) {
            Func();
        }
    }

    std::function<void()> Func;

    void Cancel() {
        Func = std::function<void()>();
    }
};

/// Join a std::shared_ptr<std::thread>
inline void JoinThread(std::shared_ptr<std::thread>& th)
{
    if (th) {
        try {
            if (th->joinable()) {
                th->join();
            }
        } catch (std::system_error& /*err*/) {}
        th = nullptr;
    }
}


//------------------------------------------------------------------------------
// High-resolution timers

/// Get time in microseconds
uint64_t GetTimeUsec();

/// Get time in milliseconds
uint64_t GetTimeMsec();


//------------------------------------------------------------------------------
// Thread Tools

/// Set the current thread name
void SetCurrentThreadName(const char* name);

/// Sleep for a number of milliseconds
void ThreadSleepForMsec(int msec);


//------------------------------------------------------------------------------
// String Conversion

/// Convert buffer to hex string
std::string HexDump(const uint8_t* data, int bytes);

/// Convert value to hex string
std::string HexString(uint64_t value);


//------------------------------------------------------------------------------
// Copy Strings

inline void SafeCopyCStr(char* dest, size_t destBytes, const char* src)
{
#if defined(_MSC_VER)
    ::strncpy_s(dest, destBytes, src, _TRUNCATE);
#else // _MSC_VER
    ::strncpy(dest, src, destBytes);
#endif // _MSC_VER
    // No null-character is implicitly appended at the end of destination
    dest[destBytes - 1] = '\0';
}


//------------------------------------------------------------------------------
// Aligned Allocation

uint8_t* AlignedAllocate(size_t size);
void AlignedFree(void* p);


//------------------------------------------------------------------------------
// Conversion to Base64

/// Get number of characters required to represent the given number of bytes.
/// Input of 0 will return 0.
int GetBase64LengthFromByteCount(int bytes);

/// Returns number of bytes (ASCII characters) written, or 0 for error.
/// Note that to disambiguate high zeros with padding bits, we use A to
/// represent high zero bits and = to pad out the output to a multiple of
/// 4 bytes.
int WriteBase64(
    const void* buffer,
    int bytes,
    char* encoded_buffer,
    int encoded_bytes);

/// This version writes a null-terminator.
int WriteBase64Str(
    const void* buffer,
    int bytes,
    char* encoded_buffer,
    int encoded_bytes);

std::string BinToBase64(const void* data, int bytes);


//------------------------------------------------------------------------------
// Conversion from Base64

/// Get number of original bytes represented by the encoded buffer.
/// This will be the number of data bytes written by ReadBase64().
int GetByteCountFromBase64(
    const char* encoded_buffer,
    int bytes);

/// Returns number of bytes written to decoded buffer.
/// Returns 0 on error.
/// Precondition: `decoded_buffer` contains enough bytes to represent the
/// original data.
/// At least GetByteCountFromBase64(encoded_buffer, encoded_bytes) bytes.
int ReadBase64(
    const char* encoded_buffer,
    int encoded_bytes,
    void* decoded_buffer);

void Base64ToBin(const std::string& base64, std::vector<uint8_t>& data);


} // namespace kvm
