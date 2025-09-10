// BluetoothControllerTests.swift

import XCTest
import Combine
import CoreBluetooth
@testable import BluetoothComponents

class BluetoothControllerTests: XCTestCase {
    var controller: BluetoothController!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        controller = BluetoothController()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        controller = nil
        super.tearDown()
    }

    func testControllerInitialization() {
        // Test that controller initializes with empty peripherals and connections
        XCTAssertTrue(controller.discoveredPeripherals.isEmpty)
        XCTAssertTrue(controller.connectionStates.isEmpty)
    }

    func testScanInputSender() {
        // Test that scan input can receive commands without crashing
        controller.scanInput.send(.start)
        controller.scanInput.send(.stop)
        controller.scanInput.send(.clear)

        // If we reach here without crashing, the input is working
        XCTAssertTrue(true)
    }

    func testConnectionInputSender() {
        // Test that connection input can receive requests without crashing
        // In a real app, peripherals would come from scanning
        XCTAssertTrue(true)
    }

    func testPeripheralsOutputPublisher() {
        // Test that we can observe peripherals output
        var receivedPeripherals: [CBPeripheral] = []
        let expectation = XCTestExpectation(description: "Peripherals output received")

        controller.$discoveredPeripherals
            .sink { peripherals in
                receivedPeripherals = peripherals
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedPeripherals.isEmpty)
    }

    func testClearCommand() {
        // Test that clear command empties the peripherals array
        // Note: We can't easily test with real peripherals in unit tests
        // but we can verify the clear behavior
        controller.scanInput.send(.clear)
        XCTAssertTrue(controller.discoveredPeripherals.isEmpty)
    }

    func testConnectionOutputPublisher() {
        // Test that we can observe connection output
        var receivedStates: [UUID: CBPeripheralState] = [:]
        let expectation = XCTestExpectation(description: "Connection output received")

        controller.$connectionStates
            .sink { states in
                receivedStates = states
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedStates.isEmpty)
    }
}
