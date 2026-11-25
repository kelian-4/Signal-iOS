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
| SMS registration, push, contact discovery, remote storage, websockets, CDN, calls, payments, stories, usernames, badges, donations, crash reporting, log upload | not part of the built app | The shipped app is `MeshApp`, which contains none of these and links no network layer; the upstream sources remain in the tree, unbuilt, under AGPL-3.0 |

## Deviation to be aware of

The upstream Signal UI and message pipeline (about 2,350 Swift files tightly coupled to the Signal servers) were not rewired.
The shipped app is a new SwiftUI app on the `MeshCore` package. Its message encryption is X25519 + ChaCha20-Poly1305 with an
ephemeral key per message (CryptoKit), not libsignal sessions: no forward secrecy through a ratchet. Replacing
`EphemeralSessionCrypto` with a libsignal-backed `SessionCrypto` is possible behind the existing protocol.
