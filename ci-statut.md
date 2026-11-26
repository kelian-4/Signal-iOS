# Statut CI (ios)

- commit: 13df28a00a92d660b315cddd0165ee683f2a22a1
- run: 45761923048 (build-2)
- date: 2026-11-26T05:30:14Z
- résultat: failure
- swift test: failure
- xcodebuild: skipped
- ipa: skipped

## fin du log tests (erreurs et dernières lignes)
```
/Users/runner/work/Signal-iOS/Signal-iOS/MeshCore/Tests/MeshCoreTests/ServiceTests.swift:78: error: -[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore] : XCTAssertEqual failed: ("["salut", "bonjour"]") is not equal to ("["bonjour"]")
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' failed (0.318 seconds).
Test Suite 'ServiceTests' failed at 2026-11-26 05:30:14.135.
Test Suite 'MeshCorePackageTests.xctest' failed at 2026-11-26 05:30:14.135.
Test Suite 'All tests' failed at 2026-11-26 05:30:14.135.
---
Test Case '-[MeshCoreTests.ServiceTests testEmptyNameRejectedAndNameClamped]' started.
Test Case '-[MeshCoreTests.ServiceTests testEmptyNameRejectedAndNameClamped]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' started.
/Users/runner/work/Signal-iOS/Signal-iOS/MeshCore/Tests/MeshCoreTests/ServiceTests.swift:78: error: -[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore] : XCTAssertEqual failed: ("["salut", "bonjour"]") is not equal to ("["bonjour"]")
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' failed (0.318 seconds).
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testRestoreFromPhraseGivesSameIdentity]' passed (0.003 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' started.
Test Case '-[MeshCoreTests.ServiceTests testSessionCryptoRoundTripAndTamper]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' started.
Test Case '-[MeshCoreTests.ServiceTests testSignatureAndSharedSecretSymmetry]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' started.
Test Case '-[MeshCoreTests.ServiceTests testWipeRemovesIdentity]' passed (0.002 seconds).
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' started.
Test Case '-[MeshCoreTests.ServiceTests testWrongBackupKeyRejected]' passed (0.002 seconds).
Test Suite 'ServiceTests' failed at 2026-11-26 05:30:14.135.
	 Executed 8 tests, with 1 failure (0 unexpected) in 0.331 (0.332) seconds
Test Suite 'MeshCorePackageTests.xctest' failed at 2026-11-26 05:30:14.135.
	 Executed 74 tests, with 1 failure (0 unexpected) in 0.444 (0.447) seconds
Test Suite 'All tests' failed at 2026-11-26 05:30:14.135.
	 Executed 74 tests, with 1 failure (0 unexpected) in 0.444 (0.449) seconds
◇ Test run started.
↳ Testing Library Version: 124.4
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests passed after 0.001 seconds.
```
