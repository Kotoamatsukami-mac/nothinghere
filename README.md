# nothinghere

`nothinghere` is a simple Android-to-laptop controller setup.

The project is not meant to be a giant platform. The real goal is simple: keep a rooted Android phone reachable and easy to control from a laptop with Tailscale, SSH, Termux, and a local web UI. The laptop side runs the controller, the Android side runs the connection pieces, and the repo should stay small and obvious.

## Shape

There are only two practical parts now: the `controller/` folder on the laptop side, and the Android-side setup on the phone. `controller/` contains the localhost web UI and launcher scripts that bring the control surface up, while the phone side is just the minimal connection stack needed to make the device reachable and keep it awake when required.

## Android side

On the Android phone, the setup is intentionally basic: Termux, `termux-wake-lock`, `sshd`, and Tailscale. That is the connection side. The point is not to build a complicated phone framework; the point is to make the phone reachable, stable, and easy to wake into a controllable state from the laptop.

A practical starting flow is: install Termux, install `openssh`, enable Tailscale, run `termux-wake-lock`, start `sshd`, then use the laptop controller to connect. If extra root or Magisk pieces still exist in the repo, treat them as legacy support until the controller is fully cleaned up.

## Controller

The laptop controller lives in `controller/`. This is the main code path for the local web UI on localhost, the helper control script, and the one-command launcher. This is the part that should be refined and wired properly going forward.

## Repo rule

Keep the repo lean. Prefer one controller folder, one main README, and only the minimum extra notes needed to make the Android connection side understandable. If old files or folders stop matching reality, merge or delete them instead of preserving dead architecture.
