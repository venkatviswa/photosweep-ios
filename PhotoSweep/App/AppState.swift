//
//  AppState.swift
//  PhotoSweep
//
//  Global, observable app state injected through the SwiftUI environment.
//  Kept deliberately small — feature state lives in the relevant ViewModels.
//

import Foundation
import Observation

@Observable
final class AppState {
    /// Whether the user has completed first-launch onboarding.
    var hasCompletedOnboarding: Bool

    /// Whether the user has unlocked the paid "Deep Clean" tier.
    var hasDeepClean: Bool

    init(hasCompletedOnboarding: Bool = false, hasDeepClean: Bool = false) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasDeepClean = hasDeepClean
    }
}
