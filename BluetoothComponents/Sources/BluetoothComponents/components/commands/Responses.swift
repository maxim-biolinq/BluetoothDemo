// Responses.swift

import Foundation

// MARK: - Response Processing Extension

public extension ParsedMessage {

    var response: CommandResponse? {
        switch self {
        case .infoResponse(let infoData, let seqNum):
            return Self.processInfoResponse(infoData, seqNum: seqNum)
        case .statusEvent:
            return nil // Status events don't correlate to specific commands
        }
    }

    // MARK: - Info Response Implementation

    private static func processInfoResponse(_ infoData: InfoResponseData, seqNum: UInt32) -> CommandResponse {
        print("Commands: InfoResponse (seq: \(seqNum)):")
        print("  num_blocks: \(infoData.numBlocks)")
        print("  timestamp: \(infoData.timestamp)")
        print("  status: \(infoData.status)")

        return .infoResponse(infoData)
    }
}

// MARK: - Future Response Handlers
// Add new response handlers here as simple static functions
// Example:
//
// private static func processStatusResponse(_ statusData: StatusResponseData, seqNum: UInt32) -> CommandResponse {
//     // Implementation here
// }
//
// No protocols, no boilerplate, just functions!
