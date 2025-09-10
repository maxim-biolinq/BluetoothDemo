# Bluetooth Components Documentation

This directory contains architecture documentation for the BluetoothComponents library.

## Documentation Overview

### [System Architecture](system-wiring-diagram.md)
- Complete system component overview
- Component interfaces and data flow
- Wiring patterns and integration examples
- Design principles and benefits

### [Connection Lifecycle](connection-lifecycle-diagram.md)
- Bluetooth connection flow sequences
- Service creation and cleanup patterns
- Session management architecture
- Memory and error handling

## Quick Start

The BluetoothComponents library provides a modular Bluetooth system with three core components:

1. **BluetoothController** - Unified scanning and connection management
2. **PeripheralFilter** - Real-time device filtering and search
3. **PeripheralService** - Connection-scoped BLE communication

**BluetoothSession** is an optional convenience wrapper that ties these components together. Apps can choose to wire up the individual components themselves for more control.

### Usage Patterns

#### Option 1: Individual Components (Full Control)
```swift
// 1. Create and wire components
let controller = BluetoothController()
let filter = PeripheralFilter()

// Wire controller output to filter input
controller.$discoveredPeripherals
    .sink { peripherals in
        filter.peripheralsInput.send(peripherals)
    }
    .store(in: &cancellables)

// 2. Start scanning and connect
controller.scanInput.send(.start)
controller.connectionInput.send(.connect(peripheral))

// 3. Create service when connected
if let peripheral = controller.connectedPeripheral {
    let service = PeripheralService(peripheral: peripheral)
    service.commandInput.send(.requestInfo)
}
```

#### Option 2: Convenience Wrapper (Simplified)
```swift
// BluetoothSession handles component wiring internally
let session = BluetoothSession()
session.startScanning()
await session.connect(to: peripheral)
let info = await session.requestInfo()
```

## Architecture Principles

Following our core tenets of **Simple, Testable, Modular**:

- **Simple**: Minimal abstractions that map directly to functionality
- **Testable**: Pure input/output interfaces using Combine
- **Modular**: Components compose through reactive data flow

Each component exposes only input subjects and output publishers - no public methods. This creates a pure data flow architecture that's easy to test and compose.
