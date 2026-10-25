import SwiftUI

struct CategoryIcon: View {
    let category: Business.Category
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: category.symbolName)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(category.color.gradient, in: Circle())
    }
}

struct CategoryPicker: View {
    @Binding var selection: Business.Category

    var body: some View {
        Picker("Category", selection: $selection) {
            ForEach(Business.Category.allCases) { category in
                Label(category.title, systemImage: category.symbolName)
                    .tag(category)
            }
        }
    }
}
