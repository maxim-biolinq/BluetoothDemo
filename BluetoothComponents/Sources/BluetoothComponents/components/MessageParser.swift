import Foundation
import SwiftProtobuf

// MARK: - Message Parser Component
// Input: raw BLE data
// Output: parsed message results
public class MessageParser {

    public init() {}

    public func parse(_ data: Data) -> Result<ParsedMessage, ParsingError> {
        do {
            let bleMessage = try Iris_BLEMessage(serializedBytes: data)

            // Check if this is a tx_msg channel
            guard case .txMsg(let txMsg) = bleMessage.channel else {
                return .failure(.unexpectedChannel)
            }

            return parseTxMessage(txMsg, seqNum: bleMessage.seqNum)
        } catch {
            return .failure(.deserializationFailed(error))
        }
    }

    // MARK: - Private Parsing Logic

    private func parseTxMessage(_ txMsg: Iris_BLEMessageChTx, seqNum: UInt32) -> Result<ParsedMessage, ParsingError> {
        switch txMsg.msg {
        case .response(let response):
            return parseTxResponse(response, seqNum: seqNum)
        case .event(let event):
            return parseTxEvent(event, seqNum: seqNum)
        case .none:
            return .failure(.emptyMessage)
        }
    }

    private func parseTxResponse(_ response: Iris_BLEMessageChTxResponse, seqNum: UInt32) -> Result<ParsedMessage, ParsingError> {
        switch response.msg {
        case .info(let info):
            let infoData = InfoResponseData(
                numBlocks: info.numBlocks,
                timestamp: info.timestamp,
                status: statusToString(info.status)
            )
            return .success(.infoResponse(infoData, seqNum: seqNum))
        case .none:
            return .failure(.emptyResponse)
        }
    }

    private func parseTxEvent(_ event: Iris_BLEMessageChTxEvent, seqNum: UInt32) -> Result<ParsedMessage, ParsingError> {
        switch event.msg {
        case .status(let statusEvent):
            return .success(.statusEvent(statusToString(statusEvent.status), seqNum: seqNum))
        case .none:
            return .failure(.emptyEvent)
        }
    }

    private func statusToString(_ status: Iris_Status) -> String {
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
    case statusEvent(String, seqNum: UInt32)

    public var seqNum: UInt32 {
        switch self {
        case .infoResponse(_, let seqNum), .statusEvent(_, let seqNum):
            return seqNum
        }
    }
}

public enum ParsingError: Error {
    case deserializationFailed(Error)
    case unexpectedChannel
    case emptyMessage
    case emptyResponse
    case emptyEvent

    public var localizedDescription: String {
        switch self {
        case .deserializationFailed(let error):
            return "Failed to parse protobuf: \(error.localizedDescription)"
        case .unexpectedChannel:
            return "Received notification on unexpected channel"
        case .emptyMessage:
            return "Received message with no content"
        case .emptyResponse:
            return "Received response with no content"
        case .emptyEvent:
            return "Received event with no content"
        }
    }
}
