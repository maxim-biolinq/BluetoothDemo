# BluetoothComponents

A pure Combine-based Swift package for building Bluetooth applications following Unix philosophy principles.

## Overview

BluetoothComponents provides reusable, testable components for Bluetooth functionality. Each component follows a pure input/output architecture using Combine subjects, with no SwiftUI dependencies. Complex behavior emerges from composing simple parts.

## Components

### `BluetoothScanner`
- **Input**: `scanInput: PassthroughSubject<ScanCommand, Never>` - Commands to start, stop, or clear scanning
- **Output**: `peripheralsOutput: CurrentValueSubject<[CBPeripheral], Never>` - Discovered Bluetooth peripherals
- **Responsibility**: Manages Bluetooth peripheral discovery

### `BluetoothConnector`
- **Input**: `connectionInput: PassthroughSubject<ConnectionRequest, Never>` - Connection/disconnection requests
- **Output**: `connectionOutput: CurrentValueSubject<[UUID: CBPeripheralState], Never>` - Connection states by peripheral UUID
- **Responsibility**: Manages peripheral connections and state tracking

### `PeripheralFilter`
- **Input**: `peripheralsInput: CurrentValueSubject<[CBPeripheral], Never>` (peripherals), `filterTextInput: CurrentValueSubject<String, Never>` (filter text)
- **Output**: `peripheralsOutput: CurrentValueSubject<[CBPeripheral], Never>` - Filtered list of peripherals
- **Responsibility**: Filters peripherals by name prefix

## Architecture Principles

### 1. Pure Input/Output Interface
Components expose only input and output ports - no public methods or SwiftUI dependencies:
```swift
// ✅ Good - using inputs/outputs
scanner.scanInput.send(.start)
filter.peripheralsInput.send(peripherals)

// ❌ Avoid - calling methods
scanner.startScanning()
filter.updatePeripherals(peripherals)
```

### 2. Reactive Composition
Connect component outputs to inputs using Combine:
```swift
// Wire scanner output to filter input
scanner.peripheralsOutput
    .sink { peripherals in
        filter.peripheralsInput.send(peripherals)
    }
    .store(in: &cancellables)
```

### 3. Testable Design
Each component can be tested in isolation:
```swift
// Test filter logic without Bluetooth hardware
filter.peripheralsInput.send(mockPeripherals)
filter.filterTextInput.send("iPhone")
// Verify output
```

## Usage Example

```swift
import BluetoothComponents
import Combine

class BluetoothViewModel: ObservableObject {
    private let scanner = BluetoothScanner()
    private let filter = PeripheralFilter()
    private var connector: BluetoothConnector?
    private var cancellables = Set<AnyCancellable>()

    @Published var filteredPeripherals: [CBPeripheral] = []
    @Published var connectionStates: [UUID: CBPeripheralState] = [:]

    init() {
        setupConnector()
        setupWiring()
    }

    private func setupConnector() {
        connector = BluetoothConnector(centralManager: scanner.centralManager)
    }

    private func setupWiring() {
        // Wire scanner output to filter input
        scanner.peripheralsOutput
            .sink { [weak self] peripherals in
                self?.filter.peripheralsInput.send(peripherals)
            }
            .store(in: &cancellables)

        // Wire filter output to UI
        filter.peripheralsOutput
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredPeripherals, on: self)
            .store(in: &cancellables)

        // Wire connector output to UI
        connector?.connectionOutput
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionStates, on: self)
            .store(in: &cancellables)
    }

    func startScanning() {
        scanner.scanInput.send(.start)
    }

    func connect(peripheral: CBPeripheral, shouldConnect: Bool) {
        let request = BluetoothConnector.ConnectionRequest(
            peripheral: peripheral,
            shouldConnect: shouldConnect
        )
        connector?.connectionInput.send(request)
    }
}
```

## Installation

### Swift Package Manager

Add this package to your Xcode project:

1. File → Add Package Dependencies
2. Enter package URL: `file:///path/to/BluetoothComponents`
3. Add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../BluetoothComponents")
]
```

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## Key Benefits

- **🧪 Highly Testable**: Pure input/output design enables comprehensive unit testing
- **🔧 Modular**: Components can be used independently or composed together
- **♻️ Reusable**: Package can be shared across multiple projects and UI frameworks
- **🎯 Simple**: Follows "Simple is paramount" principle
- **� Framework Agnostic**: No SwiftUI dependencies - works with UIKit, AppKit, or any UI framework
- **📡 Pure Combine**: Uses only Combine subjects for reactive programming

## Testing

The package includes comprehensive tests demonstrating:
- Individual component testing
- Integration testing
- Reactive behavior verification
- Mock-friendly architecture

Run tests with:
```bash
swift test
```

## License

MIT License
