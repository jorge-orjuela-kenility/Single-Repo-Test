//
// Copyright © 2026 TruVideo. All rights reserved.
//

import CoreData
internal import CoreDataUtilities
import Foundation

final class MediaUploadManagedObject: NSManagedObject, CoreDataQueryable {
    @NSManaged var id: UUID
    @NSManaged var attempts: Int16
    @NSManaged var createdAt: Date
    @NSManaged var filePath: URL
    @NSManaged var isIncludedInReport: Bool
    @NSManaged var isLibrary: Bool
    @NSManaged var metadata: Data?
    @NSManaged var remoteId: String?
    @NSManaged var remoteFileURL: URL?
    @NSManaged var status: String
    @NSManaged var tags: Data?
    @NSManaged var updatedAt: Date

    // MARK: - Static Properties

    static var idAttribute: Attribute<UUID> {
        Attribute(\MediaUploadManagedObject.id)
    }
}
