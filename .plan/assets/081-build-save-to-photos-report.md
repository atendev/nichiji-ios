# Decision report: Build Save to Photos for the scanned photo

Version v0.29.0 (MINOR). Branch `t3/96b97910`. Crop (080) and the results sheet (079) are being built on sibling branches, so Save is built against the frozen photo as it stands on this base.

## Decisions

### 1. Where the "is this photo savable" rule lives
- Question: How does Save know a library photo is already in Photos and an uncropped one should not show Save, without waiting for Crop?
- Options: A flag on `PhotoLookupModel`. A screen-level `@State`. A new `PhotoOrigin` enum (`camera`, `library`, `cropped`) with `isSavable`.
- Choice: `PhotoOrigin`, held as screen state. The screen sets `.camera` after a shutter shot and `.library` after a library pick. Crop sets `.cropped` when it replaces the photo, and Save shows again.
- Made by: Implementer. Keeping it out of `PhotoLookupModel` avoids a merge conflict with Crop, which also changes that model.
- Audit: No seat raised it.

### 2. Which image Save writes
- Question: How does Save take whichever image is current, since Crop is not on this base?
- Choice: `savePhoto()` passes `model.photoData` at tap time. Crop makes the crop the frozen photo, so Save writes the crop with no change. The saved image is the plain photo, never the one with boxes (075 decision 12).
- Made by: Implementer, from 075 and the batch note.
- Audit: No seat raised it.

### 3. Photos access and write
- Question: Which access level, and when is it asked for?
- Choice: `PHPhotoLibrary.requestAuthorization(for: .addOnly)` on the first Save tap, then `performChanges` with a `PHAssetCreationRequest`. A status other than authorized or limited gives `.denied`. A thrown error gives `.failed`. The call sits behind a `PhotoLibrarySaving` protocol, so tests use a stub.
- Made by: Implementer, from 075 decision 2 and the ticket notes.
- Audit: No seat raised it. The write needs a device check, since this host has no Swift toolchain.

### 4. Toast timing and the denied note
- Question: How long does each toast stay, and where does Open Settings go?
- Options: A fixed 1.8 s for every toast. 1.8 s for "Saved to Photos" and longer for problems.
- Choice: 1.8 s for "Saved to Photos" (the design), 5 s for "Photos access is off" and "The photo couldn't be saved." so the learner can read them and tap Open Settings. The denied toast carries an Open Settings button at least 44 pt high. Each toast has an id, so a timer only clears the toast it was set for.
- Made by: Implementer. 075 sets the wording and the Open Settings button but no duration for the problem toasts.
- Audit: No seat raised it.

### 5. Toast placement and VoiceOver
- Question: Where does the toast sit, given the results panel covers the lower half?
- Choice: A pill under the top bar, in the camera's dark ink with a green check (`cameraLearned`) for success and a vermilion mark for problems. Each toast is announced to VoiceOver, and Reduce Motion swaps the slide for a crossfade.
- Made by: Implementer, from 075 decision 17 and the design's overlay colors.

### 6. When Save shows
- Question: Which photo states show Save?
- Choice: Whenever a photo is frozen and the read is done (found, no kanji or failed), unless it is an uncropped library photo. Save is disabled while a write runs, and the model ignores a second tap.
- Made by: Implementer. Saving a shot that found nothing is still a valid use, and 075 keeps Crop and X available in those states.

### 7. Privacy copy
- Question: Which statements go stale once the photo can be saved?
- Choice: `NSCameraUsageDescription` now says Nichiji sends the photo nowhere, replacing "never leaves it". The new `NSPhotoLibraryAddUsageDescription` says Nichiji adds a photo only when the learner taps Save. The in-app Privacy screen, `DESIGN.md`, the listing's privacy paragraph and the privacy policy draft in `assets/support-site.md` say the same. The label stays Data Not Collected, and the policy draft notes that iCloud Photos settings decide whether a saved photo syncs.
- Made by: Implementer, from 075 decision 2.
- Audit: No seat raised it.

### 8. Scope kept to the ticket
- Choice: The screen edits are the Save button, the toast overlay, two origin assignments and a toast dismissal on X. Highlights, the sweep and the old results panel are untouched. The Highlights comment now says only Crop is still to come.
- Made by: Implementer, from the batch note.

## Audit

Round 1: claude APPROVE 8, gemini APPROVE 9, gpt APPROVE 9. The gate opened in one round.

The claude seat raised four minor problems, all declined.
- It could not tell whether `uiText` scales with Dynamic Type. It does (`relativeTo: .body`).
- It could not tell whether the names in the diff exist. All of them do.
- It called `oneAtATime` fragile because release could run before the continuation is registered. The stub checks `isHeld` and registers the continuation in one synchronous stretch of the actor, so either order ends the same way.
- It saw no version field change in `project.yml`. The app's version lives in `docs/CHANGELOG.md`, and `MARKETING_VERSION` is the release build's concern.

While checking the names, the implementer also changed the Open Settings link from semibold to medium, since the design system caps weight at medium. That edit came after the claude seat's approval and changes no behavior.

## Not verified here

The host is Linux with no Swift toolchain or SwiftLint, so nothing was built, linted or run. CI is the build and test check. The Photos write, the permission prompt and the toast need a device check.
