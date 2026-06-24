# PLAN.md — PhotoSweep Development Phases

> **Team:** 2 people (1 developer, 1 product/growth lead)  
> **Cadence:** Evenings + weekends (~15-20 hours/week combined)  
> **Kill metric:** 1,000 downloads in first 30 days post-launch or reassess  

---

## Phase 1: Foundation (Weeks 1-3)

### Goal
Xcode project compiles, runs on simulator and device, connects to iCloud, displays photos.

### Stories

- [ ] **PS-001:** Initialize Xcode project with SwiftUI, SwiftData, and app structure from CLAUDE.md
- [ ] **PS-002:** Configure SwiftLint with `.swiftlint.yml`
- [ ] **PS-003:** Set up GitHub repo with branch protection and PR template
- [ ] **PS-004:** Set up Fastlane with `fastlane init` and basic `Fastfile`
- [ ] **PS-005:** Create `Config.xcconfig` for environment variables (git-ignored)
- [ ] **PS-006:** Implement SwiftData models: `UnifiedPhoto`, `DuplicateGroup`, `ScanSession`, `CloudAccount`
- [ ] **PS-007:** Request PhotoKit permission with proper info.plist entries and error handling
- [ ] **PS-008:** Fetch iCloud photo metadata via `PHFetchResult<PHAsset>` and convert to `UnifiedPhoto`
- [ ] **PS-009:** Display photo grid (thumbnails) from iCloud on a basic HomeView
- [ ] **PS-010:** Write unit tests for SwiftData models (insert, query, relationships)

### Acceptance Criteria
- App builds and runs on simulator and physical device
- iCloud photos appear in a scrollable grid
- SwiftData persistence verified (kill app, reopen, data persists)
- SwiftLint passes with zero warnings
- All model unit tests pass

### Product Lead Tasks (Parallel)
- [ ] Set up GitHub Projects board with epic labels
- [ ] Write App Store description draft (subtitle, keywords, description)
- [ ] Create Canva workspace with PhotoSweep brand assets (logo, color palette, fonts)
- [ ] Research competitors: Gemini Photos, Smart Cleaner, Cleaner One — note their App Store positioning

---

## Phase 2: Google Photos Integration (Weeks 4-5)

### Goal
Google Photos connected via OAuth. Photos from both sources displayed in unified view.

### Stories

- [ ] **PS-011:** Set up Google Cloud Console project with Photos Library API enabled
- [ ] **PS-012:** Implement Google OAuth 2.0 flow with `ASWebAuthenticationSession`
- [ ] **PS-013:** Store OAuth tokens securely in iOS Keychain
- [ ] **PS-014:** Implement token refresh logic (handle expired access tokens)
- [ ] **PS-015:** Fetch Google Photos metadata via `mediaItems.search` (paginated)
- [ ] **PS-016:** Convert Google Photos metadata to `UnifiedPhoto` (normalize dates, filenames)
- [ ] **PS-017:** Display unified photo grid with source badges (iCloud/Google icons)
- [ ] **PS-018:** Handle edge cases: no photos, API rate limits, network errors
- [ ] **PS-019:** Write integration tests for Google OAuth token refresh
- [ ] **PS-020:** Write tests for date normalization (timezone edge cases)

### Acceptance Criteria
- User can connect Google Photos account and see photos
- Source badge correctly shows iCloud vs Google on each photo
- Token refresh works after simulated expiry
- Graceful error handling for no-network and rate-limit scenarios
- **Submit for Google OAuth verification** (2-4 week process starts now)

### Product Lead Tasks (Parallel)
- [ ] Set up landing page on Carrd.co with email waitlist
- [ ] Write first SEO blog post draft: "Why Your iPhone Says iCloud Storage Full"
- [ ] Design onboarding wireframes (Whimsical or Figma)
- [ ] Draft the "We Never Delete Your Photos" trust copy for onboarding

---

## Phase 3: Duplicate Detection Engine (Weeks 6-8)

### Goal
Core duplicate detection works. Exact duplicates identified across clouds.

### Stories

