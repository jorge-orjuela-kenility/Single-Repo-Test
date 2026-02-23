//
// Copyright © 2025 TruVideo. All rights reserved.
//

import SnapshotTesting
import SwiftUI
import Testing
import TruvideoSdkCamera

protocol SnapshotTestable {
    /// Whether this test file should record (overwrite) snapshots.
    /// Defaults to `false`.
    var recordMode: Bool { get }
}

extension SnapshotTestable {
    var recordMode: Bool { false }

    func assertSnapshotForAllDevices(
        _ view: some View,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line,
        orientation: TruvideoSdkCameraOrientation = .portrait
    ) {
        guard let model = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] else {
            Issue.record("No simulator model identifier detected.")
            return
        }

        guard let device = SnapshotDevice.current,
              model == device.expectedModelIdentifier else {
            Issue.record(
                """
                Snapshot tests only run on: \(SnapshotDevice.iPad13InchM4.displayName) and \(SnapshotDevice.iPhone16Pro
                    .displayName)).
                Current device: \(model)
                """
            )
            return
        }

        let frame: SwiftUISnapshotLayout = switch orientation {
        case .landscapeLeft, .landscapeRight:
            .fixed(width: device.size.height, height: device.size.width)

        default:
            .fixed(width: device.size.width, height: device.size.height)
        }

        assertSnapshot(
            of: view,
            as: .image(layout: frame),
            named: device.suffix,
            record: recordMode,
            file: file,
            testName: testName,
            line: line
        )
    }
}
