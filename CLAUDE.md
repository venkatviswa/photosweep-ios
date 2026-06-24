# CLAUDE.md — PhotoSweep

## Project Overview

PhotoSweep is a cross-cloud photo deduplication iOS app. It connects to iCloud and Google Photos, scans for duplicate photos across both platforms, and lets users review and manage duplicates without ever deleting anything automatically.

**Core promise:** "We never delete a single photo."

**Architecture:** 100% on-device. No backend. No server. No cloud functions. Everything runs on the user's iPhone.

---

## Behavioral Guidelines (Karpathy Principles)

> Adapted from [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills). These bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

**The test:** Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## Tech Stack

- **Language:** Swift 6 / SwiftUI
- **Minimum iOS:** iOS 26
- **Data:** SwiftData (SQLite under the hood)
- **Photo access:** PhotoKit (iCloud), Google Photos REST API via OAuth 2.0
- **Duplicate detection:** CryptoKit (SHA-256 exact hash), Vision framework (perceptual/feature-based similarity), Core Image (pHash generation)
- **Networking:** URLSession (no Alamofire — keep dependencies minimal)
- **Auth:** ASWebAuthenticationSession for Google OAuth
- **In-App Purchases:** StoreKit 2 (one-time purchase initially, subscriptions later)
- **Analytics:** TelemetryDeck SDK (privacy-friendly)
- **Crash reporting:** Sentry SDK

## Project Structure

```
PhotoSweep/
├── PhotoSweep/
│   ├── App/
│   │   ├── PhotoSweepApp.swift          # App entry point
│   │   └── AppState.swift               # Global app state
│   ├── Models/
│   │   ├── UnifiedPhoto.swift           # Core photo model (cross-platform)
│   │   ├── DuplicateGroup.swift         # Group of duplicate photos
│   │   ├── ScanResult.swift             # Scan session result
│   │   └── CloudAccount.swift           # Connected cloud account
│   ├── Services/
│   │   ├── PhotoKit/
│   │   │   ├── ICloudPhotoService.swift     # PhotoKit integration
│   │   │   └── ICloudPhotoImporter.swift    # Import iCloud photo metadata
│   │   ├── GooglePhotos/
│   │   │   ├── GoogleAuthService.swift      # OAuth 2.0 flow
│   │   │   ├── GooglePhotosAPI.swift        # REST API client
│   │   │   └── GooglePhotoImporter.swift    # Import Google Photos metadata
│   │   ├── DuplicateDetection/
│   │   │   ├── HashingService.swift         # SHA-256 exact hashing
│   │   │   ├── PerceptualHashService.swift  # pHash generation via Core Image
│   │   │   ├── VisualSimilarityService.swift # Vision framework feature vectors
│   │   │   └── DuplicateEngine.swift        # Orchestrates all detection methods
│   │   ├── ScanService.swift            # Manages scan lifecycle
│   │   └── PurchaseService.swift        # StoreKit 2 integration
│   ├── Views/
│   │   ├── Onboarding/
│   │   │   ├── WelcomeView.swift
│   │   │   ├── ConnectCloudsView.swift
│   │   │   └── PermissionsView.swift
│   │   ├── Home/
│   │   │   ├── HomeView.swift               # Main dashboard
│   │   │   └── StorageSavingsCard.swift
│   │   ├── Scan/
│   │   │   ├── ScanProgressView.swift
│   │   │   └── ScanCompleteView.swift
│   │   ├── Review/
│   │   │   ├── DuplicateReviewView.swift    # Swipe-to-review interface
│   │   │   ├── DuplicateGroupCard.swift
│   │   │   └── PhotoComparisonView.swift
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   ├── ConnectedAccountsView.swift
│   │   │   └── AboutView.swift
│   │   └── Components/
│   │       ├── PhotoThumbnail.swift
│   │       ├── CloudBadge.swift
│   │       └── TrustBanner.swift
│   ├── ViewModels/
│   │   ├── OnboardingViewModel.swift
│   │   ├── HomeViewModel.swift
│   │   ├── ScanViewModel.swift
│   │   └── ReviewViewModel.swift
│   ├── Utilities/
│   │   ├── ImageHasher.swift
│   │   ├── EXIFExtractor.swift
│   │   ├── DateNormalizer.swift          # Handle timezone mismatches
│   │   └── StorageCalculator.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── Localizable.strings
├── PhotoSweepTests/
│   ├── Services/
│   │   ├── HashingServiceTests.swift        # HIGH PRIORITY
│   │   ├── PerceptualHashServiceTests.swift # HIGH PRIORITY
│   │   ├── DuplicateEngineTests.swift       # HIGH PRIORITY
│   │   ├── GoogleAuthServiceTests.swift
│   │   └── GooglePhotosAPITests.swift
│   ├── Models/
│   │   └── UnifiedPhotoTests.swift
│   └── Utilities/
│       ├── DateNormalizerTests.swift
│       └── ImageHasherTests.swift
├── PhotoSweepUITests/
│   └── OnboardingUITests.swift
├── fastlane/
│   └── Fastfile
├── .swiftlint.yml
├── .gitignore
├── CLAUDE.md                            # This file
├── SPEC.md                              # Product specification
├── PLAN.md                              # Development phases
└── README.md
```

## Coding Standards

### Swift Style
- Use Swift 6 strict concurrency. All async work uses structured concurrency (`async/await`, `TaskGroup`).
- Prefer `@Observable` macro over `ObservableObject` (SwiftUI Observation framework).
- Use SwiftData `@Model` macro for persistence. No raw Core Data.
- MVVM architecture: Views → ViewModels → Services → Models.
- No force unwraps (`!`) except in tests and for IBOutlet-equivalent patterns.
- Use `guard` for early returns. Keep the happy path unindented.
- File names match the primary type they contain.

