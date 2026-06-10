import Testing
@testable import SpeecherCore

@Test func versionIsSet() {
    #expect(!SpeecherCore.version.isEmpty)
}
