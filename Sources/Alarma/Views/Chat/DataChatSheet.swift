import SwiftUI

public struct ChatMessage: Identifiable, Hashable {
    public let id = UUID()
    public let sender: MessageSender
    public let text: String
    public let timestamp: String

    public enum MessageSender {
        case user
        case ai
    }
}

public struct DataChatSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let viewModel: AlarmViewModel

    @State private var inputQuery: String = ""
    @State private var messages: [ChatMessage] = []

    private let quickPrompts = [
        "¿Cuál es mi porcentaje de snooze?",
        "¿Cuál es mi hora promedio de despertar?",
        "¿Cómo puedo mejorar mi consistencia?",
        "¿Qué alarmas tienen retos activos?"
    ]

    public init(viewModel: AlarmViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Message Stream
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                HStack {
                                    if msg.sender == .user {
                                        Spacer()
                                    }

                                    VStack(alignment: msg.sender == .user ? .trailing : .leading, spacing: 3) {
                                        Text(msg.text)
                                            .font(.system(size: 13))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .foregroundStyle(msg.sender == .user ? Color.white : Color.primary)
                                            .background(
                                                msg.sender == .user ?
                                                Color.blue :
                                                Color.secondary.opacity(0.12)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                        Text(msg.timestamp)
                                            .font(.system(size: 9))
                                            .foregroundStyle(.tertiary)
                                            .padding(.horizontal, 4)
                                    }

                                    if msg.sender == .ai {
                                        Spacer()
                                    }
                                }
                                .id(msg.id)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                // Quick Prompt Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickPrompts, id: \.self) { prompt in
                            Button {
                                sendQuery(prompt)
                            } label: {
                                Text(prompt)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.1))
                                    .foregroundStyle(Color.primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)

                Divider()

                // Input Bar
                HStack(spacing: 10) {
                    TextField("Pregunta sobre tus datos de sueño...", text: $inputQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onSubmit {
                            sendQuery(inputQuery)
                        }

                    Button {
                        sendQuery(inputQuery)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(inputQuery.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary.opacity(0.4) : Color.blue)
                    }
                    .disabled(inputQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(12)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Asistente de Datos")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupWelcomeMessage()
            }
        }
    }

    private func setupWelcomeMessage() {
        if messages.isEmpty {
            let welcome = ChatMessage(
                sender: .ai,
                text: "¡Hola! Soy tu asistente de sueño y alarmas basado en Apple HIG y análisis de datos. Tienes \(viewModel.metrics.activeAlarms) alarmas activas y un score de consistencia del \(viewModel.metrics.consistencyScoreAverage)%. ¿Qué deseas consultar sobre tus hábitos?",
                timestamp: currentTimestamp()
            )
            messages.append(welcome)
        }
    }

    private func sendQuery(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMsg = ChatMessage(sender: .user, text: query, timestamp: currentTimestamp())
        messages.append(userMsg)
        inputQuery = ""
        HapticManager.triggerImpact(.light)

        // Generate intelligent data response
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let responseText = generateAnswer(for: query)
            let aiMsg = ChatMessage(sender: .ai, text: responseText, timestamp: currentTimestamp())
            messages.append(aiMsg)
            HapticManager.triggerNotification(.success)
        }
    }

    private func generateAnswer(for query: String) -> String {
        let q = query.lowercased()
        if q.contains("snooze") || q.contains("postergar") {
            let snoozedCount = viewModel.logs.filter { $0.snoozeCount > 0 }.count
            return "Tu tasa de snooze es del \(viewModel.metrics.snoozeRatePercentage)%. En \(snoozedCount) de tus últimos registros usaste la postergación de 9 minutos. Reducir el snooze a 0 minimiza la inercia del sueño matutina."
        } else if q.contains("hora") || q.contains("promedio") || q.contains("despertar") {
            return "Tu hora promedio de despertar se sitúa en las \(viewModel.metrics.averageWakeTimeString). Mantener una variación menor a 15 minutos entre días laborales y fines de semana fortalecerá tu ritmo circadiano."
        } else if q.contains("consistencia") || q.contains("mejorar") {
            return "Tu índice de consistencia es \(viewModel.metrics.consistencyScoreAverage)/100 (Óptimo). Para llegar a 100:\n1. Acostarte en el mismo rango de 30 minutos.\n2. Mantener activo el reto de cálculo mental en tu alarma principal."
        } else if q.contains("reto") || q.contains("misión") || q.contains("mision") {
            let activeMissions = viewModel.alarms.filter { $0.missionType != .none }
            return "Tienes \(activeMissions.count) alarmas con reto anti-sueño configurado: \(activeMissions.map { "\($0.label) (\($0.missionType.rawValue))" }.joined(separator: ", "))."
        } else {
            var totalSleep: Double = 0.0
            for log in viewModel.logs {
                totalSleep += log.sleepDurationHours
            }
            let avgSleep = viewModel.logs.isEmpty ? 7.8 : totalSleep / Double(viewModel.logs.count)
            return "Analizando tus \(viewModel.logs.count) registros: tu promedio de sueño es de \(String(format: "%.1f", avgSleep)) horas por noche con una tendencia positiva de +\(String(format: "%.1f", viewModel.metrics.weeklyTrendPercentage))%."
        }
    }

    private func currentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}
