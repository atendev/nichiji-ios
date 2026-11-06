# ML Kit Digital Ink Recognition: what it sends to Google (Find what ML Kit sends to Google)

Researched 2026-11-06. Outcome: [Decide whether handwriting search keeps ML Kit](../closed/068-decide-whether-handwriting-search-keeps-ml-kit.md) dropped ML Kit for v1.0, so the replacement label and copy below are not applied. They stay here in case ML Kit returns. The app pins `MLKitDigitalInkRecognition` 8.0.0 (`Podfile`). All pages below were fetched on 2026-11-06.

## Short answer

- Google documents that handwriting stays on the device. Recognition runs offline once the `ja` model is downloaded.
- Google also documents that every ML Kit iOS SDK sends diagnostics and usage analytics to Google by default. That is data leaving the device to a third party, so "Data Not Collected" is no longer true.
- Google documents no opt-out for iOS. I found none.
- Label: "Data Collected", with Diagnostics (and, as a cautious call, Identifiers), not used for tracking. Answers are below.

## What is sent

Sources:
- Google, "Preparing for Apple's App Store data disclosure requirements" (ML Kit iOS data disclosure): https://developers.google.com/ml-kit/ios-data-disclosure (fetched 2026-11-06)
- Google, Digital Ink Recognition overview: https://developers.google.com/ml-kit/vision/digital-ink-recognition (fetched 2026-11-06)
- Google, Digital Ink Recognition iOS guide: https://developers.google.com/ml-kit/vision/digital-ink-recognition/ios (fetched 2026-11-06)

Google says the SDK collects this in every feature, by default, "for diagnostics and usage analytics":
- Device information: manufacturer, model, OS version and build, available ML hardware accelerators.
- Application information: bundle ID and app versions.
- Per-installation identifiers. Google says these are not intended to uniquely identify a user or a physical device.
- Performance metrics, such as latency.
- API configuration, such as image format and resolution.
- Event types: feature initializations, model downloads, detection, resource releases.
- Error codes for those events.

Feature-specific for Digital Ink Recognition (`MLKitDigitalInkRecognition`): the configured languages, for diagnostics and usage analytics. That is the only item in its row. For Nichiji, that means `ja`.

Google's page covers "only the latest version" of each SDK. It does not say which version number it describes, so I could not confirm it matches 8.0.0 exactly.

### Does ink or the recognition result leave the device?

Google says no. The overview page says "The user's handwriting stays on the device, recognition is performed without any network connection" and "Digital ink recognition works fully offline." The data disclosure page lists no ink, strokes, candidates or recognized text.

Limits on that answer:
- This rests on Google's statements. I did not inspect the SDK's network payloads. The App Privacy Report on the test iPhone shows only domains, not payloads, so it cannot confirm or refute this.
- The ML Kit binary is closed source. I could not read its code from a primary source.

### The network contacts seen on device

- `dl.google.com`: the `ja` model download. The iOS guide says a model must be downloaded before recognition (it describes `ModelManager` download and delete, with cellular and background download options). This is a model fetch, not user data.
- `play.googleapis.com` and `www.googleapis.com`, once each, a minute later. Google's pages do not name these hosts. That these are the usage and diagnostics logging described above is my inference from the data disclosure page and the ticket's observation. Treat the host-to-purpose mapping as unconfirmed.

### Firebase pieces

