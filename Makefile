# Benchmark suite for multi-language performance comparison
.PHONY: all bench clean bench-go bench-wasm build-go build-go-wasm help

# Default target
all: build-go build-go-wasm

# Build targets
build-go:
	@echo "Building native Go binary..."
	go build -o bench-go codegen.go

build-go-wasm:
	@echo "Building WASM binary..."
	GOOS=wasip1 GOARCH=wasm go build -o bench-go.wasm codegen.go

build-go-wasm-opt:
	@echo "Building optimized WASM binary..."
	GOOS=wasip1 GOARCH=wasm go build -ldflags="-s -w" -gcflags="-l=4" -o bench-go-opt.wasm codegen.go

# C++ Compiler and flags
CXX ?= g++
EMXX ?= em++

# Zig compiler
ZIG ?= zig

# Security-hardened CFLAGS from OpenSSF
CFLAGS_SECURITY = -Wall -Wformat -Wformat=2 -Wconversion -Wimplicit-fallthrough \
	-Werror=format-security \
	-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 \
	-D_GLIBCXX_ASSERTIONS \
	-fstrict-flex-arrays=3 \
	-fstack-clash-protection -fstack-protector-strong \
	-Wl,-z,nodlopen -Wl,-z,noexecstack \
	-Wl,-z,relro -Wl,-z,now \
	-Wl,--as-needed -Wl,--no-copy-dt-needed-entries

CXXFLAGS_DEFAULT = -std=c++20 -O2 $(CFLAGS_SECURITY)
CXXFLAGS_OPT = -std=c++20 -O3 -march=native -mtune=native -flto -DNDEBUG $(CFLAGS_SECURITY)

# C++ build targets
build-cpp:
	@echo "Building C++ binary..."
	$(CXX) $(CXXFLAGS_DEFAULT) -o bench-cpp benchmark.cpp

build-cpp-opt:
	@echo "Building optimized C++ binary..."
	$(CXX) $(CXXFLAGS_OPT) -o bench-cpp-opt benchmark.cpp

build-cpp-wasm:
	@echo "Building C++ -> WASM binary..."
	$(EMXX) -std=c++20 -O2 -o bench-cpp.wasm benchmark.cpp

# Zig build targets
build-zig:
	@echo "Building Zig binary (native backend)..."
	$(ZIG) build-exe -O ReleaseSafe benchmark.zig -femit-bin=bench-zig

build-zig-opt:
	@echo "Building optimized Zig binary (native backend)..."
	$(ZIG) build-exe -O ReleaseFast benchmark.zig -femit-bin=bench-zig-opt

build-zig-wasm:
	@echo "Building Zig -> WASM binary..."
	$(ZIG) build-exe -O ReleaseFast -target wasm32-wasi benchmark.zig -femit-bin=bench-zig.wasm

# CPU to pin to (change if needed)
CPU_PIN = 0

# 4 Core benchmark targets
bench-go: build-go
	@echo "=== Go Native ==="
	taskset -c $(CPU_PIN) ./bench-go

bench-go-wasm: build-go-wasm
	@echo "=== WASM (Wasmer) ==="
	taskset -c $(CPU_PIN) wasmer run bench-go.wasm

# C++ benchmark targets
bench-cpp: build-cpp
	@echo "=== C++ Native ==="
	taskset -c $(CPU_PIN) ./bench-cpp

bench-cpp-opt: build-cpp-opt
	@echo "=== C++ Native (Optimized) ==="
	taskset -c $(CPU_PIN) ./bench-cpp-opt

bench-cpp-wasm: build-cpp-wasm
	@echo "=== C++ -> WASM (Wasmer) ==="
	taskset -c $(CPU_PIN) wasmer run bench-cpp.wasm

bench-cpp-wasm-opt: build-cpp-wasm-opt
	@echo "=== C++ -> WASM Optimized (Wasmer) ==="
	taskset -c $(CPU_PIN) wasmer run --llvm bench-cpp-opt.wasm

# Zig benchmark targets
bench-zig: build-zig
	@echo "=== Zig Native ==="
	taskset -c $(CPU_PIN) ./bench-zig

bench-zig-opt: build-zig-opt
	@echo "=== Zig Native (Optimized) ==="
	taskset -c $(CPU_PIN) ./bench-zig-opt

bench-zig-wasm: build-zig-wasm
	@echo "=== Zig -> WASM (Wasmer) ==="
	taskset -c $(CPU_PIN) wasmer run bench-zig.wasm

# Run all Go benchmarks
bench-go-all: bench-go bench-go-wasm

# Run all C++ benchmarks  
bench-cpp-all: bench-cpp bench-cpp-opt bench-cpp-wasm

# Run all Zig benchmarks
bench-zig-all: bench-zig bench-zig-opt bench-zig-wasm

bench-wasm-all: bench-cpp-wasm bench-go-wasm bench-zig-wasm

# WASM runtime comparison targets
bench-wasm-runtimes: build-go-wasm build-cpp-wasm build-zig-wasm
	@for lang in go cpp zig; do \
		echo "=== WASM Runtime Comparison ($$lang) ==="; \
		wasm_file="bench-$$lang.wasm"; \
		echo "Wasmer Cranelift (default):"; \
		taskset -c $(CPU_PIN) wasmer run --cranelift $$wasm_file; \
		echo ""; \
		echo "Wasmer LLVM:"; \
		taskset -c $(CPU_PIN) wasmer run --llvm $$wasm_file; \
		echo ""; \
		echo "Wasmtime:"; \
		taskset -c $(CPU_PIN) wasmtime $$wasm_file; \
		echo ""; \
		echo "WasmEdge JIT:"; \
		taskset -c $(CPU_PIN) ~/.wasmedge/bin/wasmedge --enable-jit run $$wasm_file; \
		echo ""; \
	done

# Run all benchmarks (Go + C++ + Zig + WASM runtimes)
bench-all: bench-go-all bench-cpp-all bench-zig-all bench-wasm-runtimes

clean:
	rm -f bench-* *.wasm *.cwasm *.out

help:
	@echo "Available targets:"
	@echo "  bench-all           - Run all benchmarks (Go + C++ + WASM runtimes)"
	@echo "  bench-go-all        - Run Go benchmarks only"
	@echo "  bench-cpp-all       - Run C++ benchmarks only"
	@echo "  bench-wasm-runtimes - Compare WASM runtimes (Cranelift/LLVM/Wasmtime)"
	@echo ""
	@echo "Individual targets:"
	@echo "  bench-go       - Go native"
	@echo "  bench-wasm     - Go -> WASM"
	@echo "  bench-cpp      - C++ native (security hardened)"
	@echo "  bench-cpp-opt  - C++ native (optimized -march=native)"
	@echo "  bench-cpp-wasm - C++ -> WASM (Emscripten)"
	@echo ""
	@echo "Compiler options:"
	@echo "  CXX=clang++ make bench-cpp    - Use Clang instead of GCC"
	@echo "  CXX=clang++ make bench-cpp-opt - Use Clang with optimizations"
	@echo ""
	@echo "  clean          - Clean built files"
