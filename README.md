# iphoneblog Zulip

The iPhone app for the iphoneblog.de chat on Zulip. It is
[zulip-flutter](https://github.com/zulip/zulip-flutter), the official Zulip app, with a
small set of changes kept apart from upstream. It talks to one server,
`https://zulip.iphoneblog.de`, and signs people in through their iphoneblog.de account.

This app is not made or endorsed by Kandra Labs, the company behind Zulip. It carries no
Zulip logo or app icon.

"iphoneblog Zulip" is the name while Thorsten, Alex and Philip compare it with the Matrix app.
At launch the server becomes `chat.iphoneblog.de` (`SERVER_URL` in `config/app.env`).

## How a new upstream release becomes an app

The app is always built from the zulip-flutter release pinned in `config/app.env`
(`UPSTREAM_REF` and its commit `UPSTREAM_COMMIT`). Only that pinned code reaches the Apple
key.

1. Every Monday the workflow `upstream-bump` asks GitHub for the newest zulip-flutter
   release. If it is newer than the pinned one, it builds it without any secrets.
2. Green: it pushes a branch `upstream/<tag>` that pins the new release and opens a pull
   request (or, where Actions may not open one, an issue with the link). Someone reads
   upstream's changes and merges.
3. The merge is a push to `main`. The workflow `build` builds the pinned release and, once
   TestFlight is switched on, uploads it.
4. Red: an issue labelled `build-failure` opens, or the open one gets a comment.

Every build runs the same steps (workflow `build-app`):

- `scripts/fetch-upstream.sh` clones the release, checks the pinned commit, and reads the
  Flutter commit named in its `pubspec.yaml`, the one upstream tested with.
- `scripts/install-flutter.sh` installs exactly that Flutter commit.
- `scripts/prepare.sh` copies `overlay/` in, applies `patches/`, and rewrites names, ids,
  icon and colour from `config/app.env`. Every step checks that it found what it changes.
- The build for a device (unsigned) and for the simulator; `scripts/check-no-google.sh`
  fails if Firebase or Google code shipped; `scripts/simulator-smoke.sh` launches the app
  on a freshly erased simulator and keeps a screenshot with the run. The simulator build
  carries `--dart-define=IPHONEBLOG_DENY_PUSH_PROMPT=true`: it acts as if the user declined
  notifications, so no system alert covers the screenshot. Device builds ask as usual.

Nobody edits upstream code by hand. A release that breaks a patch fails the bump build, and
the fix is a change to a patch in this repository, on the bump branch.

### Security

The Apple secrets live in the GitHub environment `apple`, which only `main` may use. Only
the `testflight` job of `build` and the hand-started `Apple setup` bind it, and only for a
push or a manual run on `main`. No workflow uses `pull_request_target`. Third-party actions
are pinned by commit, fastlane and its gems by `fastlane/Gemfile.lock` (`BUNDLE_FROZEN`).
The secret job installs Flutter fresh, not from the shared cache.

Run the same on a Mac:

```bash
eval "$(scripts/fetch-upstream.sh upstream)"
scripts/install-flutter.sh
export PATH=~/flutter/bin:$PATH
scripts/prepare.sh upstream
(cd upstream && flutter build ios --simulator --debug --dart-define=IPHONEBLOG_DENY_PUSH_PROMPT=true)
scripts/simulator-smoke.sh upstream/build/ios/iphonesimulator/Runner.app screenshot.png
```

It needs Xcode and CocoaPods, and installs Flutter into `~/flutter`.

## What is changed

| Where | What | Why |
|---|---|---|
| `config/app.env` | name, bundle id, app group, server, blog colour (team id: variable `APPLE_TEAM_ID`) | the one place to change for Alex's account |
| `brand/icon-1024.png` | the blog's touch icon, on white | no Zulip marks |
| `patches/0001-brand-colour.patch` | the app's seed colour becomes the blog's teal `#149791` | blog colours |
| `patches/0002-start-on-sign-in.patch` | with no account, the app opens on sign-in, not the account list | one less screen |
| `patches/0003-preset-server-and-sign-in-sheet.patch` | the server is preset and the URL field hidden; on iOS, web sign-in runs in an `ASWebAuthenticationSession` | sign-in goes straight to the iphoneblog.de button; see "Sign-in" |
| `patches/0004-legacy-push-registration.patch` | push registers through the legacy path (`add-apns-token`), never the encrypted one | a stock server sends to Apple with our key; see "Push" |
| `overlay/packages/iphoneblog_native` | a small Swift plugin: notification permission, APNs token, sign-in sheet | talks to Apple only |
| `overlay/packages/firebase_core`, `firebase_messaging` | stand-ins with the same Dart names, no Firebase code | upstream's Dart compiles unchanged, and no Google service sees an install |
| `scripts/prepare.sh` | bundle id, team, app group, display name, permission texts, removes the `zulip://` URL scheme, icon, launch colour | plain rewrites need no patch |

### Push notifications: straight from our server to Apple, no Google

Zulip 12 and later offer an encrypted push registration (`POST /mobile_push/register`). It
encrypts the device's token to the public key of a push relay; upstream's app hard-codes
the key of Zulip's own relay, and a server answers that endpoint only through such a relay.
We run no relay. `patches/0004-legacy-push-registration.patch` makes the app always take
the older path, `POST /users/me/apns_device_token`, with the bundle id as app id. The stock
server then sends to Apple itself with Alex's APNs key (`APNS_TOKEN_KEY_FILE`,
`APNS_TOKEN_KEY_ID`, `APNS_TEAM_ID`, `APNS_SANDBOX=False`).

