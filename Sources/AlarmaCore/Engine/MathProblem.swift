import Foundation

/// Detailed reason why an input string failed mathematical parsing.
public enum InvalidInputReason: String, Codable, Equatable, Sendable {
    case empty
    case nonNumeric
    case overflow
}

/// Rich evaluation outcome of a user's answer submission.
public enum MathEvaluationResult: Equatable, Sendable {
    case correct
    case incorrect(submitted: Int, expected: Int)
    case invalidInput(reason: InvalidInputReason)
}

/// An immutable mathematical challenge problem presented to deactivate an alarm.
public struct MathProblem: Identifiable, Hashable, Equatable, Codable, Sendable, CustomStringConvertible {
    public let id: UUID
    public let expression: String
    public let solution: Int
    public let difficulty: ChallengeDifficulty
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        expression: String,
        solution: Int,
        difficulty: ChallengeDifficulty,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.expression = expression
        self.solution = solution
        self.difficulty = difficulty
        self.createdAt = createdAt
    }

    public var description: String {
        "\(expression) = \(solution) [\(difficulty.rawValue)]"
    }

    /// Evaluates user input string, returning a boolean indicating if it is mathematically correct.
    /// Trims leading and trailing whitespace and newlines.
    public func validate(input: String) -> Bool {
        evaluate(input: input) == .correct
    }

    /// Evaluates user input string with detailed diagnostic information.
    public func evaluate(input: String) -> MathEvaluationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .invalidInput(reason: .empty)
        }

        guard let parsedValue = Int(trimmed) else {
            // Distinguish integer overflow from invalid non-numeric symbols
            let nonDigits = CharacterSet(charactersIn: "0123456789+-").inverted
            if trimmed.rangeOfCharacter(from: nonDigits) == nil && trimmed.count > 1 {
                return .invalidInput(reason: .overflow)
            }
            return .invalidInput(reason: .nonNumeric)
        }

        if parsedValue == solution {
            return .correct
        } else {
            return .incorrect(submitted: parsedValue, expected: solution)
        }
    }
}
