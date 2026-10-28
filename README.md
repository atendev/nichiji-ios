# Nichiji

Native SwiftUI app for iOS 27.0 and later. Duo-specific APIs need the iOS 27.1 SDK and go behind `#available(iOS 27.1, *)`.

The Xcode project is generated from `project.yml` with XcodeGen and is not committed. CI on a GitHub macOS runner generates, lints, builds and tests it, so no local Mac is needed.

## Commands (on a Mac)

```
make generate   # create Nichiji.xcodeproj
make build
make test
make lint
make ipa        # unsigned Nichiji.ipa for device builds
```

## Testing on a device

Every push to `main` that passes CI uploads an unsigned `Nichiji.ipa` as the `Nichiji-unsigned-ipa` artifact. Download it, then sign and install it with a free Apple ID using a sideloading tool. Free-account installs expire after 7 days.

## Not set up yet

- Apple team ID (`DEVELOPMENT_TEAM` in `project.yml` is blank)
- Code signing and TestFlight
