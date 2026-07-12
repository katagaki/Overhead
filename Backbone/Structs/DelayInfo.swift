import Foundation

public struct DelayInfo: Codable {
    public let lineId: String
    public let delayMinutes: Int
    public let cause: String?
    public let updatedAt: Date

    public init(lineId: String, delayMinutes: Int, cause: String?, updatedAt: Date) {
        self.lineId = lineId
        self.delayMinutes = delayMinutes
        self.cause = cause
        self.updatedAt = updatedAt
    }

    public var isDelayed: Bool { delayMinutes > 0 }
}
