# Connection Lifecycle Diagram

## System Connection Behavior

This diagram shows the connection lifecycle patterns for the Bluetooth system, including current behavior and future evolution.

```mermaid
sequenceDiagram
    participant App as App
    participant BC as BluetoothController
    participant VM as ViewModel
    participant PS as PeripheralService
    participant Device as BLE Device

    Note over App,Device: Current: Periodic Connect/Disconnect Pattern (Every 5 minutes)

    App->>BC: Start Scan
    BC->>Device: Discover
    Device->>BC: Advertisement
    BC->>VM: discoveredPeripherals updated

    App->>BC: Connect Request
    BC->>Device: Connect
    Device->>BC: Connected
    BC->>VM: connectedPeripheral = peripheral

    Note over VM,PS: Service Creation & Lifecycle
    VM->>PS: new PeripheralService(peripheral)
    PS->>Device: Discover Services
    Device->>PS: Services/Characteristics
    PS->>VM: serviceState = .ready

    Note over App,Device: Data Download Phase
    App->>PS: Request Info
    PS->>Device: Send Command
    Device->>PS: Response Data
    PS->>VM: commandResponse
    VM->>App: Display Data

    Note over BC,Device: Automatic Disconnect (Current Pattern)
    BC->>Device: Disconnect
    Device->>BC: Disconnected
    BC->>VM: connectedPeripheral = nil
    VM->>PS: peripheralService = nil
    Note over PS: Service Destroyed & Memory Freed

    Note over App,Device: 5-Minute Wait Cycle

    Note over App,Device: Future: Always-Connected Pattern
    rect rgb(240, 248, 255)
        Note over VM,PS: Service Persists for Session
        App->>PS: Continuous Requests
        PS->>Device: Ongoing Communication
        Device->>PS: Real-time Responses
    end

    Note over App,Device: NFC Tap Pattern (User-Initiated)
    rect rgb(255, 248, 220)
        Note over Device: NFC Tap → Wake & Start Advertising
        App->>BC: Automatic Scan (on tap detection)
        BC->>Device: Discover (now advertising)
        Device->>BC: Advertisement Response
        Note over App,Device: Standard Connection Flow Follows
        BC->>Device: Connect
        VM->>PS: new PeripheralService(peripheral)
        PS->>Device: Service Discovery & Communication
        Note over App,Device: Data Exchange Complete → Disconnect
    end
```

## Key Lifecycle Characteristics

### Current Pattern (Periodic Cycles)
- **Connection Duration**: Short-lived (seconds to minutes)
- **Frequency**: Every 5 minutes or more often
- **Purpose**: Connect → Download → Disconnect
- **Service Lifecycle**: Created per connection, destroyed on disconnect

### Future Pattern (Always-Connected)
- **Connection Duration**: Long-lived (hours to session)
- **Frequency**: Single connection per session
- **Purpose**: Continuous communication
- **Service Lifecycle**: Created once, persists for session

### NFC Tap Pattern (User-Initiated)
- **Connection Duration**: Short-lived (triggered by user action)
- **Frequency**: On-demand via NFC tap
- **Purpose**: Wake device → Connect → Download → Disconnect
- **Service Lifecycle**: Created per tap event, destroyed after data exchange

## Architecture Alignment

### Perfect Match with Initialization Design
1. **Service Creation**: Tied to connection establishment
2. **Automatic Discovery**: Starts immediately upon connection
3. **Memory Management**: Service cleaned up on disconnect
4. **State Isolation**: Each connection gets fresh service state
5. **Future Compatibility**: Works for both patterns seamlessly

### Benefits
- **Periodic Pattern**: Clean slate for each connection cycle
- **Always-Connected**: Single service instance for persistent connection
- **Memory Efficient**: No persistent objects between connections
- **Error Recovery**: Connection failures automatically clean up service state
