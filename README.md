# Just Did It

A tiny, local-only iOS habit app with one job: let you press a satisfying button when you did the thing.

No streaks to lose. No accounts. No cloud. No guilt mechanics. Opening the app counts as showing up — the whole design is built around being non-punishing.

## Why

Most habit trackers punish you: break a streak and the app makes you feel like you failed. This one flips it. Every action is a chunky physical push-key that toggles in with a click. History is a quiet dot grid, not a scoreboard. If all you did today was open the app, that counts as showing up — and the app tells you how many days you've shown up, not how many you've missed.

I built it for myself. It's shared here in case the idea is useful to you.

## Features

- **Push-key checkoffs** — monochrome, tactile buttons with real pressed depth; black/white parity in dark mode
- **Groups as inline dropdowns** — related actions fold into a row, no sub-page navigation
- **GitHub-style history grid** — a 3-level intensity grid of your activity, plus "shown up N days"
- **A reminder that learns you** — one daily notification, timed from when you usually open the app (median of your recent opens, minus 15 minutes); it skips days you've already shown up, and you can turn it off
- **Date rollover** — today's list resets at midnight or when the app returns to foreground, no stale checkmarks
- **Local-only data** — SwiftData/SQLite in the app sandbox; it rides along in your normal iPhone backup; nothing ever leaves the device
- **Light & dark app icons**

## Stack

SwiftUI + SwiftData. No dependencies. iOS 18+, Xcode 16.

## Install

This isn't on the App Store — you build it onto your own phone.

### With Xcode

1. Clone, open `JustDidIt.xcodeproj`
2. In *Signing & Capabilities*, select your own team (a free Apple ID works) and change the bundle identifier to something of yours
3. Plug in your iPhone, build & run

### Headless (no Xcode UI)

After signing is configured once, plug in your unlocked iPhone and:

```sh
./deploy.sh
```

It builds, installs, and launches the app on the connected device.

> **Free Apple ID note:** apps signed with a free (non-paid) developer account expire after 7 days. Just re-run `./deploy.sh` — your data persists.

## License

[GPL-3.0](LICENSE). Use it, change it, share it — if you distribute a modified version, it has to stay open source.
