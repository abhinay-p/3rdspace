import SwiftUI

enum Theme {
    static let accent = Color(uiColor: .systemBlue)
    static let moss = Color(uiColor: .systemGreen)
    static let ochre = Color(uiColor: .systemOrange)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let text = Color.primary
}

extension Business.Category {
    var color: Color {
        switch self {
        case .cafe: Color(uiColor: .systemBrown)
        case .restaurant: Color(uiColor: .systemOrange)
        case .bar: Color(uiColor: .systemPurple)
        case .shop: Color(uiColor: .systemPink)
        case .artsStudio: Color(uiColor: .systemIndigo)
        case .fitness: Color(uiColor: .systemGreen)
        case .communitySpace: Color(uiColor: .systemBlue)
        case .services: Color(uiColor: .systemTeal)
        case .other: Color(uiColor: .systemGray)
        }
    }
}

extension Color {
    nonisolated init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    nonisolated convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1)
    }
}
