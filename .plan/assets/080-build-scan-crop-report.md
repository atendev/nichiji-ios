# Decision report: Build Crop for the scanned photo

Version v0.29.0 (MINOR). Branch `t3/build-scan-crop`. No Swift toolchain on this machine, so nothing was compiled or run here; the tests are written and CI is the first run.

## Decisions

### 1. Where the entry and rescan hook live
- Question: How does Crop join the scan screen without bloating it?
- Options: Edit `PhotoLookupScreen.swift` directly. Put the hook in a separate file.
- Choice: Separate file. `PhotoCropView.swift` holds `PhotoCropOption` and `View.photoCrop(...)`. The screen gains one `@State`, one modifier call and an HStack around Highlights.
- Made by: Implementer, then the master. Siblings (results sheet, Save) edit the same screen, and SwiftLint caps files at 400 lines. The screen ended at 390 lines.
- Audit: Rounds 1 and 2 saw the first, inline version. Round 3 saw this one.

### 2. Does Done on an untouched frame rescan?
- Question: Should Done rescan when the frame still covers the whole photo?
- Options: Rescan anyway. Close like Cancel.
- Choice: Close like Cancel. The same photo reads the same, and the sweep would replay for nothing.
- Made by: Implementer. 075 says Done rescans the crop; an unchanged frame has no crop to rescan.
- Audit: No seat objected.

### 3. When Crop shows
- Question: In which results states is Crop offered?
- Options: Only after a found read. Every settled state.
- Choice: Every settled state (found, no kanji, failed), and only once the sweep ends. 075 says Crop and X stay available when nothing is found.
- Made by: Implementer, from 075.
- Audit: No seat objected.

### 4. Hit targets and the minimum frame
- Choice: Each corner has a 44 pt target centred on the corner. The frame cannot shrink below 88 pt a side, so two corner targets never overlap. VoiceOver gets an adjustable action per corner that moves it 5% of the photo in or out.
- Made by: Implementer, from the ticket's 44 pt rule.
- Audit: No seat objected.

### 5. Crop output
- Choice: The photo is redrawn upright first when it carries an orientation flag, cropped in pixels, and saved as JPEG at 0.92. The crop replaces the photo in the model, and a retake or newer read during the crop drops it.
- Made by: Implementer.
- Audit: Round 2 and 3 seats raised nothing.

### 6. Save's dependency
- Choice: The model keeps no "is cropped" flag. 075 says Save is hidden for an uncropped library photo, and that belongs to the Save ticket, which can add the flag on its own branch.
- Made by: Implementer, to keep the batch merge small.

## Audit

- Round 1: claude 6 DISAPPROVE, gemini 10, gpt 5 DISAPPROVE.
  - Claude, blocking: the drag gesture came after `.position`, so each handle's gesture would cover the canvas and the last corner would win. Fixed by moving the target, gesture and accessibility before `.position`.
  - Claude, minor: the test stub read the same text for any image. Fixed with a reader that depends on the image width.
  - Claude, minor: symbols outside the diff were unchecked. Declined; each was read in the repo.
  - Gpt, blocking: `ForEach(id: \.self)` needs `Hashable` on `Corner`. Rebutted, since a payload-free enum is already Hashable. The conformance was declared anyway.
- Round 2: claude 8, gemini 10, gpt 9, all APPROVE. Claude's minor was real: the test used 本, which is not in the seed set. Fixed to 日, 一, 川.
- Round 3 (after the entry moved to its own file): claude 8, gemini 10, gpt 9, all APPROVE.
- Declined minor problems (3, all from claude, round 3):
  - A second Crop and Done in the few milliseconds before the read starts. Each read bumps the generation, so the later one wins and both crops are valid.
  - `frozenImage` could be stale. It is derived from `model.photoData` on change.
  - `PhotoOptionButton` called without `isOn`. The property defaults to nil.

## For the user
- Needs a device check: dragging the handles, VoiceOver nudges and the rescan sweep.
- The commit gate asked the user nothing, per the master's brief.
- `docs/CHANGELOG.md` v0.29.0 may collide with the sibling tickets' entries at the batch merge. Tagging is the user's call.
