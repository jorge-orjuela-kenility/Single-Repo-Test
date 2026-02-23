//
// Created by TruVideo on 1/10/24.
// Copyright © 2024 TruVideo. All rights reserved.
//

import Foundation

enum Event: String {
    case truvideoFileUploaderImplementation = "TruvideoFileUploaderImplementation"
    case fileURLValidatorImplementation = "FileURLValidatorImplementation"
    case awsS3FileUploaderTask = "AWSS3FileUploaderTask"
    case truvideoSdkMediaInterfaceImp = "TruvideoSdkMediaInterfaceImp"
    case mediaGatewayImplementation = "MediaGatewayImplementation"

    // v2 log events
    case mediaInit = "event_media_init"
    case fileUploadRequestBuildCreate = "event_media_file_upload_request_build_create"
    case fileUploadRequestStreamAll = "event_media_file_upload_request_stream_all"
    case fileUploadRequestGetById = "event_media_file_upload_request_get_by_id"
    case fileUploadRequestStreamById = "event_media_file_upload_request_stream_by_id"
    case fileUploadRequestGetAll = "event_media_file_upload_request_get_all"
    case authValidate = "event_media_auth_validate"
    case fileUploadRequestStart = "event_media_file_upload_request_start"
    case fileUploadRequestCancel = "event_media_file_upload_request_cancel"
    case fileUploadRequestDelete = "event_media_file_upload_request_delete"
    case fileUploadRequestPause = "event_media_file_upload_request_pause"
    case fileUploadRequestResume = "event_media_file_upload_request_resume"
    case fileUploadRequestInsert = "event_media_file_upload_request_insert"
    case fileUploadRequestUpdate = "event_media_file_upload_request_update"
    case mediaCreate = "event_media_media_create"

    var name: String {
        self.rawValue
    }
}

enum EventMessage {
    case retryUpload
    case uploadAlreadyCompleted
    case retryUploadAlreadyCompleted
    case retryUploadAlreadyRunning
    case pauseUploadNotRunning
    case deleteUpload
    case isValidUrl
    case invalidUrl
    case fileNotFound
    case initializeTask
    case cancelTask
    case pauseTask
    case resumeTask
    case registerS3Services
    case registerS3ServicesNotAuthenticated
    case uploadIfNeeded
    case uploadIfNeededInvalidFile
    case createMedia
    case uploadFileToS3
    case uploadFileToS3Failed
    case pageSizeExceedsMaximum(size: Int, maxItemsCountPerPage: Int)
    case getMediaId(id: String)
    case searchMedia(type: String, tags: String, page: String, size: String)

    // v2 event messages
    case initMediaModule
    case buildingFileUploadRequest(filePath: String)
    case streamingAllFileUploadRequests(status: Int?)
    case gettingFileUploadRequestById(id: String)
    case streamingFileUploadRequestById(id: String)
    case gettingAllFileUploadRequests(status: Int?)
    case validateAuthFailedSdkNotAuthenticated
    case startingFileUploadRequest(id: String)
    case fileUploadRequestNotFound
    case invalidStateMustBeOn(status: Int)
    case errorUploading(id: String, errorMessage: String)
    case errorCreatingMediaEntity(id: String, errorMessage: String)
    case unknownError(id: String, message: String)
    case cancelingFileUploadRequest(id: String)
    case fileUploadRequestNotFoundById(id: String)
    case deletingFileUploadRequest(id: String)
    case pausingFileUploadRequest(id: String)
    case resumingFileUploadRequest(id: String)
    case insertingFileUploadRequest(mediaJson: String)
    case errorInsertingFileUploadRequest(mediaJson: String, exception: String)
    case updatingFileUploadRequest(mediaJson: String)
    case errorUpdatingFileUploadRequest(mediaJson: String, exception: String)
    case errorDeletingFileUploadRequest(id: String, exception: String)
    case errorGettingFileUploadRequestById(id: String, exception: String)
    case errorGettingAllFileUploadRequests(status: Int?, exception: String)
    case errorStreamingFileUploadRequestById(id: String, exception: String)
    case errorStreamingAllFileUploadRequests(status: Int?, exception: String)
    case errorMediaCreatePostRequest(error: String)
    case errorParsingCreateMediaPostRequestResponse(error: String)

