# controller

Mac → Nothing 3a Pro remote control. That's it.

## what it does
- left panel: live screen via scrcpy (ADB over Tailscale)
- right panel: SSH terminal into phone
- `hi phone` alias → drops you straight into a phone shell

## requirements
```
brew install scrcpy
pip3 install websockets
```
Phone needs: Termux + sshd running (handled by nn_core Magisk module).

## run
```bash
./controller
```
Opens http://localhost:7779 automatically.

## alias
Add to `~/.zshrc`:
```zsh
alias 'hi phone'="ssh -i ~/.ssh/nhere_ed25519 -o StrictHostKeyChecking=accept-new -p 8022 u0_a296@100.99.93.102"
```
