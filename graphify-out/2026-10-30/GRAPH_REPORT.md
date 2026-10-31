# Graph Report - alarma   (2026-10-30)

## Corpus Check
- 63 files · ~75,190 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 2615 file(s) not represented in the graph (top: .pcm 71, .swiftmodule 47, .d 22)

## Summary
- 459 nodes · 788 edges · 20 communities (16 shown, 2 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 27 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17

## God Nodes (most connected - your core abstractions)
1. `AlarmViewModel` - 29 edges
2. `AlarmEditSheet` - 21 edges
3. `Weekday` - 20 edges
4. `Alarm` - 19 edges
5. `LogStatus` - 18 edges
6. `compilerOptions` - 16 edges
7. `WakeLog` - 15 edges
8. `AlarmCategory` - 14 edges
9. `WakeLog` - 14 edges
10. `react` - 14 edges

## Surprising Connections (you probably didn't know these)
- `.body` --calls--> `MainTabView`  [INFERRED]
  Sources/Alarma/App/AlarmaApp.swift → Sources/Alarma/Views/MainTabView.swift
- `MainTabView` --calls--> `AlarmViewModel`  [INFERRED]
  Sources/Alarma/Views/MainTabView.swift → Sources/Alarma/ViewModels/AlarmViewModel.swift
- `.body` --calls--> `AlarmEditSheet`  [INFERRED]
  Sources/Alarma/Views/Alarms/AlarmListView.swift → Sources/Alarma/Views/Alarms/AlarmEditSheet.swift
- `.body` --calls--> `AlarmEditSheet`  [INFERRED]
  Sources/Alarma/Views/Analytics/AnalyticsDashboardView.swift → Sources/Alarma/Views/Alarms/AlarmEditSheet.swift
- `.body` --calls--> `AlarmRowView`  [INFERRED]
  Sources/Alarma/Views/Alarms/AlarmListView.swift → Sources/Alarma/Views/Alarms/AlarmRowView.swift

## Import Cycles
- None detected.

## Communities (20 total, 2 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.08
Nodes (47): echarts-for-react, lucide-react, react, App(), TabType, AlarmModal(), AlarmModalProps, DAY_OPTIONS (+39 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (53): CaseIterable, Codable, Comparable, Foundation, Identifiable, Int, Alarm, .formattedRepeatDays (+45 more)

### Community 2 - "Community 2"
Cohesion: 0.06
Nodes (29): App, Charts, Observation, Scene, AlarmaApp, .body, AlarmListView, Alarm (+21 more)

### Community 3 - "Community 3"
Cohesion: 0.04
Nodes (39): dependencies, clsx, date-fns, echarts, echarts-for-react, lucide-react, react, react-dom (+31 more)

### Community 4 - "Community 4"
Cohesion: 0.09
Nodes (29): LogStatus, delayed, .id, missed, perfect, snoozed, Bool, Date (+21 more)

### Community 5 - "Community 5"
Cohesion: 0.10
Nodes (21): AlarmMetrics, AlarmViewModel, .alarms, .filteredLogs, .logs, .nextActiveAlarm, Alarm, AlarmSound (+13 more)

### Community 6 - "Community 6"
Cohesion: 0.10
Nodes (20): AlarmCategory, AVAudioEngine, AVFoundation, Float, MissionType, SoundEngine, AlarmSound, Double (+12 more)

### Community 7 - "Community 7"
Cohesion: 0.11
Nodes (17): HapticManager, ImpactStyle, heavy, light, medium, rigid, NotificationType, error (+9 more)

### Community 8 - "Community 8"
Cohesion: 0.16
Nodes (14): Angle, CGFloat, AppleClockView, .body, ClockFaceView, .body, .hourAngle, .minuteAngle (+6 more)

### Community 9 - "Community 9"
Cohesion: 0.19
Nodes (12): Hashable, ChatMessage, DataChatSheet, .body, MessageSender, ai, user, String (+4 more)

### Community 10 - "Community 10"
Cohesion: 0.11
Nodes (17): compilerOptions, allowImportingTsExtensions, isolatedModules, jsx, lib, module, moduleResolution, noEmit (+9 more)

### Community 11 - "Community 11"
Cohesion: 0.13
Nodes (15): devDependencies, autoprefixer, jsdom, postcss, tailwindcss, @testing-library/jest-dom, @testing-library/react, @testing-library/user-event (+7 more)

### Community 12 - "Community 12"
Cohesion: 0.17
Nodes (4): calculateNextSnooze(), generateMathProblem(), LockInStateMachine, validateMathAnswer()

### Community 13 - "Community 13"
Cohesion: 0.32
Nodes (5): Sendable, StorageService, Alarm, WakeLog, UserDefaults

### Community 15 - "Community 15"
Cohesion: 0.53
Nodes (4): AlarmMetrics, Double, Int, String

### Community 16 - "Community 16"
Cohesion: 0.60
Nodes (5): getChannelLuminance(), getContrastRatio(), getRelativeLuminance(), hexToRgb(), meetsWcagAA()

## Knowledge Gaps
- **143 isolated node(s):** `PackageDescription`, `sunday`, `monday`, `tuesday`, `wednesday` (+138 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 200 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AlarmViewModel` connect `Community 5` to `Community 9`, `Community 2`, `Community 4`, `Community 6`?**
  _High betweenness centrality (0.086) - this node is a cross-community bridge._
- **Why does `AlarmEditSheet` connect `Community 6` to `Community 1`, `Community 2`, `Community 5`?**
  _High betweenness centrality (0.085) - this node is a cross-community bridge._
- **Why does `LogStatus` connect `Community 4` to `Community 1`, `Community 5`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `AlarmViewModel` (e.g. with `.body` and `.generateAnswer()`) actually correct?**
  _`AlarmViewModel` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `AlarmEditSheet` (e.g. with `.body` and `.body`) actually correct?**
  _`AlarmEditSheet` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `sunday`, `monday` to the rest of the system?**
  _143 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.07548076923076923 - nodes in this community are weakly interconnected._