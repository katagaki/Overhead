#!/bin/sh
//usr/bin/true; eval "$(awk '/^\/\*BUILD/{f=1;next} /^BUILD\*\//{f=0} f' "$0")"; exit
/*BUILD
# Compiles this file together with Backbone into a .app bundle (cached in
# $TMPDIR, rebuilt only when a source changes) and runs it.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD="${TMPDIR:-/tmp}/DataChecker.build"
APP="$BUILD/DataChecker.app"
BIN="$APP/Contents/MacOS/DataChecker"
mkdir -p "$APP/Contents/MacOS"
if [ ! -x "$BIN" ] || [ -n "$(find "$ROOT/Backbone" "$0" -newer "$BIN" -print -quit)" ]; then
  echo "building DataChecker..." >&2
  tail -n +2 "$0" > "$BUILD/DataChecker.swift"
  printf '%s' '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>DataChecker</string>
<key>CFBundleIdentifier</key><string>com.katagaki.DataChecker</string>
<key>CFBundleName</key><string>DataChecker</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>' > "$APP/Contents/Info.plist"
  xcrun swiftc -parse-as-library -o "$BIN" \
    $(find "$ROOT/Backbone" -name "*.swift") "$BUILD/DataChecker.swift"
fi
exec env DATACHECKER_ROOT="$ROOT" "$BIN" "$@"
BUILD*/

// DataChecker — side-by-side check of generated timetable data against the official site.
//
//   ./Assets/DataChecker.swift              # or from anywhere; path is resolved
//   ./Assets/DataChecker.swift <lines-dir>
//
// Line JSONs default to Backbone/StaticData/Lines in this repo. Pick another
// folder with the フォルダ button (remembered across launches).

import SwiftUI
import WebKit

// MARK: - Data loading

enum LineLoader {
    private static let defaultsKey = "linesDirectory"

    /// Argument > last picked folder > Backbone/StaticData/Lines next to this source.
    static func defaultDirectory() -> URL {
        if let arg = CommandLine.arguments.dropFirst().first, !arg.hasPrefix("-") {
            return URL(fileURLWithPath: arg)
        }
        if let saved = UserDefaults.standard.string(forKey: defaultsKey) {
            return URL(fileURLWithPath: saved)
        }
        let root = ProcessInfo.processInfo.environment["DATACHECKER_ROOT"]
            ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent()
                .deletingLastPathComponent().path
        return URL(fileURLWithPath: root).appendingPathComponent("Backbone/StaticData/Lines")
    }

    static func remember(_ directory: URL) {
        UserDefaults.standard.set(directory.path, forKey: defaultsKey)
    }

    /// Folder picker for a directory of line JSONs.
    static func choose(startingAt current: URL) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = current
        panel.prompt = "読み込み"
        panel.message = "路線 JSON の入ったフォルダを選択"
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        remember(url)
        return url
    }

    static func loadAll(from directory: URL) -> (lines: [StaticTrainLine], errors: [String]) {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: directory.path) else {
            return ([], ["Cannot read \(directory.path)"])
        }
        var lines: [StaticTrainLine] = []
        var errors: [String] = []
        for name in names.sorted() where name.hasSuffix(".json") {
            let url = directory.appendingPathComponent(name)
            do {
                let data = try Data(contentsOf: url)
                lines.append(contentsOf: try JSONDecoder().decode([StaticTrainLine].self, from: data))
            } catch {
                errors.append("\(name): \(error)")
            }
        }
        return (lines.sorted { ($0.operatorId, $0.nameJa) < ($1.operatorId, $1.nameJa) }, errors)
    }
}

// MARK: - Official site links

enum OfficialLink {
    /// Yahoo!路線情報 — station page listing every line's timetable at that station.
    static func yahoo(station: Station) -> URL {
        url("https://transit.yahoo.co.jp/timetable/search?q=", station.name)
    }

    /// ジョルダン 駅時刻表 (redirects through a JS hop; fine in a real browser).
    static func jorudan(station: Station) -> URL {
        url("https://www.jorudan.co.jp/time/eki_", station.name, suffix: ".html")
    }

