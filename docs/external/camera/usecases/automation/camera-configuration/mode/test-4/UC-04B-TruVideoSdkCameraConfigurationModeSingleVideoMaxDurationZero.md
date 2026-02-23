# Use Case: Configuration Mode – Single Video (Max Duration = 0)

## Objective
Validate that when the SDK camera is configured with mode set to **single video** and the **maximum video duration is set to 0**, video recording cannot be started, and the SDK displays an appropriate error message indicating that videos cannot be recorded with zero duration. Photo capture must remain unavailable.

## Test Scope
**Included:**
- Verification that the Record Button is visible.
- Validation that video recording cannot start when the maximum duration is 0.
- Validation that an error message is displayed when attempting to start recording.
- Validation that no video is recorded or counted.

**Excluded:**
- Photo capture, flash, focus, zoom, quality, or lens orientation behavior.
- Audio integrity or media encoding.
- Validation of normal video duration behavior.

## Preconditions
- SDK camera initialized with single video mode.
- `maxVideoDuration` configured to **0**.
- Device has camera and microphone permissions granted.
- User is authenticated and SDK properly configured.
- App is in foreground and preview is visible.

## Expected Visible UI Elements
- Record Button: visible and enabled for user interaction.
- Media Counter (if available): must remain unchanged after attempting a video capture.

## Expected Hidden UI Elements
- Capture Button: hidden or disabled (photo capture not available).
- Mode Switcher: hidden or disabled.
- Any controls related to photo or duration adjustments.

## Interaction Rules
- Record Button
  - Tap → **must not start recording**, and the SDK must show an error message indicating that the video duration cannot be zero.
  - Video count must not increment.
- The SDK must enforce that **video recording is not allowed when max duration = 0**.

## Test Steps
1. Launch the SDK camera with single video mode active and `maxVideoDuration = 0`.
2. Verify that the Record Button is visible and enabled.
3. Tap the Record Button.
4. Confirm that video recording does not start.
5. Confirm that the SDK displays an error message stating that video duration must be greater than zero.
6. Verify that the video count remains at zero.
7. Observe SDK behavior after the failed recording attempt.

## Expected Result
- Video recording cannot start due to the zero-duration configuration.
- An error message is displayed informing the user that videos cannot be recorded with a duration of 0 seconds.
- No videos are recorded and the counter remains unchanged.
- The preview remains active and responsive throughout.

## Pass Criteria
- The SDK prevents starting video recording when `maxVideoDuration = 0`.
- The appropriate error message is displayed.
- No video media is captured or counted.
- No crash, freeze, or mode conflict occurs.

## Notes
- This test validates the enforcement of a restricted video duration in single video mode.
- For normal single video recording, refer to the standard single-video test case.
