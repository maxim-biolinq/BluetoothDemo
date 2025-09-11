# Protobuf Submodule Management

This project uses a git submodule to manage protobuf definitions from the upstream repository.

## Submodule Details

- **Repository**: https://github.com/srozell-biolinq/iris-protobuf.git
- **Path**: `Sources/BluetoothComponents/protobuf`
- **Generated Swift files**: `Sources/BluetoothComponents/protobuf/generated/swift/source/`

## Common Operations

### Initial Setup (for new clones)
```bash
# Initialize and update submodule
git submodule update --init --recursive
```

### Update to Latest Changes
```bash
# Simple update to latest (recommended)
git submodule update --remote
git add .
git commit -m "Update protobuf submodule to latest"
```

### Manual Update (if you need more control)
```bash
# Update submodule to latest from upstream manually
cd Sources/BluetoothComponents/protobuf
git pull origin main
cd ../../..
git add Sources/BluetoothComponents/protobuf
git commit -m "Update protobuf submodule to latest"
```

### Check Status
```bash
# See current submodule status
git submodule status

# See what changed in submodule
cd Sources/BluetoothComponents/protobuf
git log --oneline -5
```

### Reset Submodule
```bash
# Reset submodule to committed version
git submodule update --recursive
```

## Integration Notes

- The Swift protobuf files are automatically included in the build via `Package.swift`
- The code has been updated to work with the new simplified protobuf structure
- All tests pass with the new protobuf schema

## Migration Notes

The protobuf schema was simplified to reduce overhead:
- Removed nested channel structure (`rx_msg`/`tx_msg`)
- Messages are now direct fields of `BLEMessage`
- Added new fields: `rsp_num` and `crc32`
- Available message types: `info_request`, `info_response`, `e_data_block_request`, `e_data_block_response`, `start_sensor_command`, `status_event`
