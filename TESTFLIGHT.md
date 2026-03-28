# TestFlight Submission Guide

**For Peter — follow these steps on your Mac to get Privlens into TestFlight.**

Prerequisites:
- Apple Developer Program membership ($99/yr) — [developer.apple.com/programs](https://developer.apple.com/programs/)
- Xcode 17+ installed (requires macOS 16+)
- Your Mac signed into your Apple Developer account in Xcode

---

## Step 1: Clone & Open (One-Time)

```bash
# If you haven't already:
mkdir -p ~/Developer
git clone https://github.com/peterkimpro/privlens.git ~/Developer/privlens
cd ~/Developer/privlens

# If you already have it:
cd ~/Developer/privlens && git pull
```

Open in Xcode:
```bash
open Package.swift
# Or: open App/Privlens.xcodeproj (if using Xcode project)
```

---

## Step 2: Configure Signing & Bundle ID

1. In Xcode, select the **Privlens** target
2. Go to **Signing & Capabilities** tab
3. Check **"Automatically manage signing"**
4. Set **Team** to your Apple Developer account
5. Set **Bundle Identifier** to: `com.peterkimpro.privlens`
6. Xcode will auto-create the App ID and provisioning profile

If you see a provisioning error:
- Xcode → Settings → Accounts → your Apple ID → Manage Certificates → add "Apple Distribution" certificate

---

## Step 3: Create App in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:

| Field | Value |
|-------|-------|
| Platform | iOS |
| Name | Privlens - Private Document AI |
| Primary Language | English (U.S.) |
| Bundle ID | com.peterkimpro.privlens |
| SKU | privlens |
| User Access | Full Access |

4. Click **Create**

---

## Step 4: Set Version & Build Number

In `Info.plist` (or Xcode target settings):

| Key | Value |
|-----|-------|
| `CFBundleShortVersionString` | `1.0.0` |
| `CFBundleVersion` | `1` (increment for each upload) |

The version is already set in `App/Privlens/Info.plist`. Just increment `CFBundleVersion` for each new TestFlight upload.

---

## Step 5: Archive & Upload

### Option A: Xcode (Recommended for first time)

1. Select destination: **Any iOS Device (arm64)** (not a Simulator)
2. **Product → Archive** (⌘⇧B won't work — must use Archive)
3. Wait for build to complete (~2-5 min)
4. Xcode Organizer opens automatically
5. Select the archive → **Distribute App**
6. Choose **TestFlight & App Store** → **Upload**
7. Keep all defaults (bitcode, symbols, etc.) → **Upload**
8. Wait for upload (~1-3 min depending on connection)

### Option B: Xcode Cloud (Automated — set up once)

1. Xcode → **Product → Xcode Cloud → Create Workflow**
2. Configure:
   - **Start Condition**: Push to `main` branch (or `release` tag)
   - **Build**: Archive for iOS
   - **Post-Action**: TestFlight (Internal Testing)
3. After setup, every push to `main` auto-builds and uploads to TestFlight
4. Free: 25 compute hours/month with Apple Developer Program

---

## Step 6: TestFlight Setup

After upload completes (~5-30 min for Apple processing):

1. Go to App Store Connect → **Privlens** → **TestFlight** tab
2. You'll see your build under **iOS Builds**
3. If it says "Missing Compliance" → click **Manage** → select "None of the algorithms mentioned" (we don't use custom encryption)

### Internal Testing (Just You)

1. **TestFlight → Internal Testing → App Store Connect Users**
2. Your developer account is automatically added
3. Install TestFlight app on your iPhone
4. Open TestFlight → Privlens appears → **Install**

### External Testing (Beta Testers)

1. **TestFlight → External Testing → Create Group** (e.g., "Beta Testers")
2. Add testers by email
3. Submit build for **Beta App Review** (usually approved within 24-48 hours)
4. Testers get an email invite → install via TestFlight

---

## Step 7: App Store Metadata (While Waiting)

While builds process, fill in App Store Connect metadata.
Reference: `App/Privlens/Metadata/AppStoreMetadata.swift` has all copy ready to paste.

### Required before public release:

- [ ] App description (in AppStoreMetadata.swift)
- [ ] Keywords (in AppStoreMetadata.swift)
- [ ] Screenshots (capture from Simulator — see screenshot list in metadata file)
- [ ] App icon (1024x1024, no alpha, no rounded corners — App Store adds rounding)
- [ ] Privacy Policy URL — host at `privlens.com/privacy` or `peterkimpro.github.io/privlens/privacy`
- [ ] Support URL — `https://github.com/peterkimpro/privlens/issues`
- [ ] App Review notes (in AppStoreMetadata.swift)
- [ ] Privacy Nutrition Label responses (in AppStoreMetadata.swift)

### NOT required for TestFlight:

Screenshots, description, and keywords are only required for App Store submission, not TestFlight.

---

## Step 8: Verify on Device

1. Open TestFlight on your iPhone
2. Install Privlens
3. Test the full flow:
   - [ ] App launches correctly
   - [ ] Camera scanning works
   - [ ] OCR extracts text
   - [ ] AI analysis produces results (requires iPhone 15 Pro+ for Foundation Models)
   - [ ] Document library shows saved documents
   - [ ] Paywall appears after trial/limit
   - [ ] StoreKit 2 sandbox purchases work

---

## Quick Reference

| Action | Command / Location |
|--------|--------------------|
| Pull latest code | `cd ~/Developer/privlens && git pull` |
| Open in Xcode | `open Package.swift` |
| Archive | Product → Archive |
| Upload to TestFlight | Organizer → Distribute App → Upload |
| TestFlight builds | appstoreconnect.apple.com → TestFlight |
| Increment build number | `Info.plist` → `CFBundleVersion` += 1 |
| App Store metadata reference | `App/Privlens/Metadata/AppStoreMetadata.swift` |

---

## Troubleshooting

**"No signing certificate found"**
→ Xcode → Settings → Accounts → your Apple ID → Manage Certificates → "+" → Apple Distribution

**"Provisioning profile doesn't match bundle ID"**
→ Ensure bundle ID is exactly `com.peterkimpro.privlens` in both Xcode target and App Store Connect

**"Missing Compliance" on TestFlight**
→ App Store Connect → TestFlight → click the build → Manage → "None of the algorithms mentioned"

**Build fails on Archive**
→ Make sure destination is "Any iOS Device (arm64)", not a Simulator
→ Run `git pull` first to get latest code (CI already verified it builds)

**Foundation Models not working on device**
→ Requires iPhone 15 Pro or later with iOS 26+
→ Works in Simulator on Apple Silicon Macs (M1+)
