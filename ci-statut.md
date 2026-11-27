# Statut CI (ios)

- commit: cd4ad23b0667ab78d35e616ee30e74cd29691c7a
- run: 45958097315 (build-15)
- date: 2026-11-27T07:56:06Z
- résultat: success
- swift test: success
- xcodebuild: success
- ipa: success
- lancement simulateur: success

## lancement
```
cm.messagerie.app: 83996
alive: 1
2026-11-27 07:54:37.364 Df Signal[83996:35891] [com.apple.UIKit:BackgroundTask] Creating new assertion because there is no existing background assertion.
2026-11-27 07:54:37.364 Df Signal[83996:35891] [com.apple.UIKit:BackgroundTask] Creating new background assertion
2026-11-27 07:54:37.364 Df Signal[83996:35891] [com.apple.UIKit:BackgroundTask] Created new background assertion <BKSProcessAssertion: 0x600002102b70>
2026-11-27 07:54:37.375 E  Signal[83996:0] [com.apple.os_debug_log:] assertion failed: 24H232 22F77: libxpc.dylib + 72720 [021C0BF8-EDD4-395A-B281-2CC7A26F742F]: 0x7d
2026-11-27 07:54:37.376 Df Signal[83996:35891] [com.apple.UIKit:BackgroundTask] Incrementing reference count for background assertion <BKSProcessAssertion: 0x600002102b70>
2026-11-27 07:54:37.377 Df Signal[83996:3586b] [com.apple.runningboard:general] Added observer for process assertions expiration warning: <_RBSExpirationWarningClient: 0x60000020bc00>
2026-11-27 07:54:37.475 Df Signal[83996:35894] [com.apple.xpc:connection] [0x600003d082d0] failed to do a bootstrap look-up: xpc_error=[3: No such process]
2026-11-27 07:54:37.476 Df Signal[83996:35894] [com.apple.xpc:connection] [0x600003d04870] failed to do a bootstrap look-up: xpc_error=[3: No such process]
2026-11-27 07:54:37.569 Df Signal[83996:3586b] [com.apple.UIKit:BackgroundTask] Reusing background assertion <BKSProcessAssertion: 0x600002102b70>
2026-11-27 07:54:37.569 Df Signal[83996:3586b] [com.apple.UIKit:BackgroundTask] Incrementing reference count for background assertion <BKSProcessAssertion: 0x600002102b70>
2026-11-27 07:54:37.824 Df Signal[83996:3586b] [com.apple.UIKit:BackgroundTask] Decrementing reference count for assertion <BKSProcessAssertion: 0x600002102b70> (used by background task with identifier 1: <_UIBackgroundTaskInfo: 0x600001709d40>: taskID = 1, taskName = Launch Background Task for Coalescing, creationTime = 2575 (elapsed = 1))
2026-11-27 07:54:38.095 Df Signal[83996:35894] [com.apple.UIKit:BackgroundTask] Decrementing reference count for assertion <BKSProcessAssertion: 0x600002102b70> (used by background task with identifier 2: <_UIBackgroundTaskInfo: 0x600001703900>: taskID = 2, taskName = Persistent SceneSession Map Update, creationTime = 2576 (elapsed = 0))
2026-11-27 07:54:38.095 Df Signal[83996:35894] [com.apple.UIKit:BackgroundTask] Will invalidate assertion: <BKSProcessAssertion: 0x600002102b70> for task identifier: 2
2026-11-27 07:54:38.333 E  Signal[83996:35896] [com.apple.ttsasset:asset] #FactoryInstall Unable to query results, error: 5
```

## fin du log tests (erreurs et dernières lignes)
```
--- LibSignal
---
Test Case '-[MeshCoreTests.ServiceTests testEmptyNameRejectedAndNameClamped]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' started.
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' passed (0.038 seconds).
Test Case '-[MeshCoreTests.ServiceTests testOpaquePayloadDelivery]' started.
Test Case '-[MeshCoreTests.ServiceTests testOpaquePayloadDelivery]' passed (0.014 seconds).
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' passed (0.002 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' started.
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' started.
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' started.
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' passed (0.001 seconds).
Test Suite 'ServiceTests' passed at 2026-11-27 07:24:02.607.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.063 (0.063) seconds
Test Suite 'MeshCorePackageTests.xctest' passed at 2026-11-27 07:24:02.607.
	 Executed 75 tests, with 0 failures (0 unexpected) in 0.172 (0.175) seconds
Test Suite 'All tests' passed at 2026-11-27 07:24:02.608.
	 Executed 75 tests, with 0 failures (0 unexpected) in 0.172 (0.176) seconds
◇ Test run started.
↳ Testing Library Version: 124.4
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests passed after 0.001 seconds.
```

