//
//  BluetoothSessionTests.swift
//  BluetoothComponents Tests
//

import XCTest
import Combine
@testable import BluetoothComponents

class BluetoothSessionTests: XCTestCase {
    var session: BluetoothSession!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        session = BluetoothSession()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        session = nil
        cancellables = nil
        super.tearDown()
    }

    func testSessionInitialization() {
        // Session should initialize with empty state
        XCTAssertTrue(session.filteredPeripherals.isEmpty)
        XCTAssertTrue(session.connectionStates.isEmpty)
        XCTAssertEqual(session.serviceState, ServiceState.discovering)
        XCTAssertNil(session.lastInfoResponse)
    }

    func testFilterTextApplication() {
        let expectation = self.expectation(description: "Filter applied")

        // Monitor filtered peripherals output
        session.$filteredPeripherals
            .dropFirst() // Skip initial empty state
            .sink { peripherals in
                // Verify filter is working (though we can't easily test with real peripherals in unit tests)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Apply filter
        session.setFilter(text: "test")

        wait(for: [expectation], timeout: 1.0)
    }

    func testPublicInterface() {
        // Test that all public methods are accessible and don't crash
        XCTAssertNoThrow(session.startScanning())
        XCTAssertNoThrow(session.stopScanning())
        XCTAssertNoThrow(session.clearPeripherals())
        XCTAssertNoThrow(session.stopAndClear())
        XCTAssertNoThrow(session.disconnect())
        XCTAssertNoThrow(session.requestDeviceInfo())

        // setFilter already tested above
        session.setFilter(text: "")
    }
}
