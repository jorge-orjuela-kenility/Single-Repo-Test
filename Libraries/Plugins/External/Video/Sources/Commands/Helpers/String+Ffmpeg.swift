//
//  String+Ffmpeg.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 8/6/24.
//

import Foundation

extension String {
    func ffmpegFormatted() -> String {
        if let absoluteString = removingPercentEncoding {
            "\"\(absoluteString)\""
        } else {
            "\"\(self)\""
        }
    }
}
