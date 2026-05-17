# nothinghere

`nothinghere` is an owner-enrolled Android administration deck.

The project has two real parts.

A is the Mac or laptop controller. In v1 it is a fast terminal launcher, not Tauri. It checks status, sends approved requests over the private mesh, opens `scrcpy` as a native window for screen relay, and opens the default browser only for stream fallback.

B is the phone engine. On the enrolled phone, the engine is the Magisk module plus the Termux runtime working as one backend layer. The module anchors startup and service supervision. Termux provides the live userland services and tools.

The first supported profile is Nothing Phone 3a Pro. The repo is not Nothing-only. The target shape is Android administration with a clean profile system.

Read `DOCTRINE.md` before building or patching anything. That file is the living architecture note. If reality proves it wrong, update it instead of building around stale words.

Current v1 direction:

- no Tauri yet
- no localhost dashboard for v1
- no hardcoded IPs
- no always-on relay/debug path by default
- private network identity first
- SSH as the normal control channel
- scrcpy as the native visual relay
- browser fallback only when useful
- phone engine equals module plus Termux runtime

Working rule: read the existing variables and paths before changing anything. Do not duplicate config because you did not inspect the current strings. Keep wrappers thin and the engine clear.
