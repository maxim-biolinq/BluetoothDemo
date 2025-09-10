// PeripheralService.swift

import Foundation
import CoreBluetooth
import Combine
import SwiftProtobuf

// MARK: - Peripheral Service Component
// Input: command requests
// Output: service state and command responses
// Lifecycle: Created per peripheral connection, destroyed on disconnect
public class PeripheralService: NSObject, ObservableObject {

    // MARK: - Constants
    public static let COMMAND_CHAR_UUID = CBUUID(string: "758e1601-6cae-4265-b32d-3406022a1463") // RX Char
    public static let RESPONSE_CHAR_UUID = CBUUID(string: "758e1602-6cae-4265-b32d-3406022a1463") // TX Char

    // MARK: - Inputs/Outputs
    public let commandInput = PassthroughSubject<PeripheralCommand, Never>()

    public let serviceStateOutput = CurrentValueSubject<ServiceState, Never>(.discovering)
    public let commandResponseOutput = PassthroughSubject<CommandResponse, Never>()

    // MARK: - Private Properties
    private let peripheral: CBPeripheral
    private let messageParser = MessageParser()
    private var commandCharacteristic: CBCharacteristic?
    private var responseCharacteristic: CBCharacteristic?

    // Request correlation
    private var pendingRequests = [UInt32: PendingRequest]()
    private var nextSeqNum: UInt32 = 1

    private var cancellables = Set<AnyCancellable>()

    public init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()

        commandInput
            .sink { [weak self] command in
                self?.handleCommand(command)
            }
            .store(in: &cancellables)

        // Start service discovery immediately
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    // MARK: - Input Handlers

    private func handleCommand(_ command: PeripheralCommand) {
        switch command {
        case .requestInfo:
            requestInfo()
        }
    }

    // MARK: - Command Implementations

    private func requestInfo() {
        // Clean up any timed-out requests before sending new one
        cleanupTimedOutRequests()

        guard let commandChar = commandCharacteristic else {
            commandResponseOutput.send(.error("Not ready: command characteristic not available"))
            return
        }

        do {
            let seqNum = nextSeqNum
            nextSeqNum += 1

            let bleMessage = constructInfoRequest(seqNum: seqNum)
            let data = try bleMessage.serializedData()

            print("PeripheralService: Sending info request (seq: \(seqNum)): \(data.map { String(format: "%02x", $0) }.joined(separator: " "))")

            // Track pending request
            pendingRequests[seqNum] = PendingRequest(command: .requestInfo, timestamp: Date())

            peripheral.writeValue(data, for: commandChar, type: CBCharacteristicWriteType.withResponse)
        } catch {
            print("PeripheralService: Error serializing info request: \(error)")
            commandResponseOutput.send(.error("Failed to serialize info request: \(error.localizedDescription)"))
        }
    }

    private func constructInfoRequest(seqNum: UInt32) -> Iris_BLEMessage {
        var bleMessage = Iris_BLEMessage()
        bleMessage.seqNum = seqNum

        var rxMessage = Iris_BLEMessageChRx()
        var request = Iris_BLEMessageChRxRequest()
        request.info = Iris_InfoRequest()

        rxMessage.request = request
        bleMessage.rxMsg = rxMessage

        return bleMessage
    }


}

// MARK: - CBPeripheralDelegate

