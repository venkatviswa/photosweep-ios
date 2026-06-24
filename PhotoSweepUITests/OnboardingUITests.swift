//
//  OnboardingUITests.swift
//  PhotoSweepUITests
//
//  Minimal launch smoke test for Phase 1. The full onboarding → scan → review
//  flow test arrives in Phase 4 (PS-044).
//

import XCTest

final class OnboardingUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
