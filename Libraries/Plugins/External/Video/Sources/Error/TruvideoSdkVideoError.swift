//
//  TruvideoSdkVideoError.swift
//  TruvideoSdkNoiseCancelling
//
//  Created by Luis Francisco Piura Mejia on 24/10/23.
//

import Foundation

/// `TruvideoSdkVideo` error cases
public enum TruvideoSdkVideoError: Error, Equatable {
    /// `TruvideoSdkVideo` internal configuration error
    case configurationError

    /// `TruvideoSdkVideo` failed to process the input file
    case unableToProcessInput

    /// `TruvideoSdkVideo` failed to process the output file
    case unableToProcessOutput

    /// The clean action is already in progress
    case processingInProgress

    /// The user is not authenticated
    case userNotAuthenticated

    /// The provided file is not a video
    case invalidFile

    /// `TruvideoSdkVideo` failed during noise cancellation process
    case unableToProcessFile

    /// `TruvideoSdkVideo` failed to get the video track from an input while merging because one or more of the videos
    /// did not have a video track
    case missingVideoTrackToMerge

    /// `TruvideoSdkVideo` did not know the video codec format
    case unknownVideoCodec

    /// `TruvideoSdkVideo` did not know the audio codec format
    case unknownAudioCodec

    /// `TruvideoSdkVideo` failed while processing the merge command
    case mergeFailed

    /// `TruvideoSdkVideo` failed while processing the concat command
    case concatFailed

    /// `TruvideoSdkVideo` failed while processing the encoding command
    case encodingFailed

    /// `TruvideoSdkVideo` failed while processing the get information command
    case getInformationFailed

    /// `TruvideoSdkVideo` did not process concat due to
    case invalidInputFiles(reason: InvalidInputFilesReason)

    /// Reason why concat command was not processed
    public enum InvalidInputFilesReason {
        /// The input videos did not have the same resolution
        /// This will happen if the list of input videos have different orientations or
        /// all of them have the same orientation with different widths or heights
        case differentResolutions
        /// The input videos has different audio layers
        /// This will happen if the list of videos input videos have muted videos mixed with videos with sound
        case differentAudioLayers
        /// The input videos have different codecs for audio or video
        case differentCodecs
        /// The input files video contains at least one non-existing file
        case inputContainsNonExistingFiles
        /// The input file metadata was not generated
        case noMetadataGenerated
        /// The input files count was less than two
        case notEnoughVideos
        /// The input files have different frame rates
        case differentFrameRates
        /// The input files have different video tracks
        case differentVideoTracks
        /// The input files have different audio tracks
        case differentAudioTracks
        /// The input files have different formats
        case differentFormats
    }

    /// `TruvideoSdkVideo`the provided file was not found
    case notFoundVideo

    /// `TruvideoSdkVideo`the provided file was not found
    case unableToDeleteExistingThumbnail

    /// `TruvideoSdkVideo` the provided width is negative
    case invalidThumbnailWidth

    /// `TruvideoSdkVideo` the provided height is negative
    case invalidThumbnailHeight

    /// `TruvideoSdkVideo` the provided height/width is either zero, negative or an odd number
    case invalidResolution

    /// `TruvideoSdkVideo` the provided position is invalid
    case invalidPositionInVideo

    /// `TruvideoSdkVideo` failed while processing the thumbnail generation command
    case thumbnailGenerationFailed

    /// `TruvideoSdkVideo` failed because the trim range passed was not valid
    case invalidTrimRange

    /// `TruvideoSdkVideo` failed while performing the trim acction
    case trimFailed

    /// The operation is still in progress
    case operationStillsInProgress

    /// The operation is already completed
    case operationAlreadyCompleted

    /// The operation was not found
    case operationNotFound

    /// The operation was not processing when cancel operation was called
    case operationMustBeProcessingToBeCancelled

    var description: String {
        switch self {
        case .trimFailed:
            "An error occurred while editing the video. Please try again."
        default:
            "An error occurred. Please try again."
        }
    }
}