    /// The operator's own site — root of its 運行情報 page.
    static func operatorSite(line: StaticTrainLine) -> URL? {
        guard let status = URL(string: line.delayInfo.statusPageURL),
              let scheme = status.scheme, let host = status.host
        else { return nil }
        return URL(string: "\(scheme)://\(host)/")
    }

    static func status(line: StaticTrainLine) -> URL? {
        URL(string: line.delayInfo.statusPageURL)
    }

    private static func url(_ base: String, _ value: String, suffix: String = "") -> URL {
        let escaped = value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        return URL(string: base + escaped + suffix)!
    }
}

// MARK: - Time helpers

enum RailTime {
    /// All "H:mm" tokens in a blob of text, as minutes since midnight.
    static func parse(_ text: String) -> [Int] {
        var result: [Int] = []
        let colon = try! NSRegularExpression(pattern: #"(\d{1,2})\s*[:：]\s*(\d{2})"#)
        let ns = text as NSString
        for m in colon.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let h = Int(ns.substring(with: m.range(at: 1)))!
            let mm = Int(ns.substring(with: m.range(at: 2)))!
            guard mm < 60 else { continue }
            result.append(h * 60 + mm)
        }
        guard result.isEmpty else { return normalize(result) }
        return normalize(parseHourRows(text))
    }

    /// Ekitan/official grid style: one row per hour, "5  12 30 45".
    private static func parseHourRows(_ text: String) -> [Int] {
        var result: [Int] = []
        for line in text.split(whereSeparator: \.isNewline) {
            let nums = line
                .split(whereSeparator: { !$0.isNumber })
                .compactMap { Int($0) }
            guard let hour = nums.first, nums.count > 1, hour <= 27 else { continue }
            for minute in nums.dropFirst() where minute < 60 {
                result.append(hour * 60 + minute)
            }
        }
        return result
    }

    /// Past-midnight times are written 0:xx on official sites, 24:xx in our data.
    private static func normalize(_ minutes: [Int]) -> [Int] {
        Set(minutes.map { $0 < 3 * 60 ? $0 + 24 * 60 : $0 }).sorted()
    }

    static func string(_ minutes: Int) -> String {
        String(format: "%d:%02d", minutes / 60, minutes % 60)
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct DataCheckerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup("DataChecker") {
            ContentView()
                .frame(minWidth: 1200, minHeight: 720)
        }
        .windowStyle(.titleBar)
    }
}

struct ContentView: View {
    @State private var directory: URL = LineLoader.defaultDirectory()
    @State private var lines: [StaticTrainLine] = []
    @State private var loadErrors: [String] = []
    @State private var lineFilter: String = ""
    @State private var selectedLineId: String?
    @State private var selectedStationId: String?
    @State private var calendar: ScheduleCalendar = .weekday
    @State private var directionIndex: Int = 0
    @State private var webURL: URL = URL(string: "https://transit.yahoo.co.jp/timetable")!
    @State private var official: String = ""

    private var selectedLine: StaticTrainLine? {
        lines.first { $0.id == selectedLineId }
    }

    private var selectedStation: Station? {
        selectedLine?.stations.first { $0.id == selectedStationId }
    }

    private var filteredLines: [StaticTrainLine] {
        guard !lineFilter.isEmpty else { return lines }
        let needle = lineFilter.lowercased()
        return lines.filter {
            $0.nameJa.contains(lineFilter) || $0.nameEn.lowercased().contains(needle)
        }
    }

    private var timetables: [StationTimetableData] {
        guard let line = selectedLine, let stationId = selectedStationId else { return [] }
        return StaticTimetableGenerator.stationTimetables(
            for: line, stationId: stationId, calendar: calendar
        )
    }

