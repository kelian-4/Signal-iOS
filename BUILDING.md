# Building

No Mac is required: CI (`.github/workflows/ios.yml`) builds an unsigned .ipa on a macOS runner and publishes it as
an artifact and as a pre-release named `build-<run_number>`. Install it with SideStore (free account).

## Locally (macOS)

```
cd MeshCore && swift test
cd ..
xcodebuild build -workspace Signal.xcworkspace -scheme Signal -configuration Release -sdk iphoneos \
  -skipMacroValidation -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
```

SideStore rewrites the bundle identifier when re-signing.
