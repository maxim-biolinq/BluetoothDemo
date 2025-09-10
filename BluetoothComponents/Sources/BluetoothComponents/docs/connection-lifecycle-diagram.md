# Connection Lifecycle

This document describes the Bluetooth connection lifecycle and session management patterns.

## Current Connection Flow

```mermaid
sequenceDiagram
    participant UI as BluetoothView
    participant BC as BluetoothController
    participant BS as BluetoothSession
    participant PS as PeripheralService
    participant Device as BLE Device

    Note over UI,Device: Discovery Phase
    UI->>BC: scanInput.send(.start)
    BC->>Device: Start Scanning
    Device->>BC: Advertisement
    BC->>UI: discoveredPeripherals updated

    Note over UI,Device: Connection Phase
    UI->>BC: connectionInput.send(.connect(peripheral))
    BC->>Device: Connect Request
    Device->>BC: Connection Established
    BC->>UI: connectedPeripheral = peripheral

    Note over UI,Device: Session Creation
    UI->>BS: BluetoothSession(controller, peripheral)
    BS->>PS: PeripheralService(peripheral)
    PS->>Device: Discover Services
    Device->>PS: Services Available
    PS->>Device: Discover Characteristics
    Device->>PS: Characteristics Available
    PS->>BS: Service Ready

    Note over UI,Device: Communication Phase
    UI->>BS: requestInfo()
    BS->>PS: Send Info Request
    PS->>Device: Write Command
    Device->>PS: Notify Response
    PS->>BS: Parse Response Data
    BS->>UI: Return InfoData

    Note over UI,Device: Disconnection
    UI->>BC: connectionInput.send(.disconnect)
    BC->>Device: Disconnect
    Device->>BC: Disconnected
    BC->>UI: connectedPeripheral = nil
    Note over BS,PS: Session & Service Destroyed
```

## Connection Lifecycle Characteristics

### Service Creation Pattern
- **Timing**: Services created only when peripheral connects
- **Scope**: Services bound to specific peripheral connection
- **Memory**: Automatically cleaned up on disconnect
- **Discovery**: Service/characteristic discovery happens immediately on creation

### Session Management
- **BluetoothSession**: High-level interface created per connection
- **PeripheralService**: Low-level BLE communication handler
- **Lifecycle**: Both destroyed when connection ends
- **State**: Each connection gets fresh service state

## Key Architecture Benefits

### Memory Efficiency
- No persistent objects between connections
- Services destroyed automatically on disconnect
- Clean slate for each new connection

### Error Recovery
- Connection failures automatically clean up service state
- No lingering state from failed connections
- Robust reconnection handling

### Simplicity
- Service creation tied directly to connection success
- Automatic discovery eliminates manual setup
- Clear lifecycle boundaries

### Future Extensibility
- Pattern works for both short-lived and persistent connections
- Easy to add connection-scoped features
- Maintains clean separation of concerns
