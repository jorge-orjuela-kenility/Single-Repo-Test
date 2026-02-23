## Snapshot Testing Device Requirements

The snapshot tests included in this SDK are device-specific. They are validated only on the following simulator configurations:

* **iPhone:** iPhone 16 Pro
* **iPad:** iPad 13-inch M4

Running the snapshot suite on any other device, screen size, or resolution may produce inconsistent results, layout drift, or invalid diffs.

To ensure stable and reproducible snapshots:

1. Configure your local environment and CI to use the supported simulator models.
2. Avoid updating snapshots from unsupported devices.
3. When adding new snapshot tests, validate them on the approved device presets only.

If new device sizes need to be supported, update the snapshot baseline and this section accordingly.

## Running Tests

### From Xcode

1. Select the `TruvideoSdkCameraSnapshotTests` scheme
2. Choose the appropriate simulator (iPhone 16 Pro or iPad 13-inch M4)
3. Run tests with `Cmd + U`

### From Command Line

```bash
# Run on iPhone 16 Pro
xcodebuild test \
  -scheme TruvideoSdkCamera \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:TruvideoSdkCameraSnapshotTests

# Run on iPad 13-inch M4
xcodebuild test \
  -scheme TruvideoSdkCamera \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' \
  -only-testing:TruvideoSdkCameraSnapshotTests
```

## Recording New Snapshots

When adding new tests or updating reference images, you need to record new snapshot reference images. Tests conform to the `SnapshotTestable` protocol which provides a `recordMode` property to enable recording.

### Steps to Record New Snapshots

1. **Override `recordMode`** in your test struct to enable recording:

```swift
@MainActor
struct MyNewSnapshotTests: SnapshotTestable {
    var recordMode: Bool { true }  // Enable recording mode
    
    @Test
    func testMyNewFeature() async throws {
        // ... setup code ...
        let sut = CameraView(viewModel: viewModel)
        assertSnapshotForAllDevices(sut)  // Will record new snapshots
    }
}
```

2. **Run the tests** on the supported devices
3. **Review the generated images** in `__Snapshots__/` directory
4. **Revert `recordMode`** back to `false` (or remove the override to use the default)
5. **Commit the new reference images** along with your test changes

## Test Utilities

### `SnapshotTestable` Protocol

All snapshot test structs conform to `SnapshotTestable`, which provides:

- **`assertSnapshotForAllDevices(_:)`** - Device-aware snapshot assertion that automatically detects iPhone/iPad and uses the correct dimensions
- **`recordMode`** - Property to enable recording mode (defaults to `false`)

```swift
@MainActor
struct MySnapshotTests: SnapshotTestable {
    @Test
    func testMyFeature() async throws {
        let sut = CameraView(viewModel: viewModel)
        assertSnapshotForAllDevices(sut)  // Automatically handles device detection
    }
}
```

### `MockMediaFactory`

Creates mock media items for testing:

```swift
// Create a mock photo
let photo = MockMediaFactory.createMockPhotoMedia()

// Create a mock video clip
let clip = MockMediaFactory.createMockClipMedia(duration: 10.0)
```
