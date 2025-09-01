#include <cstdint>
#include <cstdio>
#include <chrono>
#include <cinttypes>

// Constants matching Go version
constexpr int MatrixSize = 64;
constexpr int Iterations = 10000;

// FNV-1a hash for 64-bit values (matching Go implementation)
uint64_t fnv1a_hash64(const uint64_t data[MatrixSize][MatrixSize], uint64_t seed) {
    constexpr uint64_t fnv_prime64 = 1099511628211ULL;
    uint64_t hash = seed ^ 14695981039346656037ULL; // FNV offset basis XOR seed
    
    for (int i = 0; i < MatrixSize; i++) {
        for (int j = 0; j < MatrixSize; j++) {
            hash ^= data[i][j];
            hash *= fnv_prime64;
        }
    }
    return hash;
}

// Matrix multiply and hash (matching Go implementation)
uint64_t matmul_and_hash(uint64_t seed) {
    // Generate matrices from seed to prevent constant folding
    uint64_t a[MatrixSize][MatrixSize];
    uint64_t b[MatrixSize][MatrixSize];
    for (int i = 0; i < MatrixSize; i++) {
        for (int j = 0; j < MatrixSize; j++) {
            a[i][j] = seed ^ (uint64_t)(i * MatrixSize + j);
            b[i][j] = seed ^ (uint64_t)(i + j + 1);
        }
    }

    // Integer matrix multiply
    uint64_t c[MatrixSize][MatrixSize] = {};
    for (int i = 0; i < MatrixSize; i++) {
        for (int j = 0; j < MatrixSize; j++) {
            for (int k = 0; k < MatrixSize; k++) {
                c[i][j] += a[i][k] * b[k][j];
            }
        }
    }

    // FNV-1a hash of result matrix
    return fnv1a_hash64(c, seed);
}

int main() {
    auto start = std::chrono::steady_clock::now();
    uint64_t result = 5281;

    // Chain operations to prevent optimization
    for (int i = 0; i < Iterations; i++) {
        result = matmul_and_hash(result);
    }

    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);
    double seconds = static_cast<double>(duration.count()) / 1e9;

    printf("\n");
    printf("Matrix size: %dx%d\n", MatrixSize, MatrixSize);
    printf("Result: %" PRIu64 "\n", result);
    printf("Time: %gs\n", seconds);
    printf("Ops/sec: %.2f\n", Iterations / seconds);
    printf("Matrix ops/sec: %.0f\n", (double)Iterations * MatrixSize * MatrixSize * MatrixSize / seconds);
    printf("\n");

    return 0;
}
