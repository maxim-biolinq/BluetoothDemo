//
//  BluetoothSession.swift
//  BluetoothComponents
//
//  Orchestrates BluetoothController, PeripheralFilter, and PeripheralService
//  Provides a simple interface for common Bluetooth operations
//

import Foundation
import CoreBluetooth
import Combine


// MARK: - Bluetooth Session
// Convenient wrapper that wires components together
// Clients can still use individual components if they prefer custom wiring
public class BluetoothSession: ObservableObject {

    // MARK: - Public Outputs
    @Published public var filteredPeripherals: [CBPeripheral] = []
    @Published public var serviceState: ServiceState = .discovering
    @Published public var lastInfoResponse: InfoResponseData?
    @Published public var isMultiBlockRequestActive = false

    // MARK: - Components
    private let controller: BluetoothController!
    private let filter: PeripheralFilter!
    private var peripheralService: PeripheralService?

    // MARK: - Private Properties
    private var pendingRangeRequest: (startIndex: UInt32, endIndex: UInt32, expectedCount: Int)? = nil
    private var receivedBlocks: [UInt32: Data] = [:]
    private var rangeRequestTimeout: Timer?

    private var cancellables = Set<AnyCancellable>()


    public init(
    controller: BluetoothController = BluetoothController(),
    filter: PeripheralFilter = PeripheralFilter()
    ) {
        self.controller = controller
        self.filter = filter
        setupWiring()
    }

    // MARK: - Public Interface

    public func setFilter(text: String) {
        filter.filterTextInput.send(text)
    }

    public func startScanning() {
        controller.scanInput.send(.start)
    }

    public func stopScanning() {
        controller.scanInput.send(.stop)
    }

    public func clearPeripherals() {
        controller.scanInput.send(.clear)
    }

    public func connect(peripheral: CBPeripheral) {
        controller.connectionInput.send(.connect(peripheral))
    }

    public func disconnect() {
        controller.connectionInput.send(.disconnect)
    }

    public func requestDeviceInfo() {
        peripheralService?.commandInput.send(.requestInfo)
    }

    public func requestEDataRange(startIndex: UInt32, endIndex: UInt32) {
        // Clear previous state and set up for range request
        let expectedBlockCount = endIndex - startIndex + 1
        pendingRangeRequest = (startIndex: startIndex, endIndex: endIndex, expectedCount: Int(expectedBlockCount))
        receivedBlocks.removeAll()

        DispatchQueue.main.async {
            self.isMultiBlockRequestActive = true
        }

        print("BluetoothSession: Requesting EData range \(startIndex)-\(endIndex) (\(expectedBlockCount) blocks)")
        peripheralService?.commandInput.send(.getEDataRange(startIndex: startIndex, endIndex: endIndex))

        // Set up timeout
        rangeRequestTimeout?.invalidate()
        rangeRequestTimeout = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            DispatchQueue.main.async {
                if self.isMultiBlockRequestActive {
                    self.isMultiBlockRequestActive = false
                    print("BluetoothSession: Range request timed out")
                }
            }
        }
    }

    public func requestEDataRange(_ range: ClosedRange<UInt32>) {
        requestEDataRange(startIndex: range.lowerBound, endIndex: range.upperBound)
    }

    public var combinedEDataBlocks: Data {
        // Sort blocks by index and combine their data
        let sortedBlocks = receivedBlocks.sorted { $0.key < $1.key }
        return sortedBlocks.map { $0.value }.reduce(Data(), +)
    }

    public var eDataBlocks: [(blockNum: UInt32, data: Data)] {
        // Return sorted blocks for UI display
        return receivedBlocks.sorted { $0.key < $1.key }.map { (blockNum: $0.key, data: $0.value) }
    }

    // MARK: - Component Wiring

    private func setupWiring() {
        cancellables.store {
            // Wire controller output directly to filter input
            controller.$discoveredPeripherals
                .send(to: \.peripheralsInput, on: filter)

            // Wire filter output directly to public output
            filter.peripheralsOutput
                .receive(on: DispatchQueue.main)
                .assign(to: \.filteredPeripherals, on: self)

            // Handle peripheral connection/disconnection
            controller.$connectedPeripheral
                .call(handlePeripheralConnection, on: self)
        }
    }

    private func handlePeripheralConnection(_ peripheral: CBPeripheral?) {
        // Clean up existing service and multi-block state
        peripheralService = nil

        DispatchQueue.main.async {
            self.serviceState = .discovering
            self.pendingRangeRequest = nil
            self.receivedBlocks.removeAll()
            self.isMultiBlockRequestActive = false
        }

        rangeRequestTimeout?.invalidate()

        if let peripheral = peripheral {
            // Create new service for this peripheral
            peripheralService = PeripheralService(peripheral: peripheral)
            setupPeripheralServiceBindings()
        }
    }

    private func setupPeripheralServiceBindings() {
        guard let service = peripheralService else { return }

        cancellables.store {
            // Wire service state to public output
            service.serviceStateOutput
                .receive(on: DispatchQueue.main)
                .assign(to: \.serviceState, on: self)

            // Wire service responses to public output
            service.commandResponseOutput
                .call(handleCommandResponse, on: self)
        }
    }

    private func handleCommandResponse(_ response: CommandResponse) {
        switch response {
        case .infoResponse(let data):
            DispatchQueue.main.async {
                self.lastInfoResponse = data
            }
        case .eDataBlockResponse(let data):
            DispatchQueue.main.async {
                self.handleEDataBlockResponse(data)
                print("Received eDataBlock response: index \(data.index), data length: \(data.blockData.count)")
            }
        case .error(let message):
            print("PeripheralService error: \(message)")
        }
    }

    private func handleEDataBlockResponse(_ data: EDataBlockResponseData) {
        // If we're in a range request, use the index from the response
        if isMultiBlockRequestActive, let pendingRequest = pendingRangeRequest {
            let blockIndex = data.index

            // Check if this block is within the expected range
            if blockIndex >= pendingRequest.startIndex && blockIndex <= pendingRequest.endIndex {
                receivedBlocks[blockIndex] = data.blockData

                // Check if all blocks received
                if receivedBlocks.count == pendingRequest.expectedCount {
                    DispatchQueue.main.async {
                        self.isMultiBlockRequestActive = false
                        self.pendingRangeRequest = nil
                        self.rangeRequestTimeout?.invalidate()
                        print("BluetoothSession: Range request completed. Received \(self.receivedBlocks.count) blocks.")
                    }
                }
            } else {
                print("BluetoothSession: Received block index \(blockIndex) outside expected range \(pendingRequest.startIndex)-\(pendingRequest.endIndex)")
            }
        }
    }
}
