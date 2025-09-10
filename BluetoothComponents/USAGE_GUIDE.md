# BluetoothSession Usage Guide

The BluetoothComponents package now provides two ways to use Bluetooth functionality:

## 1. Simple Approach - Using BluetoothSession

For most use cases, use the `BluetoothSession` wrapper which handles all component wiring internally:

```swift
import BluetoothComponents

class ViewModel: ObservableObject {
    private let session = BluetoothSession()
    private var cancellables = Set<AnyCancellable>()

    @Published var filterText = ""
    @Published var filteredPeripherals: [CBPeripheral] = []
    @Published var connectionStates: [UUID: CBPeripheralState] = [:]
    @Published var serviceState: ServiceState = .discovering
    @Published var lastInfoResponse: InfoResponseData?

    init() {
        setupBinding()
    }

    private func setupBinding() {
        // Bind filter text to session
        $filterText
            .sink { [weak self] text in
                self?.session.setFilter(text: text)
            }
            .store(in: &cancellables)

        // Bind session outputs to view model
        session.$filteredPeripherals
            .assign(to: \.filteredPeripherals, on: self)
            .store(in: &cancellables)

        session.$connectionStates
            .assign(to: \.connectionStates, on: self)
            .store(in: &cancellables)

        session.$serviceState
            .assign(to: \.serviceState, on: self)
            .store(in: &cancellables)

        session.$lastInfoResponse
            .assign(to: \.lastInfoResponse, on: self)
            .store(in: &cancellables)
    }

    // Public interface
    func startScanning() { session.startScanning() }
    func stopAndClear() { session.stopAndClear() }
    func connect(peripheral: CBPeripheral) { session.connect(peripheral: peripheral) }
    func disconnect() { session.disconnect() }
    func requestDeviceInfo() { session.requestDeviceInfo() }
}
```

## 2. Advanced Approach - Custom Component Wiring

For advanced use cases where you need custom behavior, you can wire the components manually:

```swift
import BluetoothComponents

class CustomViewModel: ObservableObject {
    private let controller = BluetoothController()
    private let filter = PeripheralFilter()
    private var peripheralService: PeripheralService?
    private var cancellables = Set<AnyCancellable>()

    // Your custom wiring logic here
    init() {
        // Wire controller output to filter input
        controller.$discoveredPeripherals
            .sink { [weak self] peripherals in
                self?.filter.peripheralsInput.send(peripherals)
            }
            .store(in: &cancellables)

        // Add your custom filtering, processing, or routing logic
        // ...
    }
}
```

## Benefits of BluetoothSession

- **Simplicity**: No need to understand component wiring
- **Consistency**: Standard pattern for common use cases
- **Maintainability**: Changes to internal wiring don't affect your code
- **Testability**: Session can be easily mocked for testing

## When to Use Custom Wiring

- Custom filtering logic beyond text matching
- Multiple peripheral connections
- Complex state management requirements
- Integration with other reactive frameworks
