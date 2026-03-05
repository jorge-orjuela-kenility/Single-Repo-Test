//
//  Events.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 7/26/24.
//

import Foundation

enum Event: String {
    case initVideo = "event_video_init"
    case initEditVideoScreen = "event_video_edit_screen_init"
    case getAllRequest = "event_video_request_get_all"
    case clearNoise = "event_video_clear_noise"
    case compareVideo = "event_video_compare"
    case getInfo = "event_video_get_info"
    case createThumbnail = "event_video_create_thumbnail"
    case editVideo = "event_video_edit"
    case createMergeBuilder = "event_video_merge_build_create"
    case createConcatBuilder = "event_video_concat_build_create"
    case createEncodeBuilder = "event_video_encode_build_create"
    case validateAuth = "event_video_auth_validate"
    case insertRequest = "event_video_request_insert"
    case updateRequest = "event_video_request_update"
    case getRequestById = "event_video_request_get_by_id"

    case processRequest = "event_video_request_process"
    case cancelRequest = "event_video_request_cancel"

    case mergeRequest = "event_video_merge_request"
    case mergeVideoAndAudioFailed = "event_video_merge_video_and_audio"

    case streamRequestWithStatus = "stream_request_with_status"
    case streamRequestWithID = "stream_request_with_id"

    var name: String {
        self.rawValue
    }
}

enum EventMessage {
    case initVideoModule
    case initEditVideoScreen
    case getRequestsBy(status: TruvideoSdkVideoRequest.Status)
    case clearNoise(videoPath: URL, resultPath: URL)
    case clearNoiseFailed(videoPath: URL, error: Error)
    case compare(videoPaths: [URL])
    case compareFailed(error: Error)
    case getInfo(videoPath: URL)
    case getInfoFailed(videoPath: URL, error: Error)
    case createThumbnail(videoPath: URL)
    case createThumbnailFailed(videoPath: URL, error: Error)
    case editVideo(videoPath: URL)
    case editVideoFailed(error: Error)
    case closeEditVideoScreen
    case createMergeBuilder
    case createConcatBuilder
    case createEncodeBuilder
    case notAuthenticated
    case insertRequest(id: UUID)
    case updateRequest(id: UUID)
    case getRequestBy(id: UUID)

    case streamRequestsBy(status: TruvideoSdkVideoRequest.Status?)
    case streamRequest(id: UUID)

    case processRequest(id: UUID)
    case cancelRequest(id: UUID)

    case mergeRequestFailed(error: Error)
    case mergeVideoAndAudioFailed(error: Error)

    case insertRequestFailed(error: Error)
    case processRequestFailed(error: Error)

    var message: String {
        switch self {
        case .initVideoModule:
            "Init video module"
        case .initEditVideoScreen:
            "Init edit screen called"
        case let .getRequestsBy(status):
            "Get all requests called with status: \(status)"
        case let .clearNoise(videoPath, resultPath):
            "Clear noise called with videoPath: \(videoPath), resultPath: \(resultPath)"
        case let .clearNoiseFailed(videoPath, error):
            "Error clearing noise. \(videoPath). \(error.localizedDescription)"
        case let .compare(videoPaths):
            "Compare called with videoPaths: \(videoPaths)"
        case let .compareFailed(error):
            "Error comparing videos. \(error.localizedDescription)"
        case let .getInfo(videoPath):
            "Get info called with videoPath: \(videoPath)"
        case let .getInfoFailed(videoPath, error):
            "Error getting video info: \(videoPath). \(error.localizedDescription)"
        case let .createThumbnail(videoPath):
            "Create thumbnail called with videoPath: \(videoPath)"
        case let .createThumbnailFailed(videoPath, error):
            "Error creating thumbnail: \(videoPath). \(error.localizedDescription)"
        case let .editVideo(videoPath):
            "Edit called with videoPath: \(videoPath)"
        case let .editVideoFailed(error):
            "Error editing video. \(error.localizedDescription)"
        case .createMergeBuilder:
            "Building merge builder"
        case .createConcatBuilder:
            "Building concat builder"
        case .createEncodeBuilder:
            "Building encode builder"
        case .notAuthenticated:
            "Validate authentication failed: SDK not authenticated"
        case let .insertRequest(id):
            "Insert called with video request: \(id)"
        case let .updateRequest(id):
            "Update called with video request: \(id)"
        case let .getRequestBy(id):
            "Get called with id: \(id)"
        case let .processRequest(id):
            "Process request with id: \(id)"
        case let .cancelRequest(id):
            "Cancel request with id: \(id)"
        case let .mergeRequestFailed(error):
            "Merge requeset failed. \(error.localizedDescription)"
        case let .mergeVideoAndAudioFailed(error):
            "Merge video and audio failed. \(error.localizedDescription)"
        case let .insertRequestFailed(error):
            "Insert request failed. \(error.localizedDescription)"
        case .closeEditVideoScreen:
            "Close Edit Video Screen"
        case let .processRequestFailed(error: error):
            "Process request failed. \(error)"
        case let .streamRequestsBy(status):
            "Stream requests with \(String(describing: status))"
        case let .streamRequest(id):
            "Stream requests with id \(id)"
        }
    }
}
