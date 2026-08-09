#!/bin/sh
//usr/bin/true; eval "$(awk '/^\/\*BUILD/{f=1;next} /^BUILD\*\//{f=0} f' "$0")"; exit
/*BUILD
# Compiles this file once into $TMPDIR and reruns the cached binary after that.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD="${TMPDIR:-/tmp}/StationMap.build"
BIN="$BUILD/StationMap"
mkdir -p "$BUILD"
if [ ! -x "$BIN" ] || [ -n "$(find "$0" -newer "$BIN" -print -quit)" ]; then
  echo "building StationMap..." >&2
  tail -n +2 "$0" > "$BUILD/main.swift"
  xcrun swiftc -o "$BIN" "$BUILD/main.swift"
fi
exec env STATIONMAP_ROOT="$ROOT" "$BIN" "$@"
BUILD*/

// Plots every station in a folder of line JSONs on a MapKit map.
//
//   ./Assets/StationMap.swift              # defaults to Backbone/StaticData/Lines
//   ./Assets/StationMap.swift <lines-dir>
//
// Pick another folder with the フォルダ button (remembered across launches).
// Toggle "Show previous positions" to compare against git HEAD: each moved
// station draws a grey ghost pin and a vector to where it sits now.

import AppKit
import MapKit
import SwiftUI

// MARK: - Data

struct StationJSON: Decodable {
    let id: String
    let name: String
    let nameEn: String
    let stationCode: String
    let latitude: Double?
    let longitude: Double?
}

struct LineJSON: Decodable {
    let id: String
    let nameJa: String
    let nameEn: String
    let colorHex: String
    let operatorId: String
    let stations: [StationJSON]
}

struct Stop: Identifiable {
    let id: String          // line id + station id, unique per row
    let stationID: String
    let name: String
    let nameEn: String
    let code: String
    let coord: CLLocationCoordinate2D
    let lineID: String
    let lineName: String
    let color: NSColor
    let file: String
    var previous: CLLocationCoordinate2D?

    var movedMeters: Double? {
        guard let p = previous else { return nil }
        let a = CLLocation(latitude: p.latitude, longitude: p.longitude)
        let b = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return b.distance(from: a)
    }
}

struct LineGroup: Identifiable {
    let id: String
    let nameJa: String
    let nameEn: String
    let color: NSColor
    let file: String
    let count: Int
}

func color(fromHex hex: String) -> NSColor {
    var s = hex.trimmingCharacters(in: .whitespaces)
    if s.hasPrefix("#") { s.removeFirst() }
    guard let v = UInt32(s, radix: 16), s.count == 6 else { return .systemGray }
    return NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                   green: CGFloat((v >> 8) & 0xFF) / 255,
                   blue: CGFloat(v & 0xFF) / 255,
                   alpha: 1)
}

let linesDirKey = "linesDirectory"

func rememberedLinesDir() -> URL? {
    UserDefaults.standard.string(forKey: linesDirKey).map { URL(fileURLWithPath: $0) }
}

func rememberLinesDir(_ dir: URL) {
    UserDefaults.standard.set(dir.path, forKey: linesDirKey)
}

func git(_ arguments: [String], in directory: URL) -> Data? {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    p.arguments = ["-C", directory.path] + arguments
    let out = Pipe()
    p.standardOutput = out
    p.standardError = Pipe()
    guard (try? p.run()) != nil else { return nil }
    let d = out.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return p.terminationStatus == 0 ? d : nil
}

/// Reads a file as it exists at git HEAD, so we can show pre-edit positions.
func gitHEADContents(repoRelativePath: String, repoRoot: URL) -> Data? {
    git(["show", "HEAD:\(repoRelativePath)"], in: repoRoot)
}

