# App Store Screenshots — Functional Harmony

Generated from live simulator captures (UI tests).

## Specs

| Set | Device | Size | Count |
|-----|--------|------|-------|
| `iphone-6.9/` | iPhone 17 Pro Max | **1320 × 2868** | 5 |
| `ipad-13/` | iPad Pro 13" (M5) | **2064 × 2752** | 5 |

- Format: PNG, 8-bit RGB, **no alpha**
- Status bar: 9:41, full signal/battery (overridden via simctl)
- Locale: en-US

## Shot order (first 3 appear in search)

1. `01-chords-c-major` — Chord builder: C Major tones
2. `02-scales-d-major` — Scale finder: D Major degrees
3. `03-notes-c-e-g` — Notes ID: C–E–G → C Major
4. `04-ask-gmaj7` — Ask: natural language “G major 7”
5. `05-chords-a-maj7` — Chord builder: A Major 7

## Regenerate

```bash
export DEVELOPER_DIR="/Users/dps/Downloads/Xcode-beta.app/Contents/Developer"
# iPhone 17 Pro Max
xcodebuild test -project "Functional Harmony.xcodeproj" -scheme "Functional Harmony" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:'Functional HarmonyUITests/Functional_HarmonyUITests/testCaptureAppStoreScreenshots' \
  -derivedDataPath ./build/DerivedData

# iPad Pro 13"
xcodebuild test -project "Functional Harmony.xcodeproj" -scheme "Functional Harmony" \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -only-testing:'Functional HarmonyUITests/Functional_HarmonyUITests/testCaptureIPadAppStoreScreenshots' \
  -derivedDataPath ./build/DerivedData
```

## Upload (asc)

```bash
# Resolve version localization id first
asc app-store-versions list --app 1564025162 --output table
# then:
asc screenshots upload --version-localization LOC_ID \
  --path screenshots/app-store/iphone-6.9 --device-type APP_IPHONE_69

asc screenshots upload --version-localization LOC_ID \
  --path screenshots/app-store/ipad-13 --device-type APP_IPAD_PRO_3GEN_129
```
