import SwiftUI

struct ScheduleView: View {
    @StateObject private var scheduleManager = ScheduleManager()
    @State private var showingNewSchedule = false
    
    var body: some View {
        List {
            ForEach(scheduleManager.schedules) { schedule in
                ScheduleRow(schedule: schedule)
            }
            .onDelete { indexSet in
                scheduleManager.removeSchedules(at: indexSet)
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: { showingNewSchedule = true }) {
                    Label("Add Schedule", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewSchedule) {
            NewScheduleView(scheduleManager: scheduleManager)
        }
    }
}

struct ScheduleRow: View {
    let schedule: Schedule
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(schedule.name)
                    .font(.headline)
                Text(schedule.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(schedule.isEnabled))
                .toggleStyle(.switch)
        }
        .padding(.vertical, 4)
    }
}

struct NewScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var scheduleManager: ScheduleManager
    
    @State private var name = ""
    @State private var action: ScheduleAction = .start
    @State private var time = Date()
    @State private var days: Set<DayOfWeek> = []
    @State private var isEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Schedule Name", text: $name)
                
                Picker("Action", selection: $action) {
                    Text("Start Zscaler").tag(ScheduleAction.start)
                    Text("Stop Zscaler").tag(ScheduleAction.stop)
                }
                
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                
                Section("Repeat") {
                    ForEach(DayOfWeek.allCases) { day in
                        Toggle(day.name, isOn: bindingForDay(day))
                    }
                }
                
                Toggle("Enabled", isOn: $isEnabled)
            }
            .navigationTitle("New Schedule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addSchedule()
                    }
                    .disabled(name.isEmpty || days.isEmpty)
                }
            }
        }
    }
    
    private func bindingForDay(_ day: DayOfWeek) -> Binding<Bool> {
        Binding(
            get: { days.contains(day) },
            set: { isSelected in
                if isSelected {
                    days.insert(day)
                } else {
                    days.remove(day)
                }
            }
        )
    }
    
    private func addSchedule() {
        let schedule = Schedule(
            name: name,
            action: action,
            time: time,
            days: days,
            isEnabled: isEnabled
        )
        scheduleManager.addSchedule(schedule)
        dismiss()
    }
}

class ScheduleManager: ObservableObject {
    @Published private(set) var schedules: [Schedule] = []
    private var timer: Timer?
    
    init() {
        loadSchedules()
        startTimer()
    }
    
    func addSchedule(_ schedule: Schedule) {
        schedules.append(schedule)
        saveSchedules()
    }
    
    func removeSchedules(at indexSet: IndexSet) {
        schedules.remove(atOffsets: indexSet)
        saveSchedules()
    }
    
    private func loadSchedules() {
        if let data = UserDefaults.standard.data(forKey: "schedules"),
           let decoded = try? JSONDecoder().decode([Schedule].self, from: data) {
            schedules = decoded
        }
    }
    
    private func saveSchedules() {
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: "schedules")
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkSchedules()
        }
    }
    
    private func checkSchedules() {
        let now = Date()
        let calendar = Calendar.current
        
        for schedule in schedules where schedule.isEnabled {
            let scheduleTime = calendar.dateComponents([.hour, .minute], from: schedule.time)
            let currentTime = calendar.dateComponents([.hour, .minute], from: now)
            let currentDay = DayOfWeek(rawValue: calendar.component(.weekday, from: now))!
            
            if scheduleTime.hour == currentTime.hour &&
               scheduleTime.minute == currentTime.minute &&
               schedule.days.contains(currentDay) {
                executeSchedule(schedule)
            }
        }
    }
    
    private func executeSchedule(_ schedule: Schedule) {
        Task {
            do {
                switch schedule.action {
                case .start:
                    try await ZscalerState.shared.startZscaler()
                case .stop:
                    try await ZscalerState.shared.stopZscaler()
                }
            } catch {
                print("Failed to execute schedule: \(error.localizedDescription)")
            }
        }
    }
}

struct Schedule: Identifiable, Codable {
    let id = UUID()
    var name: String
    var action: ScheduleAction
    var time: Date
    var days: Set<DayOfWeek>
    var isEnabled: Bool
    
    var description: String {
        let timeString = DateFormatter.localizedString(
            from: time,
            dateStyle: .none,
            timeStyle: .short
        )
        let daysString = days.map { $0.shortName }.joined(separator: ", ")
        return "\(action.rawValue) at \(timeString) on \(daysString)"
    }
}

enum ScheduleAction: String, Codable {
    case start = "Start"
    case stop = "Stop"
}

enum DayOfWeek: Int, CaseIterable, Identifiable, Codable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    var shortName: String {
        String(name.prefix(3))
    }
}
