//
// Copyright © 2024 TruVideo. All rights reserved.
//

import SwiftUI

struct ErrorView: View {
    // MARK: Properties

    /// A message to display
    let error: TruvideoSdkVideoError

    /// A callback with the recording result
    let onComplete: () -> Void

    /// The content and behavior of the view.
    var body: some View {
        Color.black
            .alert(isPresented: .constant(true), content: makeAlert)
            .ignoresSafeArea()
    }

    // MARK: Private Methods

    private func makeAlert() -> Alert {
        .init(
            title: Text("Error"),
            message: Text(error.description),
            dismissButton: .default(Text("ACCEPT")) {
                onComplete()
            }
        )
    }
}
