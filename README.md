# Just Did It

> Consistency is showing up — not keeping a streak alive.

A small iOS habit app I built for myself. Local-only, no accounts, no cloud, no dependencies. SwiftUI + SwiftData.

## Why I built it

Every habit tracker I tried punished me. Miss a day, the streak resets to zero, and the app makes sure I feel it. That guilt loop made me quit the tracker, not the habit.

So I flipped the rule: **reward showing up, never punish variance.** Some days I open the app and genuinely have nothing to log — a rest day. That still counts. In this app, opening it *is* showing up, and misses are just blank cells in a grid, not a zeroed counter.

The other itch was tactility. Tapping a checkbox feels like filing paperwork. I wanted checking off a habit to feel like pressing a real key — so the buttons are drawn as physical push-keys with actual pressed depth and a haptic click.

## How it works

- **Push-key checkoffs** — monochrome hardware-style keys; pressed state inverts with real depth. Black/white parity in dark mode.
- **"Shown up N days" instead of a streak** — opening the app records a `Visit`. History leads with a cumulative count that never resets, plus "M of the last 30".
- **Three-level history grid** — blank (didn't open), faint (opened, logged nothing), solid (opened + logged). Gaps are visible without being shamed.
- **A reminder that learns my schedule** — I didn't want to pick a notification time, so it computes the median of my last 21 app opens, minus 15 minutes (defaults to 20:00 until it has 3 samples). Fully local `UNUserNotificationCenter`, schedules 7 days ahead, skips days I've already shown up. Toggle in the Edit list.
- **Groups as inline dropdowns** — related actions fold into one row. I tried sub-pages first; the extra navigation was enough friction to stop me logging.
- **Date rollover** — the list kept hanging on yesterday when the app stayed open overnight, so today recomputes at midnight and on every foreground.
- **Data stays on the phone** — SwiftData/SQLite in the app sandbox. It rides along in the normal iPhone backup. Nothing leaves the device.

## Stack

SwiftUI + SwiftData, zero dependencies. iOS 18+, Xcode 16.

## Building it onto your phone

Not on the App Store — I sideload it onto my own phone, and you'd do the same.

**Xcode:** open `JustDidIt.xcodeproj`, set your own team + bundle identifier under *Signing & Capabilities*, build to your device. A free Apple ID works.

**Headless** (what I actually use): once signing is configured, plug in the unlocked phone and

```sh
./deploy.sh
```

builds, installs, and launches without opening Xcode.

With a free (non-paid) Apple ID the signature expires after 7 days — re-running `./deploy.sh` renews it, data persists.

## License

[GPL-3.0](LICENSE).
