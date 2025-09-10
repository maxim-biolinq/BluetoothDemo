//
//  BluetoothViewModel.swift
//  bluetooth
//
//  Created by Maxim Tarasov on 8/25/25.
//
import Combine
import CoreBluetooth
import BluetoothComponents

// Handles component wiring and state management for SwiftUI
class BluetoothViewModel: ObservableObject {
    private let controller = BluetoothController()
    private var peripheralService: PeripheralService?
    private let filter = PeripheralFilter()
    private var cancellables = Set<AnyCancellable>()

    @Published var filterText = ""
    @Published var filteredPeripherals: [CBPeripheral] = []
    @Published var connectionStates: [UUID: CBPeripheralState] = [:]
    @Published var serviceState: ServiceState = .discovering
    @Published var lastInfoResponse: InfoResponseData?

    init() {
        setupWiring()
    }

    private func setupWiring() {
        // Wire filter text input
        $filterText
            .sink { [weak self] text in
                self?.filter.filterTextInput.send(text)
            }
            .store(in: &cancellables)

        // Wire controller output to filter input
        controller.$discoveredPeripherals
            .sink { [weak self] peripherals in
                self?.filter.peripheralsInput.send(peripherals)
            }
            .store(in: &cancellables)

        // Wire filter output to UI
        filter.peripheralsOutput
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredPeripherals, on: self)
            .store(in: &cancellables)

        // Wire controller connection output to UI
        controller.$connectionStates
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionStates, on: self)
            .store(in: &cancellables)

        // Create PeripheralService when peripheral connects, destroy when disconnects
        controller.$connectedPeripheral
            .sink { [weak self] peripheral in
                self?.handlePeripheralConnection(peripheral)
            }
            .store(in: &cancellables)
    }

    func startScanning() {
        controller.scanInput.send(.start)
    }

    func stopAndClear() {
        controller.scanInput.send(.stop)
        controller.scanInput.send(.clear)
    }

    func connect(peripheral: CBPeripheral) {
        controller.connectionInput.send(.connect(peripheral))
    }

    func disconnect() {
        controller.connectionInput.send(.disconnect)
    }

    func requestDeviceInfo() {
        peripheralService?.commandInput.send(.requestInfo)
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

        // Wire PeripheralService outputs to UI
        service.serviceStateOutput
            .receive(on: DispatchQueue.main)
            .assign(to: \.serviceState, on: self)
            .store(in: &cancellables)

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
