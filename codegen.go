package main

import (
	"fmt"
	"time"
)

const (
	MatrixSize = 64    // Matrix dimensions (MatrixSize x MatrixSize)
	Iterations = 10000 // Number of benchmark iterations
)

//go:noinline
func matmulAndHash(seed uint64) uint64 {
	// Generate matrices from seed to prevent constant folding
	var a, b [MatrixSize][MatrixSize]uint64
	for i := 0; i < MatrixSize; i++ {
		for j := 0; j < MatrixSize; j++ {
			a[i][j] = seed ^ uint64(i*MatrixSize+j)
			b[i][j] = seed ^ uint64(i+j+1)
		}
	}

	// Integer matrix multiply
	var c [MatrixSize][MatrixSize]uint64
	for i := 0; i < MatrixSize; i++ {
		for j := 0; j < MatrixSize; j++ {
			for k := 0; k < MatrixSize; k++ {
				c[i][j] += a[i][k] * b[k][j]
			}
		}
	}

	// FNV-1a hash of result matrix
	return fnv1aHash64(c[:], seed)
}

// FNV-1a hash for 64-bit values
//
//go:noinline
func fnv1aHash64(data [][MatrixSize]uint64, seed uint64) uint64 {
	const fnvPrime64 = 1099511628211
	hash := seed ^ 14695981039346656037 // FNV offset basis XOR seed

	for i := 0; i < len(data); i++ {
		for j := 0; j < MatrixSize; j++ {
			hash ^= data[i][j]
			hash *= fnvPrime64
		}
	}
	return hash
}

func main() {
	start := time.Now()
	result := uint64(5281)

	// Chain operations to prevent optimization
	for i := 0; i < Iterations; i++ {
		result = matmulAndHash(result)
	}

	elapsed := time.Since(start)

	fmt.Println()
	fmt.Printf("Matrix size: %dx%d\n", MatrixSize, MatrixSize)
	fmt.Printf("Result: %d\n", result)
	fmt.Printf("Time: %v\n", elapsed)
	fmt.Printf("Ops/sec: %.2f\n", float64(Iterations)/elapsed.Seconds())
	fmt.Printf("Matrix ops/sec: %.0f\n", float64(Iterations*MatrixSize*MatrixSize*MatrixSize)/elapsed.Seconds())
	fmt.Println()
}
