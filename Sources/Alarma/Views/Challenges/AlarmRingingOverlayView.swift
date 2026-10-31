import SwiftUI
import AlarmaCore
#if os(iOS)
import CoreMotion
#endif

public struct AlarmRingingOverlayView: View {
    public let alarm: Alarm
    @Bindable public var viewModel: AlarmViewModel

    @State private var pulseScale: CGFloat = 1.0
    @State private var attemptBypassWarning: String? = nil

    public init(alarm: Alarm, viewModel: AlarmViewModel) {
        self.alarm = alarm
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            // Deep immersive night background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.14),
                    Color(red: 0.10, green: 0.08, blue: 0.22),
                    Color(red: 0.04, green: 0.05, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header: Pulsing Alarm Bell & Time
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.22))
                                .frame(width: 82, height: 82)
                                .scaleEffect(pulseScale)

                            Circle()
                                .fill(Color.orange.opacity(0.35))
                                .frame(width: 60, height: 60)

                            Image(systemName: "alarm.waves.left.and.right.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                        .padding(.top, 12)

                        Text(alarm.timeString)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Text(alarm.label)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))

                        // Security Lock-In Status Banner
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.orange)
                            Text("Bloqueo Activo: Supera el reto para silenciar la alarma")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    if let warning = attemptBypassWarning {
                        Text(warning)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Active Challenge Container
                    Group {
                        switch alarm.missionType {
                        case .math:
                            MathChallengeCardView(
                                difficulty: alarm.difficulty.coreDifficulty,
                                targetCount: alarm.problemCount
                            ) {
                                viewModel.completeActiveAlarmChallenge()
                            }

                        case .shake:
                            ShakeChallengeCardView(difficulty: alarm.difficulty.coreDifficulty) {
                                viewModel.completeActiveAlarmChallenge()
                            }

                        case .memory:
                            MemoryChallengeCardView(difficulty: alarm.difficulty.coreDifficulty) {
                                viewModel.completeActiveAlarmChallenge()
                            }

                        case .rapidTaps, .qr:
                            RapidTapsChallengeCardView(difficulty: alarm.difficulty.coreDifficulty) {
                                viewModel.completeActiveAlarmChallenge()
                            }

                        case .holdCountdown:
                            HoldCountdownChallengeCardView(difficulty: alarm.difficulty.coreDifficulty) {
                                viewModel.completeActiveAlarmChallenge()
                            }

                        case .none:
                            Button {
                                viewModel.completeActiveAlarmChallenge()
                            } label: {
                                Label("Desactivar Alarma", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Blocked Direct Off Button demonstrating the FSM security invariant
                    if alarm.missionType != .none {
                        Button {
                            withAnimation {
                                attemptBypassWarning = "⛔ No es posible apagar la alarma directamente sin resolver el reto asignado."
                            }
                            HapticManager.triggerNotification(.error)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bell.slash.fill")
                                Text("Apagado directo bloqueado hasta completar el reto")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulseScale = 1.24
            }
        }
    }
}

// MARK: - 1. Math Challenge Card View

struct MathChallengeCardView: View {
    let difficulty: ChallengeDifficulty
    let targetCount: Int
    let onCompleted: () -> Void

    @State private var session: MathChallengeSessionState
    @State private var inputBuffer: String = ""
    @State private var feedbackMessage: String? = nil
    @State private var isErrorFeedback: Bool = false
    @State private var cooldownTimer: Timer? = nil

    init(difficulty: ChallengeDifficulty, targetCount: Int, onCompleted: @escaping () -> Void) {
        self.difficulty = difficulty
        self.targetCount = max(1, targetCount)
        self.onCompleted = onCompleted
        _session = State(
            initialValue: MathChallengeSessionState(
                difficulty: difficulty,
                targetStreak: max(1, targetCount),
                penaltyCooldownDuration: 2.0
            )
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            // Top Progress Header
            HStack {
                Label("Reto Matemático (\(difficulty.displayName))", systemImage: "function")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)

                Spacer()

                Text("\(session.currentStreak) / \(session.targetStreak) resueltos")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            // Progress Pills
            HStack(spacing: 8) {
                ForEach(0..<session.targetStreak, id: \.self) { index in
                    Capsule()
                        .fill(index < session.currentStreak ? Color.green : Color.white.opacity(0.18))
                        .frame(height: 6)
                }
            }

            // Equation Display Box
            VStack(spacing: 8) {
                Text("Resuelve la operación:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))

                Text("\(session.currentProblem.expression) = ?")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                // Answer Input Display
                Text(inputBuffer.isEmpty ? "Ingresa tu respuesta" : inputBuffer)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(inputBuffer.isEmpty ? .white.opacity(0.35) : .orange)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(session.isLockedOut ? Color.red : Color.orange.opacity(0.5), lineWidth: 1.5)
                    )
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Cooldown / Feedback Banner
            if session.isLockedOut {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text(String(format: "Respuesta incorrecta • Penalización: %.1fs", session.cooldownRemaining))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if let msg = feedbackMessage {
                Text(msg)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isErrorFeedback ? Color.red : Color.green)
            }

            // Custom 3x4 Cupertino Numeric Keypad
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9"], id: \.self) { digit in
                    numpadButton(label: digit) {
                        appendDigit(digit)
                    }
                }

                numpadButton(label: "⌫", isSecondary: true) {
                    if !inputBuffer.isEmpty {
                        inputBuffer.removeLast()
                        HapticManager.triggerImpact(.light)
                    }
                }

                numpadButton(label: "0") {
                    appendDigit("0")
                }

                Button {
                    submitCurrentAnswer()
                } label: {
                    Text("OK")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(session.isLockedOut || inputBuffer.isEmpty ? Color.gray.opacity(0.4) : Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(session.isLockedOut || inputBuffer.isEmpty)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .onAppear {
            startCooldownTicker()
        }
        .onDisappear {
            cooldownTimer?.invalidate()
            cooldownTimer = nil
        }
    }

    private func numpadButton(label: String, isSecondary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isSecondary ? Color.white.opacity(0.18) : Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(session.isLockedOut)
    }

    private func appendDigit(_ digit: String) {
        guard !session.isLockedOut, inputBuffer.count < 8 else { return }
        inputBuffer.append(digit)
        HapticManager.triggerImpact(.light)
    }

    private func submitCurrentAnswer() {
        let result = session.submit(answer: inputBuffer)
        inputBuffer = ""

        switch result {
        case .correct(let newStreak, let remaining):
            isErrorFeedback = false
            feedbackMessage = "¡Correcto! Racha \(newStreak). Faltan \(remaining)."
            HapticManager.triggerNotification(.success)

        case .completed:
            isErrorFeedback = false
            feedbackMessage = "¡Reto matemático superado! Desactivando alarma..."
            HapticManager.triggerNotification(.success)
            onCompleted()

        case .incorrect(_, let expected, _):
            isErrorFeedback = true
            feedbackMessage = "Incorrecto (era \(expected)). La racha se reinició a 0."
            HapticManager.triggerNotification(.error)

        case .invalidInput:
            isErrorFeedback = true
            feedbackMessage = "Ingresa un número entero válido."

        case .blockedByCooldown:
            break
        }
    }

    private func startCooldownTicker() {
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                if session.isLockedOut {
                    session.tickCooldown(delta: 0.1)
                }
            }
        }
    }
}

// MARK: - 2. Shake Challenge Card View

struct ShakeChallengeCardView: View {
    let difficulty: ChallengeDifficulty
    let onCompleted: () -> Void

    @State private var engine: ShakeChallengeEngine
    #if os(iOS)
    @State private var motionManager = CMMotionManager()
    #endif

    init(difficulty: ChallengeDifficulty, onCompleted: @escaping () -> Void) {
        self.difficulty = difficulty
        self.onCompleted = onCompleted
        _engine = State(initialValue: ShakeChallengeEngine(difficulty: difficulty))
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Label("Reto: Agitar el Dispositivo", systemImage: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)
                Spacer()
                Text("\(engine.currentShakes) / \(engine.requiredShakes)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 14)
                    .frame(width: 150, height: 150)

                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(
                        AngularGradient(colors: [.orange, .yellow, .green], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 150, height: 150)
                    .animation(.spring(duration: 0.25), value: engine.progress)

                VStack(spacing: 4) {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 34))
                        .foregroundStyle(.orange)
                    Text("\(Int(engine.progress * 100))%")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .padding(.vertical, 8)

            Text("Agita enérgicamente tu iPhone o pulsa el botón de sacudida asistida para completar las \(engine.requiredShakes) agitaciones.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Button {
                let now = Date().timeIntervalSinceReferenceDate
                // Advance time past debounce for responsive interactive shake button
                let timestamp = max(now, (engine.lastShakeTimestamp ?? 0) + engine.debounceInterval + 0.01)
                if engine.registerShake(at: timestamp) {
                    HapticManager.triggerImpact(.medium)
                    if engine.isCompleted {
                        onCompleted()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                    Text("Sacudir Ahora (+1 Agitación)")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .onAppear {
            startMotionUpdates()
        }
        .onDisappear {
            stopMotionUpdates()
        }
    }

    private func startMotionUpdates() {
        #if os(iOS)
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.02
        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            guard let acc = data?.acceleration else { return }
            let now = Date().timeIntervalSinceReferenceDate
            if engine.processAcceleration(x: acc.x, y: acc.y, z: acc.z, timestamp: now) {
                HapticManager.triggerImpact(.medium)
                if engine.isCompleted {
                    stopMotionUpdates()
                    onCompleted()
                }
            }
        }
        #endif
    }

    private func stopMotionUpdates() {
        #if os(iOS)
        motionManager.stopAccelerometerUpdates()
        #endif
    }
}

// MARK: - 3. Memory Pattern Challenge Card View

struct MemoryChallengeCardView: View {
    let difficulty: ChallengeDifficulty
    let onCompleted: () -> Void

    @State private var engine: MemoryPatternChallengeEngine
    @State private var highlightedTile: MemoryTileColor? = nil
    @State private var isPlayingSequence: Bool = false
    @State private var statusMessage: String = "Observa la secuencia de colores..."

    init(difficulty: ChallengeDifficulty, onCompleted: @escaping () -> Void) {
        self.difficulty = difficulty
        self.onCompleted = onCompleted
        _engine = State(initialValue: MemoryPatternChallengeEngine(difficulty: difficulty))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Reto: Memoria de Patrón", systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)
                Spacer()
                Text("Paso \(engine.currentInputIndex) / \(engine.patternLength)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Text(statusMessage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(MemoryTileColor.allCases) { tile in
                    Button {
                        handleTileTap(tile)
                    } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color(for: tile).opacity(highlightedTile == tile ? 1.0 : 0.42))
                            .frame(height: 92)
                            .overlay(
                                VStack(spacing: 4) {
                                    Text(tile.displayName)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(highlightedTile == tile ? 0.95 : 0.2), lineWidth: highlightedTile == tile ? 3 : 1)
                            )
                            .scaleEffect(highlightedTile == tile ? 1.04 : 1.0)
                    }
                    .disabled(isPlayingSequence)
                }
            }

            Button {
                playDemonstrationSequence()
            } label: {
                Label("Repetir Demostración del Patrón", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            .disabled(isPlayingSequence)
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .onAppear {
            playDemonstrationSequence()
        }
    }

    private func color(for tile: MemoryTileColor) -> Color {
        switch tile {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .orange
        }
    }

    private func playDemonstrationSequence() {
        isPlayingSequence = true
        statusMessage = "Memoriza el orden de los colores..."
        let pattern = engine.targetPattern

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            for tile in pattern {
                withAnimation(.easeInOut(duration: 0.15)) {
                    highlightedTile = tile
                }
                HapticManager.triggerImpact(.light)
                try? await Task.sleep(nanoseconds: 450_000_000)
                withAnimation(.easeInOut(duration: 0.15)) {
                    highlightedTile = nil
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            isPlayingSequence = false
            statusMessage = "¡Tu turno! Repite los \(pattern.count) pasos."
        }
    }

    private func handleTileTap(_ tile: MemoryTileColor) {
        guard !isPlayingSequence else { return }
        withAnimation(.easeInOut(duration: 0.12)) {
            highlightedTile = tile
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            if highlightedTile == tile {
                highlightedTile = nil
            }
        }

        let res = engine.submitTap(tile)
        switch res {
        case .correctStep(let current, let total):
            HapticManager.triggerImpact(.light)
            statusMessage = "¡Bien! (\(current)/\(total))"

        case .completed:
            HapticManager.triggerNotification(.success)
            statusMessage = "¡Secuencia completada!"
            onCompleted()

        case .wrongTile(let expected, _):
            HapticManager.triggerNotification(.error)
            statusMessage = "Fallaste (era \(expected.displayName)). Observa de nuevo..."
            playDemonstrationSequence()
        }
    }
}

// MARK: - 4. Rapid Taps Challenge Card View

struct RapidTapsChallengeCardView: View {
    let difficulty: ChallengeDifficulty
    let onCompleted: () -> Void

    @State private var engine: RapidTapsChallengeEngine
    @State private var decayTimer: Timer? = nil

    init(difficulty: ChallengeDifficulty, onCompleted: @escaping () -> Void) {
        self.difficulty = difficulty
        self.onCompleted = onCompleted
        _engine = State(initialValue: RapidTapsChallengeEngine(difficulty: difficulty))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Reto: Toques Rápidos", systemImage: "hand.tap.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)
                Spacer()
                Text("\(engine.currentTaps) / \(engine.targetTaps)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            ProgressView(value: engine.progress)
                .tint(.orange)
                .scaleEffect(x: 1, y: 2.2, anchor: .center)
                .padding(.vertical, 4)

            Text("¡Pulsa rápidamente sin detenerte! Si dejas de tocar por más de 1.5s, el progreso disminuye.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Button {
                engine.registerTap(at: Date().timeIntervalSinceReferenceDate)
                HapticManager.triggerImpact(.light)
                if engine.isCompleted {
                    onCompleted()
                }
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 32, weight: .bold))
                    Text("¡TOCAR RÁPIDO!")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(
                    LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .onAppear {
            decayTimer?.invalidate()
            decayTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                Task { @MainActor in
                    engine.tickDecay(currentTime: Date().timeIntervalSinceReferenceDate, deltaSeconds: 0.5)
                }
            }
        }
        .onDisappear {
            decayTimer?.invalidate()
            decayTimer = nil
        }
    }
}

// MARK: - 5. Hold Countdown Challenge Card View

struct HoldCountdownChallengeCardView: View {
    let difficulty: ChallengeDifficulty
    let onCompleted: () -> Void

    @State private var engine: HoldCountdownChallengeEngine
    @State private var holdTimer: Timer? = nil

    init(difficulty: ChallengeDifficulty, onCompleted: @escaping () -> Void) {
        self.difficulty = difficulty
        self.onCompleted = onCompleted
        _engine = State(initialValue: HoldCountdownChallengeEngine(difficulty: difficulty))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Reto: Mantener Presionado", systemImage: "timer")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)
                Spacer()
                Text(String(format: "%.1fs restantes", engine.remainingSeconds))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(engine.isHolding ? Color.green : Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 140, height: 140)

                VStack(spacing: 4) {
                    Image(systemName: engine.isHolding ? "lock.open.rotation" : "hand.Tap.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(engine.isHolding ? .green : .orange)
                    Text(String(format: "%.0f%%", engine.progress * 100))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            if engine.releaseResetCount > 0 && !engine.isHolding {
                Text("⚠️ Soltaste antes de tiempo. El contador se reinició a 0.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.red)
            } else {
                Text("Mantén presionado el botón inferior sin soltar hasta completar la cuenta regresiva.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }

            Text(engine.isHolding ? "MANTENIENDO... NO SUELTES" : "MANTÉN PRESIONADO AQUÍ")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(engine.isHolding ? Color.green : Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !engine.isHolding {
                                engine.beginHold()
                                HapticManager.triggerImpact(.medium)
                            }
                        }
                        .onEnded { _ in
                            engine.endHold()
                            if !engine.isCompleted {
                                HapticManager.triggerNotification(.error)
                            }
                        }
                )
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .onAppear {
            holdTimer?.invalidate()
            holdTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                Task { @MainActor in
                    if engine.isHolding {
                        engine.tickHold(deltaSeconds: 0.1)
                        if engine.isCompleted {
                            holdTimer?.invalidate()
                            onCompleted()
                        }
                    }
                }
            }
        }
        .onDisappear {
            holdTimer?.invalidate()
            holdTimer = nil
        }
    }
}
