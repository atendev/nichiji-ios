---
id: "000"
title: Phase 0 initial scope and architecture boundaries
type: grilling
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

What is the initial MVP scope, data source strategy, persistence split, privacy stance, audio/handwriting boundary, notification/widget scope, Duo layout expectation, theme behavior, and tagline for Phase 0?

## Notes

Consult `docs/DESIGN.md`, `docs/design-system`, and `docs/ui-reference`.

## Resolution

- MVP boundary: Onboarding (7 screens) plus the Today tab first. Dictionary, Review, You, and Practice are later slices, though the navigation and data models leave room for them.
- Data source: Bundle verified, legally redistributable kanji, reading, meaning, level, example-word, and stroke data so the core flow works offline.
- Persistence: SwiftData for structured learner records (learned kanji, review history, and settings needing queries) and AppStorage/UserDefaults for lightweight presentation preferences (appearance, romaji).
- Privacy: Account-free and local-first with no analytics or personal data collection.
- Audio and handwriting: Implement system Japanese speech synthesis early; defer handwriting recognition and stroke checking.
- Notifications and widgets: Include daily reminder notifications and the initial WidgetKit experience in the first implementation.
- Duo layout: Leave room in the architecture for the iPhone Duo / iPad two-pane split, but implement the single-column phone layout first.
- Themes: System, Light, and Dark modes are functional from the first pass using semantic Washi and Sumi tokens.
- Tagline: Keep "One Kanji. One Day. Every Day."
