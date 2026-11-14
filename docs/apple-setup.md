# Apple setup: what Thorsten clicks

While Thorsten, Alex and Philip verify the app, it builds under Thorsten's own Apple
developer account (individual membership) with the interim bundle id
`de.iphoneblog.zulip.preview`. Until the steps below are done, the weekly build stays a
simulator build and nothing reaches TestFlight.

This page is the whole list, in order. Steps 1 to 3 and 6 also serve the Matrix app
(`Philipp-solutions-de/iphoneblog-matrix-ios`): it uses the same API key, the same APNs key
and the same secret names. Lines marked **(unverified)** were not confirmed in Apple's
documentation on 2026-11-14; the first real run settles them.

No key value goes into a chat, a commit or a log. The commands below read files or ask for
the value without echoing it.

## 1. Accept the current agreement

App Store Connect (appstoreconnect.apple.com) → **Business**. If a new Program License
Agreement waits there, accept it. Apple will not create an app record before that.

## 2. Team id → repository variable

developer.apple.com/account → **Membership details** → **Team ID** (10 characters). The team
id is not a secret.

```bash
gh variable set APPLE_TEAM_ID -R Philipp-solutions-de/iphoneblog-zulip-ios
```

`gh` asks for the value. The Matrix app keeps its team id in its own `brand.env` instead.

## 3. App Store Connect API key → three repository secrets

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**
   → **Team Keys** **(unverified menu path)**. The first time, Apple asks you to request
   access; accept.
2. **+** (Generate API Key). Name: `GitHub builds`. Access: **Admin**.
   Admin, because it is the role Apple documents with access to Certificates, Identifiers &
   Profiles, which Xcode needs to register ids, profiles and the distribution certificate.
   App Manager with that access may suffice **(unverified)**.
3. Download the `.p8` file. Apple offers the download once. Note the **Key ID** (in the
   key's row) and the **Issuer ID** (above the table).
4. Set the secrets in both app repositories. Replace the file name with yours; `gh` asks
   for the key id and issuer id without showing them:

```bash
P8=~/Downloads/AuthKey_XXXXXXXXXX.p8
for r in Philipp-solutions-de/iphoneblog-zulip-ios Philipp-solutions-de/iphoneblog-matrix-ios; do
  gh secret set ASC_KEY_ID -R "$r"
  gh secret set ASC_ISSUER_ID -R "$r"
  base64 -i "$P8" | gh secret set ASC_KEY_P8_BASE64 -R "$r"
done
```

Then store the `.p8` in your password manager and delete the download.

## 4. Register the bundle ids (a workflow does it)

```bash
gh workflow run apple-ids -R Philipp-solutions-de/iphoneblog-zulip-ios
```

It registers `de.iphoneblog.zulip.preview` and `de.iphoneblog.zulip.preview.NotificationService`
and turns on Push Notifications and App Groups, through the API key. It is safe to run
again. Check it went green on the repository's Actions page. Xcode registers the app group
`group.de.iphoneblog.zulip.preview` and the profiles itself on the first TestFlight build
**(unverified that automatic signing registers the app group)**.

## 5. App record

App Store Connect → **Apps** → **+** → **New App**:

| field | value |
|---|---|
| Platforms | iOS |
| Name | `iphoneblog Z` (if Apple says it is taken: `iphoneblog Z Preview`) |
| Primary language | German |
| Bundle ID | `de.iphoneblog.zulip.preview` (it appears after step 4) |
| SKU | `iphoneblog-zulip-preview` |
| User Access | Full Access |

**Create**. Nothing else on the app's pages needs filling for internal TestFlight.

## 6. APNs key (one key for both apps)

1. developer.apple.com/account → **Certificates, IDs & Profiles** → **Keys** → **+**.
2. Name: `iphoneblog push`. Tick **Apple Push Notifications service (APNs)** →
   **Configure**: environment **Sandbox & Production** **(unverified wording; pick the
   option that includes Production, which TestFlight builds use)**; key type **Team
   Scoped**, so the one key serves every app of the team. **Save** → **Continue** →
   **Register**.
3. Download the `.p8` (once) and note its **Key ID**.

Apple: "You can use one APNs signing key to authenticate tokens for multiple apps." The
Zulip app (topic `de.iphoneblog.zulip.preview`) and the Matrix app use the same key.

The key goes to the servers, not to GitHub. In an infra worktree run
`sops edit inventory/group_vars/all/secrets.sops.yml` and add the file's content and ids
under these names (the server sessions read them):

| Zulip server | Matrix server (Sygnal) | value |
|---|---|---|
| `zulip_apns_key` | `matrix_apns_key` | content of the `.p8` file |
| `zulip_apns_key_id` | `matrix_apns_key_id` | the key's Key ID |
| `zulip_apns_team_id` | `matrix_apple_team_id` | the team id from step 2 |

## 7. Switch TestFlight on

```bash
gh variable set TESTFLIGHT_ENABLED --body true -R Philipp-solutions-de/iphoneblog-zulip-ios
```

```bash
gh workflow run build -R Philipp-solutions-de/iphoneblog-zulip-ios
```

From then on every build on `main` and every weekly build goes to TestFlight. Apple takes
some minutes to process a build before it appears. The app's `Info.plist` declares no
non-exempt encryption (`ITSAppUsesNonExemptEncryption` = false), which should spare the
export-compliance question **(unverified for TestFlight)**.

## 8. Alex and Philip as internal testers

1. App Store Connect → **Users and Access** → **+**: Alex's and Philip's Apple Account
   e-mail addresses, role **Developer**, access to the app. They accept the e-mail
   invitation. On an individual membership they get App Store Connect access only, not your
   developer team (Apple's roles page). Whether a smaller role than Developer can test is
   **(unverified)**.
2. **Apps** → `iphoneblog Z` → **TestFlight** → **Internal Testing** → **+**: group
   `Verifier`, with automatic distribution on. Add yourself, Alex and Philip
   (**Invite Testers**, tick, **Add**). Up to 100 internal testers per group.
3. Each tester installs Apple's **TestFlight** app and accepts the invitation in it.

Internal builds need no Beta App Review **(not re-read in Apple's docs today)**.

## At launch, under Alex's company account

Repeat steps 2 to 8 there with the final bundle id `de.iphoneblog.zulip` (change
`BUNDLE_ID` and `APP_GROUP` in `config/app.env`). An app that was never released cannot be
transferred between accounts, so the testers install the new app once.
