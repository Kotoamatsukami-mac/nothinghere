# controller

Compact Nothing 3a Pro controller that launches two separate windows: a small Chrome app for the SSH utility panel and a normal scrcpy window for the phone screen.

## Behaviour

Running `python3 controller` starts the local web server on `http://localhost:7779`, opens Chrome in app mode, launches scrcpy separately, and auto-connects the SSH terminal.

## UI

The web UI is a dark 400px-wide floating panel with a single top bar, live SSH status dot, `▶ screen` button, `⊡ shot` button, and a minimal terminal prompt that shows `hi phone ❯`.

## Alias

Use this in `~/.zshrc`:

```zsh
alias hi\ phone='cd /Users/Aboogie/Desktop/nothinghere && python3 controller'
```
