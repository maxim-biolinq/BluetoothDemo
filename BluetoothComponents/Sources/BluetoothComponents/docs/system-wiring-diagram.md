# System Wiring Diagram

This diagram shows how all components are composed together into a working Bluetooth scanning system.

## Complete System Architecture

```mermaid
graph TD
    %% External Inputs
    UT[User Text Input]
    UB1[User Button: Start]
    UB2[User Button: Stop/Clear]

    %% Components
    subgraph "BluetoothScanner"
        BSI[scanInput]
        BSO[peripheralsOutput]
    end

    subgraph "PeripheralFilter"
        PFI1[peripheralsInput]
        PFI2[filterTextInput]
        PFO[peripheralsOutput]
    end

    subgraph "BluetoothConnector"
        BCI[connectionInput]
        BCO[connectionOutput]
    end

    subgraph "PeripheralRow Views"
        PRI1[peripheral props]
        PRI2[connectionState props]
        PRO[onConnect callbacks]
    end

    subgraph "BluetoothView Orchestrator"
        BV[View Logic & Wiring]
    end

    %% User Input Wiring
    UT --> |send| PFI2
    UB1 --> |send .start| BSI
    UB2 --> |send .stop/.clear| BSI

    %% Component Output to Input Wiring
    BSO --> |onReceive -> send| PFI1
    PFO --> |Published binding| PRI1
    BCO --> |Published binding| PRI2
    PRO --> |callback -> send| BCI

    %% Shared Resources
    BSI -.-> |shares centralManager| BCI

    %% Data Flow Labels
    BSO -.- |"[CBPeripheral]"| PFI1
    PFO -.- |"[CBPeripheral] filtered"| PRI1
    BCO -.- |"[UUID: CBPeripheralState]"| PRI2
    PRO -.- |"ConnectionRequest"| BCI

    %% Styling
    classDef userInput fill:#fff3e0
    classDef component fill:#e1f5fe
    classDef input fill:#f3e5f5
    classDef output fill:#e8f5e8
    classDef orchestrator fill:#fce4ec

    class UT,UB1,UB2 userInput
    class BSI,PFI1,PFI2,BCI,PRI1,PRI2 input
    class BSO,PFO,BCO,PRO output
    class BV orchestrator
```

## Wiring Summary

### Data Flow Paths:

1. **User Text Input → Filter**
   - `TextField` binding → `PeripheralFilter.filterTextInput.send()`

2. **User Buttons → Scanner**
   - Button actions → `BluetoothScanner.scanInput.send(.start/.stop/.clear)`

3. **Scanner → Filter**
   - `BluetoothScanner.peripheralsOutput` → `PeripheralFilter.peripheralsInput.send()`

4. **Filter → UI**
   - `PeripheralFilter.filteredPeripherals` → `PeripheralRow` props via `@Published`

5. **Connector → UI**
   - `BluetoothConnector.connectionStates` → `PeripheralRow.connectionState` via `@Published`

6. **UI → Connector**
   - `PeripheralRow.onConnect` callback → `BluetoothConnector.connectionInput.send()`

### Key Architectural Features:

- **Pure Input/Output**: Each component exposes only input subjects and output publishers
- **Reactive Composition**: Components are wired using Combine publishers and SwiftUI bindings
- **Shared Resources**: Scanner and Connector share the same `CBCentralManager` instance
- **Unidirectional Data Flow**: Clear flow from user actions through components to UI updates
- **Encapsulation**: All internal logic is private; only input/output ports are exposed

This architecture follows Unix philosophy principles where complex behavior emerges from simple components connected through well-defined interfaces.
