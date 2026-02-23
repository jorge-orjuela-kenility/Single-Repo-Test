# Use Case: View Video Controls Inside Gallery Video Viewer

## Objective
Validate that after recording multiple videos and opening one from the Gallery, tapping on the video while it is displayed in the viewer reveals all expected playback controls. These controls must include: play/pause, progress bar, jump backward 10 seconds, jump forward 10 seconds, and any additional SDK-defined video controls.

## Test Scope
**Included:**
- Capturing at least two or three videos.
- Opening the Gallery and selecting a specific video.
- Tapping inside the video viewer to reveal playback controls.
- Verification of all expected playback controls.
- Visibility and functionality of:
  - Play/Pause button
  - Progress bar / timeline scrubber
  - Jump Backward 10 seconds
  - Jump Forward 10 seconds
  - Additional SDK playback options (if applicable)

**Excluded:**
- Photo viewing behavior.
- Uploading, deleting, or editing media.
- Orientation testing (covered in separate cases).
- External gallery or system video player interactions.

## Preconditions
- User is authenticated.
- SDK camera is initialized and active.
- At least **2 or 3 videos have been recorded** during this session.
- Device has storage permissions granted.
- Gallery contains at least one playable video.

## Expected Visible UI Elements
- **Video Viewer**
  - Displays selected video in full screen.
- **Playback Controls** (when tapped inside the video viewer)
  - Play/Pause button
  - Timeline scrubber / progress bar
  - 10s Backward button
  - 10s Forward button
  - Any additional SDK controls (speed, mute, etc.)
- **Close (X) Button**
  - Always visible and functional.

## Expected Hidden UI Elements
- Camera UI elements (flash, capture, zoom, etc.)
- Gallery counters
- Photo-only controls

## Interaction Rules
- **Video Opening**
  - Tapping a video in the Gallery opens it in full-screen playback mode.
- **Control Reveal**
  - Tapping anywhere on the video while in the viewer must show:
    - Play/Pause
    - Progress bar
    - Jump -10 seconds
    - Jump +10 seconds
- **Playback Behavior**
  - Controls must remain visible for a reasonable timeout before auto-hiding.
  - Pressing Backward/Forward must adjust playback correctly.
  - Pressing Play/Pause must toggle playback state.
- **Close (X) Button**
  - Returns to the Gallery video list when tapped.

## Test Steps
1. Launch the SDK camera.
2. Record **at least 2 or 3 videos**.
3. Tap the Gallery icon to access the video list.
4. Select the **first recorded video**.
5. Verify that the video opens correctly in the viewer.
6. Tap once on the video (anywhere inside the viewer).
7. Confirm that all playback controls appear:
   - Play/Pause button  
   - Timeline scrubber / progress bar  
   - 10 seconds backward button  
   - 10 seconds forward button  
   - Additional SDK controls (if provided)
8. Tap the 10s Backward button → confirm playback rewinds correctly.
9. Tap the 10s Forward button → confirm playback advances correctly.
10. Tap Play/Pause → verify the video toggles between play and pause.
11. Wait for the controls to auto-hide (if applicable).
12. Tap again on the video → controls must reappear.
13. Tap the Close (X) button to exit viewer.
14. Confirm user returns to the Gallery video list.

## Expected Result
- First video opens correctly in full-screen viewer.
- Tapping inside the viewer reliably reveals all playback controls.
- Playback controls function correctly:
  - Play/Pause toggles playback.
  - 10s Forward advances video.
  - 10s Back rewinds video.
  - Progress bar updates correctly during playback.
- Controls hide and reappear as designed.
- Viewer closes correctly and returns to video list.

## Pass Criteria
- Video loads and plays without issues.
- All playback controls appear when tapping the screen.
- All playback controls function as expected.
- No broken icons, UI glitches, freezes, or playback failures occur.
- Navigation back to Gallery works correctly.

## Notes
- Recommended to test with videos of different durations.
- Validate behavior after scrubbing near the beginning or end of the video.
- Consider testing on devices with varying aspect ratios.
