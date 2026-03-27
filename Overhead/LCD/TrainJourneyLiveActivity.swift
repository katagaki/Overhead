import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Live Activity Widget

struct TrainJourneyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainJourneyAttributes.self) { context in
            // Lock Screen / Banner presentation
            LockScreenLiveActivityView(context: context)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.lineName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: context.attributes.lineColorHex))
                        HStack(spacing: 4) {
                            Text(context.attributes.trainType)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            if context.state.isTimetableMode {
                                Text("Badge.Timetable")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.orange.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.leading, 2)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if context.state.isDelayed {
                            Text("LiveActivity.Delay.Minutes \(context.state.delayMinutes)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                        } else {
                            Text("Status.OnTime")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.green)
                        }
                        Text(formatTime(context.state.estimatedArrival))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 2)
                }

                DynamicIslandExpandedRegion(.center) {
                    ExpandedIslandLineView(context: context)
                        .padding(.horizontal, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("LiveActivity.NextIs \(context.state.nextStationName)")
                                .font(.system(size: 13, weight: .semibold))
                        }

                        Spacer()

                        Link(destination: URL(string: context.attributes.refreshURLString)!) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10, weight: .semibold))
                                Text(refreshAgeText(context.state.lastRefresh))
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(Color(hex: context.attributes.lineColorHex))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: context.attributes.lineColorHex).opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 4)
                }

            } compactLeading: {
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color(hex: context.attributes.lineColorHex))
                        .frame(width: 8, height: 8)
                    Text(context.state.nextStationName.prefix(3))
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                }

            } compactTrailing: {
                if context.state.isDelayed {
                    Text("+\(context.state.delayMinutes)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                } else {
                    Text(formatTime(context.state.estimatedArrival))
                        .font(.system(size: 12, design: .monospaced))
                }

            } minimal: {
                ZStack {
                    Circle()
                        .strokeBorder(Color(hex: context.attributes.lineColorHex), lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(Color(hex: context.attributes.lineColorHex), lineWidth: 2)
                        .rotationEffect(.degrees(-90))
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f.string(from: date)
    }

    private func refreshAgeText(_ lastRefresh: Date) -> String {
        let seconds = Int(-lastRefresh.timeIntervalSinceNow)
        if seconds < 30 { return String(localized: "Time.Now") }
        let minutes = seconds / 60
        if minutes < 1 { return String(localized: "Time.LessThanOneMinuteAgo") }
        return String(localized: "Time.MinutesAgo \(minutes)")
    }
}

// MARK: - Lock Screen Live Activity View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TrainJourneyAttributes>

    private var lineColor: Color { Color(hex: context.attributes.lineColorHex) }

    var body: some View {
        VStack(spacing: 0) {
            // Header: line name + tracking mode + delay
            HStack {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(lineColor)
                        .frame(width: 4, height: 20)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Text(context.attributes.lineName)
                                .font(.system(size: 14, weight: .bold))
                            trackingModeBadge
                        }
                        Text("Destination.Suffix \(context.attributes.trainType) \(context.attributes.destinationName)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if context.state.isDelayed {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("LiveActivity.Delay.Badge \(context.state.delayMinutes)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.9))
                    .clipShape(Capsule())
                } else {
                    Text("Status.OnTimeOperation")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // LCD line diagram
            LCDLineView(
                stationNames: context.attributes.stationNames,
                stationCount: context.attributes.stationCount,
                progress: context.state.progress,
                currentStationIndex: context.state.currentStationIndex,
                lineColor: lineColor
            )
            .padding(.horizontal, 16)

            // Footer: next station + ETA + refresh button
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Label.NextStation")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(context.state.nextStationName)
                        .font(.system(size: 16, weight: .bold))
                    Text(context.state.nextStationNameEn)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Label.EstimatedArrival")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(formatTime(context.state.estimatedArrival))
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(context.state.isDelayed ? .red : .primary)
                    }

                    Link(destination: URL(string: context.attributes.refreshURLString)!) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9, weight: .semibold))
                            Text("Button.RefreshDelayInfo")
                                .font(.system(size: 9, weight: .medium))
                            Text("(\(refreshAgeText(context.state.lastRefresh)))")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(lineColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(lineColor.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground).opacity(0.95))
    }

    // MARK: - Tracking Mode Badge

    @ViewBuilder
    private var trackingModeBadge: some View {
        let mode = context.state.trackingModeRaw
        if mode == "Timetable" {
            HStack(spacing: 2) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 7))
                Text("Badge.Timetable")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
        } else if mode == "GPS" {
            HStack(spacing: 2) {
                Image(systemName: "location.fill")
                    .font(.system(size: 7))
                Text("Badge.GPS")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.15))
            .clipShape(Capsule())
        } else {
            HStack(spacing: 2) {
                Image(systemName: "location.fill")
                    .font(.system(size: 7))
                Text("Badge.GPSPlusTimetable")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.15))
            .clipShape(Capsule())
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f.string(from: date)
    }

    private func refreshAgeText(_ lastRefresh: Date) -> String {
        let seconds = Int(-lastRefresh.timeIntervalSinceNow)
        if seconds < 30 { return String(localized: "Time.Now") }
        let minutes = seconds / 60
        if minutes < 1 { return String(localized: "Time.LessThanOneMinuteAgo") }
        return String(localized: "Time.MinutesAgo \(minutes)")
    }
}

