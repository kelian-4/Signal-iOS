# Removed or neutralised from upstream Signal-iOS

| Item | Status | Reason |
|---|---|---|
| SignalNSE (notification service extension) | removed | Needs push and paid capabilities |
| SignalShareExtension | removed | Needs app groups (paid capability) |
| Upstream GitHub workflows (7) | removed | Signal CI, secrets and signing |
| FUNDING.yml | removed | Signal branding |
| Signal app icons | removed | Replaced by a neutral generated icon |
| Entitlements (push, app groups, Apple Pay, etc.) | emptied | Free SideStore account |
| Project: extension targets, embeds, schemes, alternate icons | removed | Follows the two lines above |
| Bundle id / name | changed | `cm.messagerie.app`, display name "Messagerie" |
| Info.plist | rewritten | Bluetooth, camera usage strings; bluetooth-central and bluetooth-peripheral background modes |
| SMS registration screens | replaced | Onboarding creates an on-device identity (name, 24-word phrase); no phone number, no account |
| Signal servers: websockets, prekey API, message send/receive | neutralised | `ChatConnectionManager` is replaced by `MeshChatConnectionManager`; sends, prekey fetch/upload and receipts go through a local shim and the BLE mesh. Other network features (CDN, storage service, calls, payments, usernames, donations, push, contact discovery) stay in the tree but have no server and fail offline |
| Signal UI and message pipeline | kept | Conversations, composer and settings are Signal's own; one added row "Réseau mesh" in Settings |

## Deviations to be aware of

- Message encryption is Signal's own libsignal sessions (prekey bundles exchanged over the mesh). The mesh layer wraps each payload with X25519 + ChaCha20-Poly1305.
- The mesh backup (`.meshbackup`, keyed by the 24 words) covers identity and contacts, not the Signal message database.
- Attachments, groups, calls, stories and payments are not carried by the mesh and do not work.
- Nothing here has been run on a device by the author; the first compile is CI.
