import SwiftUI
import Backbone

// MARK: - Shinkansen Ticker View

/// Simulation of the Tokaido Shinkansen in-deck full-color ticker.
struct ShinkansenTickerView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color

    private static let designWidth: CGFloat = 360
    private static let stripeHeight: CGFloat = 6
    private static let windowHeight: CGFloat = 40
    private static let designHeight: CGFloat = 5 + stripeHeight + 4 + windowHeight + 7
    private static let scrollPointsPerSecond: Double = 55
    private static let bodyBlue = Color(hex: "#1153A6")
    private static let orange = Color(hex: "#FF9A1F")
    private static let red = Color(hex: "#FF4438")

    private struct Segment {
        let text: String
        let color: Color
    }

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / Self.designWidth
            VStack(spacing: 0) {
                Color.clear.frame(height: 5)
                Self.bodyBlue.frame(height: Self.stripeHeight)
                Color.clear.frame(height: 4)
                window
                    .frame(height: Self.windowHeight)
                    .padding(.horizontal, 14)
            }
            .frame(width: Self.designWidth, height: Self.designHeight, alignment: .top)
            .background(LinearGradient(
                colors: [Color(hex: "#FDFDFC"), Color(hex: "#ECEFF1")],
                startPoint: .top, endPoint: .bottom
            ))
            .scaleEffect(scale, anchor: .topLeading)
        }
        .aspectRatio(Self.designWidth / Self.designHeight, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(6)
        .glassEffect(.regular.tint(Color(red: 0.2, green: 0.26, blue: 0.33).opacity(0.4)), in: RoundedRectangle(cornerRadius: 12))
    }

    private var window: some View {
        let segments = self.segments
        return TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: "#050505")))
                let resolved = segments.map { segment in
                    ctx.resolve(
                        Text(verbatim: segment.text)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(segment.color)
                    )
                }
                let widths = resolved.map { $0.measure(in: CGSize(width: .greatestFiniteMagnitude, height: size.height)).width }
                let total = widths.reduce(0, +)
                let cycle = total + size.width
                let t = context.date.timeIntervalSinceReferenceDate
                let offset = (t * Self.scrollPointsPerSecond).truncatingRemainder(dividingBy: cycle)
                var x = size.width - offset
                ctx.clip(to: Path(CGRect(origin: .zero, size: size)))
                for (text, width) in zip(resolved, widths) {
                    if x + width > 0 && x < size.width {
                        ctx.draw(text, at: CGPoint(x: x, y: size.height / 2), anchor: .leading)
                    }
                    x += width
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color(hex: "#43474D"), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Message

    private var segments: [Segment] {
        guard let station = headlineStation else { return [] }
        let destination = destinationStation
        let dwelling = state.currentStationIndex != nil
        var segments: [Segment] = [
            Segment(text: "この電車は、\(strippedLineName)　", color: .white),
            Segment(text: "\(typeNameJa)　\(destination?.name ?? "")ゆき", color: Self.orange),
            Segment(text: "です。", color: .white),
        ]
        if dwelling {
            segments.append(Segment(text: "ただいま、", color: .white))
            segments.append(Segment(text: station.name, color: Self.orange))
            segments.append(Segment(text: "に停車しております。", color: .white))
        } else {
            segments.append(Segment(text: "次は、", color: .white))
            segments.append(Segment(text: station.name, color: Self.orange))
            segments.append(Segment(text: "に停まります。", color: .white))
        }
        if state.delayMinutes > 0 {
            segments.append(Segment(
                text: "　ただいま、約\(state.delayMinutes)分遅れて運転しております。",
                color: Self.red
            ))
        }
        segments.append(Segment(text: "　　　This is the ", color: .white))
        segments.append(Segment(text: typeNameEn, color: Self.orange))
        segments.append(Segment(text: " train bound for ", color: .white))
        segments.append(Segment(text: destination?.nameEn ?? "", color: Self.orange))
        segments.append(Segment(
            text: dwelling ? ". We are now stopped at " : ". The next stop is ",
            color: .white
        ))
        segments.append(Segment(text: station.nameEn, color: Self.orange))
        segments.append(Segment(text: ".　　　", color: .white))
        return segments
    }

    private var headlineStation: Station? {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return nil }
        let index = state.currentStationIndex ?? state.segmentTo
        return stations[max(0, min(index, stations.count - 1))]
    }

    private var destinationStation: Station? {
        journey.line.stations.first { $0.id == journey.service.destinationStationId }
            ?? journey.journeyStations.last
    }

    private var typeNameJa: String {
        journey.service.trainType == .local ? "各駅停車" : journey.service.trainType.displayNameJa
    }

    private var typeNameEn: String {
        journey.service.trainType.rawValue
            .replacingOccurrences(
                of: "([a-z])([A-Z])", with: "$1 $2",
                options: .regularExpression
            )
    }

    /// First leg's line name without a trailing train-type qualifier.
    private var strippedLineName: String {
        let component = journey.line.name.components(separatedBy: "〜").first
            ?? journey.line.name
        let suffixes = ["通勤快速", "特別快速", "各駅停車", "快速", "急行", "特急"]
        for suffix in suffixes
        where component.hasSuffix(suffix) && component.count > suffix.count {
            return String(component.dropLast(suffix.count))
        }
        return component
    }
}
