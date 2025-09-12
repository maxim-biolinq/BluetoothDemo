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
public class BluetoothSession: ComponentWiringBase, ObservableObject {

    // MARK: - Public Outputs
    @Published public var filteredPeripherals: [CBPeripheral] = []
    @Published public var serviceState: ServiceState = .discovering
    @Published public var lastInfoResponse: InfoResponseData?
    @Published public var lastEDataResponse: EDataBlockResponseData?
    @Published public var multiBlockEDataResults: [(blockNum: UInt32, data: Data)] = []
    @Published public var isMultiBlockRequestActive = false

    // MARK: - Components
    private let controller: BluetoothController!
    private let filter: PeripheralFilter!
    private var peripheralService: PeripheralService?

    // MARK: - Private Properties
    private var pendingMultiBlockRequest: [UInt32] = [] // ordered list of expected block numbers
    private var receivedBlocks: [UInt32: Data] = [:]

    public init(
    controller: BluetoothController = BluetoothController(),
    filter: PeripheralFilter = PeripheralFilter()
    ) {
        self.controller = controller
        self.filter = filter
        super.init()
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

    public func requestEData(blockNum: UInt32) {
        peripheralService?.commandInput.send(.getEData(blockNum: blockNum))
    }

    public func requestMultipleEDataBlocks(blockNums: [UInt32]) {
        // Clear previous state
        pendingMultiBlockRequest = blockNums.sorted()
        receivedBlocks.removeAll()

        DispatchQueue.main.async {
            self.multiBlockEDataResults.removeAll()
            self.isMultiBlockRequestActive = true
        }

        // Send all requests - the CommandService will handle sequence numbers and correlation
        for blockNum in blockNums {
            peripheralService?.commandInput.send(.getEData(blockNum: blockNum))
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    public var combinedEDataBlocks: Data {
        return multiBlockEDataResults.map { $0.data }.reduce(Data(), +)
    }

    // MARK: - Component Wiring

    private func setupWiring() {
        connect {
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
            self.pendingMultiBlockRequest.removeAll()
            self.receivedBlocks.removeAll()
            self.multiBlockEDataResults.removeAll()
            self.isMultiBlockRequestActive = false
        }

        if let peripheral = peripheral {
            // Create new service for this peripheral
            peripheralService = PeripheralService(peripheral: peripheral)
            setupPeripheralServiceBindings()
        }
    }

    private func setupPeripheralServiceBindings() {
        guard let service = peripheralService else { return }

        connect {
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
                self.lastEDataResponse = data
                self.handleEDataBlockResponse(data)
                print("Received eDataBlock response: data length: \(data.blockData.count)")
            }
        case .error(let message):
            print("PeripheralService error: \(message)")
        }
    }

    private func handleEDataBlockResponse(_ data: EDataBlockResponseData) {
        // If we're in a multi-block request, consume responses in order
        if isMultiBlockRequestActive && !pendingMultiBlockRequest.isEmpty {
            let expectedBlockNum = pendingMultiBlockRequest.removeFirst()
            receivedBlocks[expectedBlockNum] = data.blockData

            DispatchQueue.main.async {
                // Add to results in order
                self.multiBlockEDataResults.append((blockNum: expectedBlockNum, data: data.blockData))

                // Check if all blocks received
                if self.pendingMultiBlockRequest.isEmpty {
                    self.isMultiBlockRequestActive = false
                    print("BluetoothSession: Multi-block request completed. Received \(self.multiBlockEDataResults.count) blocks.")
                }
            }
        }
    }
}
