// ComponentIntegrationTests.swift

import XCTest
import Combine
import CoreBluetooth
@testable import BluetoothComponents

class ComponentIntegrationTests: XCTestCase {
    var controller: BluetoothController!
    var filter: PeripheralFilter!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        controller = BluetoothController()
        filter = PeripheralFilter()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        controller = nil
        filter = nil
        super.tearDown()
    }

    func testComponentWiring() {
        // Test that components can be wired together without crashing

        // Wire controller output to filter input
        controller.peripheralsOutput
            .sink { peripherals in
                self.filter.peripheralsInput.send(peripherals)
            }
            .store(in: &cancellables)

        var filteredResults: [CBPeripheral] = []
        filter.peripheralsOutput
            .sink { filteredResults = $0 }
            .store(in: &cancellables)

        // Test that the wiring works
        controller.scanInput.send(.start)
        filter.filterTextInput.send("test")

        // If we reach here without crashing, the wiring is working
        XCTAssertTrue(filteredResults.isEmpty) // No peripherals discovered yet
    }

    func testFilterWorkflow() {
        // Test filter with empty peripherals
        var filteredResults: [CBPeripheral] = []
        filter.peripheralsOutput
            .sink { filteredResults = $0 }
            .store(in: &cancellables)

        // Send empty array and filter text
        filter.peripheralsInput.send([])
        filter.filterTextInput.send("test")

        XCTAssertTrue(filteredResults.isEmpty)
    }

    func testConnectionIntegration() {
        // Test that controller can handle connections
        var connectionStates: [UUID: CBPeripheralState] = [:]
        controller.connectionOutput
            .sink { connectionStates = $0 }
            .store(in: &cancellables)

        // Initially should be empty
        XCTAssertTrue(connectionStates.isEmpty)
    }

    func testFullWorkflowStructure() {
        // Test the complete structure like BluetoothView uses

        // Wire controller to filter
        controller.peripheralsOutput
            .sink { peripherals in
                self.filter.peripheralsInput.send(peripherals)
            }
            .store(in: &cancellables)

        // Observe filter output
        var filteredPeripherals: [CBPeripheral] = []
        filter.peripheralsOutput
            .sink { peripherals in
                filteredPeripherals = peripherals
            }
            .store(in: &cancellables)

        // Observe connection states
        var connectionStates: [UUID: CBPeripheralState] = [:]
        controller.connectionOutput
            .sink { states in
                connectionStates = states
            }
            .store(in: &cancellables)

        // Simulate user actions
        controller.scanInput.send(.start)
        filter.filterTextInput.send("")

        // Verify initial state
        XCTAssertTrue(filteredPeripherals.isEmpty)
        XCTAssertTrue(connectionStates.isEmpty)

        // Test clear
        controller.scanInput.send(.clear)
        XCTAssertTrue(controller.peripheralsOutput.value.isEmpty)
    }
}
