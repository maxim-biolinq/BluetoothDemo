// CommandService.swift

import Foundation
import CoreBluetooth
import SwiftProtobuf

// MARK: - Command Service
// Internal service for request/response correlation and command sequencing
// Lifecycle: Created per peripheral connection
public class CommandService {

    // MARK: - Private Properties
    private var pendingRequests = [UInt32: PendingRequest]()
    private var nextSeqNum: UInt32 = 1

    public init() {}

    // MARK: - Public Interface

    public func processCommand(_ command: PeripheralCommand) -> Result<CommandData, Error> {
        _ = cleanupTimedOutRequests()

        do {
            let seqNum = nextSeqNum
            nextSeqNum += 1

            let commandData = try command.data(seqNum: seqNum)
            pendingRequests[seqNum] = PendingRequest(command: command, timestamp: Date())
            return .success(commandData)
        } catch {
            print("CommandService: Error processing command \(command): \(error)")
            return .failure(error)
        }
    }

    public func handleResponse(_ message: ParsedMessage) -> CommandResponse? {
        _ = cleanupTimedOutRequests()

        // Handle status events (don't correlate to requests)
        if case .statusEvent(let status, let seqNum) = message {
            print("CommandService: Status event (seq: \(seqNum)): \(status)")
            return nil // Status events are not correlated to commands
        }

        // Get the CommandResponse from the ParsedMessage
        guard let response = message.response else {
            return nil
        }

        let seqNum = message.seqNum

        // Check if this matches a pending request
        if let _ = pendingRequests.removeValue(forKey: seqNum) {
            print("CommandService: Correlated response for seq \(seqNum)")
            return response
        } else if seqNum == 0 && !pendingRequests.isEmpty {
            // Some devices always respond with sequence 0 - match to oldest pending request
            if let oldestSeqNum = pendingRequests.keys.min() {
                pendingRequests.removeValue(forKey: oldestSeqNum)
                print("CommandService: Matched seq 0 response to pending request \(oldestSeqNum)")
                return response
            }
        }

        print("CommandService: Warning - response for unknown sequence: \(seqNum)")
        return nil
    }

    public func getTimeoutErrors() -> [CommandResponse] {
        let timeouts = cleanupTimedOutRequests()
        return timeouts
    }

    private func cleanupTimedOutRequests() -> [CommandResponse] {
        let now = Date()
        let timedOutRequests = pendingRequests.filter { (_, request) in
            now.timeIntervalSince(request.timestamp) > CommandService.REQUEST_TIMEOUT
        }

        var timeoutErrors: [CommandResponse] = []
        for (seqNum, request) in timedOutRequests {
            print("CommandService: Request \(request.command) with seq \(seqNum) timed out")
            pendingRequests.removeValue(forKey: seqNum)
            timeoutErrors.append(.error("Request timeout: \(request.command)"))
        }
        return timeoutErrors
    }
}

// MARK: - Public Data Types

public struct CommandData {
    public let data: Data
    public let seqNum: UInt32
    public let command: PeripheralCommand

    public init(data: Data, seqNum: UInt32, command: PeripheralCommand) {
        self.data = data
        self.seqNum = seqNum
        self.command = command
    }
}

public struct PendingRequest {
    public let command: PeripheralCommand
    public let timestamp: Date

    public init(command: PeripheralCommand, timestamp: Date) {
        self.command = command
        self.timestamp = timestamp
    }
}



// MARK: - Configuration
private extension CommandService {
    static let REQUEST_TIMEOUT: TimeInterval = 30.0 // 30 seconds
}
