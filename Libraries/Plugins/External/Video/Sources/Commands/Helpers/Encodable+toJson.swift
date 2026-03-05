//
//  Encodable+toJson.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 5/3/24.
//

import Foundation

extension Encodable {
    var jsonRepresentation: String? {
        guard
            let data = try? JSONEncoder().encode(self)
        else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
