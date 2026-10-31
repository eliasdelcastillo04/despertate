import XCTest
@testable import AlarmaCore

final class MathProblemGeneratorTests: XCTestCase {
    let generator = DefaultMathProblemGenerator()

    func testSeededRNGDeterminism() {
        var rng1 = SeededRandomNumberGenerator(seed: 0xDEADBEEF)
        var rng2 = SeededRandomNumberGenerator(seed: 0xDEADBEEF)

        for _ in 0..<500 {
            XCTAssertEqual(rng1.next(), rng2.next(), "Identical seeds must yield identical sequences")
        }
    }

    func testSeededRNGZeroSeedIsValid() {
        var rng = SeededRandomNumberGenerator(seed: 0)
        let first = rng.next()
        let second = rng.next()
        XCTAssertNotEqual(first, 0)
        XCTAssertNotEqual(first, second)
    }

    func testEasyProblemsInvariants() {
        var rng = SeededRandomNumberGenerator(seed: 101)
        for _ in 0..<250 {
            let p = generator.generateProblem(difficulty: .easy, using: &rng)
            XCTAssertEqual(p.difficulty, .easy)
            XCTAssertGreaterThanOrEqual(p.solution, 0, "Easy problems must never have negative solutions: \(p)")
            XCTAssertTrue(
                p.expression.contains("+") || p.expression.contains("-"),
                "Easy problem must use + or -: \(p.expression)"
            )
        }
    }

    func testMediumProblemsInvariants() {
        var rng = SeededRandomNumberGenerator(seed: 202)
        var sawAdd = false
        var sawSub = false
        var sawMul = false

        for _ in 0..<300 {
            let p = generator.generateProblem(difficulty: .medium, using: &rng)
            XCTAssertEqual(p.difficulty, .medium)
            XCTAssertGreaterThanOrEqual(p.solution, 0)
            if p.expression.contains("+") { sawAdd = true }
            if p.expression.contains("-") { sawSub = true }
            if p.expression.contains("×") { sawMul = true }
        }

        XCTAssertTrue(sawAdd && sawSub && sawMul, "Medium must generate +, -, and × problems")
    }

    func testHardProblemsExactIntegerDivisionAndMultiStep() {
        var rng = SeededRandomNumberGenerator(seed: 303)
        var sawDiv = false
        var sawParens = false

        for _ in 0..<400 {
            let p = generator.generateProblem(difficulty: .hard, using: &rng)
            XCTAssertEqual(p.difficulty, .hard)
            XCTAssertGreaterThan(p.solution, 0)

            if p.expression.contains("÷") {
                sawDiv = true
                let parts = p.expression.components(separatedBy: " ÷ ")
                XCTAssertEqual(parts.count, 2)
                let dividend = Int(parts[0])!
                let divisor = Int(parts[1])!
                XCTAssertGreaterThan(divisor, 0, "Divisor must never be zero")
                XCTAssertEqual(dividend % divisor, 0, "Division must be exact with remainder 0")
                XCTAssertEqual(dividend / divisor, p.solution)
            }

            if p.expression.contains("(") {
                sawParens = true
            }
        }

        XCTAssertTrue(sawDiv, "Hard difficulty must include exact division problems")
        XCTAssertTrue(sawParens, "Hard difficulty must include parenthesized multi-step problems")
    }
}
