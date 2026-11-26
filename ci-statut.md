# Statut CI (ios)

- commit: 542a61cd5d1faae80bf6dc16ef64da01342b923d
- run: 45763201994 (build-4)
- date: 2026-11-26T05:43:55Z
- résultat: success
- swift test: success
- xcodebuild: success
- ipa: success

## fin du log tests (erreurs et dernières lignes)
```
---
Test Case '-[MeshCoreTests.ServiceTests testCreateIdentityGivesTwentyFourWordsAndPersists]' passed (0.003 seconds).
Test Case '-[MeshCoreTests.ServiceTests testEmptyNameRejectedAndNameClamped]' started.
Test Case '-[MeshCoreTests.ServiceTests testEmptyNameRejectedAndNameClamped]' passed (0.003 seconds).
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' started.
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' passed (0.113 seconds).
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' passed (0.003 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' started.
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' started.
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' passed (0.002 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' started.
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' passed (0.003 seconds).
Test Suite 'ServiceTests' passed at 2026-11-26 05:42:16.375.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.130 (0.130) seconds
Test Suite 'MeshCorePackageTests.xctest' passed at 2026-11-26 05:42:16.375.
	 Executed 74 tests, with 0 failures (0 unexpected) in 0.286 (0.291) seconds
Test Suite 'All tests' passed at 2026-11-26 05:42:16.375.
	 Executed 74 tests, with 0 failures (0 unexpected) in 0.286 (0.293) seconds
◇ Test run started.
↳ Testing Library Version: 124.4
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests passed after 0.001 seconds.
```

## fin du log build (erreurs et dernières lignes)
```
---
    /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/dsymutil /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app/Messagerie -o /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app.dSYM

AppIntentsSSUTraining (in target 'Messagerie' from project 'Messagerie')
    cd /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp
    /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app/Info.plist --temp-dir-path /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/ssu --bundle-id cm.messagerie.app --product-path /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app --extracted-metadata-path /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app/Metadata.appintents --metadata-file-list /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/Messagerie.DependencyMetadataFileList --archive-ssu-assets
2026-11-26 05:43:48.401 appintentsnltrainingprocessor[3787:15616] Parsing options for appintentsnltrainingprocessor
2026-11-26 05:43:48.406 appintentsnltrainingprocessor[3787:15616] No AppShortcuts found - Skipping.

RegisterExecutionPolicyException /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app (in target 'Messagerie' from project 'Messagerie')
    cd /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp
    builtin-RegisterExecutionPolicyException /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app

Validate /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app (in target 'Messagerie' from project 'Messagerie')
    cd /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp
    builtin-validationUtility /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app -infoplist-subpath Info.plist

Touch /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app (in target 'Messagerie' from project 'Messagerie')
    cd /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp
    /usr/bin/touch -c /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/Messagerie.app

note: Disabling previews because SWIFT_VERSION is set and SWIFT_OPTIMIZATION_LEVEL=-O, expected -Onone (in target 'Messagerie' from project 'Messagerie')
note: Disabling previews because SWIFT_VERSION is set and SWIFT_OPTIMIZATION_LEVEL=-Owholemodule, expected -Onone (in target 'MeshCore' from project 'MeshCore')
note: Disabling previews because SWIFT_VERSION is set and SWIFT_OPTIMIZATION_LEVEL=-Owholemodule, expected -Onone (in target 'MeshBLE' from project 'MeshCore')
** BUILD SUCCEEDED **

```
