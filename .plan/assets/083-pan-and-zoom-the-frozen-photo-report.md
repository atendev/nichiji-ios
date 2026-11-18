# Decision report for Pan and zoom the frozen photo

Branch `t3/pan-zoom-frozen-photo`. Version v0.33.0 (MINOR; the master renumbers at the merge). The host has no Swift toolchain, so nothing was compiled or run. CI is the first compile and the first test run.

## Decisions

### 1. SwiftUI gestures or a UIScrollView wrapper
- Options: `MagnifyGesture`, `DragGesture` and `SpatialTapGesture`, or a `UIScrollView` wrapper.
- Choice: SwiftUI gestures. Made by the implementer.
- Why: the ticket prefers SwiftUI unless it needs workarounds, and none were needed. The photo is one screen-sized image with boxes drawn over it, so there is no content size for a scroll view to manage.
- Audit: all three seats accepted the gesture composition.

### 2. What the zoom scales
- Options: scale the whole photo layer, or scale only the image and map the boxes through the same transform in screen space.
- Choice: scale only the image and map the boxes. Made by the implementer.
- Why: scaling the layer would also scale the 2 pt box strokes and the 44 pt tap targets. Mapping the boxes keeps the stroke at 2 pt and the tap minimum at 44 pt, while the box itself grows with the kanji it covers. `PhotoZoom.apply(to:in:)` is the one transform for points and rects, so a box cannot drift off its kanji.
- Audit: the Claude seat first read the growing box as a contradiction (blocking, score 6). The implementer rebutted it with the stroke and tap-region evidence, and the seat approved in round 2.

### 3. What zoom covers
- Options: zoom the screen-sized, aspect-fill photo as it is today, or zoom the whole image so the cropped-off edges can be panned into view.
- Choice: the screen-sized photo as drawn at 1x. Made by the implementer.
- Why: 1x must look as it does now, and a pan limit of `view * (scale - 1) / 2` is continuous from 1x. Revealing the cropped edges would make the pan limit jump at 1.01x. Boxes cropped off by aspect-fill stay hidden because the highlights are masked to the zoomed photo rect.
- Consequence: the learner cannot zoom into the part of the photo that aspect-fill already cuts off. Surfaced as an open question for the learner's feedback, not a ticket.

### 3a. Clipping after the transform
- A GPT seat finding (blocking, round 1). `.clipped()` ran before `.scaleEffect` and `.offset`, so a zoomed photo could draw outside the view, which matters under the sheet's 0.8 pose.
- Fixed by clipping the image and the masked highlights to the view after the transform. All three seats approved in round 2.

### 4. Single tap and double-tap
- Options: a child single-tap on the boxes with a parent double-tap, a simultaneous double-tap that also fires the box tap, or one exclusive gesture where the double-tap goes first.
- Choice: `SpatialTapGesture(count: 2).exclusively(before: SpatialTapGesture(count: 1))`, handled in one place. Made by the implementer.
- Why: a child tap swallows the first touch, so the double-tap would never fire on a box. A simultaneous double-tap would open detail on the first tap of a double-tap. The cost is that a box tap waits out the system double-tap window before it opens detail.
- Declined problem (minor, Claude seat, round 2). The delay is a design choice, recorded in the changelog. Worth a device check.
- The box tap moved out of `HighlightsLayer` into the zoom gestures, which read the tap point against the zoomed rects. The VoiceOver action stays on each box.

### 5. Pan against pinch
- Choice: a drag pans only while zoomed and not while a pinch is running. Made by the implementer.
- Why: both gestures run together, and two writers on one state fight each other. Two-finger centroid pan is lost, which is acceptable.
- Fixed after the Claude seat's round-1 minor finding. A fresh drag now starts from a zero origin, so the photo follows the finger 1:1 (it lagged by the 10 pt `minimumDistance`). A drag that is already down when a pinch begins restarts from where the pinch left off, tracked with `isDragging` and `panNeedsRebase`.

### 6. Sheet header against photo pan
- Decision: the header drag wins. The sheet is a layer above the photo and the empty part of its layer does not take touches, so hit testing hands header touches to the sheet and the rest to the photo. No extra code. Made by the implementer, as the ticket asks.

### 7. Reset
- Decision: reset in `FrozenPhotoLayer` itself. Retake drops the layer (it only exists while a photo is frozen), and a new photo or a crop rescan gives a new `UIImage`, which `onChange(of: image)` resets. Made by the implementer.
- Why: `PhotoLookupScreen.swift` stays untouched at 368 lines, under the 400-line limit.
- Declined problem (minor, Claude seats). Two seats said the reset path sits outside the diff. The path is `model.crop` to `lookUp(imageData:)` to `photoData` to `UIImage(data:)`, a new object each time.

### 8. Zoom wait, Reduce Motion, caps
- Zoom waits for the sweep through `GestureMask.none` while `isSweeping`. Caps are 1x to 4x, with a double-tap to 2.5x. A pinch that ends under 1.05x closes to 1x.
- Reduce Motion: pinch and pan write the state directly. The double-tap and the snap back use no animation under Reduce Motion, and a 0.25 s ease otherwise.

## Council

| Round | Claude (haiku) | Gemini | GPT | Outcome |
|---|---|---|---|---|
| 1 | DISAPPROVE 6 | APPROVE 9 | DISAPPROVE 7 | one blocking finding fixed, one rebutted |
| 2 | APPROVE 8 | APPROVE 9 | APPROVE 9 | APPROVE |

Declined minor problems (3): the delay on a single tap (design choice), the "inert" per-box regions (they are accessibility frames and hit testing is off by design), and the v0.33.0 version gap (the master renumbers). The two "reset unverified" notes were answered with evidence.

## Tests
`PhotoZoomTests` has 18 tests on the real `PhotoZoom` type. They cover the caps, the pinch anchor, the clamp, the pan limit, the snap, the double-tap, point and rect mapping, and a box staying on its kanji. None have run.

## Device check needed
The pinch and pan feel, the single-tap delay on a box, zoom under the sheet's half pose, and the double-tap animation.

## Files
`PhotoZoom.swift` (new), `PhotoZoomGestures.swift` (new), `FrozenPhotoView.swift`, `PhotoZoomTests.swift` (new), and the docs (`CHANGELOG`, `PROGRESS`, `DESIGN`, `IMPLOG`). `PhotoFit`, `PhotoHighlights.swift` and `PhotoLookupScreen.swift` are unchanged.

## CI fix 1
CI failed to compile `PhotoZoomTests.swift:57`: `zoom.apply(to: .zero, in: view) == .zero` is ambiguous because `apply(to:)` has `CGPoint` and `CGRect` overloads. The implementer qualified both sides as `CGPoint.zero`. The rest of the file has no other ambiguous `.zero`, since every other call passes a typed value or sits where one type fits. Council round 3 approved it (Claude 9, Gemini 10, GPT 10), with no problems declined. No version bump, since only a test changed.
