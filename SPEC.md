# SPEC.md — PhotoSweep Product Specification

> **Version:** 1.0 (MVP)  
> **Last updated:** February 2026  
> **Status:** Pre-development  

---

## 1. Product Definition

### What It Is
PhotoSweep is an iOS app that scans photos across iCloud and Google Photos, identifies duplicates, and lets users manage them safely. All processing happens on-device. The app never deletes a photo without explicit user action.

### What It Is Not
- Not a photo editor or enhancement tool
- Not a cloud storage manager (it doesn't manage your storage plan)
- Not a backup service
- Not a social or sharing platform
- Not a general-purpose cleaner (it only handles photos, not files/contacts/cache)

### Core Value Proposition
> "See all your duplicate photos across iCloud and Google Photos. Nothing gets deleted unless you say so."

### Target User
People who use both iCloud and Google Photos (explicitly or accidentally) and are frustrated by duplicate photos eating their storage. Typically:
- iPhone users with Google Photos installed (automatic backup creates duplicates)
- People who switched from Android to iPhone and kept their Google Photos library
- Parents with thousands of baby/family photos scattered across clouds
- Anyone seeing "iCloud Storage Full" notifications

---

## 2. User Flows

### 2.1 First Launch / Onboarding

```
Welcome Screen
  ↓
"Connect Your Photo Libraries" (explanation of what we access and why)
  ↓
Connect iCloud (system permission dialog — PHPhotoLibrary)
  ↓
Connect Google Photos (ASWebAuthenticationSession → OAuth consent)
  ↓
"Ready to Scan" confirmation
  ↓
Home Screen
```

**Rules:**
- User can connect only iCloud, only Google, or both. App works with either.
- Show explicit "We never delete your photos" trust message before each connection.
- If user denies photo access, show a clear explanation of why it's needed with a button to open Settings.
- ~~Google OAuth must request `photoslibrary.readonly` scope only.~~
  **Update (July 2026):** Google removed all library-wide read scopes on March 31, 2025. The app uses the
  **Picker API** (`photospicker.mediaitems.readonly`): the user picks which Google photos to scan, inside
  the Google Photos app or web picker. We can never see photos the user doesn't explicitly pick — position
  this as a privacy feature.

### 2.2 Scanning

```
Home Screen → "Scan for Duplicates" button
  ↓
Scan Progress View
  - Phase 1: "Reading your iCloud library..." (import PHAsset metadata)
  - Phase 2: "Reading your Google Photos..." (paginated API calls)
  - Phase 3: "Comparing photos..." (hash computation + matching)
  ↓
Scan Complete View
  - "Found X duplicate groups (Y photos, ~Z MB potential savings)"
  - "Review Duplicates" button
```

**Rules:**
- Show real-time progress: "Scanning photo 1,247 of 8,302..."
- Scan must be cancellable at any point.
- If Google API rate-limits, show friendly message and pause/retry. Don't error out.
- Store scan results in SwiftData. User shouldn't need to re-scan to review.
- Free tier: scan up to 1,000 photos. Show paywall when limit hit during scan.

### 2.3 Duplicate Review

```
Duplicate Review View (swipe-based card interface)
  ↓
For each duplicate group:
  - Show side-by-side: original vs duplicate(s)
  - Show metadata: source (iCloud/Google), date taken, file size, resolution
  - Show AI quality assessment (which is the "best" copy)
  ↓
User actions per group:
  - "Keep All" → skip, mark as reviewed
  - "Tag for Later" → add a tag, revisit later
  - Swipe to select disposal for specific photos
```

**Rules:**
- NEVER auto-select photos for disposal. The user always chooses.
- Show which cloud each photo lives in with a clear badge (iCloud icon / Google icon).
- "Best" photo suggestion is a recommendation only, clearly labeled as such.
- Review state persists. User can close the app and resume review later.

### 2.4 Disposal Options

When a user selects a duplicate for disposal:

| Option | Description | Available For |
|--------|-------------|---------------|
| **Tag for Later** | Add a "Duplicate" tag. No action taken. | iCloud, Google |
| **Archive** | Move to a "PhotoSweep Archive" album | iCloud only |
| **Move to Folder** | Create a "Duplicates" folder/album | iCloud, Google (limited) |
| **Export Best** | Save the highest-quality version, tag others | iCloud |
| **Guided Self-Delete** | Show step-by-step instructions to delete in the native app | iCloud, Google |

**Rules:**
- "Guided Self-Delete" for Google Photos opens the Google Photos app with instructions. We cannot delete via API.
- "Guided Self-Delete" for iCloud triggers `PHPhotoLibrary.performChanges` which shows Apple's system confirmation dialog.
- All disposal actions are batched. User reviews everything first, then confirms all actions at once.
- Show a summary before executing: "You're about to archive 47 photos (~230 MB). This is reversible."

### 2.5 Purchase Flow

```
Free user hits 1,000 photo scan limit
  ↓
Paywall View
  - "You've scanned 1,000 of 8,302 photos"
  - "Unlock Deep Clean to scan everything — $14.99 one time"
  - Feature comparison: Free vs Deep Clean
  ↓
StoreKit 2 purchase sheet (native Apple UI)
  ↓
On success: resume scan from where it stopped
```

**Rules:**
- Paywall appears during scan, not before. Let users see value first.
- "Restore Purchase" button must be visible and functional.
- Purchase unlocks unlimited scanning forever (not a subscription in MVP).
- If purchase fails or is cancelled, user keeps their free tier scan results.

---

## 3. Data Model

### 3.1 UnifiedPhoto

The core entity. Represents a single photo normalized across platforms.

```swift
@Model
class UnifiedPhoto {
    // Identity
    var id: UUID
    var localIdentifier: String?     // PHAsset.localIdentifier (iCloud)
    var googleMediaItemId: String?   // Google Photos mediaItem.id
    var source: PhotoSource          // .icloud, .googlePhotos
    
    // Content hashes
    var sha256Hash: String?          // Exact duplicate detection
    var perceptualHash: String?      // Near-duplicate detection (pHash)
    
    // Metadata
    var creationDate: Date?
    var originalFilename: String?
    var fileSize: Int64              // Bytes
    var width: Int
    var height: Int
    var mediaType: MediaType         // .photo, .screenshot, .livePhoto, .burst
    
    // EXIF
    var cameraMake: String?
    var cameraModel: String?
    var lensInfo: String?
    var gpsLatitude: Double?
    var gpsLongitude: Double?
    
    // Scan state
    var scanSessionId: UUID
    var duplicateGroupId: UUID?
    var isReviewed: Bool = false
    var disposalAction: DisposalAction? // nil = no action taken
    var qualityScore: Float?         // 0.0-1.0, AI-assessed quality
    
    // Thumbnail
    var thumbnailData: Data?         // Low-res thumbnail for display
}

enum PhotoSource: String, Codable {
    case icloud
    case googlePhotos
}

enum MediaType: String, Codable {
    case photo
    case screenshot
    case livePhoto
    case burst
    case video  // Future
}

enum DisposalAction: String, Codable {
    case tagForLater
    case archive
    case moveToFolder
    case exportBest
    case guidedDelete
}
```

### 3.2 DuplicateGroup

```swift
@Model
class DuplicateGroup {
    var id: UUID
    var scanSessionId: UUID
    var matchType: MatchType         // .exact, .perceptual, .visual
    var matchConfidence: Float       // 0.0-1.0
    var suggestedKeepId: UUID?       // AI's recommendation for "best" photo
    var isReviewed: Bool = false
    var photos: [UnifiedPhoto]       // 2+ photos in this group
    
    var potentialSavings: Int64 {    // Bytes saved if all but best are removed
        let sorted = photos.sorted { $0.fileSize > $1.fileSize }
        return sorted.dropFirst().reduce(0) { $0 + $1.fileSize }
    }
}

enum MatchType: String, Codable {
    case exact          // SHA-256 match
    case perceptual     // pHash within threshold
    case visual         // Vision framework feature vector similarity
}
```

### 3.3 ScanSession

```swift
@Model
class ScanSession {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var status: ScanStatus
    var totalPhotosScanned: Int = 0
    var duplicateGroupsFound: Int = 0
    var potentialSavingsBytes: Int64 = 0
    var sourcesScanned: [PhotoSource]
}

enum ScanStatus: String, Codable {
    case inProgress
    case completed
    case cancelled
    case failed
}
```

### 3.4 CloudAccount

```swift
@Model
class CloudAccount {
    var id: UUID
    var source: PhotoSource
    var isConnected: Bool
    var lastSyncDate: Date?
    var totalPhotos: Int?
    var userEmail: String?           // Google only, for display
    // Google OAuth tokens stored in Keychain, NOT here
}
```

---

## 4. Duplicate Detection Pipeline

### Phase 1: Metadata Import

```
iCloud: PHFetchResult<PHAsset> → extract metadata → store as UnifiedPhoto
Google: Picker session → user picks → GET /v1/mediaItems?sessionId (paginated) → extract metadata → store as UnifiedPhoto
```

- Fetch metadata only. Don't download full images yet.
- Normalize dates to UTC. Handle timezone mismatches between platforms.
- Normalize filenames (strip platform-specific prefixes like `IMG_`, `DSC_`).

### Phase 2: Exact Duplicate Detection (SHA-256)

```
For each UnifiedPhoto where sha256Hash is nil:
  → Request image data (low-res for iCloud via PHImageManager, baseUrl for Google)
  → Compute SHA-256 hash
  → Store hash
Group photos by identical hash → create DuplicateGroups with matchType = .exact
```

- This catches identical files across platforms (e.g., same photo uploaded to both iCloud and Google).
- Fast and has zero false positives.

### Phase 3: Near-Duplicate Detection (Perceptual Hash)

```
For each UnifiedPhoto where perceptualHash is nil:
  → Request image data
  → Resize to 32x32 grayscale
  → Apply DCT (Discrete Cosine Transform)
  → Generate 64-bit perceptual hash
  → Store hash
Compare pHashes: Hamming distance ≤ 8 → mark as near-duplicate
Create DuplicateGroups with matchType = .perceptual
```

- Catches resized copies, re-compressed images, light crops.
- Hamming distance threshold of 8 (out of 64 bits) is well-tested in the literature.
- May produce occasional false positives for very similar but different photos (e.g., burst shots). These are surfaced for user review, not auto-actioned.

### Phase 4 (Future): Visual Similarity (Vision Framework)

```
For remaining ungrouped photos:
  → Generate feature vectors using VNGenerateImageFeaturePrintRequest
  → Compare feature vectors: cosine similarity ≥ 0.85 → mark as visually similar
Create DuplicateGroups with matchType = .visual
```

- Catches photos of the same scene from slightly different angles, edited versions, screenshots of photos.
- Higher false positive rate. Always requires user review.
- **Not in MVP.** Add in Phase 2.

### Quality Scoring

For each DuplicateGroup, determine the "best" photo:
1. Higher resolution (width × height) wins
2. If equal resolution: larger file size wins (less compression)
3. If tied: prefer the original source (oldest creation date)
4. Display this as a recommendation, not an automatic selection

---

## 5. Free vs Paid Tiers

### Free Tier
- Scan up to 1,000 photos across all connected sources
- See full scan report (number of duplicates, potential savings)
- Review duplicate groups
- "Tag for Later" disposal action only
- Monthly scan reminders (push notification)

### Deep Clean ($14.99 one-time)
- Unlimited photo scanning
- All 5 disposal actions
- AI quality scoring (recommended "best" photo per group)
- Storage savings tracker
- Priority support (email)

### Future Tiers (Post-MVP)
- **Plus ($4.99/mo):** Automatic weekly scans, Dropbox + OneDrive support
- **Vault ($7.99/mo):** Secure archive storage for disposed duplicates
- **Family ($11.99/mo):** Up to 5 family members, shared duplicate detection

---

## 6. Privacy & Compliance

### Data We Access
- Photo metadata (date, size, resolution, EXIF, location)
- Photo thumbnails (for display during review)
- Photo image data (for hash computation — processed on-device, never uploaded)
- Google account email (for display — "Connected as user@gmail.com")

### Data We Store
- Photo metadata and hashes in local SwiftData database
- Google OAuth refresh token in iOS Keychain
- Scan results (local only)
- Anonymous analytics events via TelemetryDeck (no PII)

### Data We NEVER Collect
- Full-resolution photos are never stored permanently
- No server-side storage of any photo data
- No tracking pixels or advertising SDKs
- No sharing of data with third parties
- No photo uploads to any cloud service

### Required Privacy Disclosures (App Store)
- **Photos:** Used to scan for duplicates. Processed on-device only.
- **Contacts:** Not accessed.
- **Location:** Not accessed (EXIF GPS data is read locally but never transmitted).

### GDPR / CCPA
- No personal data leaves the device, so most regulations are satisfied by architecture.
- Privacy policy generated via Termly (free tier) and hosted on the landing page.

---

## 7. App Store Metadata

### Name
PhotoSweep — Cross-Cloud Photo Cleaner

### Subtitle
Find duplicates across iCloud & Google Photos

### Category
Primary: Utilities  
Secondary: Photo & Video

### Keywords
duplicate photos, iCloud storage full, photo cleaner, google photos duplicates, free up storage, photo organizer, cross cloud, storage saver, photo dedup, iCloud cleanup

### Age Rating
4+ (no objectionable content)

### Positioning Note
Position as "cross-cloud photo manager" in all App Store communications. Avoid language that implies competition with Apple's built-in Photos app. Emphasize the cross-platform nature as the differentiator Apple doesn't offer.

---

## 8. Non-Functional Requirements

### Performance
- Scan 10,000 photos in under 5 minutes on iPhone 14 or newer
- Hash computation must not block the UI thread (use background TaskGroup)
- Thumbnail rendering at 60fps in the review carousel
- App launch to home screen in under 2 seconds

### Battery
- Background scan (future) must use `BGProcessingTask` and respect low-power mode
- Active scanning should not drain more than 10% battery per 5,000 photos

### Storage
- App binary size under 30 MB
- Local database should not exceed 100 MB for 50,000 photos
- Thumbnails stored at 200×200px max, JPEG quality 0.6

### Accessibility
- Full VoiceOver support for all screens
- Dynamic Type support (all text scales with system settings)
- Minimum touch target: 44×44pt
- Color is never the only indicator of state (use icons + labels)

### Offline Support
- iCloud scanning works offline (PhotoKit accesses local cache)
- Google Photos scanning requires internet (API calls)
- Review and disposal tagging works offline
- Actual disposal execution (archive, move) syncs when back online
