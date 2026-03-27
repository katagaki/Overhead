import Foundation

// MARK: - ODPT API Client

final class ODPTClient {

    private let consumerKey: String
    private let baseURL = "https://api.odpt.org/api/v4"
    private let session: URLSession

    init(consumerKey: String) {
        self.consumerKey = consumerKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    /// Read the ODPT consumer key from the bundled ODPTKey.plist.
    static func consumerKeyFromPlist() -> String {
        guard let url = Bundle.main.url(forResource: "ODPTKey", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let key = dict["ODPTConsumerKey"] as? String,
              key != "YOUR_ODPT_CONSUMER_KEY_HERE"
        else {
            return ""
        }
        return key
    }

    // MARK: - Fetch Railways

    func fetchRailways(operatorId: String) async throws -> [TrainLine] {
        let railways: [ODPTRailway] = try await fetch(
            endpoint: "odpt:Railway",
            params: ["odpt:operator": operatorId]
        )

        // For each railway, fetch stations to get lat/lon and station codes
        var lines: [TrainLine] = []
        for railway in railways {
            let railwayId = railway.sameAs

            // Build stations from stationOrder (Metro/Toei) or from Station endpoint (JR)
            var stations: [Station] = []

            if !railway.stationOrder.isEmpty {
                // Metro/Toei: stationOrder is populated
                // Also fetch Station objects for lat/lon and codes
                let stationObjects: [ODPTStation] = try await fetch(
                    endpoint: "odpt:Station",
                    params: ["odpt:railway": railwayId]
                )
                let stationMap = Dictionary(
                    stationObjects.map { ($0.sameAs, $0) },
                    uniquingKeysWith: { first, _ in first }
                )

                for order in railway.stationOrder.sorted(by: { $0.index < $1.index }) {
                    let stationId = order.station
                    let obj = stationMap[stationId]
                    stations.append(Station(
                        id: stationId,
                        name: order.stationTitle?["ja"] ?? obj?.stationTitle?["ja"] ?? railway.title,
                        nameEn: order.stationTitle?["en"] ?? obj?.stationTitle?["en"] ?? "",
                        nameKo: order.stationTitle?["ko"] ?? obj?.stationTitle?["ko"] ?? "",
                        nameZhHans: order.stationTitle?["zh-Hans"] ?? obj?.stationTitle?["zh-Hans"] ?? "",
                        nameZhHant: order.stationTitle?["zh-Hant"] ?? obj?.stationTitle?["zh-Hant"] ?? "",
                        stationCode: obj?.stationCode ?? "",
                        latitude: obj?.lat,
                        longitude: obj?.lon
                    ))
                }
            } else {
                // JR-East: stationOrder is empty, fetch stations
                let stationObjects: [ODPTStation] = try await fetch(
                    endpoint: "odpt:Station",
                    params: ["odpt:railway": railwayId]
                )
                for obj in stationObjects {
                    stations.append(Station(
                        id: obj.sameAs,
                        name: obj.stationTitle?["ja"] ?? obj.title,
                        nameEn: obj.stationTitle?["en"] ?? "",
                        nameKo: obj.stationTitle?["ko"] ?? "",
                        nameZhHans: obj.stationTitle?["zh-Hans"] ?? "",
                        nameZhHant: obj.stationTitle?["zh-Hant"] ?? "",
                        stationCode: obj.stationCode ?? "",
                        latitude: obj.lat,
                        longitude: obj.lon
                    ))
                }
                // Sort JR stations by station code number (e.g. JC05 → 05)
                stations.sort { a, b in
                    let aNum = Int(a.stationCode.drop(while: \.isLetter)) ?? 0
                    let bNum = Int(b.stationCode.drop(while: \.isLetter)) ?? 0
                    return aNum < bNum
                }
            }

            // Determine color: use API color if available, else fall back to LineColors
            let colorHex = railway.color ?? lineColorFallback(railwayId: railwayId)

            lines.append(TrainLine(
                id: railwayId,
                name: railway.railwayTitle?["ja"] ?? railway.title,
                nameEn: railway.railwayTitle?["en"] ?? "",
                nameKo: railway.railwayTitle?["ko"] ?? "",
                nameZhHans: railway.railwayTitle?["zh-Hans"] ?? "",
                nameZhHant: railway.railwayTitle?["zh-Hant"] ?? "",
                operatorId: railway.operatorId,
                stations: stations,
                colorHex: colorHex
            ))
        }

        return lines
    }

    // MARK: - Fetch Train Timetables

    func fetchTrainTimetables(railwayId: String) async throws -> [TrainService] {
        // Determine current calendar type
        let calendar = currentCalendarType()

        let timetables: [ODPTTrainTimetable] = try await fetch(
            endpoint: "odpt:TrainTimetable",
            params: [
                "odpt:railway": railwayId,
                "odpt:calendar": calendar
            ]
        )

        return timetables.compactMap { tt -> TrainService? in
            let entries = tt.trainTimetableObject.enumerated().map { (i, obj) -> TimetableEntry in
                let stationId = obj.departureStation ?? obj.arrivalStation ?? ""
                return TimetableEntry(
                    id: "\(tt.sameAs)_\(i)",
                    stationId: stationId,
                    arrivalTime: obj.arrivalTime,
                    departureTime: obj.departureTime
                )
            }

            guard !entries.isEmpty else { return nil }

            let trainType = parseTrainType(tt.trainType)
            let direction = parseDirection(tt.railDirection)

            return TrainService(
                id: tt.trainNumber ?? tt.sameAs,
                lineId: tt.railway,
                trainType: trainType,
                direction: direction,
                timetable: entries,
                destinationStationId: tt.destinationStation?.first ?? ""
            )
        }
    }

    // MARK: - Fetch Delay / Train Information

    func fetchDelayInfo(railwayId: String) async throws -> [DelayInfo] {
        let infos: [ODPTTrainInformation] = try await fetch(
            endpoint: "odpt:TrainInformation",
            params: ["odpt:railway": railwayId]
        )

        return infos.map { info in
            let text = info.trainInformationText?["ja"] ?? ""
            let isNormal = text.contains("平常") || text.contains("運転しています")
            let delayMinutes = isNormal ? 0 : parseDelayMinutes(from: text)

            return DelayInfo(
                lineId: info.railway,
                delayMinutes: delayMinutes,
                cause: isNormal ? nil : text,
                updatedAt: info.date ?? Date()
            )
        }
    }

    // MARK: - Fetch Station Timetable

    func fetchStationTimetable(stationId: String) async throws -> [StationTimetableData] {
        let calendar = currentCalendarType()

        let timetables: [ODPTStationTimetable] = try await fetch(
            endpoint: "odpt:StationTimetable",
            params: [
                "odpt:station": stationId,
                "odpt:calendar": calendar
            ]
        )

        // Collect all unique destination station IDs to resolve names
        var allDestinationIds = Set<String>()
        for tt in timetables {
            for obj in tt.stationTimetableObject {
                if let destIds = obj.destinationStation {
                    allDestinationIds.formUnion(destIds)
                }
            }
        }

        // Fetch station objects for destination name resolution
        var stationNameMap: [String: (ja: String, en: String)] = [:]
        for destId in allDestinationIds {
            let stations: [ODPTStation] = try await fetch(
                endpoint: "odpt:Station",
                params: ["owl:sameAs": destId]
            )
            if let station = stations.first {
                stationNameMap[destId] = (
                    ja: station.stationTitle?["ja"] ?? station.title,
                    en: station.stationTitle?["en"] ?? ""
                )
            }
        }

        // Fetch rail directions for enriching direction names
        let directions = try? await fetchRailDirections()

        return timetables.map { tt in
            let departures = tt.stationTimetableObject.enumerated().map { (i, obj) -> StationDeparture in
                let destId = obj.destinationStation?.first ?? ""
                let destNames = stationNameMap[destId]
                return StationDeparture(
                    id: "\(tt.sameAs)_\(i)",
                    departureTime: obj.departureTime ?? "",
                    trainType: parseTrainType(obj.trainType),
                    destinationName: destNames?.ja ?? shortStationName(destId),
                    destinationNameEn: destNames?.en ?? "",
                    trainNumber: obj.trainNumber ?? "",
                    isLast: obj.isLast ?? false
                )
            }

            let dirId = tt.railDirection ?? ""
            let dirNames = directions?[dirId]

            return StationTimetableData(
                stationId: stationId,
                railDirection: dirId,
                railDirectionName: dirNames?.ja ?? dirId,
                railDirectionNameEn: dirNames?.en ?? "",
                departures: departures
            )
        }
    }

    /// Extract a readable name from an ODPT station ID as a fallback
    private func shortStationName(_ fullId: String) -> String {
        fullId.components(separatedBy: ".").last ?? fullId
    }

    // MARK: - Fetch Rail Directions

    func fetchRailDirections() async throws -> [String: (ja: String, en: String)] {
        let directions: [ODPTRailDirection] = try await fetch(
            endpoint: "odpt:RailDirection",
            params: [:]
        )

        var map: [String: (ja: String, en: String)] = [:]
        for d in directions {
            let ja = d.railDirectionTitle?["ja"] ?? d.title
            let en = d.railDirectionTitle?["en"] ?? ""
            map[d.sameAs] = (ja: ja, en: en)
        }
        return map
    }

    // MARK: - Fetch Passenger Survey

    func fetchPassengerSurvey(operatorId: String) async throws -> [PassengerSurveyData] {
        let surveys: [ODPTPassengerSurvey] = try await fetch(
            endpoint: "odpt:PassengerSurvey",
            params: ["odpt:operator": operatorId]
        )

        return surveys.map { survey in
            let annuals = survey.passengerSurveyObject.map {
                PassengerSurveyData.AnnualSurvey(
                    year: $0.surveyYear,
                    passengerJourneys: $0.passengerJourneys
                )
            }

            return PassengerSurveyData(
                id: survey.station?.first ?? survey.sameAs,
                stationName: "",
                surveys: annuals
            )
        }
    }

    // MARK: - Generic Fetch

    private func fetch<T: Decodable>(endpoint: String, params: [String: String]) async throws -> [T] {
        var components = URLComponents(string: "\(baseURL)/\(endpoint)")!
        var queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        queryItems.append(URLQueryItem(name: "acl:consumerKey", value: consumerKey))
        components.queryItems = queryItems

        let (data, response) = try await session.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ODPTError.requestFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([T].self, from: data)
    }

    // MARK: - Calendar Type

    private func currentCalendarType() -> String {
        let tz = TimeZone(identifier: "Asia/Tokyo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let weekday = cal.component(.weekday, from: Date())
        // 1 = Sunday, 7 = Saturday
        if weekday == 1 || weekday == 7 {
            return "odpt.Calendar:SaturdayHoliday"
        }
        return "odpt.Calendar:Weekday"
    }

    // MARK: - Parsing Helpers

    private func parseTrainType(_ raw: String?) -> TrainService.TrainType {
        guard let raw else { return .local }
        let lower = raw.lowercased()
        // Check specific types before generic "rapid" to avoid misclassification
        if lower.contains("commuterrapid") { return .commuterRapid }
        if lower.contains("specialrapid") { return .specialRapid }
        if lower.contains("limitedexpress") || lower.contains("tokkyu") { return .limitedExpress }
        if lower.contains("express") { return .express }
        if lower.contains("rapid") || lower.contains("kaisoku") { return .rapid }
        return .local
    }

    private func parseDirection(_ raw: String?) -> TrainService.Direction {
        guard let raw else { return .outbound }
        // Convention: lower index → outbound; but ODPT doesn't have a clear standard
        return raw.contains("Inbound") ? .inbound : .outbound
    }

    private func parseDelayMinutes(from text: String) -> Int {
        // Try to extract delay minutes from Japanese text like "約10分の遅れ"
        let pattern = #"(\d+)\s*分"#
        if let match = text.range(of: pattern, options: .regularExpression),
           let minutes = Int(text[match].filter(\.isNumber)) {
            return minutes
        }
        // If we can't parse but it's not normal, assume minor delay
        return 5
    }

    private func lineColorFallback(railwayId: String) -> String {
        let colorMap: [String: String] = [
            "odpt.Railway:JR-East.Yamanote": LineColors.yamanote,
            "odpt.Railway:JR-East.ChuoRapid": LineColors.chuoRapid,
            "odpt.Railway:JR-East.KeihinTohoku": LineColors.keihinTohoku,
            "odpt.Railway:Toei.Asakusa": LineColors.toeiAsakusa,
            "odpt.Railway:Toei.Oedo": LineColors.toeiOedo,
        ]
        return colorMap[railwayId] ?? "#808080"
    }

    // MARK: - Error

    enum ODPTError: Error {
        case requestFailed
    }
}

// MARK: - ODPT Response Models

private struct ODPTRailway: Decodable {
    let sameAs: String
    let title: String
    let railwayTitle: [String: String]?
    let operatorId: String
    let stationOrder: [ODPTStationOrder]
    let color: String?

    enum CodingKeys: String, CodingKey {
        case sameAs = "owl:sameAs"
        case title = "dc:title"
        case railwayTitle = "odpt:railwayTitle"
        case operatorId = "odpt:operator"
        case stationOrder = "odpt:stationOrder"
        case color = "odpt:color"
    }
}

private struct ODPTStationOrder: Decodable {
    let index: Int
    let station: String
    let stationTitle: [String: String]?

    enum CodingKeys: String, CodingKey {
        case index = "odpt:index"
        case station = "odpt:station"
        case stationTitle = "odpt:stationTitle"
    }
}

private struct ODPTStation: Decodable {
    let sameAs: String
    let title: String
    let stationTitle: [String: String]?
    let stationCode: String?
    let lat: Double?
    let lon: Double?

    enum CodingKeys: String, CodingKey {
        case sameAs = "owl:sameAs"
        case title = "dc:title"
        case stationTitle = "odpt:stationTitle"
        case stationCode = "odpt:stationCode"
        case lat = "geo:lat"
        case lon = "geo:long"
    }
}

private struct ODPTTrainTimetable: Decodable {
    let sameAs: String
    let railway: String
    let trainNumber: String?
    let trainType: String?
    let railDirection: String?
    let destinationStation: [String]?
    let trainTimetableObject: [ODPTTimetableObject]

    enum CodingKeys: String, CodingKey {
        case sameAs = "owl:sameAs"
        case railway = "odpt:railway"
        case trainNumber = "odpt:trainNumber"
        case trainType = "odpt:trainType"
        case railDirection = "odpt:railDirection"
        case destinationStation = "odpt:destinationStation"
        case trainTimetableObject = "odpt:trainTimetableObject"
    }
}

private struct ODPTTimetableObject: Decodable {
    let departureStation: String?
    let arrivalStation: String?
    let departureTime: String?
    let arrivalTime: String?

    enum CodingKeys: String, CodingKey {
        case departureStation = "odpt:departureStation"
        case arrivalStation = "odpt:arrivalStation"
        case departureTime = "odpt:departureTime"
        case arrivalTime = "odpt:arrivalTime"
    }
}

private struct ODPTTrainInformation: Decodable {
    let sameAs: String
    let railway: String
    let trainInformationText: [String: String]?
    let date: Date?

    enum CodingKeys: String, CodingKey {
        case sameAs = "owl:sameAs"
        case railway = "odpt:railway"
        case trainInformationText = "odpt:trainInformationText"
        case date = "dc:date"
    }
}

private struct ODPTStationTimetable: Decodable {
    let sameAs: String
    let station: String
    let railway: String
    let railDirection: String?
    let calendar: String?
    let stationTimetableObject: [ODPTStationTimetableObject]

    enum CodingKeys: String, CodingKey {
        case sameAs = "owl:sameAs"
        case station = "odpt:station"
        case railway = "odpt:railway"
        case railDirection = "odpt:railDirection"
        case calendar = "odpt:calendar"
        case stationTimetableObject = "odpt:stationTimetableObject"
    }
}

private struct ODPTStationTimetableObject: Decodable {
    let train: String?
    let trainType: String?
    let trainNumber: String?
    let departureTime: String?
    let destinationStation: [String]?
    let isLast: Bool?

    enum CodingKeys: String, CodingKey {
        case train = "odpt:train"
        case trainType = "odpt:trainType"
        case trainNumber = "odpt:trainNumber"
        case departureTime = "odpt:departureTime"
        case destinationStation = "odpt:destinationStation"
        case isLast = "odpt:isLast"
    }
}

private struct ODPTRailDirection: Decodable {
    let sameAs: String
    let title: String
    let railDirectionTitle: [String: String]?

    enum CodingKeys: String, CodingKey {
        case sameAs = "owl:sameAs"
        case title = "dc:title"
        case railDirectionTitle = "odpt:railDirectionTitle"
    }
}

private struct ODPTPassengerSurvey: Decodable {
    let sameAs: String
    let station: [String]?
    let railway: [String]?
    let passengerSurveyObject: [ODPTPassengerSurveyObject]

    enum CodingKeys: String, CodingKey {
        case sameAs = "owl:sameAs"
        case station = "odpt:station"
        case railway = "odpt:railway"
        case passengerSurveyObject = "odpt:passengerSurveyObject"
    }
}

private struct ODPTPassengerSurveyObject: Decodable {
    let surveyYear: Int
    let passengerJourneys: Int

    enum CodingKeys: String, CodingKey {
        case surveyYear = "odpt:surveyYear"
        case passengerJourneys = "odpt:passengerJourneys"
    }
}
