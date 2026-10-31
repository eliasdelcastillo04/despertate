import { Alarm, DayOfWeek, MissionType, WakeLog } from '../../types/alarm';

export type RingingState =
  | { status: 'idle' }
  | { status: 'ringing'; alarm: Alarm; startedAt: Date }
  | { status: 'challenging'; alarm: Alarm; challengeType: MissionType; difficulty: string; progress: number }
  | { status: 'snoozed'; alarm: Alarm; snoozeUntil: Date }
  | { status: 'dismissed'; alarm: Alarm };

/**
 * Checks whether an alarm should trigger at the given date/time.
 */
export function shouldTriggerAlarm(alarm: Alarm, date: Date): boolean {
  if (!alarm.enabled) return false;

  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  const currentTime = `${hours}:${minutes}`;

  if (alarm.time !== currentTime) return false;

  // If repeatDays is empty, triggers once
  if (alarm.repeatDays.length === 0) return true;

  // DayOfWeek: 0 = Sunday, 1 = Monday, ... 6 = Saturday
  const currentDay = date.getDay() as DayOfWeek;
  return alarm.repeatDays.includes(currentDay);
}

/**
 * Generates random math challenges per difficulty level.
 */
export interface MathProblem {
  question: string;
  answer: number;
}

export function generateMathProblem(difficulty: 'facil' | 'medio' | 'dificil'): MathProblem {
  if (difficulty === 'facil') {
    const a = Math.floor(Math.random() * 20) + 1;
    const b = Math.floor(Math.random() * 10) + 1;
    const isAdd = Math.random() > 0.3;
    if (isAdd) {
      return { question: `${a} + ${b}`, answer: a + b };
    }
    const max = Math.max(a, b);
    const min = Math.min(a, b);
    return { question: `${max} - ${min}`, answer: max - min };
  }

  if (difficulty === 'medio') {
    const isMult = Math.random() > 0.4;
    if (isMult) {
      const a = Math.floor(Math.random() * 12) + 2;
      const b = Math.floor(Math.random() * 12) + 2;
      return { question: `${a} × ${b}`, answer: a * b };
    }
    const a = Math.floor(Math.random() * 50) + 10;
    const b = Math.floor(Math.random() * 50) + 10;
    return { question: `${a} + ${b}`, answer: a + b };
  }

  // Dificil: compound operation (A × B) ± C
  const a = Math.floor(Math.random() * 15) + 3;
  const b = Math.floor(Math.random() * 12) + 3;
  const c = Math.floor(Math.random() * 25) + 5;
  const isAdd = Math.random() > 0.5;
  if (isAdd) {
    return { question: `(${a} × ${b}) + ${c}`, answer: a * b + c };
  }
  return { question: `(${a} × ${b}) - ${c}`, answer: a * b - c };
}

/**
 * Evaluates answer correctness.
 */
export function validateMathAnswer(problem: MathProblem, userAnswer: number | string): boolean {
  const numeric = typeof userAnswer === 'string' ? parseInt(userAnswer, 10) : userAnswer;
  return numeric === problem.answer;
}

/**
 * Calculates next snooze timestamp.
 */
export function calculateNextSnooze(alarm: Alarm, fromDate: Date = new Date()): Date {
  const durationMs = (alarm.snoozeDuration || 9) * 60 * 1000;
  return new Date(fromDate.getTime() + durationMs);
}

/**
 * Anti-Bypass Lock-in State Machine implementation
 */
export class LockInStateMachine {
  private state: RingingState = { status: 'idle' };
  private currentProblem: MathProblem | null = null;
  private snoozeCount = 0;

  public getState(): RingingState {
    return this.state;
  }

  public getSnoozeCount(): number {
    return this.snoozeCount;
  }

  public trigger(alarm: Alarm, startedAt: Date = new Date()): void {
    this.state = { status: 'ringing', alarm, startedAt };
    this.currentProblem = null;
  }

  public requestDismiss(): 'dismissed' | 'challenge_required' {
    if (this.state.status !== 'ringing') {
      throw new Error(`Cannot request dismiss from state: ${this.state.status}`);
    }

    const { alarm } = this.state;

    if (alarm.missionType === 'none') {
      this.state = { status: 'dismissed', alarm };
      return 'dismissed';
    }

    // Lock-in: require challenge
    this.state = {
      status: 'challenging',
      alarm,
      challengeType: alarm.missionType,
      difficulty: alarm.missionDifficulty,
      progress: 0,
    };

    if (alarm.missionType === 'math') {
      this.currentProblem = generateMathProblem(alarm.missionDifficulty);
    }

    return 'challenge_required';
  }

  public getCurrentProblem(): MathProblem | null {
    return this.currentProblem;
  }

  public submitAnswer(answer: number | string): boolean {
    if (this.state.status !== 'challenging') {
      throw new Error('No active challenge in progress');
    }

    if (!this.currentProblem) {
      throw new Error('No math problem currently loaded');
    }

    const isCorrect = validateMathAnswer(this.currentProblem, answer);
    if (isCorrect) {
      this.state = { status: 'dismissed', alarm: this.state.alarm };
      return true;
    }

    // Wrong answer: generate new problem to prevent brute forcing
    this.currentProblem = generateMathProblem(this.state.alarm.missionDifficulty);
    return false;
  }

  public snooze(fromDate: Date = new Date()): Date {
    if (this.state.status !== 'ringing') {
      throw new Error(`Cannot snooze from state: ${this.state.status}`);
    }

    const { alarm } = this.state;
    if (!alarm.snoozeEnabled) {
      throw new Error('Snooze is disabled for this alarm');
    }

    this.snoozeCount += 1;
    const snoozeUntil = calculateNextSnooze(alarm, fromDate);
    this.state = { status: 'snoozed', alarm, snoozeUntil };
    return snoozeUntil;
  }

  public reset(): void {
    this.state = { status: 'idle' };
    this.currentProblem = null;
    this.snoozeCount = 0;
  }

  public createWakeLog(wakeTime: string, targetDate: string): WakeLog {
    if (this.state.status !== 'dismissed') {
      throw new Error('Cannot create wake log before alarm is dismissed');
    }
    const { alarm } = this.state;
    const hasSnooze = this.snoozeCount > 0;

    return {
      id: `log-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      alarmId: alarm.id,
      alarmLabel: alarm.label,
      scheduledTime: alarm.time,
      wakeTime,
      targetDate,
      snoozeCount: this.snoozeCount,
      missionCompleted: alarm.missionType !== 'none',
      missionType: alarm.missionType,
      sleepHours: 7.5,
      consistencyScore: hasSnooze ? Math.max(60, 100 - this.snoozeCount * 12) : 100,
      status: hasSnooze ? 'snoozed' : 'perfect',
      notes: `Alarma desactivada con ${this.snoozeCount} snoozes y misión ${alarm.missionType}.`,
    };
  }
}
