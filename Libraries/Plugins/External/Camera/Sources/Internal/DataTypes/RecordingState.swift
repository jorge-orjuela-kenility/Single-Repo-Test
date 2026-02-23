//
// Copyright © 2026 TruVideo. All rights reserved.
//

import AVFoundation
import Foundation
internal import Utilities

/// Represents the lifecycle state of a capture/recording component.
///
/// The state machine models a simple flow from initialization to running,
/// and then to either a finished or failed condition.
enum RecordingState: Sendable {
    /// The component encountered an error.
    case failed

    /// The component completed successfully and is no longer active.
    case finished

    /// The component has been created and configured but not started.
    ///
    /// From this state you can move to `running` to begin work, or to `failed`
    /// if setup detects an unrecoverable issue.
    case initialized

    /// The component is temporarily suspended but remains configured in the session.
    ///
    /// From this state you can resume to `running` or transition to `finished`
    /// if the component is no longer needed. The device remains connected
    /// to the session during this state.
    case paused

    /// The component is actively capturing or processing.
    case running

    // MARK: - Instance methods

    /// Indicates whether a transition from the current state to a new state is permitted.
    /// Any other transition is rejected to protect lifecycle invariants.
    ///
    /// - Parameter newState: The target state to evaluate.
    /// - Returns: `true` if the transition is allowed; otherwise, `false`.
    func canTransition(to newState: RecordingState) -> Bool {
        switch (self, newState) {
        case (.initialized, .failed),
             (.initialized, .finished),
             (.initialized, .running),
             (.failed, .running),
             (.failed, .initialized),
             (.finished, .running),
             (.paused, .finished),
             (.paused, .initialized),
             (.paused, .running),
             (.running, .failed),
             (.running, .finished),
             (.running, .paused):
            true

        default:
            false
        }
    }
}
