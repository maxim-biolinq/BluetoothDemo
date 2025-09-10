// BluetoothView.swift

import SwiftUI
import CoreBluetooth
import Combine
import BluetoothComponents

// MARK: - Main View Component
// Orchestrates the modular components by wiring inputs to outputs
struct BluetoothView: View {
    @StateObject private var viewModel = BluetoothViewModel()

    var body: some View {
        VStack {
            TextField("Enter prefix", text: $viewModel.filterText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Start Scanning") {
                    viewModel.startScanning()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)

                Button("Clear & Stop") {
                    viewModel.stopAndClear()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)

                Button("Get Info") {
                    viewModel.requestDeviceInfo()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
            }

            // Info Response Display
            if let info = viewModel.lastInfoResponse {
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

            List(viewModel.filteredPeripherals, id: \.identifier) { peripheral in
                PeripheralRow(
                    peripheral: peripheral,
                    connectionState: viewModel.connectionStates[peripheral.identifier] ?? .disconnected,
                    onConnect: { shouldConnect in
                        viewModel.connect(peripheral: peripheral)
                    }
                )
            }
        }
        .padding()
    }
}
