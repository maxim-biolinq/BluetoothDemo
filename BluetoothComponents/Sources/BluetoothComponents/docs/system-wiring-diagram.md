# Bluetooth System Architecture

This document describes the current Bluetooth component architecture and how components are wired together.

## Current System Components

```mermaid
graph TD
    %% User Interface Layer
    subgraph "User Interface"
        UT[Search Text Field]
        UB1[Start Scan Button]
        UB2[Stop/Clear Button]
        UB3[Connect Button]
        UB4[Get Info Button]
    end

    %% BluetoothSession Boundary
    subgraph BS["BluetoothSession Wrapper"]
        %% BluetoothController Component
        subgraph BC_Group["BluetoothController"]
            direction TB
            subgraph BC_IN[" "]
                BCSI["🔌 scanInput"]
                BCCI["🔌 connectionInput"]
            end
            BC["Central Manager &<br/>State Management"]
            subgraph BC_OUT[" "]
                BSO["📡 discoveredPeripherals"]
                BCO["📡 connectionStates"]
                BCP["📡 connectedPeripheral"]
            end
            BC_IN --> BC --> BC_OUT
        end

        %% PeripheralFilter Component
        subgraph PF_Group["PeripheralFilter"]
            direction TB
            subgraph PF_IN[" "]
                PFI1["🔌 peripheralsInput"]
                PFI2["🔌 filterTextInput"]
            end
            PF["Filter Logic"]
            subgraph PF_OUT[" "]
                PFO["📡 filteredPeripherals"]
            end
            PF_IN --> PF --> PF_OUT
        end

        %% PeripheralService Component
        subgraph PS_Group["PeripheralService"]
            direction TB
            subgraph PS_IN[" "]
                PSCI["🔌 commandInput"]
            end
            PS["BLE Communication"]
            subgraph PS_OUT[" "]
                PSSO["📡 serviceState"]
                PSCO["📡 infoResponse"]
            end
            PS_IN --> PS --> PS_OUT
        end
    end

    %% UI View Layer
    BV[BluetoothView<br/>SwiftUI Bindings]

    %% User Input Connections
    UT --> PFI2
    UB1 --> BCSI
    UB2 --> BCSI
    UB3 --> BCCI
    UB4 --> PSCI

    %% Component Interconnections
    BSO --> PFI1
    BCP --> PS

    %% Output to UI
    PFO --> BV
    BCO --> BV
    PSSO --> BV
    PSCO --> BV

    %% Styling
    classDef userInput fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    classDef componentCore fill:#e3f2fd,stroke:#2196f3,stroke-width:2px
    classDef inputSection fill:#f0f8f0,stroke:#4caf50,stroke-width:1px
    classDef outputSection fill:#fff8f0,stroke:#ff9800,stroke-width:1px
    classDef view fill:#fce4ec,stroke:#e91e63,stroke-width:2px
    classDef wrapper fill:#ffffff,stroke:#999999,stroke-width:2px,stroke-dasharray: 5 5
    classDef componentGroup fill:#ffffff,stroke:#cccccc,stroke-width:2px,rx:10,ry:10

    class UT,UB1,UB2,UB3,UB4 userInput
    class BC,PF,PS componentCore
    class BC_IN,PF_IN,PS_IN inputSection
    class BC_OUT,PF_OUT,PS_OUT outputSection
    class BV view
    class BS wrapper
    class BC_Group,PF_Group,PS_Group componentGroup
```

## Component Architecture

### BluetoothController
*Unified Bluetooth management component*

**Inputs:**
- `scanInput: PassthroughSubject<ScanCommand, Never>`
- `connectionInput: PassthroughSubject<ConnectionRequest, Never>`

**Outputs:**
- `discoveredPeripherals: @Published [CBPeripheral]`
- `connectionStates: @Published [UUID: CBPeripheralState]`
- `connectedPeripheral: @Published CBPeripheral?`

**Responsibilities:**
- Device scanning and discovery
- Connection management
- Bluetooth state handling
- Central Manager operations

### PeripheralFilter
*Device filtering and search*

**Inputs:**
- `peripheralsInput: PassthroughSubject<[CBPeripheral], Never>`
- `filterTextInput: CurrentValueSubject<String, Never>`

**Outputs:**
- `filteredPeripherals: @Published [CBPeripheral]`

**Responsibilities:**
- Real-time peripheral filtering
- Search functionality
- List processing

### BluetoothSession & PeripheralService
*Connection-scoped communication*

**BluetoothSession:**
- Created when a peripheral connects
- Manages the PeripheralService lifecycle
- Provides high-level communication interface

**PeripheralService:**
- Initialized with connected peripheral
- Handles service discovery automatically
- Manages BLE communication protocol
- Processes commands and responses

## Data Flow Sequence

### 1. Discovery Phase
```
User Action → BluetoothController → PeripheralFilter → UI
"Start Scan" → scanInput → discoveredPeripherals → peripheralsInput → filteredPeripherals → View
```

### 2. Connection Phase
```
User Selection → BluetoothController → BluetoothSession
"Connect" → connectionInput → connectedPeripheral → BluetoothSession.init()
```

### 3. Communication Phase
```
User Request → BluetoothSession → PeripheralService → Device
"Get Info" → session.requestInfo() → service.sendCommand() → BLE Response
```

## Key Design Principles

### Simple
- Single BluetoothController handles all core Bluetooth operations
- Clear separation between discovery, connection, and communication
- Minimal abstractions that map directly to functionality

### Testable
- Pure input/output interfaces using Combine
- No public methods - only reactive data flow
- Clear component boundaries enable isolated testing

### Modular
- Components can be used independently
- Connection-scoped services (BluetoothSession/PeripheralService)
- Composable through reactive wiring

### Architecture Benefits

1. **Unified Management**: Single controller for all Bluetooth operations
2. **Connection Lifecycle**: Services created/destroyed with connections
3. **Memory Efficient**: No persistent state between connections
4. **Error Recovery**: Connection failures automatically clean up
5. **Future Extensible**: Easy to add new communication patterns
