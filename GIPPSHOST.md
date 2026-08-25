# GippsHost Phone for iOS

GippsHost Phone is the GippsHost-owned iOS softphone based on Linphone. It is distributed under GPLv3; upstream copyright and licence notices remain intact.

## Security policy

- Bundle identifier: `au.com.gippshost.phone`
- Provisioning deep link: `gippshost-phone:`
- Provisioning may only be fetched over HTTPS from `nexus.gippshost.com.au` or `nexus-dev.gippshost.com.au`.
- SIP accounts are restricted to `voice.gippshost.com.au` and genuine subdomains of `.voice.gippshost.com.au`.
- Chat and meeting features are disabled; the product is focused on calling and native contacts.
- Provisioning URLs and their one-time tokens must never be written to logs.

The client-side allowlist is defence in depth. Apex/Nexus and the push gateway must independently authenticate customers, validate active services, enforce the same SIP-domain allowlist, and support device revocation.

## Local simulator build

```sh
xcodebuild \
  -project LinphoneApp.xcodeproj \
  -scheme Linphone \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## TestFlight prerequisite

Sign Xcode into the GippsHost Apple Developer organisation, select that team for every target, create the GippsHost-owned App ID/app group/push entitlement, and replace all upstream service configuration with GippsHost-owned credentials before archiving.
