// Requests.swift

import Foundation
import SwiftProtobuf

// MARK: - Command Processing Extension

public extension PeripheralCommand {

    func data(seqNum: UInt32) throws -> CommandData {
        switch self {
        case .requestInfo:
            return try Self.processInfoRequest(seqNum: seqNum)
        }
    }

    // MARK: - Info Command Implementation

    private static func processInfoRequest(seqNum: UInt32) throws -> CommandData {
        var bleMessage = Iris_BLEMessage()
        bleMessage.seqNum = seqNum

        var rxMessage = Iris_BLEMessageChRx()
        var request = Iris_BLEMessageChRxRequest()
        request.info = Iris_InfoRequest()

        rxMessage.request = request
        bleMessage.rxMsg = rxMessage

        let data = try bleMessage.serializedData()
        print("Commands: Prepared info request (seq: \(seqNum))")

        return CommandData(data: data, seqNum: seqNum, command: .requestInfo)
    }
}

// MARK: - Future Commands



// MARK: - Future Commands
// Add new command implementations here as simple static functions
// Example:
//
// static func processStatusRequest(seqNum: UInt32) throws -> CommandData {
//     // Implementation here
// }
//
// No protocols, no boilerplate, just functions!
