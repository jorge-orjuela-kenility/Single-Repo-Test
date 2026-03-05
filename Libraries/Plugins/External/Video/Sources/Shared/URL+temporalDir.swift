//
//  URL+temporalDir.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 10/2/24.
//

import Foundation

extension URL {
    static func defaultFileLocation(
        fileName: String = "tmp",
        fileExtension: String = "mp4",
        directory: FileManager.SearchPathDirectory
    ) -> URL {
        if #available(iOS 16.0, *) {
            switch directory {
            case .cachesDirectory:
                return URL
                    .cachesDirectory
                    .appendingPathComponent(fileName)
                    .appendingPathExtension(fileExtension)
            default:
                return URL
                    .documentsDirectory
                    .appendingPathComponent(fileName)
                    .appendingPathExtension(fileExtension)
            }
        } else {
            let paths = FileManager.default.urls(for: directory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            return documentsDirectory
                .appendingPathComponent(fileName)
                .appendingPathExtension(fileExtension)
        }
    }

    static func fileDir(fileName: String, fileExtension: String, directory: FileManager.SearchPathDirectory) -> URL {
        .defaultFileLocation(fileName: fileName, fileExtension: fileExtension, directory: directory)
    }
}
