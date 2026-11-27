# Statut CI (ios)

- commit: f42e299cecc7acaec37a6aa37ca1ffafdb6d1dd8
- run: 46008829558 (build-18)
- date: 2026-11-27T14:14:24Z
- résultat: success
- swift test: success
- xcodebuild: success
- ipa: success
- lancement simulateur: success

## lancement
```
cm.messagerie.app: 63089
alive: 1
2026-11-27 14:13:18.508 Df Signal[63089:29b47] [com.apple.UIKit:BackgroundTask] Creating new assertion because there is no existing background assertion.
2026-11-27 14:13:18.508 Df Signal[63089:29b47] [com.apple.UIKit:BackgroundTask] Creating new background assertion
2026-11-27 14:13:18.508 Df Signal[63089:29b47] [com.apple.UIKit:BackgroundTask] Created new background assertion <BKSProcessAssertion: 0x60000210a530>
2026-11-27 14:13:18.522 Df Signal[63089:29b47] [com.apple.UIKit:BackgroundTask] Incrementing reference count for background assertion <BKSProcessAssertion: 0x60000210a530>
2026-11-27 14:13:18.524 E  Signal[63089:0] [com.apple.os_debug_log:] assertion failed: 24H232 22F77: libxpc.dylib + 72720 [021C0BF8-EDD4-395A-B281-2CC7A26F742F]: 0x7d
2026-11-27 14:13:18.528 Df Signal[63089:29ae0] [com.apple.runningboard:general] Added observer for process assertions expiration warning: <_RBSExpirationWarningClient: 0x60000020e5a0>
2026-11-27 14:13:18.624 Df Signal[63089:29b4e] [com.apple.xpc:connection] [0x600003d083c0] failed to do a bootstrap look-up: xpc_error=[3: No such process]
2026-11-27 14:13:18.625 Df Signal[63089:29b4e] [com.apple.xpc:connection] [0x600003d08870] failed to do a bootstrap look-up: xpc_error=[3: No such process]
2026-11-27 14:13:18.693 Df Signal[63089:29ae0] [com.apple.UIKit:BackgroundTask] Reusing background assertion <BKSProcessAssertion: 0x60000210a530>
2026-11-27 14:13:18.693 Df Signal[63089:29ae0] [com.apple.UIKit:BackgroundTask] Incrementing reference count for background assertion <BKSProcessAssertion: 0x60000210a530>
2026-11-27 14:13:18.969 Df Signal[63089:29ae0] [com.apple.UIKit:BackgroundTask] Decrementing reference count for assertion <BKSProcessAssertion: 0x60000210a530> (used by background task with identifier 1: <_UIBackgroundTaskInfo: 0x600001706180>: taskID = 1, taskName = Launch Background Task for Coalescing, creationTime = 2167 (elapsed = 0))
2026-11-27 14:13:19.217 Df Signal[63089:29b67] [com.apple.UIKit:BackgroundTask] Decrementing reference count for assertion <BKSProcessAssertion: 0x60000210a530> (used by background task with identifier 2: <_UIBackgroundTaskInfo: 0x600001718680>: taskID = 2, taskName = Persistent SceneSession Map Update, creationTime = 2167 (elapsed = 1))
2026-11-27 14:13:19.217 Df Signal[63089:29b67] [com.apple.UIKit:BackgroundTask] Will invalidate assertion: <BKSProcessAssertion: 0x60000210a530> for task identifier: 2
2026-11-27 14:13:19.427 E  Signal[63089:29b4a] [com.apple.ttsasset:asset] #FactoryInstall Unable to query results, error: 5
--- /Users/runner/Library/Logs/DiagnosticReports/TypeToSiriWidgetExtension-2026-11-27-141321.000.ips
{"app_name":"TypeToSiriWidgetExtension","timestamp":"2026-11-27 14:13:21.00 +0000","app_version":"1.0","slice_uuid":"58e5d020-917e-396f-b5e6-03ee9b096bd7","build_version":"1","platform":7,"bundleID":"com.apple.siri.TypeToSiriWidget","share_with_app_devs":0,"is_first_party":1,"bug_type":"309","os_version":"macOS 15.8.2 (24H232)","roots_installed":0,"name":"TypeToSiriWidgetExtension","incident_id":"8678680B-C0F6-4922-9193-A5496B2F5AB3"}
{
  "uptime" : 2100,
  "procRole" : "Unspecified",
  "version" : 2,
  "userID" : 501,
  "deployVersion" : 210,
  "modelCode" : "VirtualMac2,1",
  "coalitionID" : 3251,
  "osVersion" : {
    "train" : "macOS 15.8.2",
    "build" : "24H232",
    "releaseType" : "User"
  },
  "captureTime" : "2026-11-27 14:12:36.6700 +0000",
  "codeSigningMonitor" : 0,
  "incident" : "8678680B-C0F6-4922-9193-A5496B2F5AB3",
  "pid" : 62009,
  "translated" : false,
  "cpuType" : "ARM-64",
  "roots_installed" : 0,
  "bug_type" : "309",
  "procLaunch" : "2026-11-27 14:12:34.7932 +0000",
  "procStartAbsTime" : 50969604418,
  "procExitAbsTime" : 51012054298,
  "procName" : "TypeToSiriWidgetExtension",
  "procPath" : "\/Volumes\/VOLUME\/*\/Siri.app\/PlugIns\/TypeToSiriWidgetExtension.appex\/TypeToSiriWidgetExtension",
  "bundleInfo" : {"CFBundleShortVersionString":"1.0","CFBundleVersion":"1","CFBundleIdentifier":"com.apple.siri.TypeToSiriWidget"},
  "parentProc" : "launchd_sim",
  "parentPid" : 60180,
  "coalitionName" : "com.apple.CoreSimulator.SimDevice.DA1C9012-81EC-4C70-B52A-068AEAFBA1DE",
  "crashReporterKey" : "B0E2D549-9467-50AF-AEB7-C95F18593F50",
  "appleIntelligenceStatus" : {"reasons":["countryBillingIneligible","selectedSiriLanguageIneligible","deviceNotCapable","countryLocationIneligible"],"state":"unavailable"},
  "responsiblePid" : 3348,
  "responsibleProc" : "SimulatorTrampoline",
  "codeSigningID" : "com.apple.siri.TypeToSiriWidget",
  "codeSigningTeamID" : "",
  "codeSigningFlags" : 570442241,
  "codeSigningValidationCategory" : 1,
  "codeSigningTrustLevel" : 4294967295,
  "codeSigningAuxiliaryInfo" : 0,
  "instructionByteStream" : {"beforePC":"Jk4BlF\/d\/5cLTwGU8wMAqiECgFLjTwGUYAAANOADE6qsSAGUUk8BlA==","atPC":"IAAg1FXd\/5cBTwGU9AMAqiECgFLZTwGUgAAANOADE6rhAxSqR0kBlA=="},
  "bootSessionUUID" : "443ABC4D-9C79-483B-9656-76213657390E",
  "sip" : "disabled",
  "exception" : {"codes":"0x0000000000000001, 0x00000001cf045f50","rawCodes":[1,7768137552],"type":"EXC_BREAKPOINT","signal":"SIGTRAP"},
  "termination" : {"flags":0,"code":5,"namespace":"SIGNAL","indicator":"Trace\/BPT trap: 5","byProc":"exc handler","byPid":62009},
  "os_fault" : {"process":"TypeToSiriWidgetExtension"},
  "extMods" : {"caller":{"thread_create":0,"thread_set_state":0,"task_for_pid":0},"system":{"thread_create":0,"thread_set_state":0,"task_for_pid":0},"targeted":{"thread_create":0,"thread_set_state":0,"task_for_pid":0},"warnings":0},
  "faultingThread" : 0,
  "threads" : [{"triggered":true,"id":167799,"threadState":{"x":[{"value":105553140400704},{"value":8502354299,"objc-selector":"release"},{"value":8368351384,"symbolLocation":0,"symbol":"OBJC_CLASS_$_OS_os_log"},{"value":22},{"value":4367346192},{"value":19},{"value":0},{"value":0},{"value":2147483647},{"value":2147483647},{"value":105553140384832},{"value":3},{"value":3},{"value":105553140384864},{"value":8368351384,"symbolLocation":0,"symbol":"OBJC_CLASS_$_OS_os_log"},{"value":8368351384,"symbolLocation":0,"symbol":"OBJC_CLASS_$_OS_os_log"},{"value":8368351384,"symbolLocation":0,"symbol":"OBJC_CLASS_$_OS_os_log"},{"value":6444012700,"symbolLocation":0,"symbol":"-[OS_object release]"},{"value":0},{"value":105553140400704},{"value":105553140405952},{"value":0},{"value":0},{"value":105553140384064},{"value":105553128869152},{"value":0},{"value":8411021312},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":7768137552},"cpsr":{"value":1610616832},"fp":{"value":6103784944},"sp":{"value":6103784848},"esr":{"value":4060086273,"description":"(Breakpoint) brk 1"},"pc":{"value":7768137552,"matchesCrashFrame":1},"far":{"value":0}},"queue":"com.apple.main-thread","frames":[{"imageOffset":171856,"symbol":"-[_EXConnectionHandlerExtension willFinishLaunching]","symbolLocation":876,"imageIndex":5},{"imageOffset":12128,"symbol":"-[_EXRunningExtension willFinishLaunching]","symbolLocation":212,"imageIndex":5},{"imageOffset":11000,"symbol":"-[_EXRunningExtension resume]","symbolLocation":40,"imageIndex":5},{"imageOffset":10780,"symbol":"-[_EXRunningExtension startWithArguments:count:]","symbolLocation":392,"imageIndex":5},{"imageOffset":85892,"symbol":"EXExtensionMain","symbolLocation":216,"imageIndex":5},{"imageOffset":7489468,"symbol":"NSExtensionMain","symbolLocation":172,"imageIndex":6},{"imageOffset":4363178964,"imageIndex":7},{"imageOffset":27544,"symbol":"start","symbolLocation":6076,"imageIndex":0}]},{"id":167901,"frames":[{"imageOffset":6532,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":4}],"threadState":{"x":[{"value":6104346624},{"value":3843},{"value":6103810048},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6104346624},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":4366276996},"far":{"value":0}}},{"id":167902,"frames":[{"imageOffset":6532,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":4}],"threadState":{"x":[{"value":6104920064},{"value":4611},{"value":6104383488},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0--- /Users/runner/Library/Logs/DiagnosticReports/TypeToSiriWidgetExtension-2026-11-27-141321.ips
{"app_name":"TypeToSiriWidgetExtension","timestamp":"2026-11-27 14:13:21.00 +0000","app_version":"1.0","slice_uuid":"58e5d020-917e-396f-b5e6-03ee9b096bd7","build_version":"1","platform":7,"bundleID":"com.apple.siri.TypeT```

