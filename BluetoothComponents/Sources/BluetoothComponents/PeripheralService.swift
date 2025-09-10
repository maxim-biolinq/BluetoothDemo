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
    private var commandCharacteristic: CBCharacteristic?
    private var responseCharacteristic: CBCharacteristic?
    private var pendingInfoRequest: Bool = false

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
        guard let commandChar = commandCharacteristic else {
            commandResponseOutput.send(.error("Not ready: command characteristic not available"))
            return
        }

        do {
            let bleMessage = constructInfoRequest()
            let data = try bleMessage.serializedData()

            print("PeripheralService: Sending info request: \(data.map { String(format: "%02x", $0) }.joined(separator: " "))")
            pendingInfoRequest = true

            peripheral.writeValue(data, for: commandChar, type: CBCharacteristicWriteType.withResponse)
        } catch {
            print("PeripheralService: Error serializing info request: \(error)")
            commandResponseOutput.send(.error("Failed to serialize info request: \(error.localizedDescription)"))
        }
    }

    private func constructInfoRequest() -> Iris_BLEMessage {
        var bleMessage = Iris_BLEMessage()
        bleMessage.seqNum = 1 // TODO: Implement proper sequence numbering

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
                parseNotificationData(data)
            }
        }
    }
}

// MARK: - Response Parsing

extension PeripheralService {

    private func parseNotificationData(_ data: Data) {
        do {
            let bleMessage = try Iris_BLEMessage(serializedBytes: data)

            // Check if this is a tx_msg channel
            if case .txMsg(let txMsg) = bleMessage.channel {
                parseTxMessage(txMsg)
            } else {
                print("PeripheralService: Received notification on unexpected channel")
            }
        } catch {
            print("PeripheralService: Error parsing notification data: \(error)")
            commandResponseOutput.send(.error("Failed to parse response: \(error.localizedDescription)"))
        }
    }

    private func parseTxMessage(_ txMsg: Iris_BLEMessageChTx) {
        switch txMsg.msg {
        case .response(let response):
            parseTxResponse(response)
        case .event(let event):
            parseTxEvent(event)
        case .none:
            print("PeripheralService: Received tx message with no content")
        }
    }

    private func parseTxResponse(_ response: Iris_BLEMessageChTxResponse) {
        switch response.msg {
        case .info(let info):
            handleInfoResponse(info)
        case .none:
            print("PeripheralService: Received response with no content")
        }
    }

    private func parseTxEvent(_ event: Iris_BLEMessageChTxEvent) {
        switch event.msg {
        case .status(let status):
            print("PeripheralService: Received status event: \(status)")
        case .none:
            print("PeripheralService: Received event with no content")
        }
    }

    private func handleInfoResponse(_ info: Iris_InfoResponse) {
        print("PeripheralService: InfoResponse:")
        print("  num_blocks: \(info.numBlocks)")
        print("  timestamp: \(info.timestamp)")
        print("  status: \(info.status)")

        if pendingInfoRequest {
            pendingInfoRequest = false
            let infoData = InfoResponseData(
                numBlocks: info.numBlocks,
                timestamp: info.timestamp,
                status: statusToString(info.status)
            )
            commandResponseOutput.send(.infoResponse(infoData))
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
