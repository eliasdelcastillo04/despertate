export type DayOfWeek = 0 | 1 | 2 | 3 | 4 | 5 | 6; // 0 = Domingo, 1 = Lunes ... 6 = Sábado

export type MissionType = 'none' | 'math' | 'shake' | 'qr' | 'step';

export type AlarmSound = 'radar' | 'chimes' | 'apex' | 'breeze' | 'cosmic';

export type AlarmCategory = 'wake-up' | 'work' | 'meds' | 'fitness' | 'study' | 'custom';

export interface Alarm {
  id: string;
  time: string; // '06:30' (24-hour format)
  label: string;
  enabled: boolean;
  repeatDays: DayOfWeek[]; // [] = Once
  sound: AlarmSound;
  volume: number; // 0 to 100
  snoozeEnabled: boolean;
  snoozeDuration: number; // in minutes (default 9 per Apple standard)
  missionType: MissionType;
  missionDifficulty: 'facil' | 'medio' | 'dificil';
  category: AlarmCategory;
  createdAt: string;
}

export interface WakeLog {
  id: string;
  alarmId: string;
  alarmLabel: string;
  scheduledTime: string;
  wakeTime: string;
  targetDate: string; // YYYY-MM-DD
  snoozeCount: number;
  missionCompleted: boolean;
  missionType: MissionType;
  sleepHours: number;
  consistencyScore: number; // 0 - 100
  status: 'perfect' | 'delayed' | 'snoozed' | 'missed';
  notes?: string;
}

export interface AlarmMetrics {
  totalAlarms: number;
  activeAlarms: number;
  averageWakeTime: string;
  snoozeRate: number; // percentage
  consistencyScore: number; // 0-100
  weeklyTrend: number; // percentage diff
}
