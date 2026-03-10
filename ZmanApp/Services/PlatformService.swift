import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum DeviceFormFactor {
    case phone
    case pad
    case mac
}

enum PlatformService {
    static var formFactor: DeviceFormFactor {
        #if os(macOS)
        return .mac
        #elseif os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return .pad
        default:
            return .phone
        }
        #else
        return .mac
        #endif
    }

    /// Compact device — iPhone only
    static var isCompactDevice: Bool {
        formFactor == .phone
    }

    /// Wide device — iPad or Mac (uses NavigationSplitView layout)
    static var isWideDevice: Bool {
        formFactor == .pad || formFactor == .mac
    }
}
