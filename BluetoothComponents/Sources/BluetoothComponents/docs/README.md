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

The BluetoothComponents library provides a modular Bluetooth system with three main components:

1. **BluetoothController** - Unified scanning and connection management
2. **PeripheralFilter** - Real-time device filtering and search
3. **BluetoothSession/PeripheralService** - Connection-scoped communication

### Basic Usage Pattern

```swift
// 1. Create and wire components
let controller = BluetoothController()
let filter = PeripheralFilter()

// Wire scanner output to filter input
controller.$discoveredPeripherals
    .sink { peripherals in
        filter.peripheralsInput.send(peripherals)
    }
    .store(in: &cancellables)

// 2. Start scanning
controller.scanInput.send(.start)

// 3. Connect to device
controller.connectionInput.send(.connect(peripheral))

// 4. Create session when connected
if let peripheral = controller.connectedPeripheral {
    let session = BluetoothSession(controller: controller, peripheral: peripheral)
    let info = await session.requestInfo()
}
```

## Architecture Principles

Following our core tenets of **Simple, Testable, Modular**:

- **Simple**: Minimal abstractions that map directly to functionality
- **Testable**: Pure input/output interfaces using Combine
- **Modular**: Components compose through reactive data flow

Each component exposes only input subjects and output publishers - no public methods. This creates a pure data flow architecture that's easy to test and compose.
