---
id: "068"
title: Decide whether handwriting search keeps ML Kit
type: grilling
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

Does v1.0 keep ML Kit for handwriting search and ship a "Data Collected" privacy label, or drop it for the KanjiVG matcher and keep "Data Not Collected"?

## Notes

Skills: `grilling` and `domain-modeling`.
From [Find what ML Kit sends to Google](../closed/064-find-what-ml-kit-sends-to-google.md): ML Kit sends Google diagnostics by default with no documented opt-out. See [ml-kit-privacy.md](../assets/ml-kit-privacy.md).
On the user's 104 drawings ML Kit scored 89.4% top-1 and 99.0% top-5, the matcher 79.8% and 92.3% ([Choose the handwriting recognizer](../closed/060-choose-the-handwriting-recognizer.md)). The listing and Pro copy lean on "Data Not Collected".
Weigh accuracy against the label, the listing's privacy promise and the extra SDK. Also decide whether to ask Google about an undocumented opt-out first.

## Resolution

Drop ML Kit. v1.0 ships handwriting search on the KanjiVG matcher alone and keeps "Data Not Collected". ML Kit is deferred to after v1.0. A sonnet subagent ran the grilling and the user approved its answers.

Why:
- The risk runs one way. Dropping ML Kit now and adding it later costs nothing. Shipping "Data Collected" and walking it back later is a visible downgrade. This is the main reason.
- ML Kit's accuracy lead is real but not conclusive. Top-1 is 89.4% against 79.8%, on 19 against 9 disagreeing drawings (p ≈ 0.09). Top-5 is 99.0% against 92.3%, on 8 against 1 (p ≈ 0.04). Both rows count, since matches show best first and a tap on any of them fills the search bar. All 104 drawings are one person's, and part of ML Kit's lead comes from filtering its output to shipped kanji (raw 87.5% and 98.1%).
- Keeping ML Kit would falsify the listing's "Data Not Collected" and "collects no data", the privacy policy, `DESIGN.md` and five in-app lines. It would also go against the spirit of the `DESIGN.md` rule that the app must not require analytics.
- The SDK costs more than the download: a closed binary through CocoaPods, device-only linking that keeps its code path out of every Simulator test and CI run, and a 20 MB Google download in a local-first app. Whether ML Kit 8.0.0 ships Apple privacy manifests is also unconfirmed, which would be review risk.
- [Choose the handwriting recognizer](060-choose-the-handwriting-recognizer.md) called privacy a tiebreaker, when it expected accuracy to come out about even. Accuracy came out a mild edge, and the privacy cost turned out to be a public label change. The user's "guideline, not a hard requirement" would have allowed keeping ML Kit, so dropping it is a judgment call, not a rule.
- The unknown that cuts the other way: learners may draw worse than the 104-drawing sample, and the matcher is weakest when the stroke count is off. That could widen the gap in real use. TestFlight feedback and the new drawing sample are where it shows up.

Middle options:
- ML Kit behind an opt-in toggle: rejected. Apple's label covers the whole app, so it still says "Data Collected", and the SDK and the CI gap stay.
- Defer ML Kit until after v1.0: accepted. This is the decision. Revisit it if testers find the matcher failing.
- Improve the matcher: accepted as [Improve the handwriting matcher's accuracy](../tickets/071-improve-the-handwriting-matchers-accuracy.md), which doesn't hold up v1.0.
- Gather drawings from more people: accepted as [Collect handwriting drawings from other learners](../tickets/072-collect-handwriting-drawings-from-other-learners.md).

Google opt-out inquiry: no. With ML Kit dropped, the question is moot. Even if ML Kit stayed, an informal reply would not be documented behaviour, so the label would still have to assume no opt-out.

If ML Kit returns later, the label answers are Device ID declared and linked, and Usage Data > Product Interaction not declared, as in [ml-kit-privacy.md](../assets/ml-kit-privacy.md).

Pro boundary and price: unchanged. Handwriting search stays Pro at $4.99. One flag that doesn't reopen anything: on the matcher alone, handwriting search is a weaker paid feature. [Test photo lookup on real signage](../tickets/061-test-photo-lookup-on-real-signage.md) should weigh that when it checks the price.

Surfaced:
- [Remove ML Kit from handwriting search](../tickets/070-remove-ml-kit-from-handwriting-search.md) removes the SDK, CocoaPods, the on-device seam and the `DESIGN.md` exception. It blocks [Update the privacy copy and label](../tickets/069-update-the-privacy-copy-and-label.md) and [Prepare the v1.0 release build](../tickets/054-prepare-the-v1-release-build.md).
- The copy ticket shrinks to checking that the existing privacy lines still hold and that nothing mentions ML Kit.
- The release build drops its `Podfile.lock` and on-device ML Kit checks.

CI: pending; see the Final Report.
