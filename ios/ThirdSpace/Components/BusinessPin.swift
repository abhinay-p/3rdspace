import SwiftUI

struct BusinessPin: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let category: Business.Category
    let isSelected: Bool
    let hasEventSoon: Bool

    var body: some View {
        VStack(spacing: -3) {
            CategoryIcon(category: category, size: isSelected ? 48 : 34)
                .overlay {
                    Circle().strokeBorder(.white, lineWidth: isSelected ? 3 : 2)
                }
                .overlay(alignment: .topTrailing) {
                    if hasEventSoon {
                        EventSoonBadge().offset(x: 4, y: -4)
                    }
                }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: isSelected ? 12 : 9))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
        .animation(Motion.animation(reduceMotion: reduceMotion), value: isSelected)
    }
}

private struct EventSoonBadge: View {
    var body: some View {
        Circle()
            .fill(Theme.ochre)
            .frame(width: 12, height: 12)
            .overlay { Circle().strokeBorder(.white, lineWidth: 2) }
    }
}
