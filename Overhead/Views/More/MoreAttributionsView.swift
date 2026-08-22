import SwiftUI

struct MoreAttributionsView: View {
    var body: some View {
        List {
            Section {
                Text(verbatim: """
                    Some train timetable data (including 当駅始発 originating-\
                    train times) is derived from the Public Transportation Open \
                    Data Center (公共交通オープンデータセンター).

                    The source data is provided by the transportation operators \
                    via the ODPT center and is used under the Creative Commons \
                    Attribution 4.0 International (CC BY 4.0) license. The data \
                    is processed by this app and is not guaranteed to be \
                    accurate or current; it does not represent the views of the \
                    operators or the ODPT center.

                    https://www.odpt.org
                    """)
            } header: {
                Text(verbatim: "Public Transportation Open Data Center")
            }
            Section {
                Text(verbatim: """
                    Some station coordinates are derived from OpenStreetMap data, \
                    © OpenStreetMap contributors, available under the Open Database \
                    License (ODbL).

                    https://www.openstreetmap.org/copyright
                    """)
            } header: {
                Text(verbatim: "OpenStreetMap")
            }
            Section {
                Text(verbatim: """
                    Some railway operator logo marks are rasterised from vector \
                    images hosted on Wikimedia Commons. These simple logo marks \
                    are below the threshold of originality and are in the public \
                    domain; other operator icons are the favicons published on \
                    each operator's own website.

                    All logo marks remain trademarks of their respective \
                    operators and are used solely to identify the operators.

                    https://commons.wikimedia.org
                    """)
            } header: {
                Text(verbatim: "Wikimedia Commons")
            }
            ForEach(Self.fonts, id: \.name) { font in
                Section {
                    if let note = font.note {
                        Text(verbatim: note)
                    }
                    Text(verbatim: Self.license(font.licenseFile))
                } header: {
                    Text(verbatim: font.name)
                }
            }
        }
        .navigationTitle("More.Attributions")
        .listStyle(.grouped)
    }

    private struct FontAttribution {
        let name: String
        let licenseFile: String
        var note: String?
    }

    private static let fonts: [FontAttribution] = [
        FontAttribution(name: "Hind", licenseFile: "Hind.license"),
        FontAttribution(name: "BIZ UDPGothic", licenseFile: "BIZUDPGothic.license"),
        FontAttribution(name: "DotGothic16", licenseFile: "DotGothic16.license"),
        FontAttribution(
            name: "Overtrain Pixel 12",
            licenseFile: "OvertrainPixel12.license",
            note: """
                Overtrain Pixel 12 is a modified version of Ark Pixel, renamed as \
                required by the reserved font name.
                """
        )
    ]

    private static func license(_ resource: String) -> String {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
