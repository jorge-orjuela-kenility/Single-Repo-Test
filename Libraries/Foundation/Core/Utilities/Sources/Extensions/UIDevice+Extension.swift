//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    /// Returns the CPU architecture of the current device or simulator.
    ///
    /// This property evaluates the architecture at compile time and returns a human-readable string
    /// indicating the architecture in use:
    /// - `"arm64"`: Indicates the app is running on a physical device or Apple Silicon Mac.
    /// - `"x86_64"`: Indicates the app is running on an Intel-based Mac or simulator.
    /// - `"unknown"`: Used as a fallback if the architecture is unrecognized.
    ///
    /// - Returns: A string representing the CPU architecture.
    public var cpuArchitecture: String {
        #if arch(arm64)
            return "arm64"
        #elseif arch(x86_64)
            return "x86_64"
        #else
            return "unknown"
        #endif
    }

    /// Returns the amount of free disk space available for important usage on the device.
    ///
    /// This property retrieves the available disk capacity that the system considers
    /// safe for important operations, such as video recording, media uploads, or
    /// caching critical data. The value is obtained using
    /// `URLResourceKey.volumeAvailableCapacityForImportantUsageKey`, which reflects
    /// the storage that iOS is willing to make available to the app, accounting for
    /// system-managed purging of caches and temporary files.
    ///
    /// If the disk space information cannot be retrieved, this property returns `0`.
    /// Because iOS may dynamically reclaim storage, the returned value can change
    /// over time and should not be cached for long-term decisions.
    ///
    /// Typical usage:
    ///
    /// ```swift
    /// if freeDiskSpace > minimumRequiredBytes {
    ///     startRecording()
    /// }
    /// ```
    ///
    /// - Important: This value represents *usable* disk space, not the raw free
    ///   filesystem capacity. For display-only purposes, prefer filesystem attributes
    ///   such as `systemFreeSize`.
    public var freeDiskSpace: Int {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])

        return Int(values?.volumeAvailableCapacityForImportantUsage ?? 0)
    }

    /// Returns the estimated amount of free memory available on the device, in bytes.
    ///
    /// This includes both **free** and **inactive** memory pages, which are considered
    /// reclaimable by the operating system.
    ///
    /// Internally, this method uses `host_statistics64` to query memory statistics from
    /// the kernel and multiplies the total number of free and inactive pages by the system's page size.
    ///
    /// - Returns: The amount of free memory in bytes, or `nil` if the memory statistics could not be retrieved.
    public var freeMemory: UInt64? {
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        let freePages = stats.free_count + stats.inactive_count
        return UInt64(freePages) * UInt64(pageSize)
    }

    /// Returns the device model identifier string that uniquely identifies the hardware model.
    ///
    /// This property provides access to the device's machine identifier, which is a string
    /// that uniquely identifies the specific hardware model of the device. Unlike `model`
    /// which returns a generic type (e.g., "iPhone"), this identifier provides the exact
    /// model specification (e.g., "iPhone16,2" for iPhone 15 Pro).
    public var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)

        let identifier = mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }

            result += String(UnicodeScalar(UInt8(value)))
        }

        switch identifier {
        case "iPod5,1":
            return "iPod touch (5th generation)"

        case "iPod7,1":
            return "iPod touch (6th generation)"

        case "iPod9,1":
            return "iPod touch (7th generation)"

        case "iPhone3,1", "iPhone3,2", "iPhone3,3":
            return "iPhone 4"

        case "iPhone4,1":
            return "iPhone 4s"

        case "iPhone5,1", "iPhone5,2":
            return "iPhone 5"

        case "iPhone5,3", "iPhone5,4":
            return "iPhone 5c"

        case "iPhone6,1", "iPhone6,2":
            return "iPhone 5s"

        case "iPhone7,2":
            return "iPhone 6"

        case "iPhone7,1":
            return "iPhone 6 Plus"

        case "iPhone8,1":
            return "iPhone 6s"

        case "iPhone8,2":
            return "iPhone 6s Plus"

        case "iPhone9,1", "iPhone9,3":
            return "iPhone 7"

        case "iPhone9,2", "iPhone9,4":
            return "iPhone 7 Plus"

        case "iPhone8,4":
            return "iPhone SE"

        case "iPhone10,1", "iPhone10,4":
            return "iPhone 8"

        case "iPhone10,2", "iPhone10,5":
            return "iPhone 8 Plus"

        case "iPhone10,3", "iPhone10,6":
            return "iPhone X"

        case "iPhone11,2":
            return "iPhone Xs"

        case "iPhone11,4", "iPhone11,6":
            return "iPhone Xs Max"

        case "iPhone11,8":
            return "iPhone Xʀ"

        case "iPhone12,1":
            return "iPhone 11"

        case "iPhone12,3":
            return "iPhone 11 Pro"

        case "iPhone12,5":
            return "iPhone 11 Pro Max"

        case "iPhone12,8":
            return "iPhone SE (2nd generation)"

        case "iPhone13,2":
            return "iPhone 12"

        case "iPhone13,1":
            return "iPhone 12 mini"

        case "iPhone13,3":
            return "iPhone 12 Pro"

        case "iPhone13,4":
            return "iPhone 12 Pro Max"

        case "iPhone14,5":
            return "iPhone 13"

        case "iPhone14,4":
            return "iPhone 13 mini"

        case "iPhone14,2":
            return "iPhone 13 Pro"

        case "iPhone14,3":
            return "iPhone 13 Pro Max"

        case "iPhone14,6":
            return "iPhone SE (3rd generation)"

        case "iPhone14,7":
            return "iPhone 14"

        case "iPhone14,8":
            return "iPhone 14 Plus"

        case "iPhone15,2":
            return "iPhone 14 Pro"

        case "iPhone15,3":
            return "iPhone 14 Pro Max"

        case "iPhone15,4":
            return "iPhone 15"

        case "iPhone15,5":
            return "iPhone 15 Plus"

        case "iPhone16,1":
            return "iPhone 15 Pro"

        case "iPhone16,2":
            return "iPhone 15 Pro Max"

        case "iPhone17,3":
            return "iPhone 16"

        case "iPhone17,4":
            return "iPhone 16 Plus"

        case "iPhone17,1":
            return "iPhone 16 Pro"

        case "iPhone17,2":
            return "iPhone 16 Pro Max"

        case "iPhone17,5":
            return "iPhone 16e"

        case "iPhone18,3":
            return "iPhone 17"

        case "iPhone18,1":
            return "iPhone 17 Pro"

        case "iPhone18,2":
            return "iPhone 17 Pro Max"

        case "iPhone18,4":
            return "iPhone Air"

        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":
            return "iPad 2"

        case "iPad3,1", "iPad3,2", "iPad3,3":
            return "iPad (3rd generation)"

        case "iPad3,4", "iPad3,5", "iPad3,6":
            return "iPad (4th generation)"

        case "iPad4,1", "iPad4,2", "iPad4,3":
            return "iPad Air"

        case "iPad5,3", "iPad5,4":
            return "iPad Air 2"

        case "iPad6,11", "iPad6,12":
            return "iPad (5th generation)"

        case "iPad7,5", "iPad7,6":
            return "iPad (6th generation)"

        case "iPad11,3", "iPad11,4":
            return "iPad Air (3rd generation)"

        case "iPad7,11", "iPad7,12":
            return "iPad (7th generation)"

        case "iPad11,6", "iPad11,7":
            return "iPad (8th generation)"

        case "iPad12,1", "iPad12,2":
            return "iPad (9th generation)"

        case "iPad13,18", "iPad13,19":
            return "iPad (10th generation)"

        case "iPad15,7", "iPad15,8":
            return "iPad (A16)"

        case "iPad13,1", "iPad13,2":
            return "iPad Air (4th generation)"

        case "iPad13,16", "iPad13,17":
            return "iPad Air (5th generation)"

        case "iPad14,8", "iPad14,9":
            return "iPad Air (11-inch) (M2)"

        case "iPad14,10", "iPad14,11":
            return "iPad Air (13-inch) (M2)"

        case "iPad15,3", "iPad15,4":
            return "iPad Air (11-inch) (M3)"

        case "iPad15,5", "iPad15,6":
            return "iPad Air (13-inch) (M3)"

        case "iPad2,5", "iPad2,6", "iPad2,7":
            return "iPad Mini"

        case "iPad4,4", "iPad4,5", "iPad4,6":
            return "iPad Mini 2"

        case "iPad4,7", "iPad4,8", "iPad4,9":
            return "iPad Mini 3"

        case "iPad5,1", "iPad5,2":
            return "iPad Mini 4"

        case "iPad11,1", "iPad11,2":
            return "iPad Mini (5th generation)"

        case "iPad14,1", "iPad14,2":
            return "iPad Mini (6th generation)"

        case "iPad16,1", "iPad16,2":
            return "iPad Mini (A17 Pro)"

        case "iPad6,3", "iPad6,4":
            return "iPad Pro (9.7-inch)"

        case "iPad6,7", "iPad6,8":
            return "iPad Pro (12.9-inch)"

        case "iPad7,1", "iPad7,2":
            return "iPad Pro (12.9-inch) (2nd generation)"

        case "iPad7,3", "iPad7,4":
            return "iPad Pro (10.5-inch)"

        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":
            return "iPad Pro (11-inch)"

        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":
            return "iPad Pro (12.9-inch) (3rd generation)"

        case "iPad8,9", "iPad8,10":
            return "iPad Pro (11-inch) (2nd generation)"

        case "iPad8,11", "iPad8,12":
            return "iPad Pro (12.9-inch) (4th generation)"

        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":
            return "iPad Pro (11-inch) (3rd generation)"

        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":
            return "iPad Pro (12.9-inch) (5th generation)"

        case "iPad14,3", "iPad14,4":
            return "iPad Pro (11-inch) (4th generation)"

        case "iPad14,5", "iPad14,6":
            return "iPad Pro (12.9-inch) (6th generation)"

        case "iPad16,3", "iPad16,4":
            return "iPad Pro (11-inch) (M4)"

        case "iPad16,5", "iPad16,6":
            return "iPad Pro (13-inch) (M4)"

        case "AudioAccessory1,1":
            return "HomePod"

        case "i386", "x86_64", "arm64":
            return "Simulator"

        default:
            return identifier
        }
    }

    /// Retrieves the total disk capacity of the device in bytes.
    ///
    /// This includes all system, user, and reserved space. It is useful for determining
    /// device storage tiers, capacity planning, or warning thresholds.
    ///
    /// - Returns: The total disk space in bytes, or `0` if the value could not be determined.
    public var totalDiskSpace: Int {
        let attributtes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let total = attributtes?[.systemSize] as? NSNumber

        return total?.intValue ?? 0
    }
}

extension UIDevice.BatteryState: @retroactive CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        switch self {
        case .charging:
            "charging"

        case .full:
            "full"

        case .unplugged:
            "unplugged"

        default:
            "unknown"
        }
    }
}
