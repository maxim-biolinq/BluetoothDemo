// Requests.swift

import Foundation
import SwiftProtobuf

// MARK: - Command Processing Extension

public extension PeripheralCommand {

    func data(seqNum: UInt32) throws -> CommandData {
        switch self {
        case .requestInfo:
            return try Self.processInfoRequest(seqNum: seqNum)
        case .getEDataRange(let startIndex, let endIndex):
            return try Self.processEDataRangeRequest(startIndex: startIndex, endIndex: endIndex, seqNum: seqNum)
        }
    }

    // MARK: - Info Command Implementation

    private static func processInfoRequest(seqNum: UInt32) throws -> CommandData {
        var bleMessage = Iris_BLEMessage()
        bleMessage.seqNum = seqNum
        bleMessage.rspNum = 0  // placeholder
        bleMessage.crc32 = 0   // placeholder
        bleMessage.infoRequest = Iris_InfoRequest()

        let data = try bleMessage.serializedData()
        print("Commands: Prepared info request (seq: \(seqNum))")

        return CommandData(data: data, seqNum: seqNum, command: .requestInfo)
    }

    // MARK: - EData Block Command Implementation

    // MARK: - EData Range Command Implementation

    private static func processEDataRangeRequest(startIndex: UInt32, endIndex: UInt32, seqNum: UInt32) throws -> CommandData {
        var bleMessage = Iris_BLEMessage()
        bleMessage.seqNum = seqNum
        bleMessage.rspNum = 0  // placeholder
        bleMessage.crc32 = 0   // placeholder

        var eDataBlockRequest = Iris_EDataBlockRequest()
        eDataBlockRequest.startIndex = startIndex
        eDataBlockRequest.endIndex = endIndex
        bleMessage.eDataBlockRequest = eDataBlockRequest

        let data = try bleMessage.serializedData()
        print("Commands: Prepared eDataBlock range request for blocks \(startIndex)-\(endIndex) (seq: \(seqNum))")

        return CommandData(data: data, seqNum: seqNum, command: .getEDataRange(startIndex: startIndex, endIndex: endIndex))
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