What this costs:
- Notification payloads reach Apple readable (TLS only), not end-to-end encrypted. The
  realm setting `require_e2ee_push_notifications` must stay off.
- **The path has an end date.** Upstream marks it `TODO(server-12)` and deletes it once it
  drops support for Zulip 11, expected around 2027. Then this patch stops applying, the
  weekly build fails, and push needs a relay of our own or Zulip's.

Upstream uses Google's `firebase_messaging` on iOS only to ask for permission and to read
the APNs token. `pubspec.yaml` overrides both Firebase packages with the stand-ins in
`overlay/packages`. They keep the names upstream imports and fetch the token from iOS
through `iphoneblog_native`. Nothing contacts Google.
`scripts/check-no-google.sh` fails the build if Firebase or Google code reaches the app.

A tap on any notification opens the conversation, including the article bot's posts. No
patch changes that.

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

Off until the Apple steps are done. [docs/apple-setup.md](docs/apple-setup.md) has this app's
values and commands; the checklist for both apps lives in the Matrix app's repository.

During verification the app builds under Thorsten's own developer account as
`de.iphoneblog.zulip.preview`. The team id comes from the repository variable
`APPLE_TEAM_ID`; the secrets `ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_P8_BASE64` (the
same names as the Matrix app) live in the GitHub environment `apple`, which only `main` may
use. The workflow `Apple setup` registers the bundle ids. The `testflight` job signs manually with the team's one
Apple Distribution certificate (environment secrets `DIST_CERT_P12_BASE64`,
`DIST_CERT_PASSWORD`, shared with the Matrix app) and App Store profiles fetched through
the API key, then uploads. The hand-started `Signing check` does the same without the
upload. `fastlane/Fastfile` holds the lanes.

## When the weekly build fails

Read the run's log. The usual causes:

- A patch no longer applies: rebase it on the new tag (`git apply --3way`), commit the new
  patch together with the new `UPSTREAM_REF` and `UPSTREAM_COMMIT`.
- `prepare.sh` reports "expected 1 match": upstream moved a line it rewrites. Adjust the
  script.
- A Dart error naming a Firebase class: upstream uses a Firebase name the stand-in lacks.
  Add it to `overlay/packages/firebase_*`.
- Upstream raised its Xcode version: change `runs-on` in the workflow.

## License

Apache License 2.0, like zulip-flutter. See `LICENSE` and `NOTICE`.
