# Android setup

This project only needs a simple Android connection side.

Install Termux on the phone, install `openssh`, make sure Tailscale is logged in, and use `termux-wake-lock` when you want the phone to stay awake and reachable. Then start `sshd` so the laptop controller can connect over the Tailscale address.

A simple baseline flow in Termux is:

```sh
pkg update -y && pkg upgrade -y
pkg install -y openssh
tailscale up
termux-wake-lock
sshd
```

The goal is not to make the phone side clever. The goal is to keep the Android side reachable, awake when needed, and available to the laptop-side controller in this repo.

If the phone gets reset, repeat the same small setup: Termux, Tailscale, `openssh`, `termux-wake-lock`, and `sshd`. Keep it boring.
