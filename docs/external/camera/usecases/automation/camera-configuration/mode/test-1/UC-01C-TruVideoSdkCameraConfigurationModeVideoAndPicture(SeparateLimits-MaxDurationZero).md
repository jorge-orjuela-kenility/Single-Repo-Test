# Use Case: Configuration Mode – Video and Picture (Separate Limits, Max Duration = 0)

## Objective
Validate that when the SDK camera is configured with **video and picture mode using separate limits** and **maximum video duration set to 0**, any attempt to start video recording is blocked, and an appropriate error message is displayed indicating that videos cannot be recorded with zero allowed duration.

## Test Scope
**Included:**
- Verification that both photo and video buttons are visible.
- Validation that photo capture remains functional.
- Validation that video recording cannot start when max video duration is 0.
- Validation that an error message is displayed when attempting to record a video.
- Validation that video count does not increase after a blocked recording attempt.

**Excluded:**
- Photo/video quality validation.
- Behavior related to flash, zoom, focus, lenses, or orientation.
- Audio integrity or encoding details.

## Preconditions
- SDK camera launched in video and picture mode with separate limits.
- `maxVideoDuration = 0`.
- Device has camera and microphone permissions granted.
- User is authenticated and SDK is properly initialized.
- App is in foreground and preview is visible.

## Expected Visible UI Elements
- Capture Button: visible and enabled for photo capture.
- Record Button: visible and enabled, but recording must not start.
- Media Counter: visible and does not increment for video attempts.

## Expected Hidden UI Elements
- Mode Switcher: hidden or disabled by configuration.
- Any controls related to video duration configuration.

## Interaction Rules
- Capture Button  
  - Tap → takes a photo, increments picture count.
- Record Button  
  - Tap → must NOT start recording.
  - SDK must show an error message indicating the video duration cannot be zero.
  - Video count must not increment.
- SDK must enforce the restriction: **videos cannot be recorded when max duration = 0**.

## Test Steps
1. Launch the SDK camera with video and picture mode (separate limits) and `maxVideoDuration = 0`.
2. Verify both Capture and Record buttons are visible and enabled.
3. Tap the Capture button and confirm a photo is taken successfully.
4. Tap the Record button.
5. Verify that video recording does not start.
6. Verify that the SDK displays an error message explaining that the video duration must be greater than zero.
7. Confirm that the video count remains unchanged.
8. Confirm that the photo count remains unaffected.
9. Verify that the preview remains active and the UI stays responsive.

## Expected Result
- Photo capture works normally.
- Attempting to record a video triggers an error message.
- No recording is started.
- Video count does not increase.
- The camera preview remains active without errors or instability.

## Pass Criteria
- The SDK prevents starting video recording when `maxVideoDuration = 0`.
- The appropriate error message is displayed to the user.
- No video media is recorded or counted.
- No crash, freeze, or unexpected behavior occurs.

## Notes
- This test validates the system’s handling of an invalid video duration configuration.
- This scenario applies only when separate photo/video limits are enabled.
