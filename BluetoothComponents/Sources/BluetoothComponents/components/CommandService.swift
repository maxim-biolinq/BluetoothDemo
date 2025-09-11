// CommandService.swift

import Foundation
import CoreBluetooth
import Combine
import SwiftProtobuf

// MARK: - Command Service Component
// Input: command requests and parsed responses
// Output: serialized commands and correlated responses
// Lifecycle: Created per peripheral connection
public class CommandService: ObservableObject {

    // MARK: - Inputs/Outputs
    public let commandInput = PassthroughSubject<PeripheralCommand, Never>()
    public let responseInput = PassthroughSubject<ParsedMessage, Never>()

    @Published public var commandDataOutput: CommandData?
    @Published public var commandResponseOutput: CommandResponse?
    @Published public var errorOutput: String?

    // MARK: - Private Properties
    private var pendingRequests = [UInt32: PendingRequest]()
    private var nextSeqNum: UInt32 = 1
    private var cancellables = Set<AnyCancellable>()

    public init() {
        commandInput
            .sink { [weak self] command in
                self?.handleCommand(command)
            }
            .store(in: &cancellables)

        responseInput
            .sink { [weak self] message in
                self?.handleResponse(message)
            }
            .store(in: &cancellables)
    }

    // MARK: - Command Handling

    private func handleCommand(_ command: PeripheralCommand) {
        cleanupTimedOutRequests()

        do {
            let seqNum = nextSeqNum
            nextSeqNum += 1

            let commandData = try command.data(seqNum: seqNum)
            pendingRequests[seqNum] = PendingRequest(command: command, timestamp: Date())
            commandDataOutput = commandData

        } catch {
            print("CommandService: Error processing command \(command): \(error)")
            errorOutput = "Failed to process command: \(error.localizedDescription)"
        }
    }

    // MARK: - Response Handling

    private func handleResponse(_ message: ParsedMessage) {
        cleanupTimedOutRequests()

        // Let the ParsedMessage extension handle the response parsing
        if let response = message.response {
            // Check if this matches a pending request
            if let _ = pendingRequests.removeValue(forKey: message.seqNum) {
                commandResponseOutput = response
            } else if message.seqNum == 0 && !pendingRequests.isEmpty {
                // Some devices always respond with sequence 0 - match to oldest pending request
                if let oldestSeqNum = pendingRequests.keys.min() {
                    pendingRequests.removeValue(forKey: oldestSeqNum)
                    commandResponseOutput = response
                    print("CommandService: Matched seq 0 response to pending request \(oldestSeqNum)")
                }
            } else {
                print("CommandService: Warning - response for unknown sequence: \(message.seqNum)")
            }
        }

        // Handle status events (don't correlate to requests)
        if case .statusEvent(let status, let seqNum) = message {
            print("CommandService: Status event (seq: \(seqNum)): \(status)")
        }
    }

    private func cleanupTimedOutRequests() {
        let now = Date()
        let timedOutRequests = pendingRequests.filter { (_, request) in
            now.timeIntervalSince(request.timestamp) > CommandService.REQUEST_TIMEOUT
        }

        for (seqNum, request) in timedOutRequests {
            print("CommandService: Request \(request.command) with seq \(seqNum) timed out")
            pendingRequests.removeValue(forKey: seqNum)
            errorOutput = "Request timeout: \(request.command)"
        }
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
