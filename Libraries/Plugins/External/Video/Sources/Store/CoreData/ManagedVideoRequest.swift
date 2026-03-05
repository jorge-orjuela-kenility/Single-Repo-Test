//
//  ManagedVideoRequest.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 21/2/24.
//

import CoreData

@objc(ManagedVideoRequest)
class ManagedVideoRequest: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var status: Int16
    @NSManaged var outputPath: URL
    @NSManaged var outputBookmark: Data?
    @NSManaged var type: String
    @NSManaged var rawData: String?
    @NSManaged var processId: String?
    @NSManaged var error: String?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var inputFiles: Set<ManagedVideoRequestInputFile>
}

extension ManagedVideoRequest {
    var localVideoRequest: LocalVideoRequest? {
        guard
            let status = LocalVideoRequest.Status(rawValue: Int(status)),
            let type = LocalVideoRequest.OperationType(rawValue: type)
        else {
            return nil
        }
        return .init(
            id: id,
            status: status,
            outputPath: getBookmarkedURL() ?? outputPath,
            output: .custom(rawPath: outputPath.deletingPathExtension().path),
            type: type,
            error: error,
            inputFiles: inputFiles.map(\.localVideoRequestFile).sorted {
                $0.index < $1.index
            },
            rawData: rawData,
            processId: processId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func insertUpload(context: NSManagedObjectContext, request: LocalVideoRequest) {
        let managedLocalRequest = ManagedVideoRequest(context: context)
        managedLocalRequest.id = request.id
        managedLocalRequest.rawData = request.rawData
        managedLocalRequest.status = Int16(request.status.rawValue)
        managedLocalRequest.type = request.type.rawValue
        managedLocalRequest.outputPath = request.outputPath
        managedLocalRequest.outputBookmark = request.outputPath.bookmark
        managedLocalRequest.createdAt = request.createdAt
        managedLocalRequest.updatedAt = request.updatedAt

        managedLocalRequest.inputFiles = Set(request.inputFiles.enumerated().map {
            let inputFile = ManagedVideoRequestInputFile(context: context)
            inputFile.path = $1.path
            inputFile.pathBookmark = $1.path.bookmark
            inputFile.index = Int16($0)
            inputFile.request = managedLocalRequest
            return inputFile
        })
    }

    static func findBy(id: UUID, in context: NSManagedObjectContext) throws -> ManagedVideoRequest? {
        let request = NSFetchRequest<ManagedVideoRequest>(entityName: entity().name!)
        request.predicate = .init(format: "%K = %@", argumentArray: [#keyPath(ManagedVideoRequest.id), id])
        return try context.fetch(request).first
    }

    static func getRequestBy(id: UUID, context: NSManagedObjectContext) -> ManagedVideoRequest? {
        let request = NSFetchRequest<ManagedVideoRequest>(entityName: entity().name!)
        request.predicate = .init(format: "%K = %@", argumentArray: [#keyPath(ManagedVideoRequest.id), id])
        let results = try? context.fetch(request)
        return results?.first
    }

    static func getRequestsBy(
        status: LocalVideoRequest.Status,
        context: NSManagedObjectContext
    ) -> [ManagedVideoRequest] {
        let request = NSFetchRequest<ManagedVideoRequest>(entityName: entity().name!)
        request.predicate = .init(
            format: "%K = %@", argumentArray: [#keyPath(ManagedVideoRequest.status), status.rawValue]
        )
        return (try? context.fetch(request)) ?? []
    }

    static func findAll(in context: NSManagedObjectContext) throws -> [ManagedVideoRequest] {
        let request = NSFetchRequest<ManagedVideoRequest>(entityName: entity().name!)
        return try context.fetch(request)
    }

    static func findBy(
        status: TruvideoSdkVideoRequest.Status,
        in context: NSManagedObjectContext
    ) throws -> [ManagedVideoRequest] {
        let request = NSFetchRequest<ManagedVideoRequest>(entityName: entity().name!)
        request.predicate = .init(
            format: "%K = %@",
            argumentArray: [#keyPath(ManagedVideoRequest.status), status.rawValue]
        )
        return try context.fetch(request)
    }

    private func getBookmarkedURL() -> URL? {
        guard let outputBookmark else { return nil }
        var isStale = false
        // Recover the file URL from its URL bookmark data
        return try? URL(resolvingBookmarkData: outputBookmark, bookmarkDataIsStale: &isStale)
    }
}

private extension URL {
    var bookmark: Data? {
        try? bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
}

struct LocalVideoRequest: Hashable {
    enum Status: Int {
        case processing = 0
        case error
        case cancelled
        case completed
        case idle
    }

    enum OperationType: String {
        case encode
        case merge
        case concat
    }

    var id: UUID
    var status: Status
    var outputPath: URL
    var output: TruvideoSdkVideoFileDescriptor
    var type: OperationType
    var error: String?
    var inputFiles: [LocalVideoRequestFile]
    var rawData: String?
    var processId: String?
    var createdAt: Date
    var updatedAt: Date
}
