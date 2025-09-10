# Component Architecture Diagrams

This folder contains mermaid diagrams showing each component individually and how they compose into a working system.

## Individual Component Diagrams

### BluetoothScanner Component

```mermaid
graph TD
    subgraph "BluetoothScanner"
        SI[scanInput: ScanCommand] --> |sink| SL[Internal Logic]
        SL --> |handleScanCommand| CM[CBCentralManager]
        CM --> |didDiscover| DP[Published discoveredPeripherals]
        DP --> SO[peripheralsOutput: AnyPublisher]

        subgraph "Private Implementation"
            SL
            CM
            CC[cancellables]
            HSC[handleScanCommand]
        end

        subgraph "Public Interface"
            SI
            SO
        end
    end

    %% Styling
    classDef input fill:#f3e5f5
    classDef output fill:#e8f5e8
    classDef private fill:#f5f5f5

    class SI input
    class SO output
    class SL,CM,CC,HSC private
```

### BluetoothConnector Component

```mermaid
graph TD
    subgraph "BluetoothConnector"
        CI[connectionInput: ConnectionRequest] --> |sink| CL[Internal Logic]
        CL --> |handleConnectionRequest| CM[CBCentralManager]
        CM --> |didConnect/didDisconnect| CS[Published connectionStates]
        CS --> CO[connectionOutput: AnyPublisher]

        subgraph "Private Implementation"
            CL
            CM
            CC[cancellables]
            HCR[handleConnectionRequest]
        end

        subgraph "Public Interface"
            CI
            CO
        end
    end

    %% Styling
    classDef input fill:#f3e5f5
    classDef output fill:#e8f5e8
    classDef private fill:#f5f5f5

    class CI input
    class CO output
    class CL,CM,CC,HCR private
```

### PeripheralFilter Component

```mermaid
graph TD
    subgraph "PeripheralFilter"
        PI[peripheralsInput: CBPeripheral array] --> |CombineLatest| FL[Filter Logic]
        FI[filterTextInput: String] --> |CombineLatest| FL
        FL --> |map| FP[Published filteredPeripherals]
        FP --> PO[peripheralsOutput: AnyPublisher]

        subgraph "Private Implementation"
            FL
            CC[cancellables]
            MAP[map filter function]
        end

        subgraph "Public Interface"
            PI
            FI
            PO
        end
    end

    %% Styling
    classDef input fill:#f3e5f5
    classDef output fill:#e8f5e8
    classDef private fill:#f5f5f5

    class PI,FI input
    class PO output
    class FL,CC,MAP private
```

### PeripheralRow Component

```mermaid
graph TD
    subgraph "PeripheralRow View"
        P[peripheral: CBPeripheral] --> |render| UI[UI Elements]
        CS[connectionState: CBPeripheralState] --> |render| UI
        UI --> |Button onTapGesture| OC[onConnect: Bool -> Void]

        subgraph "Private Implementation"
            BT[buttonText computed]
            BC[buttonColor computed]
            UI
        end

        subgraph "Public Interface"
            P
            CS
            OC
        end
    end

    %% Styling
    classDef input fill:#f3e5f5
    classDef output fill:#e8f5e8
    classDef private fill:#f5f5f5

    class P,CS input
    class OC output
    class BT,BC,UI private
```
