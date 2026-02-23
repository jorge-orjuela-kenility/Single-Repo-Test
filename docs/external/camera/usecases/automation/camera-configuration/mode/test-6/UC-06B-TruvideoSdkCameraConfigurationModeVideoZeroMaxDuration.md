# Use Case: Configuration Mode – Video Only (Max Duration = 0)

## Objective
Validate that when the SDK camera is configured with mode set to **video only** and the **maximum video duration is set to 0**, video recording cannot be started. The SDK must display an appropriate error message indicating that videos cannot be recorded with zero duration. No videos should be saved, and the media counter must remain unchanged throughout the test.

## Test Scope

**Included:**
- Verification that the Record Button is visible.
- Validation that video recording cannot start when the maximum duration is 0.
- Validation that the SDK displays an error message when video recording is attempted.
- Validation that no media is created or counted.

**Excluded:**
- Photo capture (not available in this mode).
- Flash, focus, zoom, quality, or lens orientation behavior.
- Audio integrity or media encoding.
- Validation of standard video duration enforcement.

## Preconditions
- SDK camera initialized with video-only mode.
- `maxVideoDuration` configured to **0**.
- Device has camera and microphone permissions granted.
- User is authenticated and SDK properly configured.
- App is in foreground with camera preview visible.

## Expected Visible UI Elements
- Record Button: visible and enabled for user interaction.
- Media Counter (if available): remains at `0` for the entire test.

## Expected Hidden UI Elements
- Capture Button: hidden or disabled (photo capture not available).
- Mode Switcher: hidden or disabled.
- Any UI related to photo capture or mixed media modes.

## Interaction Rules
- **Record Button**
  - Tap → must **not** start recording.
  - An error message must be displayed indicating that video duration cannot be zero.
  - Media counter must not increment.
- No video files must be created under any circumstance.
- Repeated attempts to start a recording must be consistently blocked.

## Test Steps
1. Launch the SDK camera with **video-only mode** active and `maxVideoDuration = 0`.
2. Verify that the Record Button is visible and enabled.
3. Tap the Record Button.
4. Confirm that video recording does **not** start.
5. Verify the SDK displays an error message explaining that video duration cannot be zero.
6. Confirm that the media counter remains unchanged.
7. Attempt a second recording attempt.
8. Verify the same behavior: recording does not start and the error message appears.
9. Confirm no video files are generated and no count increments.
10. Observe SDK behavior and UI responsiveness after repeated blocked attempts.

## Expected Result
- Video recording is completely blocked due to zero-duration configuration.
- An appropriate and clear error message is shown every time the Record Button is tapped.
- Media counter remains unchanged.
- No media files are created.
- The camera preview stays active and responsive.

## Pass Criteria
- The SDK prevents all attempts to start a video recording when `maxVideoDuration = 0`.
- Error message appears consistently.
- No media count increments.
- No video artifacts or partially saved files exist.
- No crash, freeze, or UI malfunction occurs.

## Notes
- This test validates zero-duration behavior specifically in **video-only mode**.
