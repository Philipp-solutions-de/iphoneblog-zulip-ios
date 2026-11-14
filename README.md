# iphoneblog Z

The iPhone app for the iphoneblog.de chat on Zulip. It is
[zulip-flutter](https://github.com/zulip/zulip-flutter), the official Zulip app, with a
small set of changes kept apart from upstream. It talks to one server,
`https://zulip.iphoneblog.de`, and signs people in through their iphoneblog.de account.

This app is not made or endorsed by Kandra Labs, the company behind Zulip. It carries no
Zulip logo or app icon.

"iphoneblog Z" is the name during the chat trial, beside the Matrix app. The final name
follows the choice.

## How a new upstream release becomes an app

1. Every Monday the workflow `build` asks GitHub for the newest zulip-flutter release.
2. `scripts/fetch-upstream.sh` clones that tag and the Flutter commit named in its
   `pubspec.yaml`, the one upstream tested with.
3. `scripts/prepare.sh` copies `overlay/` in, applies `patches/`, and rewrites names, ids,
   icon and colour from `config/app.env`. Every step checks that it found what it changes.
4. The workflow builds for a device (unsigned) and for the simulator, checks that no
   Firebase or Google code shipped, launches the app in the simulator and keeps a
   screenshot with the run.
5. A red run opens an issue labelled `build-failure`, or comments on the open one.

Nobody edits upstream code by hand. A release that breaks a patch fails the build, and the
fix is a change to a patch in this repository.

Run the same on a Mac:

```bash
eval "$(scripts/fetch-upstream.sh upstream)"
git clone https://github.com/flutter/flutter.git ~/flutter-zulip && git -C ~/flutter-zulip checkout "$FLUTTER_SHA"
export PATH=~/flutter-zulip/bin:$PATH
scripts/prepare.sh upstream
(cd upstream && flutter build ios --simulator --debug)
scripts/simulator-smoke.sh upstream/build/ios/iphonesimulator/Runner.app screenshot.png
```

It needs Xcode and CocoaPods.

## What is changed

| Where | What | Why |
|---|---|---|
| `config/app.env` | name, bundle id, team id, app group, server, blog colour | the one place to change for Alex's account |
| `brand/icon-1024.png` | the blog's touch icon with a "Z" badge, on white | no Zulip marks; tells it apart from the Matrix app |
| `patches/0001-brand-colour.patch` | the app's seed colour becomes the blog's teal `#149791` | blog colours |
| `patches/0002-start-on-sign-in.patch` | with no account, the app opens on sign-in, not the account list | one less screen |
| `patches/0003-preset-server-and-sign-in-sheet.patch` | the server is preset and the URL field hidden; on iOS, web sign-in runs in an `ASWebAuthenticationSession` | sign-in goes straight to the iphoneblog.de button; see "Sign-in" |
| `overlay/packages/iphoneblog_native` | a small Swift plugin: notification permission, APNs token, sign-in sheet | talks to Apple only |
| `overlay/packages/firebase_core`, `firebase_messaging` | stand-ins with the same Dart names, no Firebase code | upstream's Dart compiles unchanged, and no Google service sees an install |
| `scripts/prepare.sh` | bundle id, team, app group, display name, permission texts, removes the `zulip://` URL scheme, icon, launch colour | plain rewrites need no patch |

### Push notifications without Google

Upstream uses Google's `firebase_messaging` on iOS only to ask for permission and to read
the APNs token. `pubspec.yaml` overrides both Firebase packages with the stand-ins in
`overlay/packages`. They keep the names upstream imports and fetch the token from iOS
through `iphoneblog_native`. Nothing contacts Google. The server sends to Apple directly
(`APNS_TOKEN_KEY_FILE`, `APNS_TEAM_ID`, `APNS_SANDBOX=False`).
`scripts/check-no-google.sh` fails the build if Firebase or Google code reaches the app.

When upstream drops Firebase on iOS (their issue #2257), the stand-ins go.

### Sign-in

The Zulip server ends a web sign-in with a redirect to `zulip://login?…`; the scheme is
hard-coded in `zerver/views/auth.py` (`create_response_for_otp_flow`). The app opens the
sign-in page in an `ASWebAuthenticationSession`, which hands that redirect back to the app
that opened it. The app registers no URL scheme with iOS, so neither the official Zulip app
nor any other app can receive the redirect. The API key in it is also encrypted with a
one-time pad that only this app holds.

The server needs no change for this. If the server should one day send another scheme,
change `AUTH_CALLBACK_SCHEME` in `config/app.env`.

The session keeps Safari's cookies, so a second sign-in through iphoneblog.de is one tap.

## TestFlight

Off until Alex's company developer account exists. Then:

1. In `config/app.env`, set `TEAM_ID` to the account's team id, and `BUNDLE_ID` and
   `APP_GROUP` if the final names differ.
2. In App Store Connect: create the app record for `BUNDLE_ID`, register the app group,
   and create an API key with the role App Manager.
3. In this repository's settings: secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (the
   text of the `.p8` file), and the variable `TESTFLIGHT_ENABLED` = `true`.
4. For server push: an APNs key (`.p8`) from the same account goes to the Zulip server.

The `testflight` job then signs with Xcode's cloud-managed signing and uploads every weekly
build. `fastlane/Fastfile` holds the lane.

## When the weekly build fails

Read the run's log. The usual causes:

- A patch no longer applies: rebase it on the new tag (`git apply --3way`), commit the new
  patch.
- `prepare.sh` reports "expected 1 match": upstream moved a line it rewrites. Adjust the
  script.
- A Dart error naming a Firebase class: upstream uses a Firebase name the stand-in lacks.
  Add it to `overlay/packages/firebase_*`.
- Upstream raised its Xcode version: change `runs-on` in the workflow.

## License

Apache License 2.0, like zulip-flutter. See `LICENSE` and `NOTICE`.
