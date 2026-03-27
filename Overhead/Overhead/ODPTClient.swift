import Foundation

// MARK: - ODPT API Client
// Stub implementation — replace with real API calls using your ODPT consumer key.

final class ODPTClient {

    private let consumerKey: String

    init(consumerKey: String) {
        self.consumerKey = consumerKey
    }

    /// Read the ODPT consumer key from the bundled ODPTKey.plist.
    /// Copy ODPTKey-Sample.plist to ODPTKey.plist and replace the placeholder value.
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

    /// Fetch railway lines for a given operator
    func fetchRailways(operatorId: String) async throws -> [TrainLine] {
        // TODO: Implement real ODPT API call
        // GET https://api.odpt.org/api/v4/odpt:Railway?odpt:operator=<operatorId>&acl:consumerKey=<key>
        return []
    }

    /// Fetch train timetables for a given railway
    func fetchTrainTimetables(railwayId: String) async throws -> [TrainService] {
        // TODO: Implement real ODPT API call
        // GET https://api.odpt.org/api/v4/odpt:TrainTimetable?odpt:railway=<railwayId>&acl:consumerKey=<key>
        return []
    }

    /// Fetch current delay information for a given railway
    func fetchDelayInfo(railwayId: String) async throws -> [DelayInfo] {
        // TODO: Implement real ODPT API call
        // GET https://api.odpt.org/api/v4/odpt:TrainInformation?odpt:railway=<railwayId>&acl:consumerKey=<key>
        return []
    }
}