Google's page also points to Firebase Remote Config and Firebase Installations for "remote configuration diagnostics", but names them only for Translate and Smart Reply, not Digital Ink. Firebase's own page (https://firebase.google.com/docs/ios/app-store-data-collection, fetched 2026-11-06) says Firebase Installations collects only a Firebase user agent (device, OS, bundle ID, platform), "never linked to a user or device identifier". I could not confirm whether the Digital Ink pod pulls these in. `Pods/` is not checked out here, so I did not read the podspec dependencies.

## Can the app turn it off?

No documented way. I found no iOS API, plist key or Podfile option in Google's ML Kit pages for turning off the diagnostics and usage collection. The data disclosure page says the data is collected "by default" and describes no switch.

Not confirmed: I could not read ML Kit's headers or release notes from a primary source, so I cannot rule out an undocumented switch. If one is wanted, the place to ask is the ML Kit issue tracker or Google support. Plan on the label assuming no opt-out.

Removing ML Kit is the only way to get back to "Data Not Collected". The KanjiVG matcher is the fallback recognizer already chosen in [Choose the handwriting recognizer](../closed/060-choose-the-handwriting-recognizer.md).

## What Apple's rules say

Source: Apple, App privacy details on the App Store: https://developer.apple.com/app-store/app-privacy-details/ (fetched 2026-11-06). Also Apple, Manage app privacy (App Store Connect help): https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy (fetched 2026-11-06).

- "Collect" means "transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time."
- "Third-party partners" means "analytics tools, advertising networks, third-party SDKs, or other external vendors whose code you've added to your app." ML Kit is one.
- You "need to identify all of the data you or your third-party partners collect", and "even if you collect the data for reasons other than analytics or advertising, it still needs to be declared."
- Data "processed only on device is not 'collected'". This is why the ink itself is fine. If anything derived from it is sent off device, it counts separately.
- Optional disclosure needs all four criteria, including that the user supplies the data in the app interface each time. SDK background logging does not meet that.
- A request that is "immediately discarded after servicing the request" need not be disclosed. Google's pages describe the data as used for analytics, which implies retention, so I do not rely on this exemption. Google does not state a retention period on these pages (unconfirmed).
- The wording of the "Data Not Collected" product page label is not on these pages. I could not confirm it from a primary source.

Result: because a third-party SDK sends device, app and performance data to Google for analytics, "No, we do not collect data from this app" is no longer a correct answer.

## App Store Connect answers

Google does not map its data to Apple's categories, linked-to-user, or tracking. The mapping below is my judgment from Google's list and Apple's definitions. Review it before publishing. The developer is responsible for the label's accuracy.

1. "Do you or your third-party partners collect data from this app?" Yes, we collect data from this app.
2. Data types to select:
   - Diagnostics > Performance Data (latency, event timing).
   - Diagnostics > Other Diagnostic Data (device model, OS version, bundle ID and app version, API configuration, event types, error codes, configured language).
   - Identifiers > Device ID (the per-installation identifier). Google says it is not intended to identify a user or device. Apple's definition is "other device-level ID", and I cannot rule out that it counts. Declaring it is the cautious call. This is the least certain row.
   - Not selected: Usage Data > Product Interaction. Google's "event types" are SDK lifecycle events (initialization, model download, detection), not taps or screens. Revisit if you want the cautious call here too.
   - Not selected: User Content > Other User Content, Contact Info, Location, Search History. Google documents no ink, query or result data leaving the device.
3. For each selected type:
   - Linked to the user's identity? No for Performance Data and Other Diagnostic Data (Nichiji has no account). Device ID: Yes is the cautious answer, since Apple counts linkage "via their account, device, or other details" and the identifier is a device-level one. This is a judgment call.
   - Used for tracking? No. Tracking needs linking with third-party data for advertising or sharing with a data broker. Google's pages describe diagnostics and usage analytics only and name no ad use. Apple's page lists an SDK that "combines user data from your app with user data from other developers' apps to target advertising" as tracking. Google's pages do not say whether ML Kit does that. I found no such statement, but could not confirm its absence.
   - Purposes: Analytics (Google's stated purpose) and App Functionality (Apple counts "minimize app crashes, improve scalability and performance" as App Functionality, which covers diagnostics). Select both for each type.

Also check that `NSPrivacyTracking` stays false and no tracking domains are listed if the app has a `PrivacyInfo.xcprivacy`. I found no such file in the app repo. Whether the ML Kit pods ship their own privacy manifests is unconfirmed (`Pods/` is not present).

## Replacement for `.plan/assets/app-store-listing.md` line 18

Current:

```
| Privacy label | Data Not Collected | |
```

Replace with (it asserts Device ID linked, as in the answers above):

```
| Privacy label | Data Collected via Google ML Kit: Diagnostics (Performance Data, Other Diagnostic Data) and Identifiers (Device ID, linked). Not used for tracking. Purposes: Analytics, App Functionality. | |
```

## In-app lines checked against the findings

None of these hold. The replacements apply only if [Decide whether handwriting search keeps ML Kit](../closed/068-decide-whether-handwriting-search-keeps-ml-kit.md) keeps ML Kit, and "No tracking" and "drawings stay on your device" are only as sure as the unconfirmed points below; confirm both before the copy ships. ML Kit sends diagnostics and usage data to Google, so "collects nothing" and "no data" are false. What still holds: no account, no ads, no tracking (subject to the tracking caveat above), and drawings stay on the device.

The on-device test in the recognizer ticket saw the logging contact once per session when ML Kit ran. I did not verify whether the app calls ML Kit only when a user opens handwriting search (a Pro feature). Apple's label is per app, so even if only some users trigger it, the label must declare it.

| Where | Current | Holds? | Replacement |
| --- | --- | --- | --- |
| `Nichiji/Views/Onboarding/Steps/WelcomeView.swift:15` (footnote) | "No account needed. Nichiji does not collect any data." | No | "No account needed. Your progress and drawings stay on your device." |
| `Nichiji/Views/Settings/SettingsSheet.swift:262` (Privacy row value) | "Data not collected" | No | "No tracking" |
| `Nichiji/Views/Settings/SettingsSupportViews.swift:288` (badge) | "Data not collected" | No | "No tracking" |
| `Nichiji/Views/Settings/SettingsSupportViews.swift:300` (heading) | "Nichiji collects nothing" | No | "Your study stays on your device" |
| `Nichiji/Views/Settings/SettingsSupportViews.swift:304` (body) | "The app does not collect any data about you. You do not need an account to use it." | No | "You do not need an account, and Nichiji has no ads or tracking. Your progress, settings and drawings stay on your device. Handwriting search uses Google ML Kit, which downloads a language model and sends Google technical diagnostics and usage data, such as your device model, app version and error codes." |

Notes on the replacements:
- "No tracking" holds only if the tracking answer above stays No. The checkmark icon in the badge at `SettingsSupportViews.swift:283-286` can stay.
- "Drawings stay on your device" rests on Google's statement and was not verified on the wire.
- I avoided "anonymous", because Google only says its per-installation identifiers are "not intended to uniquely identify" a user.

### Other stale copy found while grepping (outside the ask; not edited)

- `.plan/assets/support-site.md:28` (privacy policy): "does not collect, store or share any personal data. It has no account, no analytics, no ads and no tracking." The "no analytics" claim is false with ML Kit. The policy also needs a sentence naming Google ML Kit and what it sends.
- `.plan/assets/app-store-listing.md:69` (description): "Nichiji collects no data, and everything stays on your iPhone." False with ML Kit.
- `docs/DESIGN.md:16`: "does not collect analytics or personal" data. Needs the same fix, and [Choose the handwriting recognizer](../closed/060-choose-the-handwriting-recognizer.md) already says to update it.

## Could not confirm from a primary source

- Which ML Kit version the data disclosure page describes (it says "latest version" only).
- Any opt-out (none documented; not ruled out for undocumented switches).
- Which hosts carry which data (`play.googleapis.com`, `www.googleapis.com` are not named by Google).
- Whether ink, strokes or recognition results are ever sent (Google says no; not verified on the wire).
- Google's retention period for the logged data.
- Whether ML Kit's data counts as "linked" or "tracking" under Apple's rules. Google does not say, so the answers above are judgment.
- The exact product-page wording of Apple's "Data Not Collected" label.
- Whether the ML Kit pods ship `PrivacyInfo.xcprivacy` manifests.
