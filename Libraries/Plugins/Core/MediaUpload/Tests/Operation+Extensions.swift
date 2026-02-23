//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

extension Operation {
    func waitUntilFinished() async {
        if isFinished { return }

        await withCheckedContinuation { continuation in
            let previous = completionBlock
            completionBlock = {
                previous?()
                continuation.resume()
            }
        }
    }
}