/// The checkout containing `dir`, plus `dir`'s path inside it — so the ghost
/// pins work for any folder, not just the one in this repo.
func gitContext(for dir: URL) -> (root: URL, prefix: String)? {
    guard let data = git(["rev-parse", "--show-toplevel"], in: dir),
          let path = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
          !path.isEmpty
    else { return nil }
    let root = URL(fileURLWithPath: path).standardizedFileURL
    let full = dir.standardizedFileURL.path
    guard full.hasPrefix(root.path) else { return nil }
    let prefix = String(full.dropFirst(root.path.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    return (root, prefix)
}

func loadStops(linesDir: URL) -> ([Stop], [LineGroup]) {
    let fm = FileManager.default
    let files = ((try? fm.contentsOfDirectory(atPath: linesDir.path)) ?? [])
        .filter { $0.hasSuffix(".json") }.sorted()

    var stops: [Stop] = []
    var groups: [LineGroup] = []
    let dec = JSONDecoder()
    let repo = gitContext(for: linesDir)

    for file in files {
        let url = linesDir.appendingPathComponent(file)
        guard let data = try? Data(contentsOf: url),
              let lines = try? dec.decode([LineJSON].self, from: data) else {
            FileHandle.standardError.write(Data("skip (decode failed): \(file)\n".utf8))
            continue
        }

        // Same file at HEAD -> map of station id to its previous coordinate.
        var old: [String: CLLocationCoordinate2D] = [:]
        let rel = repo.map { $0.prefix.isEmpty ? file : "\($0.prefix)/\(file)" } ?? file
        if let repoRoot = repo?.root,
           let headData = gitHEADContents(repoRelativePath: rel, repoRoot: repoRoot),
           let headLines = try? dec.decode([LineJSON].self, from: headData) {
            for l in headLines {
                for s in l.stations {
                    if let la = s.latitude, let lo = s.longitude {
                        old[l.id + "|" + s.id] = CLLocationCoordinate2D(latitude: la, longitude: lo)
                    }
                }
            }
        }

        for l in lines {
            let c = color(fromHex: l.colorHex)
            var n = 0
            for s in l.stations {
                guard let la = s.latitude, let lo = s.longitude else { continue }
                let now = CLLocationCoordinate2D(latitude: la, longitude: lo)
                var prev = old[l.id + "|" + s.id]
                if let p = prev,
                   abs(p.latitude - la) < 1e-9, abs(p.longitude - lo) < 1e-9 {
                    prev = nil   // unchanged
                }
                stops.append(Stop(id: l.id + "|" + s.id, stationID: s.id, name: s.name,
                                  nameEn: s.nameEn, code: s.stationCode, coord: now,
                                  lineID: l.id, lineName: l.nameJa, color: c,
                                  file: file, previous: prev))
                n += 1
            }
            groups.append(LineGroup(id: l.id, nameJa: l.nameJa, nameEn: l.nameEn,
                                    color: c, file: file, count: n))
        }
    }
    return (stops, groups)
}

// MARK: - Annotations

final class StopAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let color: NSColor
    let isGhost: Bool

    init(stop: Stop, ghost: Bool) {
        self.coordinate = ghost ? (stop.previous ?? stop.coord) : stop.coord
        self.color = ghost ? .systemGray : stop.color
        self.isGhost = ghost
        var sub = stop.lineName
        if !stop.code.isEmpty { sub += " · \(stop.code)" }
        if let m = stop.movedMeters {
            sub += ghost ? " · was here (moved \(Int(m)) m)" : " · moved \(Int(m)) m"
        }
        self.title = ghost ? "\(stop.name) (previous)" : stop.name
        self.subtitle = sub
    }
}

/// Small filled dot; far cheaper to render 1400+ of these than marker pins.
func dotImage(_ c: NSColor, ghost: Bool) -> NSImage {
    let d: CGFloat = ghost ? 9 : 11
    let img = NSImage(size: NSSize(width: d, height: d))
    img.lockFocus()
    let r = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: d - 2, height: d - 2))
    c.setFill()
    r.fill()
    (ghost ? NSColor.white.withAlphaComponent(0.6) : NSColor.white).setStroke()
    r.lineWidth = ghost ? 1 : 1.5
    r.stroke()
    img.unlockFocus()
    return img
}

// MARK: - Map view

struct MapView: NSViewRepresentable {
    var stops: [Stop]
    var showPrevious: Bool
    var fitToken: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var cache: [String: NSImage] = [:]
        var lastFit = -1

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let a = annotation as? StopAnnotation else { return nil }
            let id = a.isGhost ? "ghost" : "stop"
            let v = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                ?? MKAnnotationView(annotation: a, reuseIdentifier: id)
            v.annotation = a
            v.canShowCallout = true
            let key = "\(a.color.hashValue)-\(a.isGhost)"
            if cache[key] == nil { cache[key] = dotImage(a.color, ghost: a.isGhost) }
            v.image = cache[key]
            v.displayPriority = a.isGhost ? .defaultLow : .required
            return v
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let r = MKPolylineRenderer(overlay: overlay)
            r.strokeColor = NSColor.systemRed.withAlphaComponent(0.75)
            r.lineWidth = 2
            return r
        }
    }

    func makeNSView(context: Context) -> MKMapView {
        let m = MKMapView()
        m.delegate = context.coordinator
        m.showsZoomControls = true
        m.showsCompass = true
        // Kanto
        m.setRegion(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.72, longitude: 139.75),
            span: MKCoordinateSpan(latitudeDelta: 1.1, longitudeDelta: 1.1)), animated: false)
        return m
    }

    func updateNSView(_ m: MKMapView, context: Context) {
        m.removeAnnotations(m.annotations)
        m.removeOverlays(m.overlays)

        var anns: [MKAnnotation] = stops.map { StopAnnotation(stop: $0, ghost: false) }
        if showPrevious {
            var lines: [MKPolyline] = []
            for s in stops where s.previous != nil {
                anns.append(StopAnnotation(stop: s, ghost: true))
                var pts = [s.previous!, s.coord]
                lines.append(MKPolyline(coordinates: &pts, count: 2))
            }
            m.addOverlays(lines)
        }
        m.addAnnotations(anns)

        // Frame the current selection when the Fit button is pressed (and on first load).
        if context.coordinator.lastFit != fitToken, !anns.isEmpty {
            context.coordinator.lastFit = fitToken
            m.showAnnotations(anns, animated: false)
        }
    }
}

