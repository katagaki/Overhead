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
                    Text("CustomLine.UseTimetable")
                }
            } footer: {
                Text("CustomLine.UseTimetable.Footer")
            }

            if line.timetable != nil {
                Section {
                    Picker(selection: $calendar) {
                        Text("CustomLine.Weekday").tag(ScheduleCalendar.weekday)
                        Text("CustomLine.SaturdayHoliday").tag(ScheduleCalendar.saturdayHoliday)
                    } label: {
                        Text("CustomLine.Calendar")
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))

                    railTimeRow(label: "CustomLine.FirstDeparture", value: patternBinding(\.firstDeparture))
                    railTimeRow(label: "CustomLine.LastDeparture", value: patternBinding(\.lastDeparture))

                    Stepper(value: headwayBinding, in: 1...60) {
                        LabeledContent {
                            Text("CustomLine.Minutes \(pattern.headwayMinutes)")
                        } label: {
                            Text("CustomLine.Headway")
                        }
                    }
                } header: {
                    Text("CustomLine.Pattern")
                } footer: {
                    Text("CustomLine.RailTime.Footer")
                }
            }
        }
        .navigationTitle(Text("CustomLine.Timetable"))
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

    private func railTimeRow(label: LocalizedStringKey, value: Binding<String>) -> some View {
        LabeledContent {
            TextField("", text: value, prompt: Text(verbatim: "05:00"))
                .multilineTextAlignment(.trailing)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .font(.system(.body, design: .rounded))
        } label: {
            Text(label)
        }
    }
}