extension PeripheralService: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("PeripheralService: Error discovering services: \(error.localizedDescription)")
            serviceStateOutput.send(.error("Service discovery failed: \(error.localizedDescription)"))
            return
        }

        guard let services = peripheral.services else {
            print("PeripheralService: No services found for peripheral: \(peripheral.name ?? "Unknown")")
            serviceStateOutput.send(.error("No services found"))
            return
        }

        print("PeripheralService: Discovered \(services.count) services for peripheral: \(peripheral.name ?? "Unknown")")
        for service in services {
            print("  Service UUID: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("PeripheralService: Error discovering characteristics for service \(service.uuid): \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else {
            print("PeripheralService: No characteristics found for service: \(service.uuid)")
            return
        }

        print("PeripheralService: Discovered \(characteristics.count) characteristics for service \(service.uuid):")
        for characteristic in characteristics {
            print("    Characteristic UUID: \(characteristic.uuid)")
            print("    Properties: \(characteristic.properties)")

            // Store command characteristic reference
            if characteristic.uuid == PeripheralService.COMMAND_CHAR_UUID {
                commandCharacteristic = characteristic
                print("    Found command characteristic")
            }

            // Subscribe to the response characteristic if it supports notifications
            if characteristic.uuid == PeripheralService.RESPONSE_CHAR_UUID && characteristic.properties.contains(.notify) {
                responseCharacteristic = characteristic
                print("    Subscribing to response characteristic")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }

        // Check if we have both characteristics
        if commandCharacteristic != nil && responseCharacteristic != nil {
            serviceStateOutput.send(.ready(
                commandCharacteristic: commandCharacteristic!,
                responseCharacteristic: responseCharacteristic!
            ))
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("PeripheralService: Error updating notification state for characteristic \(characteristic.uuid): \(error.localizedDescription)")
            return
        }

        if characteristic.uuid == PeripheralService.RESPONSE_CHAR_UUID {
            if characteristic.isNotifying {
                print("PeripheralService: Successfully subscribed to response characteristic")
            } else {
                print("PeripheralService: Unsubscribed from response characteristic")
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("PeripheralService: Error reading characteristic \(characteristic.uuid): \(error.localizedDescription)")
            return
        }

        if characteristic.uuid == PeripheralService.RESPONSE_CHAR_UUID {
            if let data = characteristic.value {
                print("PeripheralService: Received response data: \(data.map { String(format: "%02x", $0) }.joined(separator: " "))")
                handleReceivedData(data)
            }
        }
    }
}

// MARK: - Response Handling

extension PeripheralService {

    private func handleReceivedData(_ data: Data) {
        // Clean up any timed-out requests when receiving data
        cleanupTimedOutRequests()

        let parseResult = messageParser.parse(data)

        switch parseResult {
        case .success(let message):
            handleParsedMessage(message)
        case .failure(let error):
            print("PeripheralService: Parsing error: \(error.localizedDescription)")
            commandResponseOutput.send(.error("Failed to parse response: \(error.localizedDescription)"))
        }
    }

    private func handleParsedMessage(_ message: ParsedMessage) {
        switch message {
        case .infoResponse(let infoData, let seqNum):
            handleInfoResponse(infoData, seqNum: seqNum)
        case .statusEvent(let status, let seqNum):
            print("PeripheralService: Received status event (seq: \(seqNum)): \(status)")
        }
    }

    private func handleInfoResponse(_ infoData: InfoResponseData, seqNum: UInt32) {
        print("PeripheralService: InfoResponse (seq: \(seqNum)):")
        print("  num_blocks: \(infoData.numBlocks)")
        print("  timestamp: \(infoData.timestamp)")
        print("  status: \(infoData.status)")

        // Check if this matches a pending request
        if let pendingRequest = pendingRequests.removeValue(forKey: seqNum) {
            print("PeripheralService: Matched response to pending \(pendingRequest.command) request")
            commandResponseOutput.send(.infoResponse(infoData))
        } else {
            print("PeripheralService: Warning - received response for unknown sequence number: \(seqNum)")
        }
    }

    private func cleanupTimedOutRequests() {
        let now = Date()
        let timedOutRequests = pendingRequests.filter { (_, request) in
            now.timeIntervalSince(request.timestamp) > PeripheralService.REQUEST_TIMEOUT
        }

        for (seqNum, request) in timedOutRequests {
            print("PeripheralService: Request \(request.command) with seq \(seqNum) timed out")
            pendingRequests.removeValue(forKey: seqNum)
            commandResponseOutput.send(.error("Request timeout: \(request.command)"))
        }
    }}

// MARK: - Public Data Types

public enum ServiceState: Equatable {
    case discovering
    case ready(commandCharacteristic: CBCharacteristic, responseCharacteristic: CBCharacteristic)
    case error(String)

    public static func == (lhs: ServiceState, rhs: ServiceState) -> Bool {
        switch (lhs, rhs) {
        case (.discovering, .discovering):
            return true
        case let (.ready(lhsCmd, lhsResp), .ready(rhsCmd, rhsResp)):
            return lhsCmd.uuid == rhsCmd.uuid && lhsResp.uuid == rhsResp.uuid
        case let (.error(lhsMsg), .error(rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

public enum PeripheralCommand {
    case requestInfo
    // Future commands can be added here
}

public enum CommandResponse {
    case infoResponse(InfoResponseData)
    case error(String)
}

public struct InfoResponseData {
    public let numBlocks: UInt32
    public let timestamp: UInt32
    public let status: String

    public init(numBlocks: UInt32, timestamp: UInt32, status: String) {
        self.numBlocks = numBlocks
        self.timestamp = timestamp
        self.status = status
    }
}

private struct PendingRequest {
    let command: PeripheralCommand
    let timestamp: Date
}

// MARK: - Configuration
private extension PeripheralService {
    static let REQUEST_TIMEOUT: TimeInterval = 30.0 // 30 seconds
}
