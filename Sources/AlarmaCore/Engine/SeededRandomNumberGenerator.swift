import Foundation

/// A deterministic 64-bit pseudo-random number generator implementing SplitMix64.
/// Conforms to Swift standard library `RandomNumberGenerator` and `Sendable`.
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Equatable, Sendable {
    private var state: UInt64

    /// Initializes the generator with a specific 64-bit seed.
    /// Any seed value (including 0 and UInt64.max) is valid.
    public init(seed: UInt64) {
        self.state = seed
    }

    /// Generates the next pseudo-random 64-bit unsigned integer.
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z: UInt64 = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
