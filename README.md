# PhotoSweep

**Cross-cloud photo deduplication for iOS.** Find duplicate photos across iCloud and Google Photos. Nothing gets deleted unless you say so.

## Quick Start

### Prerequisites
- Mac with Apple Silicon (M1 or later)
- Xcode 26+
- iOS 26+ device or simulator
- Apple Developer Program membership ($99/year)
- Google Cloud Console project with Photos Library API enabled

### Setup

```bash
# Clone
git clone git@github.com:YOUR_USERNAME/photosweep-ios.git
cd photosweep-ios

# Create your local config (git-ignored)
cp Config.xcconfig.example Config.xcconfig
# Edit Config.xcconfig with your Google Client ID, Bundle ID, etc.

# Install tools
brew install swiftlint fastlane

# Open in Xcode
open PhotoSweep.xcodeproj
```

### Run
- **Simulator:** `Cmd+R` in Xcode (iCloud only — Google Photos requires device)
- **Device:** Select your device in Xcode scheme → `Cmd+R`

### Test
```bash
# Run all tests
Cmd+U in Xcode

# Lint
swiftlint lint --strict
```

### Deploy
```bash
# TestFlight
fastlane beta

# App Store
fastlane release
```

## Architecture

```
100% on-device. No backend. No cloud functions. No servers.

┌──────────────────────────────────────────────┐
│                  SwiftUI Views               │
│        (Onboarding, Scan, Review, Home)      │
├──────────────────────────────────────────────┤
│                  ViewModels                  │
│    (OnboardingVM, ScanVM, ReviewVM, HomeVM)   │
├──────────────────────────────────────────────┤
│                   Services                   │
│  ┌────────────┐ ┌────────────┐ ┌──────────┐ │
│  │  PhotoKit   │ │Google API  │ │ Duplicate│ │
│  │  (iCloud)   │ │  (OAuth)   │ │  Engine  │ │
│  └────────────┘ └────────────┘ └──────────┘ │
├──────────────────────────────────────────────┤
│          SwiftData (local SQLite)            │
└──────────────────────────────────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Claude Code project configuration — coding standards, architecture decisions, API quirks |
| `SPEC.md` | Complete product specification — user flows, data model, detection pipeline |
| `PLAN.md` | Development phases with stories and acceptance criteria |

## Tech Stack

- **Swift 6** / SwiftUI / SwiftData
- **PhotoKit** — iCloud photo access
- **Google Photos REST API** — OAuth 2.0 + mediaItems
- **CryptoKit** — SHA-256 hashing
- **Vision** — Perceptual similarity (Phase 2)
- **Core Image** — pHash generation
- **StoreKit 2** — In-app purchase
- **TelemetryDeck** — Privacy-friendly analytics
- **Sentry** — Crash reporting
- **Fastlane** — CI/CD automation

## Revenue Model

- **Free:** Scan up to 1,000 photos. Tag duplicates.
- **Deep Clean ($14.99 one-time):** Unlimited scanning + all disposal options.

## Team

Built by a two-person team as a side project. Evenings and weekends.

## License

Proprietary. All rights reserved.
