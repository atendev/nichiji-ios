# Nichiji design system (docs copy)

Exported from the Nichiji design system artifact. `README.md` is the brand book and the source of truth for usage rules; `tokens.json` holds every token with a usage note (light and dark values); `tokens.css` is generated from it. `components/*/README.md` give usage guidelines and `components/*/preview.html` are live HTML references (open them in a browser; they load `tokens.css` and `components/bundle.css` and need the Google Fonts stylesheet). `assets/Brand/` holds the app icons and seal mark.

Notes for the SwiftUI app:
- This is a web-format reference, not Swift code. Map `tokens.json` colors to an asset catalog with Light and Dark appearances, and the type styles to SwiftUI fonts.
- Fonts are not included. Download Shippori Mincho and Zen Kaku Gothic New (both SIL Open Font License) and bundle them in the app.
- The tab icons in the previews are stand-ins. Use SF Symbols in the app.
