# Generating the Xcode Project

Since the .xcodeproj cannot be generated on Linux, follow these one-time steps on your Mac:

## Option A: Manual (Recommended for simplicity)
1. Open Xcode
2. File -> New -> Project -> iOS -> App
3. Product Name: Privlens
4. Team: Your development team
5. Organization Identifier: com.peterkimpro
6. Interface: SwiftUI
7. Storage: SwiftData
8. Save in the `App/` directory of this repo
9. Delete the auto-generated ContentView.swift (we use PrivlensUI's)
10. File -> Add Package Dependencies -> Add Local -> select repo root
11. Add PrivlensUI and PrivlensCore to the app target
12. Replace PrivlensApp.swift content with the one from App/Privlens/PrivlensApp.swift
13. Build and run (Cmd+R)

## Option B: XcodeGen
1. Install: `brew install xcodegen`
2. Run: `xcodegen generate --spec App/project.yml`
3. Open: `open App/Privlens.xcodeproj`
