Buttons carry the learner's few decisions: "Got it", "Mark as known", "Forget it".

- Use `nj-btn--primary` (vermilion fill, `on-vermilion` text) for the single main action on a screen, usually "Got it". Never place two primary buttons in the same view.
- Use `nj-btn--secondary` (`surface-raised`, `border-control` outline) for equal-weight alternatives such as "Mark as known".
- Use `nj-btn--quiet` for low-emphasis, reversible actions such as "Forget it". It is vermilion text on `surface`.
- After "Got it", swap the primary button for `nj-btn--done` showing a check and "Learned" (`vermilion-wash` fill). Keep it tappable so the learner can undo with "Forget it" in history.
- Labels are verb first, sentence case, one to three words. Targets are 44px tall.
- The consumer provides the label text and the tap handler. Focus uses a solid 2px `focus-ring` offset 2px.
- In the review session, answer cards with `nj-btn--got` ("Got it", `matcha`) and `nj-btn--forgot` ("Forgot it", `mustard-text` on `mustard-wash`). Neither is a vermilion fill, so the one-vermilion rule still holds. Both stay disabled until the card is flipped.
- `nj-btn--practice` ("Practice this kanji") is a thick dashed outline with no fill and a pencil on the left. Use it at the bottom of the stroke order card and the review answer side.
