# Statut CI (ios)

- commit: 90c550c91c106beb0777747a1023ece9cb1bd510
- run: 45932434602 (build-12)
- date: 2026-11-27T03:18:00Z
- résultat: failure
- swift test: success
- xcodebuild: failure
- ipa: skipped

## fin du log tests (erreurs et dernières lignes)
```
--- LibSignal
---
Test Case '-[MeshCoreTests.ServiceTests testEmptyNameRejectedAndNameClamped]' passed (0.001 seconds).
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' started.
Test Case '-[MeshCoreTests.ServiceTests testEndToEndWithProductionCryptoAndBackupRestore]' passed (0.028 seconds).
Test Case '-[MeshCoreTests.ServiceTests testOpaquePayloadDelivery]' started.
Test Case '-[MeshCoreTests.ServiceTests testOpaquePayloadDelivery]' passed (0.013 seconds).
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
Test Suite 'ServiceTests' passed at 2026-11-27 03:09:26.865.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.051 (0.051) seconds
Test Suite 'MeshCorePackageTests.xctest' passed at 2026-11-27 03:09:26.865.
	 Executed 75 tests, with 0 failures (0 unexpected) in 0.156 (0.159) seconds
Test Suite 'All tests' passed at 2026-11-27 03:09:26.865.
	 Executed 75 tests, with 0 failures (0 unexpected) in 0.156 (0.160) seconds
◇ Test run started.
↳ Testing Library Version: 124.4
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests passed after 0.001 seconds.
```

