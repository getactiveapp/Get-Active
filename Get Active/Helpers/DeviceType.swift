import SwiftUI
import UIKit

enum DeviceType {
    case iPhone
    case iPad
    case mac
    
    static var current: DeviceType {
        #if targetEnvironment(macCatalyst)
        return .mac
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .iPad
        } else {
            return .iPhone
        }
        #endif
    }
    
    var isPad: Bool {
        return self == .iPad
    }
    
    var isMac: Bool {
        return self == .mac
    }
    
    var isPhone: Bool {
        return self == .iPhone
    }
}

struct DeviceSize {
    // Screen dimensions
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    static var screenSize: CGSize {
        UIScreen.main.bounds.size
    }
    
    // Device type checks
    static var isPad: Bool {
        DeviceType.current.isPad
    }
    
    static var isMac: Bool {
        DeviceType.current.isMac
    }
    
    static var isPhone: Bool {
        DeviceType.current.isPhone
    }
    
    // iPhone size categories
    static var isSmalliPhone: Bool {
        guard isPhone else { return false }
        // iPhone SE, iPhone 12/13/14 mini (width < 390)
        return screenWidth < 390
    }
    
    static var isStandardiPhone: Bool {
        guard isPhone else { return false }
        // iPhone 12/13/14/15 standard (width 390-430)
        return screenWidth >= 390 && screenWidth < 430
    }
    
    static var isLargeiPhone: Bool {
        guard isPhone else { return false }
        // iPhone Pro Max, Plus models (width >= 430)
        return screenWidth >= 430
    }
    
    // iPad size categories
    static var isSmalliPad: Bool {
        guard isPad else { return false }
        // iPad mini (width < 800)
        return screenWidth < 800
    }
    
    static var isStandardiPad: Bool {
        guard isPad else { return false }
        // iPad Air, iPad standard (width 800-1000)
        return screenWidth >= 800 && screenWidth < 1000
    }
    
    static var isLargeiPad: Bool {
        guard isPad else { return false }
        // iPad Pro 12.9" (width >= 1000)
        return screenWidth >= 1000
    }
    
    // Adaptive column count for grids
    static func adaptiveColumns(minWidth: CGFloat = 300) -> [GridItem] {
        let availableWidth = screenWidth - (horizontalPadding * 2)
        let columnCount = max(1, Int(availableWidth / minWidth))
        
        if isMac {
            // Mac: 2-5 columns depending on window size
            let maxColumns = min(columnCount, 5)
            return Array(repeating: GridItem(.flexible(), spacing: 20), count: maxColumns)
        } else if isPad {
            // iPad: 2-4 columns depending on size
            let maxColumns = isLargeiPad ? min(columnCount, 4) : min(columnCount, 3)
            return Array(repeating: GridItem(.flexible(), spacing: 20), count: max(maxColumns, 2))
        } else {
            // iPhone: always 1 column
            return [GridItem(.flexible())]
        }
    }
    
    // Adaptive padding based on device and screen size
    static var horizontalPadding: CGFloat {
        if isMac {
            // Mac: More padding for larger screens
            return screenWidth > 1400 ? 60 : 40
        } else if isPad {
            // iPad: More padding on larger iPads
            if isLargeiPad {
                return 50
            } else if isStandardiPad {
                return 40
            } else {
                return 30  // iPad mini
            }
        } else {
            // iPhone: Less padding on smaller devices
            if isSmalliPhone {
                return 16
            } else if isStandardiPhone {
                return 20
            } else {
                return 24  // Large iPhone
            }
        }
    }
    
    // Adaptive vertical padding
    static var verticalPadding: CGFloat {
        if isMac {
            return 30
        } else if isPad {
            return isLargeiPad ? 30 : 24
        } else {
            return isSmalliPhone ? 12 : 16
        }
    }
    
    // Adaptive spacing between elements
    static var defaultSpacing: CGFloat {
        if isMac {
            return 30
        } else if isPad {
            return isLargeiPad ? 30 : 24
        } else {
            return isSmalliPhone ? 16 : 20
        }
    }
    
