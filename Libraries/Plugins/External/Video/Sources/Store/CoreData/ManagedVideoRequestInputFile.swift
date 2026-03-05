//
//  ManagedVideoRequestInputFile.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 21/2/24.
//

import CoreData

@objc(ManagedVideoRequestInputFile)
class ManagedVideoRequestInputFile: NSManagedObject {
    @NSManaged var path: URL
    @NSManaged var index: Int16
    @NSManaged var pathBookmark: Data?
    @NSManaged var request: ManagedVideoRequest

    var localVideoRequestFile: LocalVideoRequestFile {
        .init(path: getBookmarkedURL() ?? path, index: Int(index))
    }

    private func getBookmarkedURL() -> URL? {
        guard let pathBookmark else { return nil }
        var isStale = false
        // Recover the file URL from its URL bookmark data
        return try? URL(resolvingBookmarkData: pathBookmark, bookmarkDataIsStale: &isStale)
    }
}

struct LocalVideoRequestFile: Hashable {
    var path: URL
    var index: Int
}