// MARK: - LCD Line View (Horizontal - for Lock Screen)

struct LCDLineView: View {
    let stationNames: [String]
    let stationCount: Int
    let progress: Double
    let currentStationIndex: Int?
    let lineColor: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h: CGFloat = 40
            let circleRadius: CGFloat = stationCount > 10 ? 4.5 : 6
            let padding: CGFloat = circleRadius + 2
            let lineWidth = w - padding * 2

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: lineWidth, height: 4)
                    .offset(x: padding, y: h / 2 - 2)

                RoundedRectangle(cornerRadius: 2)
                    .fill(lineColor)
                    .frame(width: max(0, lineWidth * progress), height: 4)
                    .offset(x: padding, y: h / 2 - 2)

                ForEach(0..<stationCount, id: \.self) { i in
                    let frac = stationCount > 1 ? Double(i) / Double(stationCount - 1) : 0
                    let x = padding + lineWidth * frac
                    let isPast = frac <= progress + 0.01
                    let isCurrent = currentStationIndex == i

                    VStack(spacing: 2) {
                        if shouldShowLabel(index: i) {
                            Text(truncatedName(stationNames[i]))
                                .font(.system(size: 8, weight: isCurrent ? .bold : .regular))
                                .foregroundColor(isCurrent ? lineColor : .secondary)
                                .lineLimit(1)
                                .frame(width: 36)
                                .offset(y: -2)
                        } else {
                            Spacer().frame(height: 10)
                        }

                        ZStack {
                            Circle()
                                .fill(isPast ? lineColor : Color.gray.opacity(0.3))
                                .frame(width: circleRadius * 2, height: circleRadius * 2)

                            if isCurrent {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: circleRadius, height: circleRadius)
                            }

                            if i == 0 || i == stationCount - 1 {
                                Circle()
                                    .strokeBorder(isPast ? lineColor : Color.gray.opacity(0.5), lineWidth: 2)
                                    .frame(width: circleRadius * 2 + 4, height: circleRadius * 2 + 4)
                            }
                        }
                    }
                    .position(x: x, y: h / 2)
                }

                let trainX = padding + lineWidth * progress
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 8))
                    .foregroundColor(lineColor)
                    .position(x: trainX, y: h / 2 + circleRadius + 10)
            }
            .frame(height: h)
        }
        .frame(height: 40)
    }

    private func shouldShowLabel(index: Int) -> Bool {
        if stationCount <= 6 { return true }
        if index == 0 || index == stationCount - 1 { return true }
        if index == currentStationIndex { return true }
        let step = max(2, stationCount / 5)
        return index % step == 0
    }

    private func truncatedName(_ name: String) -> String {
        if name.count > 3 { return String(name.prefix(3)) }
        return name
    }
}

// MARK: - Expanded Island Line View

struct ExpandedIslandLineView: View {
    let context: ActivityViewContext<TrainJourneyAttributes>

    private var lineColor: Color { Color(hex: context.attributes.lineColorHex) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let count = context.attributes.stationCount
            let r: CGFloat = count > 8 ? 3.0 : 4.0
            let pad: CGFloat = r + 1

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: w - pad * 2, height: 3)
                    .offset(x: pad)

                Capsule()
                    .fill(lineColor)
                    .frame(width: max(0, (w - pad * 2) * context.state.progress), height: 3)
                    .offset(x: pad)

                ForEach(0..<count, id: \.self) { i in
                    let frac = count > 1 ? Double(i) / Double(count - 1) : 0
                    let x = pad + (w - pad * 2) * frac
                    let isPast = frac <= context.state.progress + 0.01

                    Circle()
                        .fill(isPast ? lineColor : Color.gray.opacity(0.4))
                        .frame(width: r * 2, height: r * 2)
                        .overlay {
                            if i == 0 || i == count - 1 {
                                Circle()
                                    .strokeBorder(isPast ? lineColor : Color.gray.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: r * 2 + 3, height: r * 2 + 3)
                            }
                        }
                        .position(x: x, y: 6)
                }
            }
            .frame(height: 12)
        }
        .frame(height: 12)
    }
}
