# WASM Performance Benchmarks

Multi-language performance comparison framework for CPU-bound workloads across native and WebAssembly compilation targets.

## Benchmark

- **Algorithm**: 64x64 integer matrix multiplication with FNV-1a cryptographic hash
- **Workload**: 10,000 iterations of chained operations
- **CPU Pinning**: Uses `taskset` for stable benchmarking

## Dependencies

### Required
- **Go 1.24+** - `go version`
- **C++ Compiler** - GCC (`g++`) or Clang (`clang++`)
- **Zig** - `zig version` (0.13+)
- **Emscripten** - `em++ --version` (C++ to WASM compiler)

### WASM Runtimes
- **Wasmer** - `wasmer --version` (Cranelift/LLVM engines)
- **Wasmtime** - `wasmtime --version` (Mozilla reference)
- **WasmEdge** - `~/.wasmedge/bin/wasmedge --version` (fastest for C++ WASM)

### Installation
```bash
# Emscripten
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk && ./emsdk install latest && ./emsdk activate latest
source ./emsdk_env.sh

# WasmEdge
curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash

# Wasmer/Wasmtime
curl https://get.wasmer.io -sSfL | sh
curl https://wasmtime.dev/install.sh -sSfL | bash
```

## Usage

```bash
# Run all benchmarks
make bench-all

# Compare WASM runtimes
make bench-wasm-runtimes

# Individual targets
make bench-go          # Go native
make bench-cpp-opt     # C++ optimized (-march=native)
make bench-cpp-wasm    # C++ -> WASM
make bench-zig-all     # All Zig targets
make bench-zig-wasm    # Zig -> WASM

# Clean builds
make clean
```

## Performance Results

**Test Environment:**
- **CPU**: AMD Ryzen AI 9 HX 370 (12 cores, 24 threads, up to 5.16 GHz)
- **OS**: Ubuntu 24.04 (Linux 6.14.0-29-generic)
- **Pinned to**: Single core (CPU 0) for consistent benchmarking

Native performance (ops/sec):
- **C++ Optimized**: 49,279 ops/sec (best native)
- **Zig Optimized**: 15,386 ops/sec
- **C++ Standard**: 11,660 ops/sec
- **Zig Safe**: 9,169 ops/sec
- **Go Native**: 4,883 ops/sec

WASM performance (ops/sec):
- **Zig → WasmEdge**: 15,305 ops/sec (best WASM)
- **C++ → WasmEdge**: 11,855 ops/sec
- **C++ → Wasmer LLVM**: 11,160 ops/sec
- **C++ → Wasmtime**: 6,988 ops/sec
- **C++ → Wasmer Cranelift**: 6,911 ops/sec
- **Go → WasmEdge**: 3,230 ops/sec
- **Go → Wasmer LLVM**: 3,142 ops/sec
- **Go → Wasmtime**: 2,762 ops/sec
- **Go → Wasmer Cranelift**: 2,759 ops/sec

## Notes

- **Zig WASM** achieves remarkable performance, nearly matching C++ optimized native
- **WasmEdge JIT** consistently delivers the best WASM runtime performance
- **C++ with -march=native** shows massive speedup (4.2x over standard build)
- **Security**: C++ builds use OpenSSF hardened compiler flags