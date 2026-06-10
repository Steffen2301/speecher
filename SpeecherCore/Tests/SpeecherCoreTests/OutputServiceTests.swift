import XCTest
@testable import SpeecherCore

final class OutputResultTests: XCTestCase {
    func testAllCasesExist() {
        let cases: [OutputResult] = [
            .insertedAtCursor,
            .pastedViaSimulation,
            .copiedToClipboard,
            .noTargetSaved
        ]
        XCTAssertEqual(cases.count, 4)
    }
}

final class OutputErrorTests: XCTestCase {
    func testErrorDescriptions() {
        let errors: [OutputError] = [
            .accessibilityDenied,
            .insertionFailed("AX error -25212")
        ]
        for e in errors {
            XCTAssertFalse(e.errorDescription?.isEmpty ?? true)
        }
    }

    func testAccessibilityDeniedMentionsSettings() {
        let msg = OutputError.accessibilityDenied.errorDescription ?? ""
        XCTAssertTrue(msg.contains("Systemeinstellungen") || msg.contains("Accessibility"))
    }
}
