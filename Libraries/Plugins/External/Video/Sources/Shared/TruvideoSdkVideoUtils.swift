//
//  TruvideoSdkVideoUtils.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 12/7/23.
//

import Foundation

enum TruvideoSdkVideoUtils {
    static func outputURL(for identifier: String, fileExtension: String) -> URL {
        if #available(iOS 16.0, *) {
            return URL
                .documentsDirectory
                .appendingPathComponent(identifier)
                .appendingPathExtension(fileExtension)
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            return documentsDirectory
                .appendingPathComponent(identifier)
                .appendingPathExtension(fileExtension)
        }
    }

    static func createEmptyFile(atURL url: URL) {
        FileManager.default.createFile(atPath: url.path, contents: nil)
    }

    static func deleteFileIfExists(atURL url: URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {}
    }
}
