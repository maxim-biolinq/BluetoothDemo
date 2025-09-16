import Foundation
import SwiftProtobuf

// MARK: - Message Parser Utility
// Static utility for parsing BLE data
public struct MessageParser {

    public static func parse(_ data: Data) -> Result<ParsedMessage, ParsingError> {
        do {
            let bleMessage = try Iris_BLEMessage(serializedBytes: data)
            return parseMessage(bleMessage)
        } catch {
            return .failure(.deserializationFailed(error))
        }
    }

    // MARK: - Private Parsing Logic

    private static func parseMessage(_ bleMessage: Iris_BLEMessage) -> Result<ParsedMessage, ParsingError> {
        let seqNum = bleMessage.seqNum

        // Check which message type is present using the new flat structure
        switch bleMessage.msg {
        case .infoResponse(let info):
            let infoData = InfoResponseData(
                numBlocks: info.eDataBlockCount,
                timestamp: info.timestamp,
                status: statusToString(info.status)
            )
            return .success(.infoResponse(infoData, seqNum: seqNum))

        case .eDataBlockResponse(let eDataBlock):
            let eDataBlockData = EDataBlockResponseData(index: eDataBlock.index, blockData: eDataBlock.data)
            return .success(.eDataBlockResponse(eDataBlockData, seqNum: seqNum))

        case .statusEvent(let statusEvent):
            return .success(.statusEvent(statusToString(statusEvent.status), seqNum: seqNum))

        case .none:
            return .failure(.emptyMessage)

        // Ignore request and command messages (we only process responses and events)
        case .infoRequest, .eDataBlockRequest, .startSensorCommand:
            return .failure(.unexpectedMessage)
        }
    }

    private static func statusToString(_ status: Iris_Status) -> String {
        switch status {
        case .unspecified:
            return "unspecified"
        case .ok:
            return "ok"
        case .error:
            return "error"
        case .UNRECOGNIZED(let code):
            return "unrecognized(\(code))"
        }
    }
}

// MARK: - Public Data Types

public enum ParsedMessage {
    case infoResponse(InfoResponseData, seqNum: UInt32)
    case eDataBlockResponse(EDataBlockResponseData, seqNum: UInt32)
    case statusEvent(String, seqNum: UInt32)

    public var seqNum: UInt32 {
        switch self {
        case .infoResponse(_, let seqNum), .eDataBlockResponse(_, let seqNum), .statusEvent(_, let seqNum):
            return seqNum
        }
    }
}

public enum ParsingError: Error {
    case deserializationFailed(Error)
    case unexpectedMessage
    case emptyMessage

    public var localizedDescription: String {
        switch self {
        case .deserializationFailed(let error):
            return "Failed to parse protobuf: \(error.localizedDescription)"
        case .unexpectedMessage:
            return "Received unexpected message type"
        case .emptyMessage:
            return "Received message with no content"
        }
    }
}
