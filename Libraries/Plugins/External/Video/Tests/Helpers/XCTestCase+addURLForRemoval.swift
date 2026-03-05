//
//  XCTestCase+addURLForRemoval.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 16/2/24.
//

import XCTest

extension XCTestCase {
    func addURLForRemoval(_ url: URL) {
        addTeardownBlock {
            do {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.removeItem(at: url)
                } else {
                    print("File doesn't exist during cleanup: \(url.path)")
                }
            } catch {
                print("Failed to clean up file: \(error)")
            }
        }
    }
}
