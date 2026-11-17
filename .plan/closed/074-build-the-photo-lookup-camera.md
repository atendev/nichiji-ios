---
id: "074"
title: Build the photo lookup camera
type: task
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

Can photo lookup open straight into Nichiji's own camera, where one shutter tap reads the photo with no "Use Photo" confirm step?

## Notes

Skills: apple. Asked for by the user after [Build photo lookup](../closed/073-build-photo-lookup.md): the system `UIImagePickerController` camera makes the learner confirm every shot with "Use Photo". Replace it with an AVFoundation camera that fills the screen. The shutter captures and reads at once, and the frozen shot stays behind a results panel holding the existing grid, count and "New to you" toggle. Retake goes back to the live camera. Keep the library pick inside the camera, the Pro gate, on-device reading, nothing saved, and capture-then-grid with no live scanning. Handle denied camera access and devices with no camera (the Simulator).

## Resolution

Yes. Photo lookup opens `PhotoLookupScreen` as a full-screen cover over a `CameraSession` (AVFoundation, rear camera, `.photo` preset). The shutter captures with the rotation coordinator's capture angle and starts the read at once, with a haptic and a short black flash. The shot stays frozen behind a results panel (reading, found count, "New to you", grid, or the no-kanji or failed note) that hugs a short grid and scrolls a long one, up to 55% of the screen. Retake calls `PhotoLookupModel.retake()`, which drops any read still running, and restarts the session. The camera also has tap to focus and expose, a flashlight when the device has one, and a library button. `CameraAccess` asks on first open, points to Settings when access is off, and offers only the library with no camera. The session stops while a result shows and when the camera closes. Nothing is saved. `PhotoLookupSheet` and the `UIImagePickerController` wrapper are gone. Pinch zoom stayed out. CI: pending; see Final Report. The camera, focus, flashlight and rotation need a device check.
