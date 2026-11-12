# Photo lookup test harness

Throwaway app for ticket 061, "Test photo lookup on real signage". It runs Apple Vision text recognition (`VNRecognizeTextRequest`, accurate, `ja-JP` then `en-US`) on photos from your library and records how well it read each one. It shares no code with Nichiji.

## Build

There is no Mac in the loop. The `Photo lookup harness` workflow builds an unsigned IPA on every push that touches this folder, and from the Actions tab with Run workflow. Download the `PhotoLookup-unsigned-ipa` artifact, unzip it, and sideload `PhotoLookup.ipa` onto your iPhone the same way you do `Nichiji.ipa`.

## Test

1. Check the Device section: Japanese must be listed under supported languages.
2. Tap Add photos and pick at least 30 photos of real signage and printed pages, mixed vertical and horizontal, in normal light.
3. Open each photo, compare the recognized text with what you can read, set the photo type and layout, then tap Good, Partial or Failed. Good means the kanji came back right. Partial means some did.
4. Open Summary for the success rate per photo type and per layout, and export the CSV.

Results save to the app's Documents folder, so quitting the app loses nothing. The photos themselves are not saved.
