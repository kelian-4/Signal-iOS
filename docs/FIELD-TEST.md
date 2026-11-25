# Hardware test table (to be filled in on devices)

| Test | Expected | Result |
|---|---|---|
| Discovery between two phones | peers visible in Réglages within 10 s | |
| Message latency (foreground) | under 5 s | |
| Background (screen locked, app in background) | message received, local notification | |
| App swiped away | message received after state restoration, or after next launch | |
| Overnight | links and queue still healthy, see journal | |
| Battery over 8 h | measured % | |
| 2-hop relay (A to C through B) | delivered, hop ACKs in journal | |
| Key change alert | badge removed, red banner | |
| Restore from 24 words + backup | same identity, history kept, sessions renegotiated | |

The journal (Réglages, Partager le journal) records thermal state, battery, main-thread stalls, disconnect codes and RSSI.
