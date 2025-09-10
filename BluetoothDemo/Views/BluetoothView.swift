// BluetoothView.swift

import SwiftUI
import CoreBluetooth
import Combine
import BluetoothComponents

// MARK: - Main View Component
struct BluetoothView: View {
    @StateObject private var session = BluetoothSession()
    @State private var filterText = ""

    var body: some View {
        VStack {
            TextField("Enter prefix", text: $filterText)
                .onChange(of: filterText) {
                    session.setFilter(text: filterText)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Start Scanning") {
                    session.startScanning()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)

                Button("Clear & Stop") {
                    session.stopScanning()
                    session.clearPeripherals()                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)

                Button("Get Info") {
                    session.requestDeviceInfo()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
            }

            // Info Response Display
            if let info = session.lastInfoResponse {
                VStack(alignment: .leading) {
                    Text("Device Info:")
                        .font(.headline)
                        .padding(.top)
                    Text("Num Blocks: \(info.numBlocks)")
                    Text("Timestamp: \(String(info.timestamp))")
                    Text("Status: \(info.status)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            List(session.filteredPeripherals, id: \.identifier) { peripheral in
                PeripheralRow(
                    peripheral: peripheral,
                    connectionState: session.connectionStates[peripheral.identifier] ?? .disconnected,
                    onConnect: { shouldConnect in
                        session.connect(peripheral: peripheral)
                    }
                )
            }
        }
        .padding()
    }
}
