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

                Button("Get EData") {
                    session.requestEDataRange(0...2)
                }
                .padding()
                .background(Color.orange)
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

            // Multi-Block EData Response Display
            if !session.eDataBlocks.isEmpty {
                VStack(alignment: .leading) {
                    Text("EData Blocks (0, 1, 2):")
                        .font(.headline)
                        .padding(.top)

                    Text("Total Combined Length: \(session.combinedEDataBlocks.count) bytes")
                    Text("Combined Preview: \(session.combinedEDataBlocks.prefix(32).map { String(format: "%02x", $0) }.joined(separator: " "))")
                        .font(.system(.body, design: .monospaced))

                    ForEach(session.eDataBlocks, id: \.blockNum) { result in
                        Text("Block \(result.blockNum): \(result.data.count) bytes - \(result.data.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " "))")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }

            // Loading indicator for multi-block requests
            if session.isMultiBlockRequestActive {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Requesting blocks 0, 1, 2...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            List(session.filteredPeripherals, id: \.identifier) { peripheral in
                PeripheralRow(
                    peripheral: peripheral,
                    onConnect: { shouldConnect in
                        if shouldConnect {
                            session.connect(peripheral: peripheral)
                        } else {
                            session.disconnect()
                        }
                    }
                )
            }
        }
        .padding()
    }
}
