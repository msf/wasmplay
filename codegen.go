package main

import (
	"fmt"
	"time"
)

//go:noinline
func matmulAndHash(seed uint64) uint64 {
	// Generate matrices from seed to prevent constant folding
	var a, b [4][4]uint64
	for i := 0; i < 4; i++ {
		for j := 0; j < 4; j++ {
			a[i][j] = seed ^ uint64(i*4+j)
			b[i][j] = seed ^ uint64(i+j+1)
		}
	}

	// Integer matrix multiply 4x4
	var c [4][4]uint64
	for i := 0; i < 4; i++ {
		for j := 0; j < 4; j++ {
			for k := 0; k < 4; k++ {
				c[i][j] += a[i][k] * b[k][j]
			}
		}
	}

	// FNV-1a hash of result matrix
	return fnv1aHash64(c[:], seed)
}

// FNV-1a hash for 64-bit values
//go:noinline
func fnv1aHash64(data [][4]uint64, seed uint64) uint64 {
	const fnvPrime64 = 1099511628211
	hash := seed ^ 14695981039346656037 // FNV offset basis XOR seed
	
	for i := 0; i < len(data); i++ {
		for j := 0; j < 4; j++ {
			hash ^= data[i][j]
			hash *= fnvPrime64
		}
	}
	return hash
}

func main() {
	const iterations = 1000000 // Reduced since 64-bit operations are heavier

	start := time.Now()
	result := uint64(5281)

	// Chain operations to prevent optimization
	for i := 0; i < iterations; i++ {
		result = matmulAndHash(result)
	}

	elapsed := time.Since(start)

	fmt.Printf("Result: %d\n", result)
	fmt.Printf("Time: %v\n", elapsed)
	fmt.Printf("Ops/sec: %.0f\n", float64(iterations)/elapsed.Seconds())
}
