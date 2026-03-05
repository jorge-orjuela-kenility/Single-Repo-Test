//
//  TruvideoSdkVideoFileDescriptor.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 10/2/24.
//

import Foundation

enum FileExtension: String {
    case mp4
    case jpg
}

public enum TruvideoSdkVideoFileDescriptor: Hashable {
    case cache(fileName: String)
    case files(fileName: String)
    case custom(rawPath: String)

    func url(fileExtension: String) -> URL? {
        switch self {
        case let .cache(fileName),
             let .files(fileName):
            URL.fileDir(fileName: fileName, fileExtension: fileExtension, directory: directory)
        case let .custom(rawPath):
            URL(string: rawPath + "." + fileExtension)
        }
    }

    var directory: FileManager.SearchPathDirectory {
        switch self {
        case .cache:
            .cachesDirectory
        case .files:
            .documentDirectory
        default:
            .documentDirectory
        }
    }

    static func instantiate(
        with fileName: String,
        fileDescriptor: NSTruvideoSdkVideoFileDescriptor
    ) -> TruvideoSdkVideoFileDescriptor {
        switch fileDescriptor {
        case .cache:
            .cache(fileName: fileName)
        case .files:
            .files(fileName: fileName)
        case .custom:
            .custom(rawPath: fileName)
        }
    }
}

@objc public enum NSTruvideoSdkVideoFileDescriptor: Int {
    case cache
    case files
    case custom
}
