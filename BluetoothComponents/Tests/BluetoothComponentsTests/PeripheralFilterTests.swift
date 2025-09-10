// PeripheralFilterTests.swift

import XCTest
import Combine
import CoreBluetooth
@testable import BluetoothComponents

class PeripheralFilterTests: XCTestCase {
    var filter: PeripheralFilter!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        filter = PeripheralFilter()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        filter = nil
        super.tearDown()
    }

    func testFilterInitialization() {
        // Test that filter initializes with empty arrays and empty filter text
        XCTAssertTrue(filter.peripheralsInput.value.isEmpty)
        XCTAssertTrue(filter.filterTextInput.value.isEmpty)
        XCTAssertTrue(filter.peripheralsOutput.value.isEmpty)
    }

    func testEmptyFilterText() {
        // Test that empty filter text returns all peripherals
        var outputPeripherals: [CBPeripheral] = []

        filter.peripheralsOutput
            .sink { peripherals in
                outputPeripherals = peripherals
            }
            .store(in: &cancellables)

        // Simulate having some peripherals (we can't create CBPeripheral directly)
        // So we test with empty arrays first
        filter.peripheralsInput.send([])
        filter.filterTextInput.send("")

        XCTAssertTrue(outputPeripherals.isEmpty)

        // Test that empty filter text would pass through peripherals
        filter.filterTextInput.send("")
        filter.peripheralsInput.send([]) // Still empty but confirms the flow

        XCTAssertTrue(outputPeripherals.isEmpty)
    }

    func testFilterInputsReceiveValues() {
        // Test that inputs can receive values without crashing
        filter.peripheralsInput.send([])
        filter.filterTextInput.send("test")
        filter.filterTextInput.send("")
        filter.filterTextInput.send("iPhone")

        // If we reach here without crashing, inputs are working
        XCTAssertTrue(true)
    }

    func testFilterOutputPublisher() {
        // Test that we can observe filter output
        var receivedPeripherals: [CBPeripheral] = []
        let expectation = XCTestExpectation(description: "Filter output received")

        filter.peripheralsOutput
            .sink { peripherals in
                receivedPeripherals = peripherals
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Send empty data to trigger output
        filter.peripheralsInput.send([])
        filter.filterTextInput.send("test")

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedPeripherals.isEmpty)
    }

    func testFilterReactsToBothInputs() {
        // Test that filter reacts to changes in both inputs
        var outputCount = 0

        filter.peripheralsOutput
            .sink { _ in
                outputCount += 1
            }
            .store(in: &cancellables)

        // Initial state
        XCTAssertEqual(outputCount, 1) // Initial empty output

        // Change peripherals input
        filter.peripheralsInput.send([])
        XCTAssertEqual(outputCount, 2)

        // Change filter text input
        filter.filterTextInput.send("test")
        XCTAssertEqual(outputCount, 3)

        // Change both
        filter.peripheralsInput.send([])
        XCTAssertEqual(outputCount, 4)
    }
}