    var message: String {
        switch self {
        case .retryUpload:
            "retry upload"
        case .uploadAlreadyCompleted:
            "upload already completed"
        case .retryUploadAlreadyCompleted:
            "retry upload already completed"
        case .retryUploadAlreadyRunning:
            "retry upload already running"
        case .pauseUploadNotRunning:
            "pause upload not running"
        case .deleteUpload:
            "delete upload"
        case .isValidUrl:
            "is valid url"
        case .invalidUrl:
            "invalid url"
        case .fileNotFound:
            "file not found"
        case .initializeTask:
            "initialize task"
        case .cancelTask:
            "cancel task"
        case .pauseTask:
            "pause task"
        case .resumeTask:
            "resume task"
        case .registerS3Services:
            "register S3 services"
        case .registerS3ServicesNotAuthenticated:
            "register S3 services not authenticated"
        case .uploadIfNeeded:
            "upload if needed"
        case .uploadIfNeededInvalidFile:
            "upload if needed invalid file"
        case .createMedia:
            "create media"
        case .uploadFileToS3:
            "upload file to S3"
        case .uploadFileToS3Failed:
            "upload file to S3 failed"
        case let .pageSizeExceedsMaximum(size, maxItemsCountPerPage):
            "The page size value \(size) exceeds the maximum number of items per page, " +
                "the default \(maxItemsCountPerPage) will be used"
        case let .getMediaId(id):
            "get media id: \(id)"
        case let .searchMedia(type, tags, page, size):
            "search media type: \(type), tags: \(tags), page number: \(page), size: \(size)"
        // v2 event messages
        case .initMediaModule:
            "Init media module"
        case let .buildingFileUploadRequest(filePath):
            "Building file upload request for path: \(filePath)"
        case let .streamingAllFileUploadRequests(status):
            "Streaming all file upload requests with status: \(String(describing: status))"
        case let .gettingFileUploadRequestById(id):
            "Getting file upload request by ID: \(id)"
        case let .streamingFileUploadRequestById(id):
            "Streaming file upload request by ID: \(id)"
        case let .gettingAllFileUploadRequests(status):
            "Getting all file upload requests with status: \(String(describing: status))"
        case .validateAuthFailedSdkNotAuthenticated:
            "Validate authentication failed: SDK not authenticated"
        case let .startingFileUploadRequest(id):
            "Starting file upload request: \(id)"
        case .fileUploadRequestNotFound:
            "File upload request not found"
        case let .invalidStateMustBeOn(status):
            "Invalid state. Must be on: \(status)"
        case let .errorUploading(id, errorMessage):
            "Error uploading: \(id). \(errorMessage)"
        case let .errorCreatingMediaEntity(id, errorMessage):
            "Error creating media entity: \(id). \(errorMessage)"
        case let .unknownError(id, message):
            "Unknown error: \(id). \(message)"
        case let .cancelingFileUploadRequest(id):
            "Canceling file upload request: \(id)"
        case let .fileUploadRequestNotFoundById(id):
            "File upload request not found: \(id)"
        case let .deletingFileUploadRequest(id):
            "Deleting file upload request: \(id)"
        case let .pausingFileUploadRequest(id):
            "Pausing file upload request: \(id)"
        case let .resumingFileUploadRequest(id):
            "Resuming file upload request: \(id)"
        case let .insertingFileUploadRequest(mediaJson):
            "Inserting file upload request: \(mediaJson)"
        case let .errorInsertingFileUploadRequest(mediaJson, exception):
            "Error inserting file upload request: \(mediaJson). \(exception)"
        case let .updatingFileUploadRequest(mediaJson):
            "Updating file upload request request: \(mediaJson)"
        case let .errorUpdatingFileUploadRequest(mediaJson, exception):
            "Error updating file upload request \(mediaJson). \(exception)"
        case let .errorDeletingFileUploadRequest(id, exception):
            "Error deleting file upload request: \(id). \(exception)"
        case let .errorGettingFileUploadRequestById(id, exception):
            "Error getting file upload request by ID: \(id). \(exception)"
        case let .errorGettingAllFileUploadRequests(status, exception):
            "Error getting all file upload requests with status: \(String(describing: status)). \(exception)"
        case let .errorStreamingFileUploadRequestById(id, exception):
            "Error streaming file upload request by ID: \(id). \(exception)"
        case let .errorStreamingAllFileUploadRequests(status, exception):
            "Error streaming all file upload requests with status: \(String(describing: status)). \(exception)"
        case let .errorMediaCreatePostRequest(error):
            "Error media create post request. \(error)"
        case let .errorParsingCreateMediaPostRequestResponse(error):
            "Error parsing create media post request response. \(error)"
        }
    }
}
