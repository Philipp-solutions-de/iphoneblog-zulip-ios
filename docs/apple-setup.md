# Apple setup: the Zulip app's part

The checklist for both apps is one page, in the Matrix app's repository:
[iphoneblog-matrix-ios/docs/apple-setup.md](https://github.com/Philipp-solutions-de/iphoneblog-matrix-ios/blob/main/docs/apple-setup.md).
Follow it once; where it does something for the Matrix app, do the same here with the values
below. Account-wide steps (API access, the API key, the APNs key, inviting Alex and Philip)
happen once and serve both apps.

## Values for this app

| | |
|---|---|
| Bundle id (app) | `de.iphoneblog.zulip.preview`: Push Notifications, App Groups |
| Bundle id (notification extension) | `de.iphoneblog.zulip.preview.NotificationService`: App Groups |
| App group | `group.de.iphoneblog.zulip.preview` |
| App record name | `iphoneblog Zulip Preview` (set by `Apple setup`; name under the icon: `iphoneblog Zulip`) |
| SKU | `iphoneblog-zulip-preview` |
| APNs topic | `de.iphoneblog.zulip.preview`, sent to the Zulip server as the app id |
| Repository | `Philipp-solutions-de/iphoneblog-zulip-ios` |

These are interim, under Thorsten's personal team. At launch the same steps run under
Alex's company account with `de.iphoneblog.zulip` (change `BUNDLE_ID` and `APP_GROUP` in
`config/app.env`); the testers install the new app once.

## Secrets and variables

The same names as the Matrix app. The secrets go into this repository's environment
`apple`, which only `main` may use; the team id and the switch are repository variables.

```bash
gh variable set APPLE_TEAM_ID --repo Philipp-solutions-de/iphoneblog-zulip-ios
```

```bash
gh secret set ASC_KEY_ID --env apple --repo Philipp-solutions-de/iphoneblog-zulip-ios
```

```bash
gh secret set ASC_ISSUER_ID --env apple --repo Philipp-solutions-de/iphoneblog-zulip-ios
```

```bash
base64 -i ~/Downloads/AuthKey_KEYID.p8 | gh secret set ASC_KEY_P8_BASE64 --env apple --repo Philipp-solutions-de/iphoneblog-zulip-ios
```

The team's one Apple Distribution certificate, the same `.p12` and password as for the
Matrix app (the combined page says how it is made):

```bash
base64 -i ~/Downloads/distribution.p12 | gh secret set DIST_CERT_P12_BASE64 --env apple --repo Philipp-solutions-de/iphoneblog-zulip-ios
```

```bash
gh secret set DIST_CERT_PASSWORD --env apple --repo Philipp-solutions-de/iphoneblog-zulip-ios
```

`gh` asks for the team id, key id, issuer id and certificate password at a hidden prompt;
the files are read directly. No value goes into a chat or a log.

## Register the bundle ids

After the app group exists (registered by hand, as on the combined page):

```bash
gh workflow run apple-setup.yml --repo Philipp-solutions-de/iphoneblog-zulip-ios
```

It registers both bundle ids and switches their capabilities on through the API key. Running
it again changes nothing. Then tie `group.de.iphoneblog.zulip.preview` to both ids by hand,
as the combined page describes.

## Push for the Zulip server

The APNs key is the one Team Scoped key from the combined page; the Zulip server uses it
with the topic above. The combined page's command block writes the same `.p8` into infra's
secrets twice: `zulip_apns_key`, `zulip_apns_key_id`, `zulip_apns_team_id` for the Zulip
server, and the `sygnal_apns_*` names for Matrix.

## Signing check

Builds the pinned release, signs it with the distribution certificate and App Store
profiles (fetched or created through the API key), exports the `.ipa`, uploads nothing.
It must be green before TestFlight goes on.

```bash
gh workflow run signing-check.yml --repo Philipp-solutions-de/iphoneblog-zulip-ios
```

## Switch TestFlight on

```bash
gh variable set TESTFLIGHT_ENABLED --repo Philipp-solutions-de/iphoneblog-zulip-ios --body true
```

From then on every push to `main` builds the pinned zulip-flutter release and uploads it.
Newer upstream releases arrive as pull requests from the weekly `upstream-bump` workflow,
built without secrets; they reach TestFlight once merged. Add the internal
tester group on the app record as the combined page describes.
