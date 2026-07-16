import SwiftUI
import Backbone

// MARK: - Custom Timetable Editor

struct CustomTimetableEditorView: View {
    @Binding var line: CustomLine
    @State private var calendar: ScheduleCalendar = .weekday

    private var isEnabled: Binding<Bool> {
        Binding(
            get: { line.timetable != nil },
            set: { line.timetable = $0 ? (line.timetable ?? CustomTimetable()) : nil }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: isEnabled) {
                    Text(verbatim: "時刻表を使う")
                }
            } footer: {
                Text(verbatim: "時刻表なしでも走行できます（手動で駅を進めるモード）。")
            }

            if line.timetable != nil {
                Section {
                    Picker(selection: $calendar) {
                        Text(verbatim: "平日").tag(ScheduleCalendar.weekday)
                        Text(verbatim: "土休日").tag(ScheduleCalendar.saturdayHoliday)
                    } label: {
                        Text(verbatim: "カレンダー")
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))

                    railTimeRow(label: "始発", value: patternBinding(\.firstDeparture))
                    railTimeRow(label: "終電", value: patternBinding(\.lastDeparture))

                    Stepper(value: headwayBinding, in: 1...60) {
                        LabeledContent {
                            Text(verbatim: "\(pattern.headwayMinutes)分")
                        } label: {
                            Text(verbatim: "運転間隔")
                        }
                    }
                } header: {
                    Text(verbatim: "運転パターン")
                } footer: {
                    Text(verbatim: "24時以降は「24:10」のように入力できます。")
                }
            }
        }
        .navigationTitle(Text(verbatim: "時刻表"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Pattern bindings

    private var pattern: CustomServicePattern {
        line.timetable?.pattern(for: calendar) ?? CustomServicePattern()
    }

    private func patternBinding(_ keyPath: WritableKeyPath<CustomServicePattern, String>) -> Binding<String> {
        Binding(
            get: { pattern[keyPath: keyPath] },
            set: { newValue in
                guard line.timetable != nil else { return }
                if calendar == .weekday { line.timetable!.weekday[keyPath: keyPath] = newValue }
                else { line.timetable!.saturdayHoliday[keyPath: keyPath] = newValue }
            }
        )
    }

    private var headwayBinding: Binding<Int> {
        Binding(
            get: { pattern.headwayMinutes },
            set: { newValue in
                guard line.timetable != nil else { return }
                if calendar == .weekday { line.timetable!.weekday.headwayMinutes = newValue }
                else { line.timetable!.saturdayHoliday.headwayMinutes = newValue }
            }
        )
    }

    private func railTimeRow(label: String, value: Binding<String>) -> some View {
        LabeledContent {
            TextField("", text: value, prompt: Text(verbatim: "05:00"))
                .multilineTextAlignment(.trailing)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .font(.system(.body, design: .rounded))
        } label: {
            Text(verbatim: label)
        }
    }
}
