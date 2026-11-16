---
id: "061"
title: Test photo lookup on real signage
type: task
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

Does on-device Japanese text recognition read kanji from real shop signage and printed pages well enough to carry the $4.99 Pro price?

## Notes

Skills: none. This is a device test, run by the user.
Settled while grilling "Decide the free/Pro boundary, price and unlock flow": photo lookup is a Pro feature in v1.0. Ship with it, then decide whether the price holds.
Apple's Vision text recognition supports Japanese (WWDC22 session 10024), and recognition runs on-device. Vertical text may fail in some cases. Confirm the recognition languages on device with `supportedRecognitionLanguages(for:revision:)`.
Test on at least 30 photos of real signage and printed pages, mixed vertical and horizontal, in normal light.
Harness: `prototypes/photo-lookup/` on `feature/photo-lookup-test-harness`. Its README has the steps; its Summary screen gives the rates and a CSV.
Flow decided: photo lookup is capture-then-grid, not live. The user takes or picks a photo, the app shows every dictionary kanji it found with the photo alongside, and a tap opens the existing kanji detail. A "New to you" toggle filters the grid to unlearned kanji; it is off by default, so everything found shows. Live scanning is dropped. The product extracts kanji only, so the test should judge kanji read correctly, not whole lines.
Output: the success rate per photo type, and a go/no-go on the price. If the test fails, the photo lookup is cut and the price is revisited.

## Resolution

Go. 30 photos on device (shop signs 15, printed pages 6, other 6, menus or labels 3): 24 Good, 4 Partial, 2 Failed, so 80% Good and 93% Good or Partial. By type, Good or Partial was 93% for shop signs, 100% for printed pages and menus, 83% for other. Horizontal text was 88% Good and 100% usable; vertical text (6 photos) was 50% Good and 67% usable.

- **Pass bar:** Good or Partial at least 90% overall and no photo type under 80%. The run clears it. Menus or labels had only 3 photos, so its 67% Good is not read as a signal.
- **Vertical text:** Vision runs first. When it reads fewer than 4 characters, Live Text (VisionKit) stands in. On the run this recovered 3 of the 4 weak reads. The rotation retry never beat the upright read in 5 tries and is dropped.
- **Price:** the $4.99 Pro price holds with photo lookup in it.
- **Flow:** capture-then-grid, as in Notes. The listing says "point the camera at a sign" and does not promise vertical text.
- **Caveats:** all photos came from one Tokyo area, and vertical had 6. Handwritten signs, dim light and odd angles were not tested. The harness now logs `combined_text` and `kanji_found` for a later run.
