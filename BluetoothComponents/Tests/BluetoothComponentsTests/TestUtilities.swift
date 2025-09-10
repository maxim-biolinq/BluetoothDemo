// TestUtilities.swift

import Foundation
import CoreBluetooth

// We don't need MockCBPeripheral since CBPeripheral.init() is unavailable
// Instead, we test filtering logic with the actual input/output streams

// Mock CBCentralManager for testing
class MockCBCentralManager: CBCentralManager {
    var mockState: CBManagerState = .unknown
    var scanForPeripheralsCalled = false
    var stopScanCalled = false
    var connectCalled = false
    var disconnectCalled = false
    var lastConnectedPeripheral: CBPeripheral?
    var lastDisconnectedPeripheral: CBPeripheral?

    override var state: CBManagerState {
        return mockState
    }

    override func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?) {
        scanForPeripheralsCalled = true
    }

    override func stopScan() {
        stopScanCalled = true
    }

    override func connect(_ peripheral: CBPeripheral, options: [String : Any]?) {
        connectCalled = true
        lastConnectedPeripheral = peripheral
    }

    override func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        disconnectCalled = true
        lastDisconnectedPeripheral = peripheral
    }
}
