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
        XCTAssertEqual(session.serviceState, ServiceState.discovering)
        XCTAssertNil(session.lastInfoResponse)
    }

    func testFilterTextApplication() {
        // Test that filter text can be set without throwing errors
        XCTAssertNoThrow(session.setFilter(text: "test"))
        XCTAssertNoThrow(session.setFilter(text: ""))
        XCTAssertNoThrow(session.setFilter(text: "Device"))

        // Test that session remains in a good state
        XCTAssertTrue(session.filteredPeripherals.isEmpty)
    }

    func testPublicInterface() {
        // Test that all public methods are accessible and don't crash
        XCTAssertNoThrow(session.startScanning())
        XCTAssertNoThrow(session.stopScanning())
        XCTAssertNoThrow(session.clearPeripherals())
        XCTAssertNoThrow(session.disconnect())
        XCTAssertNoThrow(session.requestDeviceInfo())

        // setFilter already tested above
        session.setFilter(text: "")
    }
}
