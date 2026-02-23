# Use Case: Configuration Mode – Single Video or Picture (Max Duration = 0)

## Objective
Validate that when the SDK camera is configured with mode set to **single video or picture** and the **maximum video duration is set to 0**, video recording cannot be started, and the SDK displays an appropriate error message indicating that videos cannot be recorded with zero duration. Photo capture must remain functional, but the SDK must still enforce that only one media item can be captured in total.

## Test Scope
**Included:**
- Verification that both Capture and Record buttons are visible.
- Validation that video recording cannot start when the maximum duration is 0.
- Validation that an error message is shown when attempting to start a video recording.
- Validation that photo capture remains functional.
- Validation that only **one media item** can be captured.

**Excluded:**
- Capturing more than one media item.
- Flash, focus, zoom, quality, or lens orientation behavior.
- Audio integrity or media encoding.
- Validation of normal video duration behavior.

## Preconditions
- SDK camera initialized with single video or picture mode.
- `maxVideoDuration` configured to **0**.
- Device has camera and microphone permissions granted.
- User is authenticated and SDK properly configured.
- App is in foreground and preview is visible.

## Expected Visible UI Elements
- Capture Button: visible and enabled for photo capture.
- Record Button: visible and enabled for user interaction.
- Media Counter (if available): must remain unchanged after an attempted video capture.

## Expected Hidden UI Elements
- Mode Switcher: hidden or disabled (fixed by configuration).
- Unavailable Controls: no additional media types beyond the single capture.

## Interaction Rules
- Capture Button  
  - Tap → takes a photo, increments media count.
- Record Button  
  - Tap → **must not start recording**, and an error message must be displayed indicating that video duration cannot be zero.
  - Media count must not increment after a failed attempt.
- The SDK must enforce that only **one media item** can be captured, regardless of type.
- Video recording is strictly blocked when max duration = 0.

## Test Steps
1. Launch the SDK camera with single video or picture mode active and `maxVideoDuration = 0`.
2. Verify that both Capture and Record buttons are visible and enabled.
3. Tap the Record Button.
4. Confirm that video recording does not start.
5. Confirm that the SDK displays an error message indicating that video duration must be greater than zero.
6. Verify that the media count remains unchanged.
7. Capture a photo using the Capture Button.
8. Verify that the photo is saved successfully and the media count increments to one.
9. Attempt any additional capture (photo or video) and verify it is blocked.
10. Observe SDK behavior after the single allowed capture.

## Expected Result
- Video recording cannot start due to zero-duration configuration.
- An error message is displayed explaining that videos cannot be recorded with zero duration.
- A photo can be captured successfully.
- Only one media item can be captured; additional attempts are blocked.
- The preview remains active and responsive throughout.

## Pass Criteria
- The SDK prevents video recording when `maxVideoDuration = 0`.
- Error message is displayed exactly as expected.
- At most one media item is captured.
- Photo capture works correctly.
- No crash, freeze, or mode conflict occurs.

## Notes
- This test validates the system’s handling of zero-duration video configuration in single-media mode.
