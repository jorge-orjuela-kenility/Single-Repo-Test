//
//  View+Conditionals.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 11/11/24.
//

import SwiftUI

extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, @ViewBuilder transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
