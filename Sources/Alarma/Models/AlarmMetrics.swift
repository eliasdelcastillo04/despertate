import Foundation

public struct AlarmMetrics: Codable {
    public var totalAlarms: Int
    public var activeAlarms: Int
    public var averageWakeTimeString: String
    public var snoozeRatePercentage: Int
    public var consistencyScoreAverage: Int
    public var weeklyTrendPercentage: Double

    public init(
        totalAlarms: Int = 0,
        activeAlarms: Int = 0,
        averageWakeTimeString: String = "06:45",
        snoozeRatePercentage: Int = 12,
        consistencyScoreAverage: Int = 94,
        weeklyTrendPercentage: Double = 4.5
    ) {
        self.totalAlarms = totalAlarms
        self.activeAlarms = activeAlarms
        self.averageWakeTimeString = averageWakeTimeString
        self.snoozeRatePercentage = snoozeRatePercentage
        self.consistencyScoreAverage = consistencyScoreAverage
        self.weeklyTrendPercentage = weeklyTrendPercentage
    }
}
