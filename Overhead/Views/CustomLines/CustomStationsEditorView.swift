import SwiftUI
import CoreLocation
import Backbone

// MARK: - Custom Stations Editor
//
// Reorderable native List of the line's stations, plus per-segment ride times.
// Editing writes straight back through the `line` binding, which the parent
// autosaves.

struct CustomStationsEditorView: View {
    @Binding var line: CustomLine

    var body: some View {
        List {
            Section {
                ForEach($line.stations.indices, id: \.self) { index in
                    NavigationLink {
                        CustomStationDetailView(
                            station: $line.stations[index],
                            code: line.stationCode(at: index),
                            style: line.badgeStyle,
                            color: line.color
                        )
                    } label: {
                        stationRow(index: index)
                    }
                }
                .onMove { indices, destination in
                    line.stations.move(fromOffsets: indices, toOffset: destination)
                    line.normalizeHopMinutes()
                }
                .onDelete { offsets in
                    line.stations.remove(atOffsets: offsets)
                    line.normalizeHopMinutes()
                }
            } header: {
                Text(verbatim: line.stations.isEmpty ? "駅" : "\(line.stations.count)駅 · 上から下り方向")
            } footer: {
                Text(verbatim: "全駅に座標を設定すると、GPSモードで走行できます。未設定の駅は前後から補間されます。")
            }

            if line.stations.count >= 2 {
                Section {
                    ForEach(0..<(line.stations.count - 1), id: \.self) { gap in
                        Stepper(value: hopBinding(gap), in: 1...30) {
                            LabeledContent {
                                Text(verbatim: "\(Int(line.hopMinutes[safe: gap] ?? 2))分")
                            } label: {
                                Text(verbatim: "\(stationName(gap)) → \(stationName(gap + 1))")
                                    .lineLimit(1)
                            }
                        }
                    }
                } header: {
                    Text(verbatim: "駅間の所要時間")
                }
            }
        }
        .navigationTitle(Text(verbatim: "駅"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    line.stations.append(.new())
                    line.normalizeHopMinutes()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Text(verbatim: "駅を追加"))
            }
        }
        .overlay {
            if line.stations.isEmpty {
                ContentUnavailableView {
                    Label { Text(verbatim: "駅がありません") } icon: { Image(systemName: "tram") }
                } description: {
                    Text(verbatim: "右上の＋から駅を追加してください")
                }
            }
        }
    }

    private func stationRow(index: Int) -> some View {
        let station = line.stations[index]
        return HStack(spacing: 12) {
            StationNumberBadge(
                code: line.stationCode(at: index),
                color: line.color,
                size: .compact,
                styleOverride: line.badgeStyle
            )
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: station.name.isEmpty ? "（駅名未設定）" : station.name)
                    .foregroundColor(station.name.isEmpty ? .secondary : .primary)
                if !station.nameEn.isEmpty {
                    Text(verbatim: station.nameEn)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 0)
            if station.hasCoordinates {
                Image(systemName: "location.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func stationName(_ index: Int) -> String {
        let name = line.stations[safe: index]?.name ?? ""
        return name.isEmpty ? "駅\(index + 1)" : name
    }

    private func hopBinding(_ gap: Int) -> Binding<Double> {
        Binding(
            get: { line.hopMinutes[safe: gap] ?? 2 },
            set: { newValue in
                line.normalizeHopMinutes()
                if gap < line.hopMinutes.count { line.hopMinutes[gap] = newValue }
            }
        )
    }
}

// MARK: - Station detail (name + GPS)

struct CustomStationDetailView: View {
    @Binding var station: CustomStation
    let code: String
    let style: BadgeStyle
    let color: Color

    @StateObject private var location = OneShotLocation()

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    TextField("", text: $station.name, prompt: Text(verbatim: "例：杉戸口"))
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text(verbatim: "駅名")
                }
                LabeledContent {
                    TextField("", text: $station.nameEn, prompt: Text(verbatim: "Sugitoguchi"))
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                } label: {
                    Text(verbatim: "駅名（英語）")
                }
            } header: {
                HStack(spacing: 8) {
                    StationNumberBadge(code: code, color: color, size: .compact, styleOverride: style)
                    Text(verbatim: code)
                }
            }

            Section {
                Button {
                    location.requestLocation { coordinate in
                        if let coordinate {
                            station.latitude = coordinate.latitude
                            station.longitude = coordinate.longitude
                        }
                    }
                } label: {
                    HStack {
                        Label {
                            Text(verbatim: "現在地を記録")
                        } icon: {
                            Image(systemName: "location.fill")
                        }
                        Spacer()
                        if location.isRequesting { ProgressView() }
                    }
                }

                if let lat = station.latitude, let lon = station.longitude {
                    LabeledContent {
                        Text(verbatim: String(format: "%.5f, %.5f", lat, lon))
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    } label: {
                        Text(verbatim: "座標")
                    }
                    Button(role: .destructive) {
                        station.latitude = nil
                        station.longitude = nil
                    } label: {
                        Text(verbatim: "位置情報を削除")
                    }
                }
            } header: {
                Text(verbatim: "位置情報（オプション）")
            } footer: {
                if let error = location.lastError {
                    Text(verbatim: error).foregroundColor(.red)
                }
            }
        }
        .navigationTitle(Text(verbatim: station.name.isEmpty ? "駅" : station.name))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Safe indexing

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
