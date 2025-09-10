# Refactored System Wiring Diagram

This diagram shows how the refactored components compose into a working system following our modular architecture principles.

## Complete Refactored System Architecture

```mermaid
graph TD
    %% External Inputs
    UT[User Text Input]
    UB1[User Button: Start Scan]
    UB2[User Button: Stop/Clear]
    UB3[User Button: Connect/Disconnect]
    UB4[User Button: Get Info]

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
        BCPO[connectedPeripheralOutput]
    end

    subgraph "ServiceDiscoverer"
        SDI[peripheralInput]
        SDO1[servicesOutput]
        SDO2[characteristicsOutput]
    end

    subgraph "DeviceInfoRequester"
        DIRI[requestInput]
        DICI[characteristicsInput]
        DIRO[responseOutput]
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
    UT --> |TextField binding| PFI2
    UB1 --> |send .start| BSI
    UB2 --> |send .stop/.clear| BSI
    UB3 --> |send ConnectionRequest| BCI
    UB4 --> |send ()| DIRI

    %% Component Wiring
    BSO --> |onReceive -> send| PFI1
    PFO --> |Published binding| PRI1
    BCO --> |Published binding| PRI2
    BCPO --> |onReceive -> send| SDI
    SDO2 --> |onReceive -> send| DICI
    PRO --> |callback -> send| BCI

    %% UI Bindings
    DIRO --> |Published binding| BV

    %% Data Flow Labels
    BSO -.- |"[CBPeripheral]"| PFI1
    PFO -.- |"[CBPeripheral] filtered"| PRI1
    BCO -.- |"[UUID: CBPeripheralState]"| PRI2
    BCPO -.- |"CBPeripheral?"| SDI
    SDO2 -.- |"[CBCharacteristic]"| DICI
    DIRO -.- |"InfoResponseData?"| BV

    %% Styling
    classDef userInput fill:#fff3e0
    classDef component fill:#e1f5fe
    classDef input fill:#f3e5f5
    classDef output fill:#e8f5e8
    classDef orchestrator fill:#fce4ec

    class UT,UB1,UB2,UB3,UB4 userInput
    class BSI,PFI1,PFI2,BCI,SDI,DIRI,DICI,PRI1,PRI2 input
    class BSO,PFO,BCO,BCPO,SDO1,SDO2,DIRO,PRO output
    class BV orchestrator
```

## Wiring Flow Sequence

### 1. Scanning Phase
```
User Action → BluetoothScanner → PeripheralFilter → UI
UB1 (Start) → BSI → BSO → PFI1 → PFO → PRI1 (List Display)
```

### 2. Connection Phase
```
User Selection → BluetoothConnector → ServiceDiscoverer
UB3 (Connect) → BCI → BCO → PRI2 (State Update)
                    └→ BCPO → SDI → Discovery Process
```

### 3. Service Discovery Phase
```
Connected Peripheral → ServiceDiscoverer → DeviceInfoRequester
BCPO → SDI → SDO2 → DICI (Characteristics Available)
```

### 4. Info Request Phase
```
User Action → DeviceInfoRequester → UI
UB4 (Get Info) → DIRI → DIRO → BV (Info Display)
```

## Component Interactions

### Sequential Dependencies
1. **Scanner** discovers devices
2. **Filter** refines the list
3. **Connector** manages connections
4. **Discoverer** finds services/characteristics
5. **InfoRequester** communicates with device

### Parallel Operations
- Scanner and Filter work together continuously
- Connector state updates happen independently
- InfoRequester can work with any connected device

### Shared Resources
- All components that need CBCentralManager share the same instance
- CBPeripheral instances are passed between components as needed
- No components directly modify shared state

## Architecture Benefits

### Separation of Concerns
- **Scanning**: Only handles device discovery
- **Connection**: Only handles connection lifecycle
- **Discovery**: Only handles service/characteristic discovery
- **Info Request**: Only handles device communication protocol
- **Filtering**: Only handles search logic

### Testability
- Each component can be tested with mock inputs
- No complex interdependencies
- Clear input/output contracts

### Simplicity
- Single responsibility per component
- Minimal interfaces (PassthroughSubject inputs, @Published outputs)
- No public methods - pure data flow architecture

### Modularity
- Components can be reused in different contexts
- Easy to add new capabilities without touching existing code
- Clear boundaries between responsibilities
