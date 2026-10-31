import Foundation

/// Protocol defining the interface for generating math challenge problems.
public protocol MathProblemGenerating: Sendable {
    func generateProblem(difficulty: ChallengeDifficulty) -> MathProblem
    func generateProblem<R: RandomNumberGenerator>(difficulty: ChallengeDifficulty, using rng: inout R) -> MathProblem
}

public extension MathProblemGenerating {
    func generateProblem(difficulty: ChallengeDifficulty) -> MathProblem {
        var systemRNG = SystemRandomNumberGenerator()
        return generateProblem(difficulty: difficulty, using: &systemRNG)
    }
}

/// Default production generator creating random math problems adhering to difficulty invariants.
public struct DefaultMathProblemGenerator: MathProblemGenerating, Sendable {

    public init() {}

    public func generateProblem<R: RandomNumberGenerator>(
        difficulty: ChallengeDifficulty,
        using rng: inout R
    ) -> MathProblem {
        switch difficulty {
        case .easy:
            return generateEasyProblem(using: &rng)
        case .medium:
            return generateMediumProblem(using: &rng)
        case .hard:
            return generateHardProblem(using: &rng)
        }
    }

    // MARK: - Easy Generation

    private func generateEasyProblem<R: RandomNumberGenerator>(using rng: inout R) -> MathProblem {
        let isAddition = Bool.random(using: &rng)
        if isAddition {
            let a = Int.random(in: 1...20, using: &rng)
            let b = Int.random(in: 1...20, using: &rng)
            return MathProblem(
                expression: "\(a) + \(b)",
                solution: a + b,
                difficulty: .easy
            )
        } else {
            // Guarantee non-negative subtraction: a >= b
            let a = Int.random(in: 2...25, using: &rng)
            let b = Int.random(in: 1...a, using: &rng)
            return MathProblem(
                expression: "\(a) - \(b)",
                solution: a - b,
                difficulty: .easy
            )
        }
    }

    // MARK: - Medium Generation

    private func generateMediumProblem<R: RandomNumberGenerator>(using rng: inout R) -> MathProblem {
        let opChoice = Int.random(in: 0..<3, using: &rng)
        switch opChoice {
        case 0:
            // Addition with 2-digit numbers
            let a = Int.random(in: 10...99, using: &rng)
            let b = Int.random(in: 10...99, using: &rng)
            return MathProblem(
                expression: "\(a) + \(b)",
                solution: a + b,
                difficulty: .medium
            )
        case 1:
            // Subtraction with 2-digit numbers (guaranteed non-negative)
            let a = Int.random(in: 20...99, using: &rng)
            let b = Int.random(in: 10...a, using: &rng)
            return MathProblem(
                expression: "\(a) - \(b)",
                solution: a - b,
                difficulty: .medium
            )
        default:
            // Multiplication
            let subType = Bool.random(using: &rng)
            let a: Int
            let b: Int
            if subType {
                // Times tables up to 12
                a = Int.random(in: 3...12, using: &rng)
                b = Int.random(in: 3...12, using: &rng)
            } else {
                // Single digit x 2-digit (11...20)
                a = Int.random(in: 2...9, using: &rng)
                b = Int.random(in: 11...20, using: &rng)
            }
            return MathProblem(
                expression: "\(a) × \(b)",
                solution: a * b,
                difficulty: .medium
            )
        }
    }

    // MARK: - Hard Generation

    private func generateHardProblem<R: RandomNumberGenerator>(using rng: inout R) -> MathProblem {
        let category = Int.random(in: 0..<4, using: &rng)
        switch category {
        case 0:
            // Exact integer division: a = b * q -> a ÷ b = q (remainder 0)
            let b = Int.random(in: 2...15, using: &rng) // Divisor (strictly non-zero)
            let q = Int.random(in: 2...20, using: &rng) // Quotient
            let a = b * q                              // Dividend
            return MathProblem(
                expression: "\(a) ÷ \(b)",
                solution: q,
                difficulty: .hard
            )

        case 1:
            // Advanced multiplication
            let a = Int.random(in: 12...35, using: &rng)
            let b = Int.random(in: 4...16, using: &rng)
            return MathProblem(
                expression: "\(a) × \(b)",
                solution: a * b,
                difficulty: .hard
            )

        case 2:
            // Multi-step with parentheses: (a + b) × c or (a - b) × c
            let isAdd = Bool.random(using: &rng)
            let c = Int.random(in: 2...8, using: &rng)
            if isAdd {
                let a = Int.random(in: 4...20, using: &rng)
                let b = Int.random(in: 4...20, using: &rng)
                return MathProblem(
                    expression: "(\(a) + \(b)) × \(c)",
                    solution: (a + b) * c,
                    difficulty: .hard
                )
            } else {
                let a = Int.random(in: 10...30, using: &rng)
                let b = Int.random(in: 2...(a - 1), using: &rng)
                return MathProblem(
                    expression: "(\(a) - \(b)) × \(c)",
                    solution: (a - b) * c,
                    difficulty: .hard
                )
            }

        default:
            // Multi-step order of operations: a × b + c or a + b × c
            let variant = Bool.random(using: &rng)
            if variant {
                let a = Int.random(in: 4...12, using: &rng)
                let b = Int.random(in: 3...12, using: &rng)
                let c = Int.random(in: 10...50, using: &rng)
                return MathProblem(
                    expression: "\(a) × \(b) + \(c)",
                    solution: (a * b) + c,
                    difficulty: .hard
                )
            } else {
                let a = Int.random(in: 10...50, using: &rng)
                let b = Int.random(in: 3...12, using: &rng)
                let c = Int.random(in: 3...12, using: &rng)
                return MathProblem(
                    expression: "\(a) + \(b) × \(c)",
                    solution: a + (b * c),
                    difficulty: .hard
                )
            }
        }
    }
}
