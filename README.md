# Nichiji

Native SwiftUI app for iOS 27.0 and later. Duo-specific APIs need the iOS 27.1 SDK and go behind `#available(iOS 27.1, *)`.

The Xcode project is generated from `project.yml` with XcodeGen and is not committed. CI on a GitHub macOS runner generates, lints, builds and tests it, so no local Mac is needed.

## Commands (on a Mac)

```
make generate   # create Nichiji.xcodeproj
make build
make test
make lint
make testflight # signed Internal build, uploaded to TestFlight (needs the App Store Connect key)
```

## Testing on a device

Every passing CI run, started manually from the Actions tab or with `gh workflow run ci.yml --ref <branch>`, signs an Internal build and uploads it to TestFlight. Internal is a Release build with the dev unlock, and it is for internal testers only. Install it from the TestFlight app once Apple finishes processing, usually 10 to 30 minutes.

CI signs manually with the Apple Distribution certificate in the `DIST_CERT_P12` and `DIST_CERT_PASSWORD` secrets and the `Nichiji App Store` and `Nichiji Widget App Store` profiles in `PROFILE_APP` and `PROFILE_WIDGET`. It talks to App Store Connect with the `ASC_KEY_P8`, `ASC_KEY_ID` and `ASC_ISSUER_ID` API key secrets. The certificate and profiles expire after a year: run `tools/signing/testflight-wizard.sh` to make new ones.

