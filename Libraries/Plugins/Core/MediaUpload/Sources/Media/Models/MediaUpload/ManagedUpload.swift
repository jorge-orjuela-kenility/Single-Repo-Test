//
// Copyright © 2026 TruVideo. All rights reserved.
//

import CoreData
import Foundation

@objc(ManagedUpload)
public class ManagedUpload: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var filePath: URL
    @NSManaged public var retryCount: Int16
    @NSManaged public var status: Int16
    @NSManaged public var createdAt: Double
    @NSManaged public var updatedAt: Double
    @NSManaged public var progress: Double
    @NSManaged public var cloudServiceId: String?
    @NSManaged public var errorMessage: String?
    @NSManaged public var remoteCreationDate: String?
    @NSManaged public var remoteId: String?
    @NSManaged public var remoteURL: URL?
    @NSManaged public var bookmarkData: Data?
    @NSManaged public var tags: Data?
    @NSManaged public var metadata: Data?
    @NSManaged public var transcriptURL: String?
    @NSManaged public var transcriptLength: Float
    @NSManaged public var includeInReport: String?
    @NSManaged public var isLibrary: String?
}
