//
//  UnauthenticatedView.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 11/11/24.
//

import SwiftUI

struct UnauthenticatedView: View {
    // MARK: Properties

    /// A callback with the recording result
    var onComplete: () -> Void

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
            message: Text("Authentication required"),
            dismissButton: .default(Text("ACCEPT")) {
                onComplete()
            }
        )
    }
}

#Preview {
    UnauthenticatedView {}
}
