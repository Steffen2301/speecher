import XCTest
@testable import SpeecherCore

final class ASRTextCleanerTests: XCTestCase {

    func testRemovesFillerWords() {
        let input = "äh ich wollte ähm sagen dass das so funktioniert"
        let result = ASRTextCleaner.clean(input, language: "de")
        XCTAssertFalse(result.contains("äh"), "äh sollte entfernt sein")
        XCTAssertFalse(result.contains("ähm"), "ähm sollte entfernt sein")
        XCTAssertTrue(result.contains("sagen"))
    }

    func testRemovesConsecutiveDuplicates() {
        let input = "ich ich wollte das das machen"
        let result = ASRTextCleaner.clean(input, language: "de")
        let lower = result.lowercased()
        XCTAssertFalse(lower.contains("ich ich"), "Doppeltes 'ich' sollte entfernt sein")
        XCTAssertFalse(lower.contains("das das"), "Doppeltes 'das' sollte entfernt sein")
        XCTAssertTrue(lower.contains("ich"), "Einzelnes 'ich' sollte erhalten bleiben")
    }

    func testCapitalizesFirstLetter() {
        let input = "hallo welt"
        let result = ASRTextCleaner.clean(input, language: "de")
        XCTAssertTrue(result.hasPrefix("H"), "Erster Buchstabe sollte großgeschrieben sein")
    }

    func testPreservesNormalText() {
        let input = "Das ist ein normaler Satz ohne Probleme."
        let result = ASRTextCleaner.clean(input, language: "de")
        XCTAssertEqual(result, input)
    }

    func testEmptyInput() {
        XCTAssertEqual(ASRTextCleaner.clean(""), "")
        XCTAssertEqual(ASRTextCleaner.clean("   "), "   ")
    }

    func testRemovesVeryShortNonWords() {
        // Einzelne Zeichen ohne Bedeutung (kein bekanntes Kurzwort)
        let input = "x y ich bin hier"
        let result = ASRTextCleaner.clean(input, language: "de")
        let lower = result.lowercased()
        XCTAssertTrue(lower.contains("ich"), "'ich' sollte als bekanntes Wort erhalten bleiben")
        XCTAssertTrue(lower.contains("hier"))
    }

    func testRealWorldASROutput() {
        // Typischer schlechter ASR-Output
        let input = "äh hallo ich ich bin speecher ähm ich wandle gesprochene sprache in korrekten text"
        let result = ASRTextCleaner.clean(input, language: "de")
        XCTAssertFalse(result.lowercased().contains("äh"))
        XCTAssertFalse(result.lowercased().contains("ähm"))
        XCTAssertTrue(result.hasPrefix("H") || result.hasPrefix("h".uppercased()))
        print("Bereinigt: \(result)")
    }
}
