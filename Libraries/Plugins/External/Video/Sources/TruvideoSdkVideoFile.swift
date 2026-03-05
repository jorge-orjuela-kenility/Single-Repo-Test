//
//  TruvideoSdkVideoFile.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 10/2/24.
//

import Foundation

@objc public class TruvideoSdkVideoFile: NSObject {
    let url: URL

    public init(url: URL) {
        self.url = url
    }

    public init(path: String) throws {
        guard let url = URL(string: path) else {
            throw TruvideoSdkVideoError.invalidFile
        }

        self.url = url
    }

    @objc public static func instantiate(url: URL) -> TruvideoSdkVideoFile {
        .init(url: url)
    }

    @objc public static func instantiate(path: String) throws -> TruvideoSdkVideoFile {
        try .init(path: path)
    }

    var fileExtension: String {
        url.pathExtension
    }
}
