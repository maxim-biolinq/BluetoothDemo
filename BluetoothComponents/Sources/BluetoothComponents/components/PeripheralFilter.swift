// PeripheralFilter.swift

import Foundation
import CoreBluetooth
import Combine

// MARK: - Peripheral Filter Component
// Input: peripherals and filter text
// Output: filtered peripherals
public class PeripheralFilter {
    // Pure inputs - external components write to these
    public let peripheralsInput = CurrentValueSubject<[CBPeripheral], Never>([])
    public let filterTextInput = CurrentValueSubject<String, Never>("")

    // Pure output - external components read from this
    public let peripheralsOutput = CurrentValueSubject<[CBPeripheral], Never>([])
    
    public var cancellables = Set<AnyCancellable>()

    public init() {
        cancellables.store {
            Publishers.CombineLatest(peripheralsInput, filterTextInput)
                .map { peripherals, filterText in
                    guard !filterText.isEmpty else { return peripherals }
                    return peripherals.filter { peripheral in
                        peripheral.name?.lowercased().hasPrefix(filterText.lowercased()) ?? false
                    }
                }
                .send(to: \.peripheralsOutput, on: self)
        }
    }
}
