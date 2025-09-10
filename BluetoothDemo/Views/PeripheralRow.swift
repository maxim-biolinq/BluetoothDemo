// PeripheralRow.swift

import SwiftUI
import CoreBluetooth

// MARK: - Peripheral Row View
// Simple SwiftUI view component for displaying peripheral devices
struct PeripheralRow: View {
    let peripheral: CBPeripheral
    let connectionState: CBPeripheralState
    let onConnect: (Bool) -> Void

    init(peripheral: CBPeripheral, connectionState: CBPeripheralState, onConnect: @escaping (Bool) -> Void) {
        self.peripheral = peripheral
        self.connectionState = connectionState
        self.onConnect = onConnect
    }

    var body: some View {
        HStack {
            Text(peripheral.name ?? "Unknown Device")
                .padding()

            Spacer()

            Button(buttonText) {
                onConnect(connectionState != .connected)
            }
            .padding()
            .background(buttonColor)
            .foregroundColor(.white)
        }
    }

    private var buttonText: String {
        switch connectionState {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        default: return "Connect"
        }
    }

    private var buttonColor: Color {
        switch connectionState {
        case .connected: return .green
        case .connecting: return .orange
        default: return .blue
        }
    }
}
