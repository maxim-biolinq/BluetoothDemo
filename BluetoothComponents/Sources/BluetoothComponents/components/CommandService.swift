// CommandService.swift

import Foundation
import CoreBluetooth
import SwiftProtobuf

// MARK: - Command Service
// Internal service for command processing
// Lifecycle: Created per peripheral connection
public class CommandService {

    public init() {}

    // MARK: - Public Interface

    public func processCommand(_ command: PeripheralCommand) -> Result<CommandData, Error> {
        do {
            let commandData = try command.data(seqNum: 0)
            return .success(commandData)
        } catch {
            print("CommandService: Error processing command \(command): \(error)")
            return .failure(error)
        }
    }

    public func handleResponse(_ message: ParsedMessage) -> CommandResponse? {
        // Handle status events (don't correlate to requests)
        if case .statusEvent(let status, let seqNum) = message {
            print("CommandService: Status event (seq: \(seqNum)): \(status)")
            return nil // Status events are not correlated to commands
        }

        // Simply return the response - no sequence number correlation needed
        // since firmware always returns seq 0
        return message.response
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
