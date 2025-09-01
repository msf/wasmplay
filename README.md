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

# Clean builds
make clean
```

## Performance Notes

- **Best Performance**: C++ WASM via WasmEdge JIT (~12k ops/sec)
- **Go Native**: ~4.7k ops/sec baseline
- **Optimization**: Go uses GOAMD64=v4 (AVX-512) when available
- **Security**: C++ builds use OpenSSF hardened compiler flags