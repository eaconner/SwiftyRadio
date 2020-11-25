import XCTest
@testable import SwiftyRadio

final class SwiftyRadioTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftyRadio().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
