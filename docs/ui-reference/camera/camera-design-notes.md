# Nichiji: camera scan, design notes

Scan a kanji with the camera and get the kanji in the photo. Part of the Dictionary tab. Designed on the Nichiji design canvas (App page, bottom row), using the Nichiji design system. Everything shown is mocked: the "photo" is a drawn notice and nothing is really recognized.

## The flow

1. **Entry.** The Dictionary has two buttons under the search bar, side by side: **Draw a kanji** and **Scan a kanji** (camera icon). Scan opens the camera over the whole screen. The tab bar is hidden while the camera is open.
2. **Viewfinder** (in-app custom camera, not the system camera app).
   - Close (X) top left, flash top right.
   - A corner-bracket reticle and a hint pill: "Point at a kanji, then tap the shutter".
   - Bottom: photo-library button (left), shutter (center). Choosing a library photo goes through the same flow as the shutter.
   - The live feed drifts slightly and is a touch soft, so it reads as live.
3. **Photo frozen.** Tapping the shutter flashes white (about 0.2s) and freezes the shot.
   - A scan line sweeps down the photo (about 1.6s). Kanji get a box as the line passes them. A "Scanning for kanji…" pill sits at the bottom.
   - **Red box = new to you** (not learned yet). **Green box = already learned.** The same colors are used for the NEW tag and the check in the results grid.
   - Options, top right, each with a text label: **Crop**, **Save**, **Highlights** (shows or hides the boxes).
   - **X at top left removes the photo and goes back to the camera.**
4. **Results sheet.** About 1.9s after the shutter the sheet rises by itself to half height. The photo shrinks and moves up (to about 80%) so the highlights stay visible above the sheet.
   - Header: "11 kanji found", subtitle "5 new to you · 6 learned", and a **New only** switch.
   - Body: a 3-column grid of tiles. Each tile is the kanji (44px), its short meaning, and either a **NEW** tag (new tiles, raised background, darker border) or a green check (learned tiles, quieter).
   - With New only on, the subtitle reads "Showing 5 new". If nothing is new, the grid shows "Nothing new here. You have already learned every kanji in this photo."
   - The grid is in photo reading order, one tile per distinct kanji.
5. **Open a kanji.** Tap a tile, or tap a box on the photo, to open that kanji's normal detail screen (back label "Scan results"). Back returns to the sheet exactly as it was.
6. **Swipe down** on the sheet: it collapses to a **peek bar** ("11 kanji found · 5 new to you · Swipe up"). The whole photo with its highlights is visible. Tapping the peek bar returns to half height.
7. **Swipe up** on the sheet: it goes to the **full-screen grid** and the **tab bar comes back** (Dictionary active).
   - Header follows the tab pattern: 写 | Scan, with a chevron at top right that returns to the photo.
   - Under it: a photo thumbnail, "Your photo / Scanned just now", and a **View photo** button (back to the peek state).
   - Then the title row with the New only switch, and the grid.
   - Scrolling the half-height grid also pulls the sheet up to full screen. Dragging the header down returns to half.

## Sheet states

| State | Sheet height | Photo | Navigation |
|-------|--------------|-------|------------|
| Peek | 112px | full size | hidden |
| Half | 456px | scaled to 0.8, moved up 100px | hidden |
| Full | 844px (whole screen) | hidden behind the sheet, thumbnail in header | visible |

- Drag from the header: the sheet follows the finger, then snaps to the nearest state. A drag of more than 40px always moves one state in the direction of the drag.
- While dragging between peek and half, the photo scales continuously with the sheet.
- Snap animation: 0.32s, `cubic-bezier(.2,.8,.2,1)`. The sheet's top corners are 20px, and flatten to 0 as it reaches full screen.
- Buttons in the header (switch, chevron, View photo) opt out of dragging so taps work.

## Crop

- The Crop option shows the photo at full size with the rest dimmed, a crop frame with corner handles and thirds lines, the title "Crop", the hint "Drag the corners to choose the part to scan", and **Cancel** / **Done** buttons.
- Done is the one filled (vermilion) button on that screen. Done rescans the cropped photo (the scan animation runs again). Cancel returns to the results.
- In the mockup the frame is static.

## Save

- Save shows a toast, "Saved to Photos" (green check), for about 1.8s. The mockup does not save anything.

## Look

- The camera uses a **dark overlay treatment** over the photo: controls are translucent ink (`rgba(21,19,15,.55)`) with a faint light outline (`rgba(239,232,216,.25)`) and light text (`#efe8d8`). These are the design system's dark-theme tokens.
- Highlight colors use the dark-theme tokens so they read on a photo: new `#e8603f` (vermilion), learned `#8db483` (matcha), each with about 22% fill.
- The results sheet and full grid use the normal light theme: surface `#f4eee2`, tiles `#fbf7ee`, hairline `#d9cfbc`, control border `#8c8068`. NEW tag: vermilion wash `#f7e6de` with vermilion text.
- Shutter is neutral (light ring and disc), not vermilion. The only vermilion fill on the camera screens is Done in Crop.
- Touch targets are at least 44px. Text labels sit next to the icons in the photo options because bare icons were found unclear elsewhere in the app.
- All motion is disabled under reduced-motion.

## Mocked and sample data

- The "photo" is a CSS-drawn paper notice on a dark table: 日本語学校 / 入口 · 受付 / 月〜金 9:00–17:00. Eleven distinct kanji are recognized.
- Learned in the sample: 日 本 学 校 月 金. New: 語 入 口 受 付. (Same learned set as the rest of the mockup.)
- Detail data was added for the new kanji 語 入 口 受 付 (readings, meaning, strokes, JLPT, two example words each). Stroke diagrams exist only for 13 kanji; these show the "not drawn yet" note.
- Not real: recognition, the crop handles, Save, the library button, the flash.
- Not designed: the camera permission prompt, a "no kanji found" result, a blurry-photo hint, vertical text, and kanji that appear only inside words.

## Suggested production approach (not decided)

- Offline and on-device, like the rest of the app: no accounts, nothing uploaded.
- Capture with `AVCaptureSession` in a custom view; the library button via `PHPickerViewController`; Save to Photos needs the add-only Photos permission.
- Text recognition with Apple's Vision framework (`VNRecognizeTextRequest`, Japanese). Use the returned bounding boxes for the highlight rectangles, keep only characters that are in the kanji database, and de-duplicate.
- "New to you" is a lookup against the learner's per-kanji state (unseen vs learned or known). Show that same state in the tiles and the boxes.
- Tapping a box or tile opens the standard kanji detail.

## Files

- `source/Camera.dc.html`: the whole flow (state, gestures, sheet, crop). Props: `start` (viewfinder, scanning, peek, half, full), `newOnly`, `detail`, `crop`, `still`, `onClose`, `onTab`.
- `source/CameraScene.dc.html`: the drawn photo, the glyph positions, the highlight boxes and the scan line.
- `source/Camera*.dc.html` (Viewfinder, Scanning, Peek, Results, ResultsNew, Full, Detail, Crop): one artboard per step, each a wrapper that mounts `Camera` in that state.
- `../source/Dictionary.dc.html`: adds the Scan button and mounts the camera.
- `../source/KanjiDetail.dc.html`: adds data for 語 入 口 受 付.
