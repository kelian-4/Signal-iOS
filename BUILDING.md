# Building

No Mac is required: CI (`.github/workflows/ios.yml`) builds an unsigned .ipa on a macOS runner and publishes it as
an artifact and as a pre-release named `build-<run_number>`. Install it with SideStore (free account).

## Locally (macOS)

```
brew install xcodegen
cd MeshCore && swift test
cd ../MeshApp && xcodegen generate
xcodebuild build -project Messagerie.xcodeproj -scheme Messagerie -configuration Release -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
```

The bundle identifier is `cm.messagerie.app`; SideStore rewrites it when re-signing, and nothing in the code depends on it.

The upstream Signal targets (`Signal.xcodeproj`) are not built by CI. See docs/REMOVED.md.