- [ ] **PS-021:** Implement SHA-256 hashing service using CryptoKit
- [ ] **PS-022:** Request image data from iCloud (PHImageManager, low-quality for hashing)
- [ ] **PS-023:** Request image data from Google Photos (baseUrl download)
- [ ] **PS-024:** Implement batch hashing with `TaskGroup` (background thread, cancellable)
- [ ] **PS-025:** Group photos by identical SHA-256 hash → create `DuplicateGroup` entities
- [ ] **PS-026:** Implement perceptual hash (pHash) generation via Core Image DCT
- [ ] **PS-027:** Implement Hamming distance comparison for pHash (threshold ≤ 8)
- [ ] **PS-028:** Create `DuplicateEngine` that orchestrates exact → perceptual pipeline
- [ ] **PS-029:** Implement quality scoring: resolution × file size × source priority
- [ ] **PS-030:** Write comprehensive unit tests for `HashingService` (known hash pairs)
- [ ] **PS-031:** Write unit tests for `PerceptualHashService` (same image resized, different images)
- [ ] **PS-032:** Write unit tests for `DuplicateEngine` (end-to-end with mock photos)
- [ ] **PS-033:** Performance test: hash 1,000 photos in under 60 seconds

### Acceptance Criteria
- Exact duplicates (same file on iCloud and Google) reliably detected
- Near-duplicates (resized, recompressed) detected with pHash
- Zero false positives on exact match
- pHash false positive rate < 5% (verified with test image set)
- Scan of 1,000 photos completes in under 60 seconds on iPhone 14
- All duplicate detection tests pass (minimum 15 test cases)

### Product Lead Tasks (Parallel)
- [ ] Create App Store screenshot templates in Canva (iPhone 15 Pro frame)
- [ ] Write comparison table: PhotoSweep vs Gemini vs Smart Cleaner
- [ ] Draft Product Hunt launch copy (maker story + feature description)
- [ ] Begin collecting beta tester emails from landing page waitlist

---

## Phase 4: Scan & Review UI (Weeks 9-10)

### Goal
User can initiate a scan, see progress, and review results in a polished interface.

### Stories

- [ ] **PS-034:** Implement `ScanProgressView` with real-time photo count and phase labels
- [ ] **PS-035:** Implement scan cancellation (cancels TaskGroup, saves partial results)
- [ ] **PS-036:** Implement `ScanCompleteView` with summary stats (groups, photos, savings)
- [ ] **PS-037:** Implement `DuplicateReviewView` with swipe-based card interface
- [ ] **PS-038:** Implement `PhotoComparisonView` (side-by-side with metadata overlay)
- [ ] **PS-039:** Implement `CloudBadge` component (iCloud / Google source indicator)
- [ ] **PS-040:** Implement "Keep All" and "Tag for Later" actions
- [ ] **PS-041:** Implement review state persistence (resume after app kill)
- [ ] **PS-042:** Add trust banner: "PhotoSweep has never deleted any of your photos"
- [ ] **PS-043:** Implement free tier scan limit (1,000 photos) with soft paywall
- [ ] **PS-044:** Basic UI smoke tests (XCUITest: onboarding → scan → review)

### Acceptance Criteria
- Full flow works: launch → connect → scan → review → tag
- Scan progress is accurate and updates in real-time
- Review carousel is smooth (60fps scrolling)
- App state survives background/kill (scan results and review progress persist)
- Trust messaging visible on scan and review screens
- Free tier limit enforced at 1,000 photos