## fin du log tests (erreurs et dernières lignes)
```
--- LibSignal
---
Test Case '-[MeshCoreTests.ServiceTests testEmptyNameRejectedAndNameClamped]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' started.
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' passed (0.078 seconds).
Test Case '-[MeshCoreTests.ServiceTests testOpaquePayloadDelivery]' started.
Test Case '-[MeshCoreTests.ServiceTests testOpaquePayloadDelivery]' passed (0.036 seconds).
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' passed (0.004 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' started.
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' started.
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' passed (0.004 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' started.
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' passed (0.007 seconds).
Test Suite 'ServiceTests' passed at 2026-11-27 13:39:09.053.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.139 (0.140) seconds
Test Suite 'MeshCorePackageTests.xctest' passed at 2026-11-27 13:39:09.053.
	 Executed 75 tests, with 0 failures (0 unexpected) in 0.264 (0.267) seconds
Test Suite 'All tests' passed at 2026-11-27 13:39:09.053.
	 Executed 75 tests, with 0 failures (0 unexpected) in 0.264 (0.272) seconds
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
Copy /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/GeneratedModuleMaps-iphoneos/LibSignalClient.modulemap /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/LibSignalClient.modulemap (in target 'LibSignalClient' from project 'LibSignalClient')
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient.build/LibSignalClient.modulemap /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/GeneratedModuleMaps-iphoneos
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient\ product.build/empty-LibSignalClient_-379C53AEA1C291D_PackageProduct.plist (in target 'LibSignalClient' from project 'LibSignalClient')
---
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    builtin-swiftStdLibTool --copy --verbose --scan-executable /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Signal.debug.dylib --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Frameworks --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/PlugIns --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/SystemExtensions --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Extensions --scan-folder /System/Library/Frameworks/AudioToolbox.framework --scan-folder /System/Library/Frameworks/AVFoundation.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/BonMot_1760A186445495_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/CFNetwork.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/CloudKit.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/CocoaLumberjack_-500FEF4A7B3EDA0C_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Contacts.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/ContactsUI.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/CoreMedia.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/CoreServices.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/CoreTelephony.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/DeviceDiscoveryUI.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Foundation.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/GRDB_5DC4DB053_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Intents.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/libPhoneNumber_32788E2F62C8D1A8_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/LibSignalClient_-379C53AEA1C291D_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/libwebp_4647D9071D10D7EC_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/Logging_35C93DA702091ECE_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/Lottie_19F76E9844E937_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/MediaPlayer.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/MessageUI.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Metal.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/MetalKit.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/MobileCoinCore_50FF61D552B47778_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Photos.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/PureLayout_7B4592321BA5AA24_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/PushKit.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/QuartzCore.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/SDWebImage_-382901E92613C85E_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/SDWebImageWebPCoder_2F1A86FD5050ED06_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/Security.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/SignalRingRTC_5A63726BF07452E4_PackageProduct.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/SignalServiceKit.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/SignalUI.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/SQLCipher_6ABC871F80100B54_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/StoreKit.framework --scan-folder /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/PackageFrameworks/SwiftProtobuf_7CEE9AB92C12BC6B_PackageProduct.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/SystemConfiguration.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/UIKit.framework --scan-folder /Applications/Xcode_26.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/WiFiAware.framework --platform iphoneos --toolchain /var/run/com.apple.security.cryptexd/mnt/com.apple.MobileAsset.MetalToolchain-v17.3.7003.10.7Ynvoa/Metal.xctoolchain --toolchain /Applications/Xcode_26.3.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Frameworks --strip-bitcode --strip-bitcode-tool /Applications/Xcode_26.3.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/Signal.build/Debug-iphoneos/Signal.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os --back-deploy-swift-span
Ignoring --strip-bitcode because --sign was not passed

AppIntentsSSUTraining (in target 'Signal' from project 'Signal')
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    /Applications/Xcode_26.3.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Info.plist --temp-dir-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/Signal.build/Debug-iphoneos/Signal.build/ssu --bundle-id cm.messagerie.app --product-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app --extracted-metadata-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/Signal.app/Metadata.appintents --metadata-file-list /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/Signal.build/Debug-iphoneos/Signal.build/Signal.DependencyMetadataFileList --archive-ssu-assets
2026-11-27 13:52:07.846 appintentsnltrainingprocessor[24206:68853] Parsing options for appintentsnltrainingprocessor
2026-11-27 13:52:07.849 appintentsnltrainingprocessor[24206:68853] No AppShortcuts found - Skipping.

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
