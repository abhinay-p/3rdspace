import SwiftUI

struct CategoryChips: View {
    @Binding var selection: Business.Category?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "All", symbolName: "square.grid.2x2.fill",
                    color: Theme.accent, isSelected: selection == nil
                ) {
                    selection = nil
                }
                ForEach(Business.Category.allCases) { category in
                    CategoryChip(
                        title: category.title, symbolName: category.symbolName,
                        color: category.color, isSelected: selection == category
                    ) {
                        selection = selection == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct CategoryChip: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let symbolName: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation(Motion.selectionAnimation(reduceMotion: reduceMotion)) { action() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                    .foregroundStyle(isSelected ? .white : color)
                    .accessibilityHidden(true)
                Text(title)
                    .foregroundStyle(isSelected ? .white : Theme.text)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .medium))
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background {
                if isSelected {
                    Capsule().fill(Theme.accent)
                } else {
                    Capsule().fill(.regularMaterial)
                }
            }
            .overlay {
                Capsule().strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.1), lineWidth: 0.5)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
