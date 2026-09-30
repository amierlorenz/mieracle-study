import Foundation
import SwiftData

/// A saved session configuration, such as "CS 101 Exam 2 mix".
@Model
public final class SessionPreset {
    public var name: String = ""
    /// JSON-encoded session configuration, kept as data so the configuration
    /// type can evolve without a schema change.
    public var configData: Data = Data()
    public var createdAt: Date = Date.now

    public init(name: String, configData: Data) {
        self.name = name
        self.configData = configData
    }
}

/// A completed or in-progress study session.
@Model
public final class StudySession {
    public var sessionID: UUID = UUID()
    public var startedAt: Date = Date.now
    public var endedAt: Date?
    public var configData: Data = Data()
    public var reflection: String?

    public init(sessionID: UUID = UUID(), startedAt: Date = .now, configData: Data) {
        self.sessionID = sessionID
        self.startedAt = startedAt
        self.configData = configData
    }
}
