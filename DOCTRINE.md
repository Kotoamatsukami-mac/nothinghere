# nothinghere — Doctrine

`nothinghere` is an owner-enrolled Android control deck. It is designed for devices the operator owns, has configured, and is allowed to administer.

The project is not a camera script, not a Nothing-only toy, not a GUI experiment, and not a pile of prototype Termux tricks. It is a clean split between a controller and a phone engine. The controller decides. The phone engine stays reachable, reports state, and performs approved local actions on the enrolled phone.

This doctrine should evolve as the build proves what is true. Update it whenever the architecture changes. Do not preserve old wording because it sounded good yesterday. Truth beats decoration.

## The shape

There are two real parts.

A is the Mac or laptop controller. For v1, this is a fast terminal launcher/menu, not Tauri. The menu checks status, sends approved requests, opens native relay windows, launches browser fallback when needed, and stays out of the way. It does not become the brain. It calls the controller engine.

B is the phone engine. On the controlled phone, the engine is the Magisk module plus the Termux runtime working as one backend layer. Magisk provides privileged startup, service supervision, and the stable backend container. Termux provides the live userland tools: `sshd`, wake-lock helpers, shell scripts, dependencies, status checks, and the local execution surface. Do not argue Magisk-first versus Termux-first on the controlled phone. Together they are the phone engine.

The first supported phone profile is the Nothing Phone 3a Pro. That does not mean the repo is Nothing-only. The long-term shape is rooted Android with profile zero proven on the Nothing device.

Samsung/S25 controller support is parked for now. Its future shape is simple: Termux text menu, SSH requests, browser stream fallback, no heavy GUI. Do not let that distract from v1.

## The authority chain

The controller should think in this order:

`controller menu -> controller engine -> Tailscale identity -> SSH channel -> phone engine -> approved local action`

Visual relay is the exception path:

`controller menu -> temporary debug bridge path over Tailscale -> scrcpy native window -> close relay path when finished`

SSH over Tailscale is the normal command channel. The debug bridge is not the normal door. It exists for scrcpy/screen relay and deliberate maintenance, then it closes again. Always-on wireless debugging at boot is prototype contamination unless a future explicit profile says otherwise.

The Mac should not host a fake app just to look serious. For v1, a terminal launcher is enough. When the operator asks for screen relay, spawn `scrcpy` in its own native window. When the operator asks for web stream fallback, open the default browser. Let macOS do what it is already good at.

Tauri is not banned. Tauri is v2 material only if the terminal controller proves the control model and a real cockpit becomes worth the weight. If Tauri ever returns, it must remain a shell over the same engine, not a second implementation of the engine.

## Armed mode

Armed mode is not vibes. It is the phone engine intentionally ready to accept requests from approved controllers.

A useful state model is:

`disarmed` means the phone is not controller-ready.

`armed` means Tailscale is up, SSH is reachable, the phone engine answers status, and approved requests can run.

`relay-active` means a visual relay path has been temporarily opened for scrcpy or stream viewing.

`degraded` means the phone is reachable but one expected service is weak or missing.

`rescue` means the normal path failed and the operator is deliberately entering a manual recovery path.

Do not build a soft toggle that can strand the operator without a recovery path. Stopping the transport or shell service is not the same as stopping a minor helper. The phone engine needs state-aware start, stop, restart, and status behaviour before any pretty menu tries to control it.

## Command scope

The phone engine should expose a narrow owner-useful surface first. Start with real actions and expand only when the need is proven.

The first surface should cover status, wake/sleep, service restart, visual relay preparation, diagnostics, and cleanup. Status means battery, thermal state, privileged state, Tailscale state, SSH state, wake lock, storage, and relay state. Wake/sleep means acquire or release wake lock and wake the screen when deliberately requested. Visual relay means prepare the temporary relay path, let the controller launch the viewer, then close the relay path when finished. Diagnostics means useful snapshots, not endless noise.

A broad manual shell is not the default product. It can exist as a deliberate owner recovery path, clearly separated from normal menu actions.

## Identity and configuration

Do not build around IP addresses. Tailscale hostnames and profile names are the stable layer. IP addresses are plumbing and should not leak into operator-facing config.

Private values stay private: Tailscale IPs, Wi-Fi IPs, SSH keys, host keys, device serials, local usernames, local paths, tokens, PINs, and personal hostnames when they are not meant to be shared.

Reusable values belong in profiles: device family, Android version floor, camera package hints, relay capability, input-node hints, service requirements, package dependencies, and capability flags.

The Nothing profile is profile zero because it is the device being proven first. It is not a licence to hardcode Nothing assumptions into the core.

## What the prototype taught us

The ZIP was useful because it exposed working scraps and bad habits at the same time. Treat it as evidence, not scripture.

Keep the ideas that are structurally sound: wakeup polling, PID discipline, service supervision patterns, identity-based peer discovery, SSH control, Tailscale transport, and scrcpy as an external native relay surface.

Bin or quarantine the prototype habits: hardcoded IPs, hardcoded Termux UID, plaintext PINs, fixed input nodes, fixed Nothing activities, backup copies as real source, old roomcam identity, localhost dashboards for no reason, always-on wireless debugging at boot, and duplicate logic across wrappers.

## Working rule for agents

Read before patching. Do not create duplicate variables because you did not search the existing strings. Do not promote a wrapper into the brain because it is the most visible file. Do not flatten the system into a shopping list. Follow the architecture in the subtext: controller decides, phone engine performs, transport stays private, relay wakes only when needed, config stays profile-aware.

When reality contradicts this doctrine, update the doctrine and explain why. The project should get sharper as it is built, not more cluttered.
