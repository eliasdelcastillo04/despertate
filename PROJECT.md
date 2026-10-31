# Alarma iOS — Aplicación Nativa en Swift con Retos Matemáticos e Interactivos

## 1. Arquitectura General

La aplicación está desarrollada íntegramente en **Swift (iOS 17+ / macOS 14+)** siguiendo los lineamientos de **Apple Human Interface Guidelines (HIG)** y una arquitectura modular limpia dividida en dos módulos principales:

1. **`AlarmaCore` (`Sources/AlarmaCore/`)**:
   - **Modelos de Dominio (`Models/`)**: `Alarm`, `AlarmTime`, `WeekdaySet`, `SoundAsset`, `ChallengeConfiguration`.
   - **Motores de Retos (`Engine/`)**:
     - `MathProblem`, `MathProblemGenerator`, `SeededRandomNumberGenerator`, `MathChallengeSession`: Generación de operaciones matemáticas aleatorias con niveles Fácil, Medio y Difícil, validación de respuestas, racha consecutiva y penalización de bloqueo de 2 segundos anti-fuerza bruta.
     - `InteractiveChallengeEngines`:
       - `ShakeChallengeEngine`: Detección física de sacudidas por acelerómetro ($|a| \ge 2.2g$) con filtro *debounce* de $200\text{ ms}$.
       - `MemoryPatternChallengeEngine`: Secuencia de memoria cognitiva en cuadrícula $2 \times 2$ de 4 colores.
       - `RapidTapsChallengeEngine`: Pulsaciones rápidas con barra de decaimiento si hay inactividad ($> 1.5\text{ s}$).
       - `HoldCountdownChallengeEngine`: Botón de presión continua que reinicia el progreso a 0 si se suelta antes de completar la cuenta regresiva.
     - `AlarmDeactivationStateMachine`: Máquina de estados finitos (FSM) que impide silenciar o apagar la alarma (`DeactivationError.deactivationBlocked`) hasta que el reto asignado sea completado exitosamente.
   - **Servicios de Infraestructura (`Services/`)**:
     - `JSONFileAlarmRepository`: Actor thread-safe con escritura atómica (`.atomic`) y auto-recuperación ante corrupción de archivos.
     - `NotificationSchedulerService`: Programación en `UNUserNotificationCenter` con soporte multi-día y ventana deslizante de 48 notificaciones (bajo el límite de 64 de iOS).
     - `AudioPlayerService`: Reproducción continua mediante `AVAudioPlayer` con categoría `.playback` (que ignora el interruptor físico de silencio en iOS) y síntesis PCM WAV en tiempo real.
     - `AlarmCoordinator`: Orquestador de ciclo de vida, disparo de alarmas, persistencia de bloqueo activo ante cierre forzado y desactivación automática de alarmas de una sola vez.

2. **`Alarma` (`Sources/Alarma/`)**:
   - **Interfaz SwiftUI (`Views/`)**:
     - `MainTabView`: Navegación principal (Alarmas, Métricas de Despertar, Reloj/Cronómetro) y presentación a pantalla completa no descartable (`.interactiveDismissDisabled(true)`) de `AlarmRingingOverlayView`.
     - `AlarmListView`, `AlarmRowView`, `AlarmEditSheet`: Creación, edición, activación/desactivación, previsualización de sonido y botón directo (`⚡`) para probar la alarma y su reto de desactivación.
     - `AlarmRingingOverlayView`: Pantalla de bloqueo activo con las 5 vistas interactivas de retos (`MathChallengeCardView`, `ShakeChallengeCardView`, `MemoryChallengeCardView`, `RapidTapsChallengeCardView`, `HoldCountdownChallengeCardView`).
     - `AnalyticsDashboardView`, `SleepDurationChartView`, `WakeConsistencyChartView`: Estadísticas de sueño y consistencia al despertar.

---

## 2. Compilación y Ejecución

### Abrir en Xcode (Empaquetado `.app` para App Store y Simulador iOS)
```bash
open Alarma.xcodeproj
```
O compilar por línea de comandos para el simulador de iOS:
```bash
xcodebuild -project Alarma.xcodeproj \
  -scheme Alarma \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

### Ejecutar Suite de Pruebas Unitarias y E2E
```bash
swift test
```
