import Foundation
import Testing
@testable import OFFGRID

/// Guards the founder's platform decisions (ADR-013, ADR-018) against
/// accidental project-setting changes. The tests run inside the host app,
/// so `Bundle.main` is the built OFFGRID.app.
struct AppConfigurationTests {
    private let info = Bundle.main.infoDictionary ?? [:]

    @Test func bundleIdentifierIsOffgrid() {
        #expect(Bundle.main.bundleIdentifier == "com.offgrid.app")
    }

    @Test func displayNameIsOffgrid() {
        #expect(info["CFBundleDisplayName"] as? String == "Offgrid")
    }

    @Test func minimumIOSVersionIs26() {
        #expect(info["MinimumOSVersion"] as? String == "26.0")
    }

    @Test func runsOnIPhoneOnly() {
        // UIDeviceFamily 1 = iPhone, 2 = iPad.
        #expect(info["UIDeviceFamily"] as? [Int] == [1])
    }

    @Test func portraitOnly() {
        #expect(info["UISupportedInterfaceOrientations"] as? [String] == ["UIInterfaceOrientationPortrait"])
    }
}
