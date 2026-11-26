# Messagerie (iOS)

Offline messenger over Bluetooth Low Energy mesh. No server, no phone number, no account.

- `MeshCore/`: Swift package (protocol, relay, outbox, identity, verification, backup, service engine, BLE transport) with unit tests (`swift test`).
- `Signal/`, `SignalServiceKit/`, `SignalUI/`: the Signal-iOS app and UI, unchanged except for the backend: `SignalServiceKit/Mesh/` and `Signal/Mesh/` route Signal's own message pipeline over the Bluetooth mesh instead of Signal's servers.
- `spec/`: see the LAB repository (PROTOCOL.md, vectors.json).
- `docs/REMOVED.md`: what was removed from upstream Signal-iOS and why.
- `docs/FIELD-TEST.md`: hardware test table.

Build: see BUILDING.md. Fork of Signal-iOS, AGPL-3.0, see NOTICE.md.
