import Foundation

struct MessageEnvelope: Codable, Sendable {
    let type: String
    let payload: Data
}

struct ButtonTapPayload: Codable, Sendable {
    let buttonIndex: Int
    let timestamp: Double
}

struct AppContextPayload: Codable, Sendable {
    let appName: String
    let bundleId: String
    let iconData: Data?
    let buttonLabels: [String]?
}
