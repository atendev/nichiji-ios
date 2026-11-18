# Decision report: Fit library and cropped photos on the frozen photo screen

Version v0.34.0. Gate used: the master's brief (council audit, commit every time) over the repo's haiku auditor in `docs/workflow.md`; the repo's requirements and deviation reports went into `docs/IMPLOG.md`.

## Decisions

1. **How the mode is chosen.** Options: a flag set by each caller, or a pure mapping from `PhotoOrigin`. Chose the mapping (`PhotoOrigin.fitMode`: camera fills, library and cropped fit). Made by the main thread. It follows the ticket, and a cropped camera shot already has origin `.cropped`.
2. **Where the geometry lives.** `PhotoFit.photoFrame(imageSize:in:mode:)` joins the existing filled and fitted frames, and `viewRect` takes a mode that defaults to fill, so existing callers and tests compile unchanged. Made by the main thread.
3. **How zoom learns the photo's size.** Options: a new stage type that replaces the view size in every call, or an optional `content` size on each `PhotoZoom` method. Chose the optional size: the 083 tests stay valid and a nil size means the whole view.
4. **Pan limit.** The limit per axis is `max((content * scale - view) / 2, 0)`. An axis the scaled photo does not fill stays centred, so a letterboxed photo cannot be panned into its bars. At 1x the offset is always zero, even for a filled shot wider than the view. A filled shot's cut-off sides are reachable once zoomed, which closes the open note on the zoom ticket.
5. **Box mask.** The mask that hides boxes now uses the photo's rect under the zoom, not the view's rect, so no box shows on a bar, and a box cut off by aspect-fill appears once zoomed in far enough.
6. **Sweep (found by the audit).** The scan line and the box fade timing first ran down the full view height, so a fitted photo's bars were swept. Fixed with `PhotoFit.sweepFrame` (photo rect clipped to the view; the whole view for a filled shot, so camera timing is unchanged).
7. **Zoom reset.** Zoom also resets when the fit mode changes, next to the existing reset on a new image.
8. **File size.** `PhotoLookupScreen.swift` gains one line (369 of 400). The rest is in the frozen photo, geometry and zoom files.

## Audit

- Round 1 (haiku seat, Gemini, GPT): Gemini APPROVE 9. Claude seat DISAPPROVE 7 with one blocking problem (the sweep over the bars), fixed in decision 6. GPT DISAPPROVE 3 with one blocking problem (`fittedFrame` undefined), rebutted: it is defined at `Nichiji/PhotoLookup/PhotoCrop.swift:127`.
- Round 2: Claude seat APPROVE 8, Gemini APPROVE 9, GPT APPROVE 9.
- Declined minor problems (3):
  - Missing `.clipped()` on the image: declined. The photo is still clipped by the `.frame(size).clipped()` after the zoom transform.
  - `photoZoomGestures` has a new required `contentSize`: declined. `FrozenPhotoView` is its only caller (checked with grep).
  - No camera base colour in the layer: rebutted. `PhotoLookupScreen.swift:97` paints it beneath the backdrop.

## Not run

No Swift toolchain on this host. CI is the build, lint and test check. The fit, the pan limit and the sweep need a device check.
