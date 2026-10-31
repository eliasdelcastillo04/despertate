import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { AppleToggle } from '../components/common/AppleToggle';
import { AlarmRow } from '../components/alarms/AlarmRow';
import { AlarmModal } from '../components/alarms/AlarmModal';
import { CupertinoSegmentedControl } from '../components/common/CupertinoSegmentedControl';
import { WakeLogTable } from '../components/table/WakeLogTable';
import { InvestigationSidePanel } from '../components/sidepanel/InvestigationSidePanel';
import { App } from '../App';
import { calculateMetrics } from '../services/storageService';
import { shouldTriggerAlarm } from './helpers/alarmEngine';
import { getContrastRatio, meetsWcagAA } from './helpers/wcagContrast';
import { Alarm, WakeLog } from '../types/alarm';
import { Bell, Flame } from 'lucide-react';

describe('Tier 2: Boundary & Corner Cases', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  // ==========================================
  // Section 1: Empty State & Metric Edge Cases
  // ==========================================
  describe('B1: Empty State & Metrics Boundary Conditions', () => {
    it('calculates metrics gracefully when alarms and logs arrays are empty', () => {
      const metrics = calculateMetrics([], []);
      expect(metrics.totalAlarms).toBe(0);
      expect(metrics.activeAlarms).toBe(0);
      expect(metrics.averageWakeTime).toBe('06:45');
      expect(metrics.snoozeRate).toBe(0);
      expect(metrics.consistencyScore).toBe(90);
      expect(metrics.weeklyTrend).toBe(2.5);
    });

    it('renders empty wake log table with helpful feedback when logs array is empty', () => {
      render(
        <WakeLogTable
          logs={[]}
          selectedLogId={null}
          onSelectLog={vi.fn()}
        />
      );
      expect(
        screen.getByText(/No se encontraron registros con los filtros actuales/i)
      ).toBeInTheDocument();
      expect(screen.getByText(/Página 1 de 1 \(0 registros\)/i)).toBeInTheDocument();
    });

    it('renders empty alarms state in App when localStorage is empty of custom alarms', () => {
      // Set empty array in localStorage
      localStorage.setItem('alarma_apple_items_v1', JSON.stringify([]));
      render(<App />);

      expect(screen.getByText(/Tus Alarmas \(0\)/i)).toBeInTheDocument();
      expect(
        screen.getByText(/Selecciona cualquier alarma de la lista para ver su configuración completa y editarla/i)
      ).toBeInTheDocument();
      // Next alarm banner should not be displayed
      expect(screen.queryByText(/Próxima Alarma/i)).not.toBeInTheDocument();
    });

    it('handles wake logs with all zero snooze counts without NaN snoozeRate', () => {
      const logs: WakeLog[] = [
        {
          id: 'l-zero',
          alarmId: 'alm-1',
          alarmLabel: 'Madrugar',
          scheduledTime: '06:00',
          wakeTime: '06:00',
          targetDate: '2026-10-31',
          snoozeCount: 0,
          missionCompleted: true,
          missionType: 'math',
          sleepHours: 8.0,
          consistencyScore: 100,
          status: 'perfect',
        },
      ];
      const alarms: Alarm[] = [];
      const metrics = calculateMetrics(alarms, logs);
      expect(metrics.snoozeRate).toBe(0);
      expect(metrics.consistencyScore).toBe(100);
      expect(metrics.averageWakeTime).toBe('06:00');
    });
  });

  // ==========================================
  // Section 2: Midnight 00:00 & Extreme Time Boundaries
  // ==========================================
  describe('B2: Midnight 00:00 & Extreme Time Boundaries', () => {
    const baseAlarm: Alarm = {
      id: 'alarm-boundary',
      time: '00:00',
      label: 'Medianoche',
      enabled: true,
      repeatDays: [],
      sound: 'radar',
      volume: 80,
      snoozeEnabled: true,
      snoozeDuration: 9,
      missionType: 'none',
      missionDifficulty: 'facil',
      category: 'other',
      createdAt: '2026-10-31T00:00:00.000Z',
    };

    it('formats midnight 00:00 as AM in AlarmRow', () => {
      render(<AlarmRow alarm={baseAlarm} onToggle={vi.fn()} onSelect={vi.fn()} />);
      expect(screen.getByText('00:00')).toBeInTheDocument();
      expect(screen.getByText('AM')).toBeInTheDocument();
    });

    it('formats noon 12:00 as PM in AlarmRow', () => {
      const noonAlarm: Alarm = { ...baseAlarm, time: '12:00', label: 'Mediodía' };
      render(<AlarmRow alarm={noonAlarm} onToggle={vi.fn()} onSelect={vi.fn()} />);
      expect(screen.getByText('12:00')).toBeInTheDocument();
      expect(screen.getByText('PM')).toBeInTheDocument();
    });

    it('formats late night 23:59 as PM in AlarmRow', () => {
      const lateAlarm: Alarm = { ...baseAlarm, time: '23:59', label: 'Fin de día' };
      render(<AlarmRow alarm={lateAlarm} onToggle={vi.fn()} onSelect={vi.fn()} />);
      expect(screen.getByText('23:59')).toBeInTheDocument();
      expect(screen.getByText('PM')).toBeInTheDocument();
    });

    it('formats morning 07:05 with leading zeros properly', () => {
      const morningAlarm: Alarm = { ...baseAlarm, time: '07:05', label: 'Temprano' };
      render(<AlarmRow alarm={morningAlarm} onToggle={vi.fn()} onSelect={vi.fn()} />);
      expect(screen.getByText('07:05')).toBeInTheDocument();
      expect(screen.getByText('AM')).toBeInTheDocument();
    });

    it('shouldTriggerAlarm triggers exactly at midnight 00:00 and not 23:59 or 00:01', () => {
      const midnightAlarm: Alarm = { ...baseAlarm, time: '00:00', repeatDays: [] };
      const exactMidnight = new Date('2026-10-31T00:00:00');
      const oneMinuteBefore = new Date('2026-10-30T23:59:00');
      const oneMinuteAfter = new Date('2026-10-31T00:01:00');

      expect(shouldTriggerAlarm(midnightAlarm, exactMidnight)).toBe(true);
      expect(shouldTriggerAlarm(midnightAlarm, oneMinuteBefore)).toBe(false);
      expect(shouldTriggerAlarm(midnightAlarm, oneMinuteAfter)).toBe(false);
    });

    it('shouldTriggerAlarm rejects alarm when enabled=false even at exact match', () => {
      const disabledAlarm: Alarm = { ...baseAlarm, time: '07:00', enabled: false };
      const matchDate = new Date('2026-10-31T07:00:00');
      expect(shouldTriggerAlarm(disabledAlarm, matchDate)).toBe(false);
    });
  });

  // ==========================================
  // Section 3: Recurrence Edge Cases
  // ==========================================
  describe('B3: Recurrence Formatter Edge Cases in AlarmRow', () => {
    const testAlarm: Alarm = {
      id: 'alarm-repeat',
      time: '08:00',
      label: 'Test Recurrence',
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
    };

    it('displays "Una sola vez" when repeatDays is empty', () => {
      render(<AlarmRow alarm={{ ...testAlarm, repeatDays: [] }} onToggle={vi.fn()} onSelect={vi.fn()} />);
      expect(screen.getByText('Una sola vez')).toBeInTheDocument();
    });

    it('displays "Todos los días" when repeatDays contains all 7 days', () => {
      render(
        <AlarmRow
          alarm={{ ...testAlarm, repeatDays: [0, 1, 2, 3, 4, 5, 6] }}
          onToggle={vi.fn()}
          onSelect={vi.fn()}
        />
      );
      expect(screen.getByText('Todos los días')).toBeInTheDocument();
    });

    it('displays "Días laborales" when repeatDays is Monday through Friday', () => {
      render(
        <AlarmRow
          alarm={{ ...testAlarm, repeatDays: [1, 2, 3, 4, 5] }}
          onToggle={vi.fn()}
          onSelect={vi.fn()}
        />
      );
      expect(screen.getByText('Días laborales')).toBeInTheDocument();
    });

    it('displays "Fines de semana" when repeatDays is Saturday and Sunday', () => {
      render(
        <AlarmRow
          alarm={{ ...testAlarm, repeatDays: [0, 6] }}
          onToggle={vi.fn()}
          onSelect={vi.fn()}
        />
      );
      expect(screen.getByText('Fines de semana')).toBeInTheDocument();
    });

    it('displays comma-separated day names for custom day subsets', () => {
      render(
        <AlarmRow
          alarm={{ ...testAlarm, repeatDays: [2, 4] }}
          onToggle={vi.fn()}
          onSelect={vi.fn()}
        />
      );
      expect(screen.getByText(/Mar, Jue/i)).toBeInTheDocument();
    });
  });

  // ==========================================
  // Section 4: 44pt Touch Target Bounding Box Verification
  // ==========================================
  describe('B4: Apple HIG 44pt Touch Target Bounding Verification', () => {
    it('verifies AppleToggle has min-h-[44px] and min-w-[51px] touch target', () => {
      render(<AppleToggle checked={true} onChange={vi.fn()} label="Switch Target" />);
      const toggle = screen.getByRole('switch');
      expect(toggle.className).toMatch(/min-h-\[44px\]/);
      expect(toggle.className).toMatch(/min-w-\[51px\]/);
    });

    it('verifies AlarmRow sound preview button meets min 44x44px target', () => {
      const mockAlarm: Alarm = {
        id: 'row-touch',
        time: '07:00',
        label: 'Touch Test',
        enabled: true,
        repeatDays: [],
        sound: 'radar',
        volume: 80,
        snoozeEnabled: false,
        snoozeDuration: 9,
        missionType: 'none',
        missionDifficulty: 'facil',
        category: 'wake-up',
        createdAt: '2026-10-31T00:00:00.000Z',
      };
      render(<AlarmRow alarm={mockAlarm} onToggle={vi.fn()} onSelect={vi.fn()} />);
      const soundBtn = screen.getByLabelText(/Probar sonido de alarma radar/i);
      expect(soundBtn.className).toMatch(/min-w-\[44px\]/);
      expect(soundBtn.className).toMatch(/min-h-\[44px\]/);
    });

    it('verifies AlarmModal header Cancelar and Guardar buttons meet 44px min target', () => {
      render(<AlarmModal isOpen={true} onClose={vi.fn()} onSave={vi.fn()} />);
      const cancelBtn = screen.getByText('Cancelar');
      const saveBtn = screen.getByText('Guardar');
      expect(cancelBtn.className).toMatch(/min-h-\[44px\]/);
      expect(cancelBtn.className).toMatch(/min-w-\[44px\]/);
      expect(saveBtn.className).toMatch(/min-h-\[44px\]/);
      expect(saveBtn.className).toMatch(/min-w-\[44px\]/);
    });

    it('verifies AlarmModal 7 day circles are 44x44px (w-11 h-11)', () => {
      render(<AlarmModal isOpen={true} onClose={vi.fn()} onSave={vi.fn()} />);
      const dayButtons = screen.getAllByRole('button', { pressed: false });
      // Day buttons with full labels
      const sundayBtn = screen.getByLabelText(/Domingo,/i);
      expect(sundayBtn.className).toMatch(/w-11\s+h-11/);
    });

    it('verifies CupertinoSegmentedControl tabs have min-h-[44px]', () => {
      render(
        <CupertinoSegmentedControl
          options={[
            { value: 'tab1', label: 'Tab 1', icon: <Bell className="w-4 h-4" /> },
            { value: 'tab2', label: 'Tab 2', icon: <Flame className="w-4 h-4" /> },
          ]}
          value="tab1"
          onChange={vi.fn()}
        />
      );
      const tabs = screen.getAllByRole('tab');
      tabs.forEach((tab) => {
        expect(tab.className).toMatch(/min-h-\[44px\]/);
      });
    });

    it('verifies WakeLogTable pagination buttons meet min 44x44px target', () => {
      render(
        <WakeLogTable
          logs={[]}
          selectedLogId={null}
          onSelectLog={vi.fn()}
        />
      );
      const prevBtn = screen.getByLabelText('Página anterior');
      const nextBtn = screen.getByLabelText('Página siguiente');
      expect(prevBtn.className).toMatch(/min-w-\[44px\]/);
      expect(prevBtn.className).toMatch(/min-h-\[44px\]/);
      expect(nextBtn.className).toMatch(/min-w-\[44px\]/);
      expect(nextBtn.className).toMatch(/min-h-\[44px\]/);
    });

    it('verifies InvestigationSidePanel close button meets min 44x44px target', () => {
      const mockLog: WakeLog = {
        id: 'log-panel',
        alarmId: 'alm-1',
        alarmLabel: 'Panel Test',
        scheduledTime: '07:00',
        wakeTime: '07:00',
        targetDate: '2026-10-31',
        snoozeCount: 0,
        missionCompleted: true,
        missionType: 'none',
        sleepHours: 8.0,
        consistencyScore: 100,
        status: 'perfect',
      };
      render(
        <InvestigationSidePanel
          log={mockLog}
          onClose={vi.fn()}
          onUpdateStatus={vi.fn()}
          onOpenEditAlarm={vi.fn()}
        />
      );
      const closeBtn = screen.getByLabelText(/Cerrar panel de inspección/i);
      expect(closeBtn.className).toMatch(/min-w-\[44px\]/);
      expect(closeBtn.className).toMatch(/min-h-\[44px\]/);
    });
  });

  // ==========================================
  // Section 5: WCAG 2.1 AA Contrast Ratio Verification
  // ==========================================
  describe('B5: WCAG 2.1 AA Contrast Ratio Verification', () => {
    it('verifies Apple HIG Light Mode primary text passes WCAG AA (>= 4.5:1)', () => {
      // Light background #F2F2F7 vs Pure Black #000000
      const ratio = getContrastRatio('#000000', '#F2F2F7');
      expect(ratio).toBeGreaterThan(15.0);
      expect(meetsWcagAA('#000000', '#F2F2F7')).toBe(true);

      // Card surface #FFFFFF vs Charcoal Text #1C1C1E
      const cardRatio = getContrastRatio('#1C1C1E', '#FFFFFF');
      expect(cardRatio).toBeGreaterThan(13.0);
      expect(meetsWcagAA('#1C1C1E', '#FFFFFF')).toBe(true);
    });

    it('verifies Apple HIG Dark Mode primary text passes WCAG AA (>= 4.5:1)', () => {
      // Pure Black background #000000 vs Pure White text #FFFFFF
      const darkRatio = getContrastRatio('#FFFFFF', '#000000');
      expect(darkRatio).toBe(21.0);
      expect(meetsWcagAA('#FFFFFF', '#000000')).toBe(true);

      // Dark card surface #1C1C1E vs White text #FFFFFF
      const darkCardRatio = getContrastRatio('#FFFFFF', '#1C1C1E');
      expect(darkCardRatio).toBeGreaterThan(15.0);
      expect(meetsWcagAA('#FFFFFF', '#1C1C1E')).toBe(true);
    });

    it('verifies Apple System Accent Colors against dark backgrounds', () => {
      // Apple Orange #FF9500 on #000000
      const orangeRatio = getContrastRatio('#FF9500', '#000000');
      expect(orangeRatio).toBeGreaterThan(8.0);
      expect(meetsWcagAA('#FF9500', '#000000')).toBe(true);

      // Apple Green #34C759 on #000000
      const greenRatio = getContrastRatio('#34C759', '#000000');
      expect(greenRatio).toBeGreaterThan(9.0);
      expect(meetsWcagAA('#34C759', '#000000')).toBe(true);
    });

    it('verifies Apple Secondary Text #636366 and #8E8E93 pass contrast thresholds', () => {
      // Light secondary #636366 on white #FFFFFF
      const lightSecRatio = getContrastRatio('#636366', '#FFFFFF');
      expect(lightSecRatio).toBeGreaterThanOrEqual(4.5);
      expect(meetsWcagAA('#636366', '#FFFFFF')).toBe(true);

      // Dark secondary #8E8E93 on pure black #000000
      const darkSecRatio = getContrastRatio('#8E8E93', '#000000');
      expect(darkSecRatio).toBeGreaterThanOrEqual(4.5);
      expect(meetsWcagAA('#8E8E93', '#000000')).toBe(true);
    });

    it('adversarial contrast test: accurately flags insufficient contrast (< 4.5:1)', () => {
      // Identical colors return 1.0:1
      expect(getContrastRatio('#FFFFFF', '#FFFFFF')).toBe(1.0);
      expect(meetsWcagAA('#FFFFFF', '#FFFFFF')).toBe(false);

      expect(getContrastRatio('#000000', '#000000')).toBe(1.0);
      expect(meetsWcagAA('#000000', '#000000')).toBe(false);

      // Light gray on white (#CCCCCC on #FFFFFF) has ratio ~ 1.6:1
      expect(meetsWcagAA('#CCCCCC', '#FFFFFF')).toBe(false);
    });
  });
});