## fin du log build (erreurs et dernières lignes)
```
/Users/runner/work/Signal-iOS/Signal-iOS/Signal/Mesh/MeshOnboardingViewController.swift:126:76: error: cannot convert value of type '() -> Task<(), Never>' to expected argument type '() -> Void'
/Users/runner/work/Signal-iOS/Signal-iOS/Signal/Mesh/MeshOnboardingViewController.swift:127:42: error: cannot infer contextual base in reference to member 'fullScreen'
The following build commands failed:
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
WriteAuxiliaryFile /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/LibSignalClient.build/Debug-iphoneos/LibSignalClient\ product.build/Objects-normal/arm64/LibSignalClient_-379C53AEA1C291D_PackageProduct.LinkFileList (in target 'LibSignalClient' from project 'LibSignalClient')
---

SwiftCompile normal arm64 /Users/runner/work/Signal-iOS/Signal-iOS/Signal/ConversationView/CellViews/AudioWaveformProgressView.swift (in target 'Signal' from project 'Signal')
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    

SwiftCompile normal arm64 /Users/runner/work/Signal-iOS/Signal-iOS/Signal/ConversationView/CellViews/CVAttachmentProgressView.swift (in target 'Signal' from project 'Signal')
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    

SwiftCompile normal arm64 /Users/runner/work/Signal-iOS/Signal-iOS/Signal/ConversationView/CellViews/CVColorOrGradientView.swift (in target 'Signal' from project 'Signal')
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    

SwiftDriverJobDiscovery normal arm64 Compiling AudioAllMediaPresenter.swift, AudioCell.swift, MediaGalleryFileCell.swift, MediaTileListModeCell.swift, WidePhotoCell.swift, MediaDismissAnimationController.swift, MediaInteractiveDismiss.swift, MediaPresentationContext.swift, MediaTransitionImageView.swift, MediaZoomAnimationController.swift, AllMediaViewController.swift, JournalingOrderedDictionary.swift, MediaCaptionView.swift, MediaControlPanelView.swift, MediaGallery.swift, MediaGalleryAccessoriesHelper.swift, MediaGalleryCellItem.swift, MediaGalleryCollectionViewUpdater.swift, MediaGallerySections.swift, MediaItemViewController.swift, MediaPageViewController.swift, MediaTileScrollFlag.swift, MediaTileViewController.swift, SquareMediaTileViewLayout.swift, VideoPlaybackControls.swift (in target 'Signal' from project 'Signal')

SwiftCompile normal arm64 Compiling\ DeviceTransferStatusViewController.swift,\ IncomingDeviceTransferTask.swift,\ OutgoingDeviceTransferTask.swift,\ SelfSignedIdentity.swift,\ ThroughputMonitor.swift,\ TransferStatusState.swift,\ Emoji.swift,\ Emoji+Category.swift,\ Emoji+Name.swift,\ Emoji+SkinTones.swift,\ EmojiWithSkinTones+String.swift,\ Emoji+Available.swift,\ EmojiPickerCollectionView.swift,\ EmojiPickerSectionToolbar.swift,\ EmojiPickerSheet.swift,\ EmojiReactionPickerConfigViewController.swift,\ EmojiSkinTonePicker.swift,\ EmojiWithSkinTones.swift,\ OsExpiry.swift,\ UIDevice+CanUpgradeOperatingSystem.swift,\ GroupSendEndorsementExpirationJob.swift,\ LowDiskSpaceMonitoring.swift,\ BackupsBackUpYourMediaMegaphone.swift,\ BackupsEnabledRecentlyNotificationMegaphone.swift,\ BackupsGenericEnableMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/DeviceTransfer/DeviceTransferStatusViewController.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/DeviceTransfer/IncomingDeviceTransferTask.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/DeviceTransfer/OutgoingDeviceTransferTask.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/DeviceTransfer/SelfSignedIdentity.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/DeviceTransfer/ThroughputMonitor.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/DeviceTransfer/TransferStatusState.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/Generated/Emoji.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/Generated/Emoji+Category.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/Generated/Emoji+Name.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/Generated/Emoji+SkinTones.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/Generated/EmojiWithSkinTones+String.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/Emoji+Available.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/EmojiPickerCollectionView.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/EmojiPickerSectionToolbar.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/EmojiPickerSheet.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/EmojiReactionPickerConfigViewController.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/EmojiSkinTonePicker.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Emoji/EmojiWithSkinTones.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Expiration/OsExpiry.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Expiration/UIDevice+CanUpgradeOperatingSystem.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Groups/GroupSendEndorsementExpirationJob.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/LowDiskSpace/LowDiskSpaceMonitoring.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/BackupsBackUpYourMediaMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/BackupsEnabledRecentlyNotificationMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/BackupsGenericEnableMegaphone.swift (in target 'Signal' from project 'Signal')

** BUILD FAILED **


The following build commands failed:
	SwiftCompile normal arm64 Compiling\ BackupsNeverLoseAMessageMegaphone.swift,\ BackupsSaveSpaceMegaphone.swift,\ ContactPermissionReminderMegaphone.swift,\ CreateUsernameMegaphone.swift,\ InactiveLinkedDeviceReminderMegaphone.swift,\ InactivePrimaryDeviceReminderMegaphone.swift,\ IntroducingPINsMegaphone.swift,\ MegaphoneView.swift,\ NewLinkedDeviceNotificationMegaphone.swift,\ NotificationPermissionReminderMegaphone.swift,\ PinReminderMegaphone.swift,\ RecoveryKeyReminderMegaphone.swift,\ RemoteMegaphone.swift,\ ExperienceUpgradeManager.swift,\ RemoteAnnouncementFetcher.swift,\ RemoteMegaphoneFetcher.swift,\ RemoteReleaseNotesFetcher.swift,\ RemoteReleaseNotesFetchingManager.swift,\ MeshBridge.swift,\ MeshKeychainVault.swift,\ MeshOnboardingViewController.swift,\ MeshViewController.swift,\ AppIconBadgeUpdater.swift,\ BadgeManager.swift,\ MessageFetchBGRefreshTask.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/BackupsNeverLoseAMessageMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/BackupsSaveSpaceMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/ContactPermissionReminderMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/CreateUsernameMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/InactiveLinkedDeviceReminderMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/InactivePrimaryDeviceReminderMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/IntroducingPINsMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/MegaphoneView.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/NewLinkedDeviceNotificationMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/NotificationPermissionReminderMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/PinReminderMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/RecoveryKeyReminderMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/UserInterface/RemoteMegaphone.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/ExperienceUpgradeManager.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/RemoteAnnouncementFetcher.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/RemoteMegaphoneFetcher.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/RemoteReleaseNotesFetcher.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Megaphones/RemoteReleaseNotesFetchingManager.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Mesh/MeshBridge.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Mesh/MeshKeychainVault.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Mesh/MeshOnboardingViewController.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Mesh/MeshViewController.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Notifications/AppIconBadgeUpdater.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Notifications/BadgeManager.swift /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Notifications/MessageFetchBGRefreshTask.swift (in target 'Signal' from project 'Signal')
	SwiftCompile normal arm64 /Users/runner/work/Signal-iOS/Signal-iOS/Signal/Mesh/MeshOnboardingViewController.swift (in target 'Signal' from project 'Signal')
	Building workspace Signal with scheme Signal and configuration Debug
(3 failures)
```