## fin du log build (erreurs et dernières lignes)
```
--- LibSignal
  LibSignalClient: https://github.com/signalapp/libsignal @ 0.108.1
        ➜ Explicit dependency on target 'LibSignalClient' in project 'LibSignalClient'
        ➜ Explicit dependency on target 'LibSignalClient' in project 'LibSignalClient'
        ➜ Explicit dependency on target 'LibSignalClient' in project 'LibSignalClient'
        ➜ Explicit dependency on target 'LibSignalFfi' in project 'BinaryDependencies'
    Target 'LibSignalFfi' in project 'BinaryDependencies' (no dependencies)
    Target 'LibSignalClient' in project 'LibSignalClient'
        ➜ Explicit dependency on target 'LibSignalClient' in project 'LibSignalClient'
    Target 'LibSignalClient' in project 'LibSignalClient'
        ➜ Explicit dependency on target 'SignalFfi' in project 'LibSignalClient'
    Target 'SignalFfi' in project 'LibSignalClient' (no dependencies)
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/Objects-normal/arm64/LibSignalClient_const_extract_protocols.json (in target 'LibSignalClient' from project 'LibSignalClient')
    write-file /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/Objects-normal/arm64/LibSignalClient_const_extract_protocols.json
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/Objects-normal/arm64/LibSignalClient.SwiftFileList (in target 'LibSignalClient' from project 'LibSignalClient')
    write-file /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/Objects-normal/arm64/LibSignalClient.SwiftFileList
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/Objects-normal/arm64/LibSignalClient.SwiftConstValuesFileList (in target 'LibSignalClient' from project 'LibSignalClient')
    write-file /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/Objects-normal/arm64/LibSignalClient.SwiftConstValuesFileList
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/Objects-normal/arm64/LibSignalClient.LinkFileList (in target 'LibSignalClient' from project 'LibSignalClient')
    write-file /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/Objects-normal/arm64/LibSignalClient.LinkFileList
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/Objects-normal/arm64/LibSignalClient-OutputFileMap.json (in target 'LibSignalClient' from project 'LibSignalClient')
    write-file /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/Objects-normal/arm64/LibSignalClient-OutputFileMap.json
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/LibSignalClient.modulemap (in target 'LibSignalClient' from project 'LibSignalClient')
    write-file /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/LibSignalClient.modulemap
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/LibSignalClient.DependencyStaticMetadataFileList (in target 'LibSignalClient' from project 'LibSignalClient')
    write-file /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/LibSignalClient.DependencyStaticMetadataFileList
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/LibSignalClient.DependencyMetadataFileList (in target 'LibSignalClient' from project 'LibSignalClient')
    write-file /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/LibSignalClient.DependencyMetadataFileList
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient\ product.build/empty-LibSignalClient_-379C53AEA1C291D_PackageProduct.plist (in target 'LibSignalClient' from project 'LibSignalClient')
    write-file /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient\ product.build/empty-LibSignalClient_-379C53AEA1C291D_PackageProduct.plist
Copy /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/GeneratedModuleMaps-iphoneos/LibSignalClient.modulemap /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/LibSignalClient.modulemap (in target 'LibSignalClient' from project 'LibSignalClient')
---
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    builtin-swiftStdLibTool --copy --verbose --scan-executable /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Signal.debug.dylib --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Frameworks --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/PlugIns --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/SystemExtensions --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Extensions --scan-folder /System/Library/Frameworks/AudioToolbox.framework --scan-folder /System/Library/Frameworks/AVFoundation.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/BonMot_1760A186445495_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/CFNetwork.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/CloudKit.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/CocoaLumberjack_-500FEF4A7B3EDA0C_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Contacts.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/ContactsUI.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/CoreMedia.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/CoreServices.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/CoreTelephony.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/DeviceDiscoveryUI.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Foundation.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/GRDB_5DC4DB053_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Intents.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/libPhoneNumber_32788E2F62C8D1A8_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/LibSignalClient_-379C53AEA1C291D_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/libwebp_4647D9071D10D7EC_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/Logging_35C93DA702091ECE_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/Lottie_19F76E9844E937_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/MediaPlayer.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/MessageUI.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Metal.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/MetalKit.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/MobileCoinCore_50FF61D552B47778_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Photos.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/PureLayout_7B4592321BA5AA24_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/PushKit.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/QuartzCore.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/SDWebImage_-382901E92613C85E_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/SDWebImageWebPCoder_2F1A86FD5050ED06_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Security.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/SignalRingRTC_5A63726BF07452E4_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/SignalServiceKit.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/SignalUI.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/SQLCipher_6ABC871F80100B54_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/StoreKit.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/SwiftProtobuf_7CEE9AB92C12BC6B_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/SystemConfiguration.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/UIKit.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/WiFiAware.framework --platform iphoneos --toolchain /var/run/com.apple.security.cryptexd/mnt/com.apple.MobileAsset.MetalToolchain-v17.3.7003.10.6bDAXH/Metal.xctoolchain --toolchain /Applications/Xcode_26.3.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Frameworks --strip-bitcode --strip-bitcode-tool /Applications/Xcode_26.3.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/Signal.build/Debug-iphoneos/Signal.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os --back-deploy-swift-span
Ignoring --strip-bitcode because --sign was not passed

AppIntentsSSUTraining (in target 'Signal' from project 'Signal')
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    /Applications/Xcode_26.3.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Info.plist --temp-dir-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/Signal.build/Debug-iphoneos/Signal.build/ssu --bundle-id cm.messagerie.app --product-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app --extracted-metadata-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Metadata.appintents --metadata-file-list /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/Signal.build/Debug-iphoneos/Signal.build/Signal.DependencyMetadataFileList --archive-ssu-assets
2026-11-27 07:35:15.903 appintentsnltrainingprocessor[39307:106571] Parsing options for appintentsnltrainingprocessor
2026-11-27 07:35:15.905 appintentsnltrainingprocessor[39307:106571] No AppShortcuts found - Skipping.

RegisterExecutionPolicyException /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app (in target 'Signal' from project 'Signal')
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    builtin-RegisterExecutionPolicyException /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app

Validate /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app (in target 'Signal' from project 'Signal')
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    builtin-validationUtility /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app -validate-for-store -shallow-bundle -infoplist-subpath Info.plist
warning: All interface orientations must be supported unless the app requires full screen. (in target 'Signal' from project 'Signal')

Touch /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app (in target 'Signal' from project 'Signal')
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    /usr/bin/touch -c /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app

** BUILD SUCCEEDED **

```