### SwiftUI Conventions
- Views are small and composable. If a View body exceeds ~50 lines, extract subviews.
- Use `@Environment` for dependency injection over singletons.
- Prefer `NavigationStack` over deprecated `NavigationView`.
- Use `.task {}` modifier for async data loading, not `onAppear` with Task {}.
- All user-facing strings go through `Localizable.strings` even in MVP.

### Error Handling
- Never silently swallow errors. Log with `os.Logger` at minimum.
- All user-facing errors get a clear, non-technical message.
- Google Photos API errors must distinguish between auth failures (re-auth needed) vs API errors (retry) vs quota errors (back off).

### Security & Privacy
- NEVER persist raw Google OAuth tokens in UserDefaults. Use Keychain via `KeychainAccess` or the Security framework.
- NEVER upload photo data to any server. All processing is on-device.
- NEVER request write/delete permissions for photos unless the user explicitly initiates a disposal action.
- Log analytics events to TelemetryDeck only. No PII in analytics payloads.

### Testing
- Duplicate detection logic MUST have unit tests. This is the core algorithm.
- Google OAuth token refresh MUST have integration tests.
- Use Swift Testing framework (`@Test`, `#expect`) for new tests, not XCTest.
- Test file naming: `{ClassName}Tests.swift`
- Minimum test coverage for `Services/DuplicateDetection/`: 80%+

### Git Conventions
- Branch naming: `feature/description`, `fix/description`, `chore/description`
- Commit messages: imperative mood, concise. Examples:
  - `Add perceptual hash comparison to DuplicateEngine`
  - `Fix Google OAuth token refresh on expired session`
  - `Remove unused CloudAccount migration code`
- Commit often. WIP commits are fine on feature branches. Squash on merge.
- Never commit API keys, tokens, or secrets. Use `.xcconfig` files excluded from git.

## Key Design Decisions

1. **No backend.** Everything runs on the user's device. This is a core architectural decision, not a temporary shortcut. It eliminates hosting costs, simplifies privacy compliance, and builds user trust. Do not introduce a backend unless explicitly discussed.

2. **Read-only by default.** The app requests read-only access to photo libraries. Write/delete permissions are requested only when the user chooses a disposal action, and only for the specific photos selected.

3. **"Never delete" is a feature, not a limitation.** The Google Photos API doesn't support deletion via API. We position this as intentional safety. The 5 disposal options are: Tag for Later, Archive, Move to Folder, Export Best, Guided Self-Delete.

4. **Exact hash first, perceptual hash second.** The duplicate detection pipeline runs SHA-256 exact match first (fast, zero false positives), then perceptual hash for near-duplicates (screenshots, crops, edits). These are separate passes, not combined.

5. **SwiftData over Core Data.** Modern, cleaner API, better SwiftUI integration. No legacy migration concerns since this is a new app.

6. **Minimal dependencies.** Prefer Apple frameworks over third-party libraries. URLSession over Alamofire, CryptoKit over third-party hash libraries, Keychain Security framework over pods. Every dependency is a maintenance burden.

## What NOT to Build

- No social features, sharing, or accounts
- No cloud sync of scan results (local only)
- No automatic background scanning in MVP
- No photo editing or enhancement
- No Vault feature until Phase 3
- No Family plan until Phase 3
- No subscription IAP until Phase 2
- No Android, no web, no macOS in MVP
- No Dropbox, OneDrive, or Amazon Photos until Phase 2+

## API Quirks to Know

### PhotoKit (iCloud)
- `PHAsset` gives you metadata without downloading the full image. Use `PHImageManager.requestImage` with `.lowQualityFormat` for thumbnails during scanning.
- Deletion requires `PHPhotoLibrary.shared().performChanges()` and triggers a system confirmation dialog. We cannot bypass this.
- Photo Library access is all-or-nothing starting iOS 14+ (no "selected photos" mode for a scanning app — we need full access).

### Google Photos API
- OAuth 2.0 with `photoslibrary.readonly` scope.
- Rate limit: ~10,000 requests/day for free tier. Batch `mediaItems.search` calls.
- No delete API. Period. "Guided Self-Delete" means showing the user which photos to delete and linking them to the Google Photos app.
- Thumbnails via `baseUrl` expire. Re-fetch `baseUrl` for display; don't cache permanently.
- Album listing is paginated. Always handle `nextPageToken`.

## Common Commands

```bash
# Build and run
open PhotoSweep.xcodeproj    # Or .xcworkspace if using CocoaPods

# Run tests
swift test                    # SPM tests
# Or: Cmd+U in Xcode

# Lint
swiftlint lint --strict

# Deploy to TestFlight
fastlane beta

# Submit to App Store
fastlane release
```

## Environment Variables / Config

Store in `Config.xcconfig` (git-ignored):
```
GOOGLE_CLIENT_ID = your-client-id.apps.googleusercontent.com
GOOGLE_REVERSED_CLIENT_ID = com.googleusercontent.apps.your-client-id
BUNDLE_ID = com.yourname.photosweep
TELEMETRY_APP_ID = your-telemetry-id
SENTRY_DSN = https://your-sentry-dsn
```

## Helpful Context

- This is a 2-person team: one developer (Venkat), one product/growth lead (non-technical).
- Revenue model: Free tier (scan 1,000 photos, see report, tag-only) + One-Time Deep Clean ($14.99).
- Launch target: 1,000 downloads in first 30 days.
- If I ask you to generate tests, prioritize `DuplicateDetection/` services above everything else.
- When writing UI code, keep the "never delete" trust language visible. Every screen where a user might worry about losing photos should have reassuring copy.
