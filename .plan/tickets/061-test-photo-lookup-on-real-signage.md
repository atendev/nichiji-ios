---
id: "061"
title: Test photo lookup on real signage
type: task
mode: HITL
status: open
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
Output: the success rate per photo type, and a go/no-go on the price. If the test fails, the photo lookup is cut and the price is revisited.

## Resolution
