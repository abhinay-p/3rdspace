import SwiftUI

struct StatusPill: View {
    let text: String
    let symbolName: String

    var body: some View {
        Label(text, systemImage: symbolName)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .chromeBackground(in: Capsule())
            .padding(.bottom, 16)
    }
}
