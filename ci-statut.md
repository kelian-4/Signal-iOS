# Statut CI (ios)

- commit: 1197eebc481b6011bdc91ab8f1d736c483518810
- run: 45762419140 (build-3)
- date: 2026-11-26T05:35:53Z
- résultat: failure
- swift test: success
- xcodebuild: failure
- ipa: skipped

## fin du log tests (erreurs et dernières lignes)
```
---
Test Case '-[MeshCoreTests.ServiceTests testCreateIdentityGivesTwentyFourWordsAndPersists]' passed (0.004 seconds).
Test Case '-[MeshCoreTests.ServiceTests testEmptyNameRejectedAndNameClamped]' started.
Test Case '-[MeshCoreTests.ServiceTests testEmptyNameRejectedAndNameClamped]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' started.
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' passed (0.043 seconds).
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' passed (0.002 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' started.
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' started.
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' started.
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' passed (0.002 seconds).
Test Suite 'ServiceTests' passed at 2026-11-26 05:34:45.501.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.056 (0.056) seconds
Test Suite 'MeshCorePackageTests.xctest' passed at 2026-11-26 05:34:45.501.
	 Executed 74 tests, with 0 failures (0 unexpected) in 0.191 (0.194) seconds
Test Suite 'All tests' passed at 2026-11-26 05:34:45.501.
	 Executed 74 tests, with 0 failures (0 unexpected) in 0.191 (0.197) seconds
◇ Test run started.
↳ Testing Library Version: 124.4
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests passed after 0.001 seconds.
```

## fin du log build (erreurs et dernières lignes)
```
/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/AppModel.swift:33:29: error: 'BLEStatus' initializer is inaccessible due to 'internal' protection level
/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/RootView.swift:163:31: error: referencing subscript 'subscript(dynamicMember:)' requires wrapper 'EnvironmentObject<AppModel>.Wrapper'
/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/RootView.swift:163:55: error: referencing operator function '>' on 'BinaryInteger' requires that 'Binding<Subject>' conform to 'BinaryInteger'
/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/RootView.swift:167:26: error: referencing subscript 'subscript(dynamicMember:)' requires wrapper 'EnvironmentObject<AppModel>.Wrapper'
/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/RootView.swift:167:52: error: referencing operator function '==' on 'StringProtocol' requires that 'Binding<Subject>' conform to 'StringProtocol'
/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/SettingsView.swift:46:45: error: cannot convert value of type 'Binding<Subject>' to expected argument type 'String'
/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/SettingsView.swift:46:32: error: referencing subscript 'subscript(dynamicMember:)' requires wrapper 'EnvironmentObject<AppModel>.Wrapper'
The following build commands failed:
---
                                            ^
/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/SettingsView.swift:46:32: error: referencing subscript 'subscript(dynamicMember:)' requires wrapper 'EnvironmentObject<AppModel>.Wrapper'
                row("Central", model.status.centralState)
                               ^
                               $

SwiftDriver\ Compilation Messagerie normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Messagerie' from project 'Messagerie')
    cd /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp
    builtin-Swift-Compilation -- /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name Messagerie -O -whole-module-optimization -enforce-exclusivity\=checked @/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/Objects-normal/arm64/Messagerie.SwiftFileList -enable-bare-slash-regex -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.5.sdk -target arm64-apple-ios15.0 -g -module-cache-path /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -swift-version 5 -I /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos -F /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/PackageFrameworks -F /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/PackageFrameworks -F /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos -c -num-threads 3 -Xcc -ivfsstatcache -Xcc /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/SDKStatCaches.noindex/iphoneos18.5-22F76-a529daf784b3616c7c04a36aeb7f5c05.sdkstatcache -output-file-map /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/Objects-normal/arm64/Messagerie-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/Objects-normal/arm64/Messagerie.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/Objects-normal/arm64/Messagerie_const_extract_protocols.json -Xcc -iquote -Xcc /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/Messagerie-generated-files.hmap -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/Messagerie-own-target-headers.hmap -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/Messagerie-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie-642dd7e1dea2bade2f01e25ae95e71ee-VFS-iphoneos/all-product-headers.yaml -Xcc -iquote -Xcc /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/Messagerie-project-headers.hmap -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/include -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/DerivedSources-normal/arm64 -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/DerivedSources/arm64 -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/DerivedSources -emit-objc-header -emit-objc-header-path /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/Objects-normal/arm64/Messagerie-Swift.h -working-directory /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp -no-emit-module-separately-wmo

RegisterExecutionPolicyException /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/MeshBLE.o (in target 'MeshBLE' from project 'MeshCore')
    cd /Users/runner/work/Signal-iOS/Signal-iOS/MeshCore
    builtin-RegisterExecutionPolicyException /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Products/Release-iphoneos/MeshBLE.o

note: Disabling previews because SWIFT_VERSION is set and SWIFT_OPTIMIZATION_LEVEL=-O, expected -Onone (in target 'Messagerie' from project 'Messagerie')
note: Disabling previews because SWIFT_VERSION is set and SWIFT_OPTIMIZATION_LEVEL=-Owholemodule, expected -Onone (in target 'MeshCore' from project 'MeshCore')
note: Disabling previews because SWIFT_VERSION is set and SWIFT_OPTIMIZATION_LEVEL=-Owholemodule, expected -Onone (in target 'MeshBLE' from project 'MeshCore')
** BUILD FAILED **


The following build commands failed:
	SwiftCompile normal arm64 Compiling\ AppModel.swift,\ ChatView.swift,\ KeychainVault.swift,\ MessagerieApp.swift,\ QRSupport.swift,\ RootView.swift,\ SettingsView.swift,\ GeneratedAssetSymbols.swift /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/AppModel.swift /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/ChatView.swift /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/KeychainVault.swift /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/MessagerieApp.swift /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/QRSupport.swift /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/RootView.swift /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/Sources/SettingsView.swift /Users/runner/work/Signal-iOS/Signal-iOS/MeshApp/build/Build/Intermediates.noindex/Messagerie.build/Release-iphoneos/Messagerie.build/DerivedSources/GeneratedAssetSymbols.swift (in target 'Messagerie' from project 'Messagerie')
	CompileSwift normal arm64 (in target 'Messagerie' from project 'Messagerie')
	Building project Messagerie with scheme Messagerie and configuration Release
(3 failures)
```