    private var timetable: StationTimetableData? {
        let all = timetables
        guard !all.isEmpty else { return nil }
        return all[min(directionIndex, all.count - 1)]
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                pickers
                Divider()
                if let timetable {
                    TimetablePane(
                        timetable: timetable,
                        official: $official
                    )
                } else {
                    ContentUnavailableView(
                        lines.isEmpty ? "路線データなし" : "駅を選択",
                        systemImage: "tram",
                        description: loadErrors.isEmpty ? nil : Text(loadErrors.joined(separator: "\n"))
                    )
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(minWidth: 420, idealWidth: 520)

            WebPane(url: $webURL)
                .frame(minWidth: 520)
        }
        .task { reload() }
        .onChange(of: selectedLineId) { _, _ in
            selectedStationId = selectedLine?.stations.first?.id
            directionIndex = 0
        }
        .onChange(of: selectedStationId) { _, _ in
            directionIndex = 0
            official = ""
            openOfficial()
        }
    }

    // MARK: Pickers

    private var pickers: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Button {
                    if let picked = LineLoader.choose(startingAt: directory) {
                        directory = picked
                        reload()
                    }
                } label: {
                    Label("フォルダ", systemImage: "folder")
                }
                Button { reload() } label: { Image(systemName: "arrow.clockwise") }
                Text(directory.path)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.head)
                    .foregroundStyle(.secondary)
                    .help(directory.path)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            HStack {
                TextField("路線を絞り込み", text: $lineFilter)
                    .textFieldStyle(.roundedBorder)
                Text("\(lines.count) 路線")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            HStack {
                Picker("路線", selection: $selectedLineId) {
                    ForEach(filteredLines, id: \.id) { line in
                        Text(line.nameJa).tag(Optional(line.id))
                    }
                }
                Picker("駅", selection: $selectedStationId) {
                    ForEach(selectedLine?.stations ?? [], id: \.id) { station in
                        Text(station.name).tag(Optional(station.id))
                    }
                }
            }

            Picker("", selection: $calendar) {
                Text("平日").tag(ScheduleCalendar.weekday)
                Text("土休日").tag(ScheduleCalendar.saturdayHoliday)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if timetables.count > 1 {
                Picker("", selection: $directionIndex) {
                    ForEach(Array(timetables.enumerated()), id: \.offset) { index, data in
                        Text(data.railDirectionName).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            HStack(spacing: 6) {
                if let line = selectedLine, let station = selectedStation {
                    Button("Yahoo!時刻表") { webURL = OfficialLink.yahoo(station: station) }
                    Button("ジョルダン") { webURL = OfficialLink.jorudan(station: station) }
                    Button("公式サイト") { webURL = OfficialLink.operatorSite(line: line) ?? webURL }
                    Button("運行情報") { webURL = OfficialLink.status(line: line) ?? webURL }
                    Spacer()
                    Text(line.id).font(.caption.monospaced()).foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(10)
        .onChange(of: calendar) { _, _ in official = "" }
    }

    private func reload() {
        let loaded = LineLoader.loadAll(from: directory)
        lines = loaded.lines
        loadErrors = loaded.errors
        if !lines.contains(where: { $0.id == selectedLineId }) {
            selectedLineId = lines.first?.id
            selectedStationId = lines.first?.stations.first?.id
            directionIndex = 0
            official = ""
        }
    }

    private func openOfficial() {
        guard let station = selectedStation else { return }
        webURL = OfficialLink.yahoo(station: station)
    }
}

// MARK: - Generated timetable + diff

struct TimetablePane: View {
    let timetable: StationTimetableData
    @Binding var official: String

    private var departures: [(minute: Int, departure: StationDeparture)] {
        timetable.departures.compactMap { dep in
            guard let secs = TimetableEntry.parseRailTime(dep.departureTime) else { return nil }
            return (secs / 60, dep)
        }
        .sorted { $0.minute < $1.minute }
    }

    private var byHour: [(hour: Int, rows: [(minute: Int, departure: StationDeparture)])] {
        Dictionary(grouping: departures) { $0.minute / 60 }
            .sorted { $0.key < $1.key }
            .map { (hour: $0.key, rows: $0.value.sorted { $0.minute < $1.minute }) }
    }

    private var officialMinutes: [Int] { RailTime.parse(official) }

    private var diff: (missing: [Int], extra: [Int])? {
        guard !officialMinutes.isEmpty else { return nil }
        let ours = Set(departures.map(\.minute))
        let theirs = Set(officialMinutes)
        return (theirs.subtracting(ours).sorted(), ours.subtracting(theirs).sorted())
    }

    var body: some View {
        VSplitView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(byHour, id: \.hour) { group in
                        HourRow(
                            hour: group.hour,
                            rows: group.rows,
                            officialMinutes: Set(officialMinutes),
                            hasOfficial: !officialMinutes.isEmpty
                        )
                        Divider()
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 220)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("公式の時刻を貼り付け")
                        .font(.headline)
                    Spacer()
                    Text("\(departures.count) 本 / 公式 \(officialMinutes.count) 本")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("消去") { official = "" }
                        .controlSize(.small)
                }
                TextEditor(text: $official)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 80)
                    .border(.separator)

                if let diff {
                    HStack(alignment: .top, spacing: 16) {
                        DiffColumn(title: "公式にあってアプリにない", minutes: diff.missing, color: .red)
                        DiffColumn(title: "アプリにあって公式にない", minutes: diff.extra, color: .orange)
                    }
                    if diff.missing.isEmpty && diff.extra.isEmpty {
                        Label("一致", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(10)
            .frame(minHeight: 200)
        }
    }
}

private struct HourRow: View {
    let hour: Int
    let rows: [(minute: Int, departure: StationDeparture)]
    let officialMinutes: Set<Int>
    let hasOfficial: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(hour)")
                .font(.system(.title3, design: .monospaced).bold())
                .frame(width: 34, alignment: .trailing)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(rows, id: \.minute) { row in
                    HStack(spacing: 6) {
                        Text(String(format: "%02d", row.minute % 60))
                            .font(.system(.body, design: .monospaced).bold())
                            .frame(width: 26, alignment: .trailing)
                        Text(row.departure.trainType.displayNameJa)
                            .font(.caption)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(row.departure.trainType == .local ? Color.gray.opacity(0.2) : Color.accentColor.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                        Text(row.departure.destinationName)
                        if row.departure.isFirst {
                            Text("始発").font(.caption2).foregroundStyle(.blue)
                        }
                        if row.departure.isLast {
                            Text("終電").font(.caption2).foregroundStyle(.purple)
                        }
                        Spacer()
                        if hasOfficial, !officialMinutes.contains(row.minute) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}

private struct DiffColumn: View {
    let title: String
    let minutes: [Int]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(title) (\(minutes.count))")
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(minutes.isEmpty ? "—" : minutes.map(RailTime.string).joined(separator: "  "))
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Web pane

struct WebPane: View {
    @Binding var url: URL
    @State private var address: String = ""
    @State private var webView = makeWebView()

    /// Official sites gate content on the UA; pretend to be Safari 26 on macOS.
    private static func makeWebView() -> WKWebView {
        let view = WKWebView()
        view.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"
        return view
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { webView.goBack() } label: { Image(systemName: "chevron.left") }
                Button { webView.goForward() } label: { Image(systemName: "chevron.right") }
                Button { webView.reload() } label: { Image(systemName: "arrow.clockwise") }
                TextField("URL", text: $address)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        let text = address.hasPrefix("http") ? address : "https://\(address)"
                        if let new = URL(string: text) { url = new }
                    }
            }
            .buttonStyle(.borderless)
            .padding(8)
            Divider()
            WebViewRepresentable(webView: webView, url: url, address: $address)
        }
        .onChange(of: url) { _, new in address = new.absoluteString }
        .onAppear { address = url.absoluteString }
    }
}

struct WebViewRepresentable: NSViewRepresentable {
    let webView: WKWebView
    let url: URL
    @Binding var address: String

    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.address = $address
        if nsView.url?.absoluteString != url.absoluteString, context.coordinator.requested != url {
            context.coordinator.requested = url
            nsView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(address: $address) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var address: Binding<String>
        var requested: URL?

        init(address: Binding<String>) { self.address = address }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            if let current = webView.url { address.wrappedValue = current.absoluteString }
        }
    }
}