    // Max content width for readability (centered on large screens)
    static var maxContentWidth: CGFloat? {
        if isMac {
            return screenWidth > 1400 ? 1400 : nil
        } else if isPad {
            return nil  // Use full width on iPad
        } else {
            return nil  // Use full width on iPhone
        }
    }
    
    // Adaptive font sizes
    static var titleFontSize: CGFloat {
        if isMac {
            return 32
        } else if isPad {
            if isLargeiPad {
                return 32
            } else if isStandardiPad {
                return 28
            } else {
                return 26  // iPad mini
            }
        } else {
            if isSmalliPhone {
                return 20
            } else if isStandardiPhone {
                return 22
            } else {
                return 24  // Large iPhone
            }
        }
    }
    
    static var bodyFontSize: CGFloat {
        if isMac {
            return 18
        } else if isPad {
            if isLargeiPad {
                return 20
            } else if isStandardiPad {
                return 18
            } else {
                return 16  // iPad mini
            }
        } else {
            if isSmalliPhone {
                return 14
            } else if isStandardiPhone {
                return 16
            } else {
                return 17  // Large iPhone
            }
        }
    }
    
    static var captionFontSize: CGFloat {
        if isMac {
            return 14
        } else if isPad {
            return 14
        } else {
            return isSmalliPhone ? 11 : 12
        }
    }
    
    // Card sizing - responsive to screen size
    static var featuredEventCardWidth: CGFloat {
        if isMac {
            return min(450, screenWidth * 0.3)
        } else if isPad {
            if isLargeiPad {
                return 450
            } else if isStandardiPad {
                return 400
            } else {
                return 350  // iPad mini
            }
        } else {
            // iPhone: Use percentage of screen width with max constraint
            let baseWidth = screenWidth * 0.85
            if isSmalliPhone {
                return min(baseWidth, 280)
            } else if isStandardiPhone {
                return min(baseWidth, 320)
            } else {
                return min(baseWidth, 360)  // Large iPhone
            }
        }
    }
    
    static var featuredEventCardHeight: CGFloat {
        if isMac {
            return 320
        } else if isPad {
            if isLargeiPad {
                return 320
            } else if isStandardiPad {
                return 280
            } else {
                return 250  // iPad mini
            }
        } else {
            // iPhone: Maintain aspect ratio
            let aspectRatio: CGFloat = 200.0 / 280.0
            return featuredEventCardWidth * aspectRatio
        }
    }
    
    // Button sizes
    static var buttonHeight: CGFloat {
        if isMac {
            return 50
        } else if isPad {
            return isLargeiPad ? 50 : 44
        } else {
            return isSmalliPhone ? 40 : 44
        }
    }
    
    // Icon sizes
    static var iconSize: CGFloat {
        if isMac {
            return 24
        } else if isPad {
            return isLargeiPad ? 28 : 24
        } else {
            return isSmalliPhone ? 18 : 20
        }
    }
    
    // Profile image sizes
    static var profileImageSize: CGFloat {
        if isMac {
            return 60
        } else if isPad {
            return isLargeiPad ? 60 : 50
        } else {
            return isSmalliPhone ? 40 : 48
        }
    }
    
    // Search bar height
    static var searchBarHeight: CGFloat {
        if isMac {
            return 50
        } else if isPad {
            return isLargeiPad ? 50 : 44
        } else {
            return isSmalliPhone ? 40 : 44
        }
    }
    
    // Tab bar height adjustment
    static var tabBarHeight: CGFloat {
        if isMac {
            return 60
        } else if isPad {
            return 50
        } else {
            return 49  // Standard iOS tab bar
        }
    }
    
    // Safe area insets helper
    static func safeAreaInsets() -> EdgeInsets {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.toEdgeInsets()
        }
        return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
}

// Helper extension to convert UIEdgeInsets to EdgeInsets
extension UIEdgeInsets {
    func toEdgeInsets() -> EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

