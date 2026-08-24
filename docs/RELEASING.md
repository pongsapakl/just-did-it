# Releasing

`./deploy.sh` installs the app straight onto a plugged-in iPhone and is all you
need for day-to-day use. This document covers the other path: uploading a build
to App Store Connect so it can be installed through **TestFlight**, over the air,
with no cable.

TestFlight needs a paid **Apple Developer Program** membership. Whoever holds that
membership runs the steps below on their own Mac; nothing here is specific to any
one account.

## One-time setup

1. **Register the bundle identifier** — Certificates, Identifiers & Profiles →
   Identifiers → new App ID for `com.pongsapakl.justdidit`. (Bundle IDs are global,
   so if it is taken, pick another and update `PRODUCT_BUNDLE_IDENTIFIER` in the
   project. Changing it later means the app installs fresh, with no history.)
2. **Create the app record** in App Store Connect → Apps → new iOS app, pointing at
   that bundle ID. The name there must be unique across the App Store; it has no
   effect on the name shown on the home screen, so any free name will do.
3. **Create an App Store Connect API key** — Users and Access → Integrations →
   App Store Connect API → generate a key with the *App Manager* role. Download the
   `AuthKey_XXXXXXXXXX.p8` **once** (Apple will not offer it again) and put it in
   `~/.appstoreconnect/private_keys/`. Note the Key ID and the Issuer ID.

   The `.p8` is a credential. It stays on that machine and never enters this repo.

## Every release

```sh
DEVELOPMENT_TEAM=ABCDE12345 \
ASC_KEY_ID=XXXXXXXXXX \
ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000 \
./release.sh
```

The Team ID is the 10-character string in the Apple Developer account's Membership
details. The script archives in Release, exports a signed `.ipa`, and uploads it.
Build numbers are generated from the current timestamp, so there is nothing to bump
by hand between uploads.

Leave `ASC_KEY_ID`/`ASC_ISSUER_ID` unset and the script stops after producing the
`.ipa`, which can then be uploaded with Apple's free
[Transporter](https://apps.apple.com/app/transporter/id1450874784) app instead.

Apple takes roughly 5–30 minutes to process a build before it shows up in TestFlight.

## Handing the build to a tester

Internal testing needs no App Review and is available as soon as processing ends.

1. App Store Connect → Users and Access → invite the tester's Apple ID with the
   *Developer* or *Marketing* role.
2. TestFlight tab → Internal Testing → create a group → add them → assign the build.
3. They install [TestFlight](https://apps.apple.com/app/testflight/id899247664) on
   their iPhone and accept the emailed invitation.

Up to 100 internal testers are allowed, 30 devices each.

## The 90-day clock

**A TestFlight build stops launching 90 days after it is uploaded.** Keeping the app
usable means running `./release.sh` again roughly every three months. Nothing else
changes — testers get the new build automatically through TestFlight.
