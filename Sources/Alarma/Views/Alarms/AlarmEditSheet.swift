import SwiftUI

public struct AlarmEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    public var alarmToEdit: Alarm?
    public var onSave: (Alarm) -> Void

    @State private var selectedDate: Date = Date()
    @State private var label: String = "Alarma"
    @State private var repeatDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var sound: AlarmSound = .radar
    @State private var volume: Double = 0.85
    @State private var snoozeEnabled: Bool = true
    @State private var snoozeDurationMinutes: Int = 9
    @State private var missionType: MissionType = .math
    @State private var difficulty: MissionDifficulty = .medium
    @State private var problemCount: Int = 3
    @State private var category: AlarmCategory = .wakeUp
    @State private var isPlayingPreview: Bool = false

    public init(alarmToEdit: Alarm? = nil, onSave: @escaping (Alarm) -> Void) {
        self.alarmToEdit = alarmToEdit
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Apple Clock Wheel Time Picker
                Section {
                    DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        #if os(iOS)
                        .datePickerStyle(.wheel)
                        #else
                        .datePickerStyle(.automatic)
                        #endif
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)

                // Section 2: Label & Category
                Section("Detalles") {
                    TextField("Etiqueta", text: $label)

                    Picker("Categoría", selection: $category) {
                        ForEach(AlarmCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName).tag(cat)
                        }
                    }
                }

                // Section 3: Repeat Days Selector
                Section("Repetición") {
                    HStack {
                        ForEach(Weekday.allCases) { day in
                            let isSelected = repeatDays.contains(day)
                            Button {
                                if isSelected {
                                    repeatDays.remove(day)
                                } else {
                                    repeatDays.insert(day)
                                }
                                HapticManager.triggerImpact(.light)
                            } label: {
                                Text(day.shortName)
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.orange : Color.secondary.opacity(0.12))
                                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 8) {
                        presetChip("L-V") {
                            repeatDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                        }
                        presetChip("Fin de sem.") {
                            repeatDays = [.saturday, .sunday]
                        }
                        presetChip("Todos") {
                            repeatDays = Set(Weekday.allCases)
                        }
                        presetChip("Una vez") {
                            repeatDays = []
                        }
                    }
                }

                // Section 4: Sound & Volume
                Section("Sonido y Vibración") {
                    Picker("Tono de Alarma", selection: $sound) {
                        ForEach(AlarmSound.allCases) { snd in
                            Text(snd.rawValue).tag(snd)
                        }
                    }

                    HStack {
                        Button {
                            if isPlayingPreview {
                                SoundEngine.shared.stop()
                                isPlayingPreview = false
                            } else {
                                SoundEngine.shared.preview(sound: sound, volume: volume)
                                isPlayingPreview = true
                            }
                        } label: {
                            Label(isPlayingPreview ? "Detener" : "Probar sonido", systemImage: isPlayingPreview ? "stop.fill" : "play.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.blue)
                        }

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Volumen: \(Int(volume * 100))%")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Slider(value: $volume, in: 0.2...1.0)
                            .tint(.blue)
                    }
                }

                // Section 5: Wake Missions
                Section {
                    Picker("Misión para despertar", selection: $missionType) {
                        ForEach(MissionType.allCases) { mission in
                            Label(mission.rawValue, systemImage: mission.iconName).tag(mission)
                        }
                    }

                    if missionType != .none {
                        Picker("Dificultad", selection: $difficulty) {
                            ForEach(MissionDifficulty.allCases) { diff in
                                Text(diff.rawValue).tag(diff)
                            }
                        }
                        .pickerStyle(.segmented)

                        if missionType == .math {
                            Stepper("Operaciones a resolver: \(problemCount)", value: $problemCount, in: 1...10)
                        }
                    }
                } header: {
                    Text("Reto Anti-Sueño")
                } footer: {
                    Text("Exige superar operaciones matemáticas o acciones interactivas antes de apagar la alarma.")
                }

                // Section 6: Snooze Settings (Apple 9-minute standard)
                Section {
                    Toggle("Permitir Postergación", isOn: $snoozeEnabled)
                        .tint(.green)

                    if snoozeEnabled {
                        Picker("Duración del Snooze", selection: $snoozeDurationMinutes) {
                            Text("5 minutos").tag(5)
                            Text("9 minutos (Estándar Apple)").tag(9)
                            Text("15 minutos").tag(15)
                        }
                    }
                } footer: {
                    Text("Las normativas de Apple HIG establecen un intervalo de postergación de 9 minutos por defecto.")
                }
            }
            .navigationTitle(alarmToEdit == nil ? "Nueva Alarma" : "Editar Alarma")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        SoundEngine.shared.stop()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                setupInitialValues()
            }
            .onDisappear {
                SoundEngine.shared.stop()
            }
        }
    }

    private func presetChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.12))
                .foregroundStyle(Color.orange)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func setupInitialValues() {
        if let alarm = alarmToEdit {
            label = alarm.label
            repeatDays = alarm.repeatDays
            sound = alarm.sound
            volume = alarm.volume
            snoozeEnabled = alarm.snoozeEnabled
            snoozeDurationMinutes = alarm.snoozeDurationMinutes
            missionType = alarm.missionType
            difficulty = alarm.difficulty
            problemCount = alarm.problemCount
            category = alarm.category

            let parts = alarm.timeString.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2 {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = parts[0]
                components.minute = parts[1]
                if let date = Calendar.current.date(from: components) {
                    selectedDate = date
                }
            }
        }
    }

    private func save() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: selectedDate)

        let alarm = Alarm(
            id: alarmToEdit?.id ?? UUID(),
            timeString: timeString,
            label: label.isEmpty ? "Alarma" : label,
            isEnabled: true,
            repeatDays: repeatDays,
            sound: sound,
            volume: volume,
            snoozeEnabled: snoozeEnabled,
            snoozeDurationMinutes: snoozeDurationMinutes,
            missionType: missionType,
            difficulty: difficulty,
            problemCount: problemCount,
            category: category,
            createdAt: alarmToEdit?.createdAt ?? Date()
        )

        onSave(alarm)
        dismiss()
    }
}
