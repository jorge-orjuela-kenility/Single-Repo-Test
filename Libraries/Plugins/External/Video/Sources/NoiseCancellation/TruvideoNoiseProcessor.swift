//
//  TruvideoNoiseProcessor.swift
//  TruvideoSdkNoiseCancelling
//
//  Created by Luis Francisco Piura Mejia on 18/10/23.
//

import AudioToolbox
import AVFoundation

/// An `TruVideoNoiseProcessor` is a processor in charge to take
/// and process a chunk of buffers and returns the processed buffer
/// with the background noise cancelled.
class TruVideoNoiseProcessor {
    private let bufferSize: UInt
    private let frameDuration: UInt
    private var sessionId: KrispAudioSessionID?
    private let modelName: String
    private let sampleRate: UInt

    // MARK: Initializers

    /// Creates a new instance of the `TruVideoNoiseProcessor` with the given
    /// model, sample and frame duration-
    ///
    /// - Parameters:
    ///   - modelName: The name of the model to use when filtering the noise.
    ///   - sampleRate: The rate used by the audio.
    ///   - frameDuration: The duration of each frame.
    init(modelName: String, sampleRate: UInt, frameDuration: UInt) {
        self.bufferSize = UInt(sampleRate * frameDuration / 1000)
        self.frameDuration = frameDuration
        self.modelName = modelName
        self.sampleRate = sampleRate
    }

    // MARK: Instance methods

    /// Ends the current Krisp session or throws an error if something fails.
    func endSession() throws {
        krispAudioNcCloseSession(sessionId)
        if krispAudioGlobalDestroy() != 0 {
            throw TruvideoSdkVideoError.configurationError
        }
    }

    /// Process the current audio buffer by calling `krispAudioNcCleanAmbientNoise` and cleaning
    /// any noise from the background.
    ///
    /// - Parameters:
    ///    - bufferIn: The original piece of the audio buffer.
    ///    - bufferOut: The processed buffer.
    func process(bufferIn: AVAudioPCMBuffer, bufferOut: inout AVAudioPCMBuffer) {
        if let floatData = bufferIn.floatChannelData {
            krispAudioNcCleanAmbientNoiseFloat(
                sessionId,
                floatData.pointee,
                UInt32(bufferSize),
                bufferOut.floatChannelData?.pointee,
                UInt32(bufferSize)
            )
        } else if let int16Data = bufferIn.int16ChannelData {
            krispAudioNcCleanAmbientNoiseInt16(
                sessionId,
                int16Data.pointee,
                UInt32(bufferSize),
                bufferOut.int16ChannelData?.pointee,
                UInt32(bufferSize)
            )
        } else {
            print("Only PCM float32 & int16 are supported, please contact to CIT team for support")
        }
    }

    /// Starts a new session.
    func startSession() throws {
        let bundle = Bundle(for: TruvideoSdkVideoProvider.self)

        guard
            let resourceURL = bundle.resourceURL?.path.appending("/" + modelName)
        else {
            throw TruvideoSdkVideoError.configurationError
        }

        var status: Int32 = -1
        resourceURL.withWideChars { character in
            status = krispAudioSetModel(character, modelName.cString(using: .utf8))
        }

        if status != 0 {
            throw TruvideoSdkVideoError.configurationError
        }

        sessionId = krispAudioNcCreateSession(
            sampleRate.krispRate,
            sampleRate.krispRate,
            frameDuration.krispFrameDuration,
            modelName.cString(using: .utf8)
        )

        if sessionId == nil {
            throw TruvideoSdkVideoError.configurationError
        }
    }
}

extension String {
    /// Calls the given closure with a pointer to the contents of the string,
    /// represented as a null-terminated wchar_t array.
    func withWideChars<Result>(_ body: (UnsafePointer<wchar_t>) -> Result) -> Result {
        let u32 = unicodeScalars.map { wchar_t(bitPattern: $0.value) } + [0]
        return u32.withUnsafeBufferPointer { body($0.baseAddress!) }
    }
}

private extension UInt {
    var krispFrameDuration: KrispAudioFrameDuration {
        switch self {
        case 10: KRISP_AUDIO_FRAME_DURATION_10MS
        case 15: KRISP_AUDIO_FRAME_DURATION_15MS
        case 20: KRISP_AUDIO_FRAME_DURATION_20MS
        case 30: KRISP_AUDIO_FRAME_DURATION_30MS
        case 32: KRISP_AUDIO_FRAME_DURATION_32MS
        case 40: KRISP_AUDIO_FRAME_DURATION_40MS
        default: KRISP_AUDIO_FRAME_DURATION_10MS
        }
    }

    var krispRate: KrispAudioSamplingRate {
        switch self {
        case 8000: KRISP_AUDIO_SAMPLING_RATE_8000HZ
        case 12000: KRISP_AUDIO_SAMPLING_RATE_12000HZ
        case 24000: KRISP_AUDIO_SAMPLING_RATE_24000HZ
        case 32000: KRISP_AUDIO_SAMPLING_RATE_32000HZ
        case 44100: KRISP_AUDIO_SAMPLING_RATE_44100HZ
        case 48000: KRISP_AUDIO_SAMPLING_RATE_48000HZ
        case 88200: KRISP_AUDIO_SAMPLING_RATE_88200HZ
        case 96000: KRISP_AUDIO_SAMPLING_RATE_96000HZ
        default: KRISP_AUDIO_SAMPLING_RATE_16000HZ
        }
    }
}
