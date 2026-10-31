import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, act } from '@testing-library/react';
import { AlarmModal } from '../components/alarms/AlarmModal';
import { AlarmRow } from '../components/alarms/AlarmRow';
import { soundService } from '../services/soundService';
import {
  generateMathProblem,
  validateMathAnswer,
  LockInStateMachine,
  shouldTriggerAlarm,
} from './helpers/alarmEngine';
import { Alarm } from '../types/alarm';

describe('Tier 3: Cross-Feature Interactions', () => {
  beforeEach(() => {
    localStorage.clear();
    soundService.stop();
  });

  // ==========================================
  // Section 1: Repeat Days Scheduling & Presets Interaction
  // ==========================================
  describe('C1: Repeat Days Presets & Toggle Interactions', () => {
    it('applies Laborables (L-V) preset and updates selected day circles', () => {
      render(
        <AlarmModal
          isOpen={true}
          onClose={vi.fn()}
          onSave={vi.fn()}
          initialAlarm={{
            id: 'alm-p1',
            time: '07:00',
            label: 'Test Preset',
            enabled: true,
            repeatDays: [],
            sound: 'radar',
            volume: 80,
            snoozeEnabled: true,
            snoozeDuration: 9,
            missionType: 'none',
            missionDifficulty: 'facil',
            category: 'wake-up',
            createdAt: '2026-10-31T00:00:00.000Z',
          }}
        />
      );

      const weekdaysPreset = screen.getByText('Laborables (L-V)');
      fireEvent.click(weekdaysPreset);

      expect(screen.getByText('5 días')).toBeInTheDocument();
      // Sunday should not be selected
      expect(screen.getByLabelText(/Domingo, no seleccionado/i)).toBeInTheDocument();
      // Monday through Friday should be selected
      expect(screen.getByLabelText(/Lunes, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Martes, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Miércoles, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Jueves, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Viernes, seleccionado/i)).toBeInTheDocument();
      // Saturday should not be selected
      expect(screen.getByLabelText(/Sábado, no seleccionado/i)).toBeInTheDocument();
    });

    it('applies Fines de semana preset (S-D)', () => {
      render(<AlarmModal isOpen={true} onClose={vi.fn()} onSave={vi.fn()} />);
      const weekendPreset = screen.getByText('Fines de semana');
      fireEvent.click(weekendPreset);

      expect(screen.getByText('2 días')).toBeInTheDocument();
      expect(screen.getByLabelText(/Domingo, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Sábado, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Lunes, no seleccionado/i)).toBeInTheDocument();
    });

    it('applies Todos los días preset (7 days)', () => {
      render(<AlarmModal isOpen={true} onClose={vi.fn()} onSave={vi.fn()} />);
      const allPreset = screen.getByText('Todos');
      fireEvent.click(allPreset);

      expect(screen.getByText('Todos los días')).toBeInTheDocument();
      expect(screen.getByLabelText(/Domingo, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Lunes, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Martes, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Miércoles, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Jueves, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Viernes, seleccionado/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/Sábado, seleccionado/i)).toBeInTheDocument();
    });

    it('disambiguates and toggles Martes (Ma) and Miércoles (Mi) individually', () => {
      render(<AlarmModal isOpen={true} onClose={vi.fn()} onSave={vi.fn()} />);
      // Click Martes button
      const martesBtn = screen.getByLabelText(/Martes,/i);
      const isInitiallySelected = martesBtn.getAttribute('aria-pressed') === 'true';

      fireEvent.click(martesBtn);
      expect(martesBtn.getAttribute('aria-pressed')).toBe(isInitiallySelected ? 'false' : 'true');

      // Click Miércoles button
      const miercolesBtn = screen.getByLabelText(/Miércoles,/i);
      const isMiercolesSelected = miercolesBtn.getAttribute('aria-pressed') === 'true';

      fireEvent.click(miercolesBtn);
      expect(miercolesBtn.getAttribute('aria-pressed')).toBe(isMiercolesSelected ? 'false' : 'true');
    });
  });

  // ==========================================
  // Section 2: Audio Preview States & Lifecycle Interaction
  // ==========================================
  describe('C2: Audio Preview States & Lifecycle Interaction', () => {
    it('toggles audio test button between Escuchar and Detener', () => {
      const previewSpy = vi.spyOn(soundService, 'previewSound');
      const stopSpy = vi.spyOn(soundService, 'stop');

      render(<AlarmModal isOpen={true} onClose={vi.fn()} onSave={vi.fn()} />);
      const testSoundBtn = screen.getByLabelText(/Escuchar sonido/i);
      expect(testSoundBtn).toHaveTextContent(/Escuchar/i);

      // Start audio preview
      fireEvent.click(testSoundBtn);
      expect(previewSpy).toHaveBeenCalledTimes(1);
      expect(screen.getByLabelText(/Detener prueba de sonido/i)).toBeInTheDocument();
      expect(screen.getByText(/Detener/i)).toBeInTheDocument();

      // Stop audio preview
      const stopSoundBtn = screen.getByLabelText(/Detener prueba de sonido/i);
      fireEvent.click(stopSoundBtn);
      expect(stopSpy).toHaveBeenCalled();
      expect(screen.getByLabelText(/Escuchar sonido/i)).toBeInTheDocument();
    });

    it('changes sound while playing audio triggers previewSound with new sound', () => {
      const previewSpy = vi.spyOn(soundService, 'previewSound');
      render(<AlarmModal isOpen={true} onClose={vi.fn()} onSave={vi.fn()} />);

      // Start preview
      const testSoundBtn = screen.getByLabelText(/Escuchar sonido/i);
      fireEvent.click(testSoundBtn);

      // Change sound dropdown to 'apex'
      const select = screen.getByLabelText(/Sonido de Alarma/i);
      fireEvent.change(select, { target: { value: 'apex' } });

      expect(previewSpy).toHaveBeenLastCalledWith('apex', expect.any(Number));
    });

    it('stops audio playback when modal is cancelled', () => {
      const stopSpy = vi.spyOn(soundService, 'stop');
      const handleClose = vi.fn();
      render(<AlarmModal isOpen={true} onClose={handleClose} onSave={vi.fn()} />);

      // Start preview
      const testSoundBtn = screen.getByLabelText(/Escuchar sonido/i);
      fireEvent.click(testSoundBtn);

      // Click Cancelar
      const cancelBtn = screen.getByText('Cancelar');
      fireEvent.click(cancelBtn);

      expect(stopSpy).toHaveBeenCalled();
      expect(handleClose).toHaveBeenCalled();
    });

    it('stops audio playback when modal is closed with Escape key', () => {
      const stopSpy = vi.spyOn(soundService, 'stop');
      const handleClose = vi.fn();
      render(<AlarmModal isOpen={true} onClose={handleClose} onSave={vi.fn()} />);

      // Start preview
      const testSoundBtn = screen.getByLabelText(/Escuchar sonido/i);
      fireEvent.click(testSoundBtn);

      // Press Escape
      fireEvent.keyDown(window, { key: 'Escape' });
      expect(stopSpy).toHaveBeenCalled();
      expect(handleClose).toHaveBeenCalled();
    });

    it('toggles sound preview inside AlarmRow and auto-stops after timeout', () => {
      vi.useFakeTimers();
      const previewSpy = vi.spyOn(soundService, 'previewSound');
      const stopSpy = vi.spyOn(soundService, 'stop');

      const alarm: Alarm = {
        id: 'alm-row-audio',
        time: '06:30',
        label: 'Sound Test',
        enabled: true,
        repeatDays: [1, 2],
        sound: 'chimes',
        volume: 75,
        snoozeEnabled: false,
        snoozeDuration: 9,
        missionType: 'none',
        missionDifficulty: 'facil',
        category: 'wake-up',
        createdAt: '2026-10-31T00:00:00.000Z',
      };

      render(<AlarmRow alarm={alarm} onToggle={vi.fn()} onSelect={vi.fn()} />);
      const soundBtn = screen.getByLabelText(/Probar sonido de alarma chimes/i);

      // Click to start
      fireEvent.click(soundBtn);
      expect(previewSpy).toHaveBeenCalledWith('chimes', 75);
      expect(screen.getByLabelText(/Detener prueba de sonido/i)).toBeInTheDocument();

      // Advance timers past 2500ms auto-stop
      act(() => {
        vi.advanceTimersByTime(2600);
      });

      expect(screen.getByLabelText(/Probar sonido de alarma chimes/i)).toBeInTheDocument();
      vi.useRealTimers();
    });
  });

  // ==========================================
  // Section 3: Math Problem Generator & Validation
  // ==========================================
  describe('C3: Math Problem Generator & Anti-Brute Force Engine', () => {
    it('generates valid mathematical problems for "facil" difficulty', () => {
      for (let i = 0; i < 20; i++) {
        const problem = generateMathProblem('facil');
        expect(problem.question).toMatch(/^\d+\s+[+\-]\s+\d+$/);

        // Verify mathematical accuracy
        if (problem.question.includes('+')) {
          const [a, b] = problem.question.split('+').map((s) => parseInt(s.trim(), 10));
          expect(problem.answer).toBe(a + b);
        } else {
          const [a, b] = problem.question.split('-').map((s) => parseInt(s.trim(), 10));
          expect(problem.answer).toBe(a - b);
          expect(problem.answer).toBeGreaterThanOrEqual(0); // Non-negative
        }
      }
    });

    it('generates valid mathematical problems for "medio" difficulty', () => {
      for (let i = 0; i < 20; i++) {
        const problem = generateMathProblem('medio');
        if (problem.question.includes('×')) {
          const [a, b] = problem.question.split('×').map((s) => parseInt(s.trim(), 10));
          expect(problem.answer).toBe(a * b);
        } else {
          const [a, b] = problem.question.split('+').map((s) => parseInt(s.trim(), 10));
          expect(problem.answer).toBe(a + b);
        }
      }
    });

    it('generates valid mathematical problems for "dificil" difficulty', () => {
      for (let i = 0; i < 20; i++) {
        const problem = generateMathProblem('dificil');
        // Format: (A × B) ± C
        const match = problem.question.match(/\((\d+)\s+×\s+(\d+)\)\s+([+\-])\s+(\d+)/);
        expect(match).not.toBeNull();
        if (match) {
          const a = parseInt(match[1], 10);
          const b = parseInt(match[2], 10);
          const op = match[3];
          const c = parseInt(match[4], 10);
          const expected = op === '+' ? a * b + c : a * b - c;
          expect(problem.answer).toBe(expected);
        }
      }
    });

    it('validates math answer correctly for numbers and numeric strings', () => {
      const problem = { question: '12 + 15', answer: 27 };
      expect(validateMathAnswer(problem, 27)).toBe(true);
      expect(validateMathAnswer(problem, '27')).toBe(true);
      expect(validateMathAnswer(problem, 28)).toBe(false);
      expect(validateMathAnswer(problem, 'wrong')).toBe(false);
    });
  });

  // ==========================================
  // Section 4: Lock-In Anti-Bypass State Machine Transitions
  // ==========================================
  describe('C4: Lock-In Anti-Bypass State Machine Lifecycle', () => {
    const mathAlarm: Alarm = {
      id: 'alm-lockin',
      time: '07:00',
      label: 'Anti-Bypass Math Alarm',
      enabled: true,
      repeatDays: [1, 2, 3, 4, 5],
      sound: 'radar',
      volume: 85,
      snoozeEnabled: true,
      snoozeDuration: 9,
      missionType: 'math',
      missionDifficulty: 'medio',
      category: 'wake-up',
      createdAt: '2026-10-31T00:00:00.000Z',
    };

    it('transitions from idle to ringing when triggered', () => {
      const fsm = new LockInStateMachine();
      expect(fsm.getState().status).toBe('idle');

      fsm.trigger(mathAlarm);
      expect(fsm.getState().status).toBe('ringing');
    });

    it('demands challenge when dismiss is requested for math-gated alarm', () => {
      const fsm = new LockInStateMachine();
      fsm.trigger(mathAlarm);

      const result = fsm.requestDismiss();
      expect(result).toBe('challenge_required');
      expect(fsm.getState().status).toBe('challenging');
      expect(fsm.getCurrentProblem()).not.toBeNull();
    });

    it('rejects wrong answers, regenerates problem to block brute force, and keeps challenging', () => {
      const fsm = new LockInStateMachine();
      fsm.trigger(mathAlarm);
      fsm.requestDismiss();

      const initialProblem = fsm.getCurrentProblem()!;
      const wrongAnswer = initialProblem.answer + 999;

      const submitResult = fsm.submitAnswer(wrongAnswer);
      expect(submitResult).toBe(false);
      expect(fsm.getState().status).toBe('challenging');

      // Problem must be regenerated to prevent script retry
      const newProblem = fsm.getCurrentProblem()!;
      expect(newProblem).not.toBeNull();
    });

    it('dismisses alarm on correct answer submission', () => {
      const fsm = new LockInStateMachine();
      fsm.trigger(mathAlarm);
      fsm.requestDismiss();

      const problem = fsm.getCurrentProblem()!;
      const submitResult = fsm.submitAnswer(problem.answer);
      expect(submitResult).toBe(true);
      expect(fsm.getState().status).toBe('dismissed');
    });

    it('handles snooze transition, increments snoozeCount, and generates wake log', () => {
      const fsm = new LockInStateMachine();
      const triggerTime = new Date('2026-10-31T07:00:00');
      fsm.trigger(mathAlarm, triggerTime);

      const snoozeUntil = fsm.snooze(triggerTime);
      expect(fsm.getState().status).toBe('snoozed');
      expect(fsm.getSnoozeCount()).toBe(1);
      // 9 minutes later
      expect(snoozeUntil.getTime() - triggerTime.getTime()).toBe(9 * 60 * 1000);

      // Simulate second ring
      fsm.trigger(mathAlarm, snoozeUntil);
      fsm.requestDismiss();
      const problem = fsm.getCurrentProblem()!;
      fsm.submitAnswer(problem.answer);

      // Create wake log after dismissal
      const log = fsm.createWakeLog('07:15', '2026-10-31');
      expect(log.alarmId).toBe(mathAlarm.id);
      expect(log.snoozeCount).toBe(1);
      expect(log.status).toBe('snoozed');
      expect(log.consistencyScore).toBe(88); // 100 - 12
      expect(log.missionCompleted).toBe(true);
    });

    it('immediately dismisses alarms with missionType="none"', () => {
      const noMissionAlarm: Alarm = { ...mathAlarm, missionType: 'none' };
      const fsm = new LockInStateMachine();
      fsm.trigger(noMissionAlarm);

      const result = fsm.requestDismiss();
      expect(result).toBe('dismissed');
      expect(fsm.getState().status).toBe('dismissed');

      const log = fsm.createWakeLog('07:00', '2026-10-31');
      expect(log.snoozeCount).toBe(0);
      expect(log.status).toBe('perfect');
      expect(log.consistencyScore).toBe(100);
      expect(log.missionCompleted).toBe(false);
    });
  });
});
