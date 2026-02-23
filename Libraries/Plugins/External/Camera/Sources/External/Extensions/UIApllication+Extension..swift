//
// Copyright © 2025 TruVideo. All rights reserved.
//

import UIKit

extension UIApplication {
    /// Returns the top-most view controller in the receiver's presentation hierarchy.
    ///
    /// This computed property walks through the current view controller hierarchy to
    /// determine which view controller is currently at the top and visible to the user.
    var topMostViewController: UIViewController? {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

    /// The current interface orientation of the active foreground scene.
    var activeInterfaceOrientation: UIInterfaceOrientation {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .interfaceOrientation
            ?? .portrait
    }
}