// MARK: - UI

struct ContentView: View {
    @State private var linesDir: URL
    @State private var allStops: [Stop]
    @State private var groups: [LineGroup]

    @State private var enabled: Set<String>
    @State private var showPrevious: Bool
    @State private var onlyMoved: Bool
    @State private var query = ""
    @State private var fitToken = 0

    init(linesDir: URL, stops: [Stop], groups: [LineGroup], showPrevious: Bool, onlyMoved: Bool) {
        _linesDir = State(initialValue: linesDir)
        _allStops = State(initialValue: stops)
        _groups = State(initialValue: groups)
        _enabled = State(initialValue: Set(groups.map(\.id)))
        _showPrevious = State(initialValue: showPrevious)
        _onlyMoved = State(initialValue: onlyMoved)
    }

    private func load(_ dir: URL) {
        let (stops, groups) = loadStops(linesDir: dir)
        linesDir = dir
        allStops = stops
        self.groups = groups
        enabled = Set(groups.map(\.id))
        fitToken += 1
        rememberLinesDir(dir)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = linesDir
        panel.prompt = "Load"
        panel.message = "Choose a folder of line JSONs"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        load(url)
    }

    var visible: [Stop] {
        allStops.filter {
            guard enabled.contains($0.lineID) else { return false }
            if onlyMoved && $0.previous == nil { return false }
            if !query.isEmpty {
                let q = query.lowercased()
                return $0.name.contains(query) || $0.nameEn.lowercased().contains(q)
                    || $0.lineName.contains(query) || $0.code.lowercased().contains(q)
            }
            return true
        }
    }

    var movedCount: Int { allStops.filter { $0.previous != nil }.count }

    var byFile: [(String, [LineGroup])] {
        Dictionary(grouping: groups, by: \.file).sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("Stations")
                        .font(.headline)
                    Spacer()
                    Button { chooseFolder() } label: { Label("Folder", systemImage: "folder") }
                    Button { load(linesDir) } label: { Image(systemName: "arrow.clockwise") }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Text(linesDir.path)
                    .font(.caption).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.head).help(linesDir.path)

                Text("\(visible.count) shown · \(allStops.count) total · \(movedCount) moved vs HEAD")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)

                TextField("Filter station / line", text: $query)
                    .textFieldStyle(.roundedBorder)

                Toggle("Show previous positions", isOn: $showPrevious)
                Toggle("Only moved stations", isOn: $onlyMoved)

                HStack {
                    Button("All") { enabled = Set(groups.map(\.id)) }
                    Button("None") { enabled = [] }
                    Button("Fit") { fitToken += 1 }
                }.controlSize(.small)

                Divider()

                List {
                    ForEach(byFile, id: \.0) { file, ls in
                        Section(file.replacingOccurrences(of: ".json", with: "")) {
                            ForEach(ls) { g in
                                Toggle(isOn: Binding(
                                    get: { enabled.contains(g.id) },
                                    set: { on in
                                        if on { enabled.insert(g.id) } else { enabled.remove(g.id) }
                                    })) {
                                    HStack(spacing: 6) {
                                        Circle().fill(Color(g.color)).frame(width: 9, height: 9)
                                        Text(g.nameJa).font(.system(size: 11))
                                        Spacer()
                                        Text("\(g.count)").font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }.listStyle(.sidebar)
            }
            .padding(10)
            .frame(minWidth: 260, idealWidth: 300, maxWidth: 420)

            MapView(stops: visible, showPrevious: showPrevious, fitToken: fitToken)
                .frame(minWidth: 600, minHeight: 500)
        }
    }
}

// MARK: - Launch

let args = Array(CommandLine.arguments.dropFirst())
let flagPrevious = args.contains("--previous") || args.contains("--moved")
let flagOnlyMoved = args.contains("--moved")

let repoRoot = URL(fileURLWithPath: ProcessInfo.processInfo.environment["STATIONMAP_ROOT"]
    ?? URL(fileURLWithPath: CommandLine.arguments[0])
        .deletingLastPathComponent().deletingLastPathComponent().path).standardizedFileURL
let positional = args.filter { !$0.hasPrefix("--") }
let linesDir: URL = positional.first.map { URL(fileURLWithPath: $0) }
    ?? rememberedLinesDir()
    ?? repoRoot.appendingPathComponent("Backbone/StaticData/Lines")

let (stops, groups) = loadStops(linesDir: linesDir)
print("loaded \(stops.count) stations across \(groups.count) lines from \(linesDir.path)")
print("moved vs HEAD: \(stops.filter { $0.previous != nil }.count)")

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 1280, height: 820),
    styleMask: [.titled, .closable, .miniaturizable, .resizable],
    backing: .buffered, defer: false)
window.title = "Overhead — Station Map"
window.contentView = NSHostingView(rootView: ContentView(
    linesDir: linesDir, stops: stops, groups: groups,
    showPrevious: flagPrevious, onlyMoved: flagOnlyMoved))
window.center()
window.makeKeyAndOrderFront(nil)

app.activate(ignoringOtherApps: true)
app.run()
