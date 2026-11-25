# Messagerie (iOS)

Offline messenger over Bluetooth Low Energy mesh. No server, no phone number, no account.

- `MeshCore/`: Swift package (protocol, relay, outbox, identity, verification, backup, service engine, BLE transport) with unit tests (`swift test`).
- `MeshApp/`: SwiftUI app (project generated with XcodeGen from `project.yml`).
- `spec/`: see the LAB repository (PROTOCOL.md, vectors.json).
- `docs/REMOVED.md`: what was removed from upstream Signal-iOS and why.
- `docs/FIELD-TEST.md`: hardware test table.

Build: see BUILDING.md. Fork of Signal-iOS, AGPL-3.0, see NOTICE.md.
