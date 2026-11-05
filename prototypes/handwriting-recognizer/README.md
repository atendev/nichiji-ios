# PROTOTYPE: handwriting recognizer

Throwaway. Lives on the `prototype/handwriting-recognizer` branch only, never on `main`.

Question (ticket "Choose the handwriting recognizer"): which reads a learner's drawn kanji more accurately on the same drawn test set, a matcher against the bundled KanjiVG strokes or Google ML Kit Digital Ink Recognition?

## KanjiVG matcher

```sh
python3 -I -B prototypes/handwriting-recognizer/build_templates.py   # writes templates.js (gitignored, 5 MB)
```

Open `index.html` in a browser. To draw with a finger on a phone, serve the folder on your Tailscale address and open it from the phone:

```sh
python3 -I -B prototypes/handwriting-recognizer/serve.py "$(tailscale ip -4)" 8000
```

**Send to laptop** posts the test set to `serve.py`, which saves it as `handwriting-testset.json` in this folder. It refuses a set smaller than the saved one.

- **Draw test set** walks 104 targets: 80 spread across the frequency list, plus 24 confusables (土士, 未末, 人入, 大犬太…). Save & next stores each drawing in this browser's `localStorage`. **Export test set** downloads `handwriting-testset.json`, which ML Kit also reads.
- **Free play** shows the top 10 from all four matcher variants as you draw.
- **Score** reports top-1, top-5 and top-10 accuracy per variant and draws every miss.

From the command line:

```sh
node prototypes/handwriting-recognizer/score.js handwriting-testset.json
node prototypes/handwriting-recognizer/score.js --synthetic   # pipeline check on distorted templates, not the verdict
```

The matcher resamples each stroke to 12 points, normalizes the drawing (bounding box or moments), keeps candidates within 2 strokes of the drawn count, and scores stroke pairs by mean point distance, with reversed strokes allowed at a small penalty. "Strict order" pairs strokes by position; "free order" finds the best stroke assignment, so stroke-order mistakes still match. "bbox + free order" is the primary variant, fixed before drawing; the other three are reference only. A drawing more than 2 strokes off its kanji's count can't match, by design.

## ML Kit harness

`mlkit-harness/` is a throwaway SwiftUI app (xcodegen + CocoaPods, `GoogleMLKit/DigitalInkRecognition`). Pushing changes under it to this branch makes `.github/workflows/prototype-mlkit-harness.yml` build an unsigned IPA on the `xcode-27` runner (artifact `MLKitHarness-unsigned-ipa`). Sideload it the same way as Nichiji, then:

1. Turn on Settings > Privacy & Security > App Privacy Report before the first launch.
2. Download the ja model, import `handwriting-testset.json` from Files, and run it.
3. Share the results text back. The primary figure keeps only ML Kit candidates that are kanji the app ships (the export's `pool`), which is what search would show, so it compares fairly with the matcher's pool of 2,383. Raw ML Kit figures are listed too. The App Privacy Report lists every domain the harness contacted, which is the network traffic the ticket asks for.

## Test set format

```json
{ "version": 1, "canvas": { "width": 360, "height": 360 },
  "samples": [{ "target": "日", "strokes": [[[x, y, t], ...], ...] }] }
```

`x` and `y` are CSS px on the canvas, and `t` is ms since the sample's first touch, which ML Kit's `StrokePoint` takes as is.
