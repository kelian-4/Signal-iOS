# Statut CI (signal-ui)

- commit: 14a020e7e7a6c21db44143e15458702329bb78d4
- run: 45793301063
- resolve: success
- build: failure

## resolve: erreurs
```
---
  blurhash: /Users/runner/work/Signal-iOS/Signal-iOS/ThirdParty/blurhash
  swift-log: https://github.com/apple/swift-log @ 1.4.0
  SignalMessageBackupTests: https://github.com/signalapp/Signal-Message-Backup-Tests @ a76aa28
  SwiftProtobuf: https://github.com/apple/swift-protobuf @ 1.39.0
  libPhoneNumber: https://github.com/signalapp/libPhoneNumber-iOS @ 1.2.0-signal.2
  SignalRingRTC: https://github.com/signalapp/ringrtc @ 2.75.0
  libwebp: https://github.com/SDWebImage/libwebp-Xcode.git @ 1.5.0
  BinaryDependencies: /Users/runner/work/Signal-iOS/Signal-iOS/BinaryDependencies
  LibSignalClient: https://github.com/signalapp/libsignal @ 0.108.1
  PureLayout: https://github.com/PureLayout/PureLayout @ 3.1.9
  Lottie: https://github.com/airbnb/lottie-ios.git @ 4.4.3
  MobileCoin: https://github.com/signalapp/MobileCoin-Swift @ 6.0.3-signal.1
  SQLCipher: https://github.com/signalapp/sqlcipher @ 4.6.1-signal.1

resolved source packages: SDWebImageWebPCoder, SDWebImage, GRDB, BonMot, CocoaLumberjack, blurhash, swift-log, SignalMessageBackupTests, SwiftProtobuf, libPhoneNumber, SignalRingRTC, libwebp, BinaryDependencies, LibSignalClient, PureLayout, Lottie, MobileCoin, SQLCipher
```

## build: erreurs
```
/Users/runner/work/Signal-iOS/Signal-iOS/build/SourcePackages/checkouts/libsignal/swift/Sources/LibSignalClient/NativeNice.swift:5286:5: error: unexpected ',' separator
/Users/runner/work/Signal-iOS/Signal-iOS/build/SourcePackages/checkouts/libsignal/swift/Sources/LibSignalClient/NativeNice.swift:5389:5: error: unexpected ',' separator
/Users/runner/work/Signal-iOS/Signal-iOS/build/SourcePackages/checkouts/libsignal/swift/Sources/LibSignalClient/NativeNice.swift:5574:5: error: unexpected ',' separator
/Users/runner/work/Signal-iOS/Signal-iOS/build/SourcePackages/checkouts/libsignal/swift/Sources/LibSignalClient/NativeNice.swift:6139:5: error: unexpected ',' separator
---
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    

SwiftDriver BonMot normal arm64 com.apple.xcode.tools.swift.compiler (in target 'BonMot' from project 'BonMot')
    cd /Users/runner/work/Signal-iOS/Signal-iOS
    builtin-SwiftDriver -- /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name BonMot -Onone -enforce-exclusivity\=checked @/Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/BonMot.build/Debug-iphoneos/BonMot.build/Objects-normal/arm64/BonMot.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DXcode -plugin-path /Applications/Xcode_16.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.5.sdk -target arm64-apple-ios12.0 -g -module-cache-path /Users/runner/work/Signal-iOS/Signal-iOS/build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Index.noindex/DataStore -swift-version 5 -I /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos -I /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib -F /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos -F /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Frameworks -F /Applications/Xcode_16.4.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.5.sdk/Developer/Library/Frameworks -c -j3 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/runner/work/Signal-iOS/Signal-iOS/build/SDKStatCaches.noindex/iphoneos18.5-22F76-a529daf784b3616c7c04a36aeb7f5c05.sdkstatcache -output-file-map /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/BonMot.build/Debug-iphoneos/BonMot.build/Objects-normal/arm64/BonMot-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/BonMot.build/Debug-iphoneos/BonMot.build/Objects-normal/arm64/BonMot.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/runner/work/Signal-iOS/Signal-iOS/build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/BonMot.build/Debug-iphoneos/BonMot.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/BonMot.build/Debug-iphoneos/BonMot.build/Objects-normal/arm64/BonMot_const_extract_protocols.json -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Products/Debug-iphoneos/include -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/BonMot.build/Debug-iphoneos/BonMot.build/DerivedSources-normal/arm64 -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/BonMot.build/Debug-iphoneos/BonMot.build/DerivedSources/arm64 -Xcc -I/Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/BonMot.build/Debug-iphoneos/BonMot.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/runner/work/Signal-iOS/Signal-iOS/build/Build/Intermediates.noindex/BonMot.build/Debug-iphoneos/BonMot.build/Objects-normal/arm64/BonMot-Swift.h -working-directory /Users/runner/work/Signal-iOS/Signal-iOS -experimental-emit-module-separately -disable-cmo

** BUILD FAILED **


The following build commands failed:
	SwiftEmitModule normal arm64 Emitting\ module\ for\ LibSignalClient (in target 'LibSignalClient' from project 'LibSignalClient')
	EmitSwiftModule normal arm64 (in target 'LibSignalClient' from project 'LibSignalClient')
	Building workspace Signal with scheme Signal and configuration Debug
(3 failures)
```
