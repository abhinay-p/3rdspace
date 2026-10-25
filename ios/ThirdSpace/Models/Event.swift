import Foundation

nonisolated struct Event: Identifiable, Hashable, Codable {
    let id: UUID
    let businessID: Business.ID
    var title: String
    var description: String
    var category: Business.Category
    var startTime: Date
    var endTime: Date
    var capacity: Int?
    var timeZoneID: String? = nil
    var sourceName: String? = nil
    var sourceURL: URL? = nil

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    func isHappening(within interval: TimeInterval, from now: Date) -> Bool {
        endTime > now && startTime < now.addingTimeInterval(interval)
    }

    var displayTimeZone: TimeZone {
        timeZoneID.flatMap(TimeZone.init(identifier:)) ?? .current
    }

    func formatted(_ date: Date, using style: Date.FormatStyle) -> String {
        var style = style
        style.timeZone = displayTimeZone
        return date.formatted(style)
    }

    var dateText: String {
        formatted(startTime, using: .dateTime.weekday(.wide).month(.wide).day())
    }

    var startTimeText: String {
        let time = formatted(startTime, using: .dateTime.hour().minute())
        return displayTimeZone.identifier == TimeZone.current.identifier
            ? time : "\(time) \(zoneAbbreviation(at: startTime))"
    }

    var timeRangeText: String {
        let start = formatted(startTime, using: .dateTime.hour().minute())
        var calendar = Calendar.current
        calendar.timeZone = displayTimeZone
        let endStyle: Date.FormatStyle
        if calendar.isDate(startTime, inSameDayAs: endTime) {
            endStyle = .dateTime.hour().minute()
        } else if calendar.component(.year, from: startTime) == calendar.component(.year, from: endTime) {
            endStyle = .dateTime.month(.abbreviated).day().hour().minute()
        } else {
            endStyle = .dateTime.month(.abbreviated).day().year().hour().minute()
        }
        let end = formatted(endTime, using: endStyle)
        if displayTimeZone.secondsFromGMT(for: startTime) != displayTimeZone.secondsFromGMT(for: endTime) {
            return "\(start) \(zoneAbbreviation(at: startTime)) – \(end) \(zoneAbbreviation(at: endTime))"
        }
        let zone = displayTimeZone.identifier == TimeZone.current.identifier
            ? "" : " \(zoneAbbreviation(at: endTime))"
        return "\(start) – \(end)\(zone)"
    }

    var durationText: String {
        Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    private func zoneAbbreviation(at date: Date) -> String {
        displayTimeZone.abbreviation(for: date) ?? displayTimeZone.identifier
    }
}
