nonisolated struct MapBounds: Hashable {
    var minLatitude: Double
    var maxLatitude: Double
    var minLongitude: Double
    var maxLongitude: Double

    func contains(latitude: Double, longitude: Double) -> Bool {
        guard latitude.isFinite, longitude.isFinite,
              latitude >= minLatitude, latitude <= maxLatitude else { return false }
        if maxLongitude - minLongitude >= 360 { return true }
        let start = Self.normalized(minLongitude)
        let end = Self.normalized(maxLongitude)
        let point = Self.normalized(longitude)
        return start <= end ? (point >= start && point <= end) : (point >= start || point <= end)
    }

    private static func normalized(_ longitude: Double) -> Double {
        let remainder = (longitude + 180).truncatingRemainder(dividingBy: 360)
        return (remainder < 0 ? remainder + 360 : remainder) - 180
    }
}
