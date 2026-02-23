//
// Copyright © 2026 TruVideo. All rights reserved.
//

import AVFoundation
import SnapshotTesting
import SwiftUI
import Testing

@testable import TruvideoSdkCamera

@MainActor
struct PresetsViewSnapshotTests: SnapshotTestable {
    // MARK: - Properties

    var recordMode = false

    // MARK: - Tests

    @Test
    func testThatPresetsViewDisplaysAllOptions() {
        // Given
        let presets: [AVCaptureSession.Preset] = [.hd1920x1080, .hd1280x720, .vga640x480]
        let isPresented = Binding.constant(true)
        let selection = Binding.constant(AVCaptureSession.Preset.hd1280x720)

        // When
        let sut = PresetsView(presets: presets, isPresented: isPresented, selection: selection)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatPresetsViewHighlightsSelectedFHDPreset() {
        // Given
        let presets: [AVCaptureSession.Preset] = [.hd1920x1080, .hd1280x720, .vga640x480]
        let isPresented = Binding.constant(true)
        let selection = Binding.constant(AVCaptureSession.Preset.hd1920x1080)

        // When
        let sut = PresetsView(presets: presets, isPresented: isPresented, selection: selection)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatPresetsViewDisplaysTwoOptions() {
        // Given
        let presets: [AVCaptureSession.Preset] = [.hd1920x1080, .hd1280x720]
        let isPresented = Binding.constant(true)
        let selection = Binding.constant(AVCaptureSession.Preset.hd1920x1080)

        // When
        let sut = PresetsView(presets: presets, isPresented: isPresented, selection: selection)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatPresetsViewDisplaysSingleOption() {
        // Given
        let presets: [AVCaptureSession.Preset] = [.vga640x480]
        let isPresented = Binding.constant(true)
        let selection = Binding.constant(AVCaptureSession.Preset.vga640x480)

        // When
        let sut = PresetsView(presets: presets, isPresented: isPresented, selection: selection)

        // Then
        assertSnapshotForAllDevices(sut)
    }
}