### Product Lead Tasks (Parallel)
- [ ] Take real App Store screenshots using TestFlight build
- [ ] Write all App Store metadata (description, what's new, privacy labels)
- [ ] Finalize landing page with screenshots and feature list
- [ ] Prepare Reddit post drafts for r/iphone, r/ios, r/googlephotos

---

## Phase 5: Onboarding, Payments & Polish (Weeks 11-12)

### Goal
Complete onboarding flow. StoreKit 2 purchase working. App ready for TestFlight.

### Stories

- [ ] **PS-045:** Implement `WelcomeView` with value proposition and trust messaging
- [ ] **PS-046:** Implement `ConnectCloudsView` with step-by-step iCloud + Google connection
- [ ] **PS-047:** Implement `PermissionsView` with fallback to Settings if denied
- [ ] **PS-048:** Implement StoreKit 2 one-time purchase ($14.99 Deep Clean)
- [ ] **PS-049:** Implement "Restore Purchase" functionality
- [ ] **PS-050:** Implement paywall UI (appears at scan limit)
- [ ] **PS-051:** Implement `SettingsView` (connected accounts, about, restore purchase)
- [ ] **PS-052:** Add TelemetryDeck analytics (scan started, scan completed, purchase, review actions)
- [ ] **PS-053:** Add Sentry crash reporting
- [ ] **PS-054:** Implement app icon (use SF Symbols + Apple's Icon Composer for Liquid Glass)
- [ ] **PS-055:** Privacy policy page (Termly-generated, hosted on landing page)
- [ ] **PS-056:** Configure Fastlane for TestFlight upload
- [ ] **PS-057:** First TestFlight build distributed to beta testers

### Acceptance Criteria
- Complete flow: install → onboard → connect → scan → review → purchase works end-to-end
- StoreKit 2 purchase completes in sandbox testing
- Restore purchase works on a fresh install
- Analytics events fire correctly (verify in TelemetryDeck dashboard)
- Crash reporting active (verify with test crash)
- TestFlight build installs and runs on beta tester devices
- Privacy policy accessible from app and landing page

### Product Lead Tasks (Parallel)
- [ ] Recruit 10-20 beta testers from waitlist
- [ ] Collect and respond to beta feedback
- [ ] Finalize App Store listing (all metadata, screenshots, preview video if time permits)
- [ ] Schedule Product Hunt launch (Tuesday or Wednesday)

---

## Phase 6: App Store Submission (Week 13)

### Goal
App approved and live on the App Store.

### Stories

- [ ] **PS-058:** Address beta tester feedback (critical bugs only — resist feature creep)
- [ ] **PS-059:** App Store submission via Fastlane
- [ ] **PS-060:** Respond to any App Review rejections
- [ ] **PS-061:** Verify purchase flow in production (post-approval)
- [ ] **PS-062:** Launch on Product Hunt
- [ ] **PS-063:** Post on Reddit (r/iphone, r/ios, r/googlephotos, r/datahoarder)
- [ ] **PS-064:** Post on Indie Hackers

### Acceptance Criteria
- App approved by App Review
- Purchase flow works in production
- Landing page links to live App Store listing
- Launch posts published on all planned channels
- First 48 hours: monitor crash reports and reviews actively

### Launch-or-Kill Checkpoint
**30 days after App Store approval:**
- ≥ 1,000 downloads → proceed to Phase 2 roadmap (subscriptions, more clouds)
- < 1,000 downloads → honest reassessment (pivot positioning? different channel? kill?)

---

## Epic Labels for GitHub

Use these as GitHub Issue labels:

| Label | Color | Scope |
|-------|-------|-------|
| `epic:foundation` | `#0E8A16` | Project setup, structure, SwiftData |
| `epic:icloud` | `#1D76DB` | PhotoKit integration |
| `epic:google-photos` | `#D93F0B` | Google Photos API, OAuth |
| `epic:duplicate-engine` | `#5319E7` | Hashing, pHash, detection pipeline |
| `epic:scan-ui` | `#FBCA04` | Scan progress, results display |
| `epic:review-ui` | `#B60205` | Duplicate review, comparison, actions |
| `epic:onboarding` | `#0075CA` | Welcome, permissions, cloud connection |
| `epic:payments` | `#E4E669` | StoreKit 2, paywall, restore |
| `epic:polish` | `#C5DEF5` | Analytics, crash reporting, icons, A11y |
| `epic:launch` | `#D876E3` | App Store submission, marketing, launch |

## Milestone Mapping

| GitHub Milestone | Phase | Target |
|-----------------|-------|--------|
| `v0.1 — Foundation` | Phase 1 | Week 3 |
| `v0.2 — Google Photos` | Phase 2 | Week 5 |
| `v0.3 — Detection Engine` | Phase 3 | Week 8 |
| `v0.4 — Scan & Review` | Phase 4 | Week 10 |
| `v0.5 — Beta (TestFlight)` | Phase 5 | Week 12 |
| `v1.0 — App Store Launch` | Phase 6 | Week 13 |
