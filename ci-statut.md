# Statut CI (ios)

- commit: 916b4ebaea536541871c89c47ec7ef36d7019153
- run: 45929298909 (build-8)
- date: 2026-11-27T02:42:47Z
- résultat: failure
- swift test: success
- xcodebuild: failure
- ipa: skipped

## fin du log tests (erreurs et dernières lignes)
```
---
Test Case '-[MeshCoreTests.ServiceTests testEmptyNameRejectedAndNameClamped]' passed (0.003 seconds).
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' started.
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' passed (0.065 seconds).
Test Case '-[MeshCoreTests.ServiceTests testOpaquePayloadDelivery]' started.
Test Case '-[MeshCoreTests.ServiceTests testOpaquePayloadDelivery]' passed (0.022 seconds).
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' passed (0.002 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' started.
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' started.
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' passed (0.002 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' started.
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' passed (0.005 seconds).
Test Suite 'ServiceTests' passed at 2026-11-27 02:37:13.327.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.107 (0.108) seconds
Test Suite 'MeshCorePackageTests.xctest' passed at 2026-11-27 02:37:13.327.
	 Executed 75 tests, with 0 failures (0 unexpected) in 0.224 (0.228) seconds
Test Suite 'All tests' passed at 2026-11-27 02:37:13.327.
	 Executed 75 tests, with 0 failures (0 unexpected) in 0.224 (0.230) seconds
◇ Test run started.
↳ Testing Library Version: 124.4
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests passed after 0.001 seconds.
```

## fin du log build (erreurs et dernières lignes)
```
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Account/TSAccountManager/RegistrationStateChangeManager/RegistrationStateChangeManager.swift:7:15: error: Unable to find module dependency: 'LibSignalClient'
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Account/ServiceId.swift:7:15: error: Unable to find module dependency: 'GRDB'
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Avatars/AvatarDefaultColorManager.swift:9:15: error: Unable to find module dependency: 'SignalRingRTC'
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Messages/Attachments/BlurHash.swift:6:8: error: Unable to find module dependency: 'blurhash'
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Protos/Backups/Backup.pb.swift:20:15: error: Unable to find module dependency: 'SwiftProtobuf'
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Account/TSAccountManager/RegistrationStateChangeManager/RegistrationStateChangeManager.swift:7:15: error: Unable to find module dependency: 'LibSignalClient'
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Account/ServiceId.swift:7:15: error: Unable to find module dependency: 'GRDB'
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Avatars/AvatarDefaultColorManager.swift:9:15: error: Unable to find module dependency: 'SignalRingRTC'
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Messages/Attachments/BlurHash.swift:6:8: error: Unable to find module dependency: 'blurhash'
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Protos/Backups/Backup.pb.swift:20:15: error: Unable to find module dependency: 'SwiftProtobuf'
The following build commands failed:
---
public import SwiftProtobuf
              ^ (in target 'SignalServiceKit' from project 'Signal')
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/Protos/Generated/svr2.pb.swift:20:8: note: Also imported here
import SwiftProtobuf
       ^ (in target 'SignalServiceKit' from project 'Signal')
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/SecureValueRecovery/SgxWebsocketConfigurator.swift:8:15: note: Also imported here
public import SwiftProtobuf
              ^ (in target 'SignalServiceKit' from project 'Signal')
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/SecureValueRecovery/SgxWebsocketConnection.swift:8:8: note: Also imported here
import SwiftProtobuf
       ^ (in target 'SignalServiceKit' from project 'Signal')
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/StorageService/StorageServiceManager.swift:9:8: note: Also imported here
import SwiftProtobuf
       ^ (in target 'SignalServiceKit' from project 'Signal')
/Users/runner/work/Signal-iOS/Signal-iOS/SignalServiceKit/StorageService/StorageServiceProto+Sync.swift:9:8: note: Also imported here
import SwiftProtobuf
       ^ (in target 'SignalServiceKit' from project 'Signal')

** BUILD FAILED **


The following build commands failed:
	SwiftDriver SignalServiceKit normal arm64 com.apple.xcode.tools.swift.compiler (in target 'SignalServiceKit' from project 'Signal')
	Building workspace Signal with scheme Signal and configuration Release
(2 failures)
```
