const std = @import("std");
const print = std.debug.print;

// Constants matching Go/C++ versions
const MatrixSize = 64;
const Iterations = 10000;

// FNV-1a hash for 64-bit values (matching Go/C++ implementation)
fn fnv1aHash64(data: [MatrixSize][MatrixSize]u64, seed: u64) u64 {
    const fnv_prime64: u64 = 1099511628211;
    var hash = seed ^ 14695981039346656037; // FNV offset basis XOR seed
    
    var i: usize = 0;
    while (i < MatrixSize) : (i += 1) {
        var j: usize = 0;
        while (j < MatrixSize) : (j += 1) {
            hash ^= data[i][j];
            hash *%= fnv_prime64;
        }
    }
    return hash;
}

// Matrix multiply and hash (matching Go/C++ implementation)
fn matmulAndHash(seed: u64) u64 {
    // Generate matrices from seed to prevent constant folding
    var a: [MatrixSize][MatrixSize]u64 = undefined;
    var b: [MatrixSize][MatrixSize]u64 = undefined;
    
    var i: usize = 0;
    while (i < MatrixSize) : (i += 1) {
        var j: usize = 0;
        while (j < MatrixSize) : (j += 1) {
            a[i][j] = seed ^ @as(u64, @intCast(i * MatrixSize + j));
            b[i][j] = seed ^ @as(u64, @intCast(i + j + 1));
        }
    }

    // Integer matrix multiply
    var c: [MatrixSize][MatrixSize]u64 = std.mem.zeroes([MatrixSize][MatrixSize]u64);
    i = 0;
    while (i < MatrixSize) : (i += 1) {
        var j: usize = 0;
        while (j < MatrixSize) : (j += 1) {
            var k: usize = 0;
            while (k < MatrixSize) : (k += 1) {
                c[i][j] +%= a[i][k] *% b[k][j];
            }
        }
    }

    // FNV-1a hash of result matrix
    return fnv1aHash64(c, seed);
}

pub fn main() void {
    const start = std.time.nanoTimestamp();
    var result: u64 = 5281;

    // Chain operations to prevent optimization
    var i: usize = 0;
    while (i < Iterations) : (i += 1) {
        result = matmulAndHash(result);
    }

    const end = std.time.nanoTimestamp();
    const duration = @as(f64, @floatFromInt(end - start));
    const seconds = duration / 1e9;

    print("\n", .{});
    print("Matrix size: {}x{}\n", .{ MatrixSize, MatrixSize });
    print("Result: {}\n", .{result});
    print("Time: {d:.6}s\n", .{seconds});
    print("Ops/sec: {d:.2}\n", .{@as(f64, @floatFromInt(Iterations)) / seconds});
    print("Matrix ops/sec: {d:.0}\n", .{@as(f64, @floatFromInt(Iterations * MatrixSize * MatrixSize * MatrixSize)) / seconds});
    print("\n", .{});
}