import XCTest
@testable import SpeecherCore

final class SpeecherCoreTests: XCTestCase {
    func testVersionIsSet() {
        XCTAssertFalse(SpeecherCore.version.isEmpty)
    }
}
