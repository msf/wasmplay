# Benchmark suite for multi-language performance comparison
.PHONY: all bench clean bench-native bench-wasm build-native build-wasm help

# Default target
all: build-native build-wasm

# Build targets
build-native:
	@echo "Building native Go binary..."
	go build -o bench-native codegen.go

build-wasm:
	@echo "Building WASM binary..."
	GOOS=wasip1 GOARCH=wasm go build -o bench.wasm codegen.go

build-wasm-opt:
	@echo "Building optimized WASM binary..."
	GOOS=wasip1 GOARCH=wasm go build -ldflags="-s -w" -gcflags="-l=4" -o bench-opt.wasm codegen.go

# CPU to pin to (change if needed)
CPU_PIN = 0

# Benchmark targets
bench-native: build-native
	@echo "=== Native Go (AMD64) - CPU pinned ==="
	taskset -c $(CPU_PIN) ./bench-native

bench-wasm: build-wasm
	@echo "=== Go -> WASM (Wasmtime) - CPU pinned ==="
	taskset -c $(CPU_PIN) wasmtime bench.wasm

bench-wasm-wasmer: build-wasm
	@echo "=== Go -> WASM (Wasmer) - CPU pinned ==="
	taskset -c $(CPU_PIN) wasmer run bench.wasm

# Optimized Go -> WASM builds
bench-wasm-go-opt: build-wasm-opt
	@echo "=== Go Optimized -> WASM (Wasmtime) - CPU pinned ==="
	taskset -c $(CPU_PIN) wasmtime bench-opt.wasm

bench-wasm-go-opt-wasmer: build-wasm-opt
	@echo "=== Go Optimized -> WASM (Wasmer) - CPU pinned ==="
	taskset -c $(CPU_PIN) wasmer run bench-opt.wasm

# Run all benchmarks
bench: bench-native bench-wasm bench-wasm-wasmer

# Optimized variants (runtime optimizations)
bench-wasm-runtime-opt: build-wasm
	@echo "=== Go -> WASM (Wasmtime Runtime Optimized) - CPU pinned ==="
	taskset -c $(CPU_PIN) wasmtime -O opt-level=2 -O pooling-allocator=y bench.wasm

bench-go-opt:
	@echo "=== Native Go (Optimized) - CPU pinned ==="
	go build -ldflags="-s -w" -gcflags="-l=4" -o bench-native-opt codegen.go
	taskset -c $(CPU_PIN) ./bench-native-opt

# Extended benchmark suite
bench-all: bench bench-wasm-opt bench-go-opt

clean:
	rm -f bench-native bench-native-opt bench.wasm *.cwasm

help:
	@echo "Available targets:"
	@echo "  bench          - Run native + WASM benchmarks"
	@echo "  bench-native   - Run native Go benchmark"
	@echo "  bench-wasm     - Run WASM benchmark (Wasmtime)"
	@echo "  bench-wasm-wasmer - Run WASM benchmark (Wasmer)"
	@echo "  bench-wasm-opt - Run optimized WASM benchmark"
	@echo "  bench-go-opt   - Run optimized native Go benchmark"
	@echo "  bench-all      - Run all benchmark variants"
	@echo "  build-native   - Build native binary"
	@echo "  build-wasm     - Build WASM binary"
	@echo "  clean          - Clean built files"
