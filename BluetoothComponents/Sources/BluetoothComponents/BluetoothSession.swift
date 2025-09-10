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
    @Published public var connectionStates: [UUID: CBPeripheralState] = [:]
    @Published public var serviceState: ServiceState = .discovering
    @Published public var lastInfoResponse: InfoResponseData?

    // MARK: - Components
    private let controller = BluetoothController()
    private let filter = PeripheralFilter()
    private var peripheralService: PeripheralService?

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    public init() {
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

    // MARK: - Component Wiring

    private func setupWiring() {
        // Wire controller output to filter input
        controller.$discoveredPeripherals
            .sink { [weak self] peripherals in
                self?.filter.peripheralsInput.send(peripherals)
            }
            .store(in: &cancellables)

        // Wire filter output to public output
        filter.peripheralsOutput
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredPeripherals, on: self)
            .store(in: &cancellables)

        // Wire controller connection states to public output
        controller.$connectionStates
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionStates, on: self)
            .store(in: &cancellables)

        // Handle peripheral connection/disconnection
        controller.$connectedPeripheral
            .sink { [weak self] peripheral in
                self?.handlePeripheralConnection(peripheral)
            }
            .store(in: &cancellables)
    }

    private func handlePeripheralConnection(_ peripheral: CBPeripheral?) {
        // Clean up existing service
        peripheralService = nil
        serviceState = .discovering

        if let peripheral = peripheral {
            // Create new service for this peripheral
            peripheralService = PeripheralService(peripheral: peripheral)
            setupPeripheralServiceBindings()
        }
    }

    private func setupPeripheralServiceBindings() {
        guard let service = peripheralService else { return }

        // Wire service state to public output
        service.serviceStateOutput
            .receive(on: DispatchQueue.main)
            .assign(to: \.serviceState, on: self)
            .store(in: &cancellables)

        // Wire service responses to public output
        service.commandResponseOutput
            .sink { [weak self] response in
                switch response {
                case .infoResponse(let data):
                    DispatchQueue.main.async {
                        self?.lastInfoResponse = data
                    }
                case .error(let message):
                    print("PeripheralService error: \(message)")
                }
            }
            .store(in: &cancellables)
    }
}
