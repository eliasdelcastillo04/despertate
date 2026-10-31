import { Alarm, WakeLog, AlarmMetrics } from '../types/alarm';

const STORAGE_ALARMS_KEY = 'alarma_apple_items_v1';
const STORAGE_LOGS_KEY = 'alarma_apple_logs_v1';

const INITIAL_ALARMS: Alarm[] = [
  {
    id: 'alm-1',
    time: '06:30',
    label: 'Despertar Productivo 🚀',
    enabled: true,
    repeatDays: [1, 2, 3, 4, 5],
    sound: 'radar',
    volume: 90,
    snoozeEnabled: true,
    snoozeDuration: 9,
    missionType: 'math',
    missionDifficulty: 'medio',
    category: 'wake-up',
    createdAt: '2026-10-01T08:00:00.000Z',
  },
  {
    id: 'alm-2',
    time: '07:15',
    label: 'Gimnasio & Movilidad 🏋️‍♂️',
    enabled: true,
    repeatDays: [1, 3, 5],
    sound: 'apex',
    volume: 85,
    snoozeEnabled: false,
    snoozeDuration: 5,
    missionType: 'shake',
    missionDifficulty: 'facil',
    category: 'fitness',
    createdAt: '2026-10-05T09:00:00.000Z',
  },
  {
    id: 'alm-3',
    time: '08:45',
    label: 'Daily Standup / Trabajo 💼',
    enabled: true,
    repeatDays: [1, 2, 3, 4, 5],
    sound: 'chimes',
    volume: 75,
    snoozeEnabled: true,
    snoozeDuration: 9,
    missionType: 'none',
    missionDifficulty: 'facil',
    category: 'work',
    createdAt: '2026-10-10T10:00:00.000Z',
  },
  {
    id: 'alm-4',
    time: '09:30',
    label: 'Fin de Semana Relax ☕',
    enabled: false,
    repeatDays: [0, 6],
    sound: 'breeze',
    volume: 70,
    snoozeEnabled: true,
    snoozeDuration: 9,
    missionType: 'none',
    missionDifficulty: 'facil',
    category: 'wake-up',
    createdAt: '2026-10-12T11:00:00.000Z',
  },
  {
    id: 'alm-5',
    time: '23:00',
    label: 'Desconectar Pantallas & Dormir 🌙',
    enabled: true,
    repeatDays: [0, 1, 2, 3, 4, 5, 6],
    sound: 'cosmic',
    volume: 65,
    snoozeEnabled: false,
    snoozeDuration: 5,
    missionType: 'none',
    missionDifficulty: 'facil',
    category: 'custom',
    createdAt: '2026-10-15T12:00:00.000Z',
  },
];

const INITIAL_LOGS: WakeLog[] = [
  {
    id: 'log-1',
    alarmId: 'alm-1',
    alarmLabel: 'Despertar Productivo 🚀',
    scheduledTime: '06:30',
    wakeTime: '06:32',
    targetDate: '2026-10-30',
    snoozeCount: 0,
    missionCompleted: true,
    missionType: 'math',
    sleepHours: 7.8,
    consistencyScore: 98,
    status: 'perfect',
    notes: 'Desperté con energía y resolví el reto de cálculo en 15s.',
  },
  {
    id: 'log-2',
    alarmId: 'alm-1',
    alarmLabel: 'Despertar Productivo 🚀',
    scheduledTime: '06:30',
    wakeTime: '06:39',
    targetDate: '2026-10-29',
    snoozeCount: 1,
    missionCompleted: true,
    missionType: 'math',
    sleepHours: 7.2,
    consistencyScore: 88,
    status: 'snoozed',
    notes: '1 snooze usado. Buen ritmo de sueño.',
  },
  {
    id: 'log-3',
    alarmId: 'alm-1',
    alarmLabel: 'Despertar Productivo 🚀',
    scheduledTime: '06:30',
    wakeTime: '06:30',
    targetDate: '2026-10-28',
    snoozeCount: 0,
    missionCompleted: true,
    missionType: 'math',
    sleepHours: 8.0,
    consistencyScore: 100,
    status: 'perfect',
    notes: 'Despertar exacto sin resistencia.',
  },
  {
    id: 'log-4',
    alarmId: 'alm-1',
    alarmLabel: 'Despertar Productivo 🚀',
    scheduledTime: '06:30',
    wakeTime: '06:48',
    targetDate: '2026-10-27',
    snoozeCount: 2,
    missionCompleted: true,
    missionType: 'math',
    sleepHours: 6.4,
    consistencyScore: 78,
    status: 'delayed',
    notes: 'Dormí tarde viendo series. Costó levantar.',
  },
  {
    id: 'log-5',
    alarmId: 'alm-1',
    alarmLabel: 'Despertar Productivo 🚀',
    scheduledTime: '06:30',
    wakeTime: '06:31',
    targetDate: '2026-10-26',
    snoozeCount: 0,
    missionCompleted: true,
    missionType: 'math',
    sleepHours: 7.5,
    consistencyScore: 97,
    status: 'perfect',
    notes: 'Misión completada de inmediato.',
  },
  {
    id: 'log-6',
    alarmId: 'alm-4',
    alarmLabel: 'Fin de Semana Relax ☕',
    scheduledTime: '09:30',
    wakeTime: '09:35',
    targetDate: '2026-10-25',
    snoozeCount: 0,
    missionCompleted: false,
    missionType: 'none',
    sleepHours: 8.5,
    consistencyScore: 92,
    status: 'perfect',
    notes: 'Excelente descanso de fin de semana.',
  },
  {
    id: 'log-7',
    alarmId: 'alm-4',
    alarmLabel: 'Fin de Semana Relax ☕',
    scheduledTime: '09:30',
    wakeTime: '09:50',
    targetDate: '2026-10-24',
    snoozeCount: 2,
    missionCompleted: false,
    missionType: 'none',
    sleepHours: 9.0,
    consistencyScore: 84,
    status: 'snoozed',
  },
  {
    id: 'log-8',
    alarmId: 'alm-1',
    alarmLabel: 'Despertar Productivo 🚀',
    scheduledTime: '06:30',
    wakeTime: '06:34',
    targetDate: '2026-10-23',
    snoozeCount: 0,
    missionCompleted: true,
    missionType: 'math',
    sleepHours: 7.6,
    consistencyScore: 95,
    status: 'perfect',
  },
  {
    id: 'log-9',
    alarmId: 'alm-1',
    alarmLabel: 'Despertar Productivo 🚀',
    scheduledTime: '06:30',
    wakeTime: '06:40',
    targetDate: '2026-10-22',
    snoozeCount: 1,
    missionCompleted: true,
    missionType: 'math',
    sleepHours: 7.1,
    consistencyScore: 89,
    status: 'snoozed',
  },
  {
    id: 'log-10',
    alarmId: 'alm-1',
    alarmLabel: 'Despertar Productivo 🚀',
    scheduledTime: '06:30',
    wakeTime: '06:30',
    targetDate: '2026-10-21',
    snoozeCount: 0,
    missionCompleted: true,
    missionType: 'math',
    sleepHours: 7.9,
    consistencyScore: 100,
    status: 'perfect',
  },
];

