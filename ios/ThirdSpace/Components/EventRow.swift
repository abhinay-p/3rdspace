import SwiftUI

struct EventRow: View {
    let event: Event
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            DateBadge(event: event, tint: tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                Text(event.timeRangeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                EventTimingLabel(event: event)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct EventTimingLabel: View {
    let event: Event

    var body: some View {
        if event.endTime <= .now {
            Text("Event ended")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        } else if event.startTime <= .now {
            Label {
                Text("Happening now").foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "circle.fill").foregroundStyle(Theme.moss)
            }
            .font(.caption.weight(.semibold))
        } else {
            Text("Starts \(event.startTime.formatted(.relative(presentation: .named)))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct DateBadge: View {
    let event: Event
    let tint: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(event.formatted(event.startTime, using: .dateTime.month(.abbreviated)))
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
            Text(event.formatted(event.startTime, using: .dateTime.day()))
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(Theme.text)
        .frame(width: 52, height: 56)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
