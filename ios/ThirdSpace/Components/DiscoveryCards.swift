import SwiftUI

struct DiscoveryEventCard: View {
    let event: Event
    let business: Business
    @Environment(\.savedEventsStore) private var savedEvents

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Label {
                    Text(event.category.title).foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: event.category.symbolName).foregroundStyle(event.category.color)
                }
                .font(.caption.weight(.semibold))
                Spacer()
                if savedEvents.contains(event.id) {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityLabel("Saved")
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(business.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Divider()
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.formatted(event.startTime, using: .dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.text)
                    Text(event.startTimeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct DiscoveryPlaceRow: View {
    let business: Business
    let hasEvent: Bool

    var body: some View {
        HStack(spacing: 14) {
            CategoryIcon(category: business.category, size: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(business.name).font(.headline).foregroundStyle(Theme.text)
                Text(business.category.title).font(.subheadline).foregroundStyle(.secondary)
                if !business.address.isEmpty {
                    Text(business.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if hasEvent {
                    Label {
                        Text("Events this week").foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "calendar").foregroundStyle(Theme.accent)
                    }
                    .font(.caption.weight(.medium))
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