export const getStoredAlarms = (): Alarm[] => {
  try {
    const data = localStorage.getItem(STORAGE_ALARMS_KEY);
    if (!data) {
      localStorage.setItem(STORAGE_ALARMS_KEY, JSON.stringify(INITIAL_ALARMS));
      return INITIAL_ALARMS;
    }
    return JSON.parse(data);
  } catch {
    return INITIAL_ALARMS;
  }
};

export const saveAlarms = (alarms: Alarm[]): void => {
  localStorage.setItem(STORAGE_ALARMS_KEY, JSON.stringify(alarms));
};

export const getStoredLogs = (): WakeLog[] => {
  try {
    const data = localStorage.getItem(STORAGE_LOGS_KEY);
    if (!data) {
      localStorage.setItem(STORAGE_LOGS_KEY, JSON.stringify(INITIAL_LOGS));
      return INITIAL_LOGS;
    }
    return JSON.parse(data);
  } catch {
    return INITIAL_LOGS;
  }
};

export const saveLogs = (logs: WakeLog[]): void => {
  localStorage.setItem(STORAGE_LOGS_KEY, JSON.stringify(logs));
};

export const calculateMetrics = (alarms: Alarm[], logs: WakeLog[]): AlarmMetrics => {
  const activeCount = alarms.filter((a) => a.enabled).length;

  if (logs.length === 0) {
    return {
      totalAlarms: alarms.length,
      activeAlarms: activeCount,
      averageWakeTime: '06:45',
      snoozeRate: 0,
      consistencyScore: 90,
      weeklyTrend: 2.5,
    };
  }

  // Average wake minutes
  let totalMinutes = 0;
  let totalSnoozeCount = 0;
  let totalConsistency = 0;

  logs.forEach((log) => {
    const [h, m] = log.wakeTime.split(':').map(Number);
    totalMinutes += h * 60 + m;
    totalSnoozeCount += log.snoozeCount;
    totalConsistency += log.consistencyScore;
  });

  const avgMinutes = Math.round(totalMinutes / logs.length);
  const avgH = Math.floor(avgMinutes / 60)
    .toString()
    .padStart(2, '0');
  const avgM = (avgMinutes % 60).toString().padStart(2, '0');

  const logsWithSnooze = logs.filter((l) => l.snoozeCount > 0).length;
  const snoozeRate = Math.round((logsWithSnooze / logs.length) * 100);
  const avgScore = Math.round(totalConsistency / logs.length);

  return {
    totalAlarms: alarms.length,
    activeAlarms: activeCount,
    averageWakeTime: `${avgH}:${avgM}`,
    snoozeRate,
    consistencyScore: avgScore,
    weeklyTrend: 4.8,
  };
};
