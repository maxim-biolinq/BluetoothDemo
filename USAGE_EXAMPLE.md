# BluetoothDemo Info Request Usage Example

## Quick Start

The `getinfo` functionality has been successfully implemented and integrated into the app. Here's how to use it:

### Basic Usage

1. **Start the app** and begin scanning for devices
2. **Connect to a device** using the existing connect functionality
3. **Request device info** by tapping the "Get Info" button in the UI

### Programmatic Usage

```swift
// In your view model or controller
let viewModel = BluetoothViewModel()

// Connect to a device first
viewModel.connect(peripheral: somePeripheral, shouldConnect: true)

// Request device info
viewModel.requestDeviceInfo()

// Subscribe to info responses
viewModel.$lastInfoResponse
    .sink { infoResponse in
        if let info = infoResponse {
            print("Device has \(info.numBlocks) blocks")
            print("Timestamp: \(info.timestamp)")
            print("Status: \(info.status)")
        }
    }
    .store(in: &cancellables)
```

### API Reference

#### BluetoothController

- `requestDeviceInfo()` - Initiates an info request
- `infoResponseOutput` - PublishesSubject for info responses

#### BluetoothViewModel

- `requestDeviceInfo()` - Initiates an info request
- `@Published lastInfoResponse` - Latest info response data

#### InfoResponseData

```swift
public struct InfoResponseData {
    public let numBlocks: UInt32    // Number of data blocks
    public let timestamp: UInt32    // Device timestamp
    public let status: String       // Device status ("ok", "error", etc.)
}
```

### Message Flow

1. **User Action**: Tap "Get Info" button or call `requestDeviceInfo()`
2. **Request Construction**: Creates BLE protobuf message with InfoRequest
3. **BLE Transmission**: Sends message via command characteristic
4. **Device Response**: Device sends InfoResponse via response characteristic
5. **Response Parsing**: Parses protobuf response and extracts data
6. **UI Update**: Updates UI via reactive binding

### Example Device Response

```
Device Info:
Num Blocks: 42
Timestamp: 1694276400
Status: ok
```

### Error Handling

- Connection validation before sending requests
- Protobuf serialization/deserialization error handling
- Timeout handling can be added at the UI level
- Failed requests result in `nil` being published to `infoResponseOutput`

### Integration Notes

- The implementation follows the existing reactive architecture pattern
- All updates happen on the main thread for UI safety
- The protobuf message structure matches the Python reference implementation
- SwiftProtobuf dependency is automatically managed by the package system
