// BluetoothController.swift

import Foundation
import CoreBluetooth
import Combine

// MARK: - Bluetooth Controller Component
// Input: scan and connection commands
// Output: discovered peripherals, connection states, and connected peripheral
public class BluetoothController: NSObject, ObservableObject, CBCentralManagerDelegate {

    private var centralManager: CBCentralManager!

    // Scan inputs/outputs
    public let scanInput = PassthroughSubject<ScanCommand, Never>()
    @Published public var discoveredPeripherals: [CBPeripheral] = []

    // Connection inputs/outputs
    public let connectionInput = PassthroughSubject<ConnectionRequest, Never>()
    @Published public var connectionStates: [UUID: CBPeripheralState] = [:]
    @Published public var connectedPeripheral: CBPeripheral?

    private var cancellables = Set<AnyCancellable>()

    public enum ScanCommand {
        case start
        case stop
        case clear
    }

    public enum ConnectionRequest {
        case connect(CBPeripheral)
        case disconnect
    }

    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main, options: [
            CBCentralManagerOptionRestoreIdentifierKey: "com.biolinq.gemini.bluetooth",
            CBCentralManagerOptionShowPowerAlertKey: true
        ])

        scanInput
            .sink { [weak self] command in
                self?.handleScanCommand(command)
            }
            .store(in: &cancellables)

        connectionInput
            .sink { [weak self] request in
                self?.handleConnectionRequest(request)
            }
            .store(in: &cancellables)
    }

    private func handleScanCommand(_ command: ScanCommand) {
        switch command {
        case .start:
            if centralManager.state == .poweredOn {
                centralManager.scanForPeripherals(withServices: nil, options: nil)
            }
        case .stop:
            centralManager.stopScan()
        case .clear:
            discoveredPeripherals = []
        }
    }

    private func handleConnectionRequest(_ request: ConnectionRequest) {
        switch request {
        case .connect(let peripheral):
            centralManager.connect(peripheral, options: [
                CBConnectPeripheralOptionNotifyOnConnectionKey: true,
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
            ])
        case .disconnect:
            if let peripheral = connectedPeripheral {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth ready")
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionStates[peripheral.identifier] = .connected
        connectedPeripheral = peripheral
        centralManager.stopScan()
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionStates[peripheral.identifier] = .disconnected
        if connectedPeripheral == peripheral {
            connectedPeripheral = nil
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionStates[peripheral.identifier] = .disconnected
        if connectedPeripheral == peripheral {
            connectedPeripheral = nil
        }

//        // Auto-reconnect
//        centralManager.connect(peripheral, options: [
//            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
//            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
//        ])
    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            discoveredPeripherals = peripherals
        }
    }

}
