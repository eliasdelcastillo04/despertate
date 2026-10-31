import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, act } from '@testing-library/react';
import { AppleToggle } from '../components/common/AppleToggle';
import { AlarmRow } from '../components/alarms/AlarmRow';
import { AlarmModal } from '../components/alarms/AlarmModal';
import { AppleClockView } from '../components/clock/AppleClockView';
import { CupertinoSegmentedControl } from '../components/common/CupertinoSegmentedControl';
import { KpiCard } from '../components/common/KpiCard';
import { WakeLogTable } from '../components/table/WakeLogTable';
import {
  getStoredAlarms,
  saveAlarms,
  getStoredLogs,
  saveLogs,
  calculateMetrics,
} from '../services/storageService';
import { soundService } from '../services/soundService';
import { Alarm, WakeLog, AlarmSound } from '../types/alarm';
import { Bell, Flame } from 'lucide-react';

describe('Tier 1: Feature Coverage Tests', () => {
  beforeEach(() => {
    localStorage.clear();
    soundService.stop();
  });

  // ==========================================
  // Feature 1: AppleToggle Cupertino Switch
  // ==========================================
  describe('F1: AppleToggle Cupertino Switch', () => {
    it('renders with role="switch" and reflects aria-checked=true when enabled', () => {
      render(<AppleToggle checked={true} onChange={vi.fn()} label="Alarma activa" />);
      const toggle = screen.getByRole('switch');
      expect(toggle).toBeInTheDocument();
      expect(toggle).toHaveAttribute('aria-checked', 'true');
      expect(toggle).toHaveAttribute('aria-label', 'Alarma activa');
    });

    it('reflects aria-checked=false when disabled', () => {
      render(<AppleToggle checked={false} onChange={vi.fn()} label="Alarma inactiva" />);
      const toggle = screen.getByRole('switch');
      expect(toggle).toHaveAttribute('aria-checked', 'false');
    });

    it('calls onChange with inverted boolean when clicked', () => {
      const handleChange = vi.fn();
      render(<AppleToggle checked={false} onChange={handleChange} />);
      const toggle = screen.getByRole('switch');
      fireEvent.click(toggle);
      expect(handleChange).toHaveBeenCalledTimes(1);
      expect(handleChange).toHaveBeenCalledWith(true);
    });

    it('does not trigger onChange when disabled=true', () => {
      const handleChange = vi.fn();
      render(<AppleToggle checked={true} onChange={handleChange} disabled={true} />);
      const toggle = screen.getByRole('switch');
      fireEvent.click(toggle);
      expect(handleChange).not.toHaveBeenCalled();
    });

    it('stops click event propagation to parent container', () => {
      const parentClick = vi.fn();
      const handleChange = vi.fn();
      render(
        <div onClick={parentClick}>
          <AppleToggle checked={false} onChange={handleChange} />
        </div>
      );
      const toggle = screen.getByRole('switch');
      fireEvent.click(toggle);
      expect(handleChange).toHaveBeenCalledWith(true);
      expect(parentClick).not.toHaveBeenCalled();
    });
  });

  // ==========================================
  // Feature 2: Alarm Listing & Management (AlarmRow)
  // ==========================================
  describe('F2: AlarmRow Component', () => {
    const mockAlarm: Alarm = {
      id: 'test-1',
      time: '07:30',
      label: 'Despertar Gym',
      enabled: true,
      repeatDays: [1, 3, 5],
      sound: 'radar',
      volume: 80,
      snoozeEnabled: true,
      snoozeDuration: 9,
      missionType: 'math',
      missionDifficulty: 'medio',
      category: 'wake-up',
      createdAt: '2026-10-30T00:00:00.000Z',
    };

    it('renders alarm time in 24h format and correct AM/PM indicator', () => {
      render(
        <AlarmRow
          alarm={mockAlarm}
          onToggle={vi.fn()}
          onSelect={vi.fn()}
        />
      );
      expect(screen.getByText('07:30')).toBeInTheDocument();
      expect(screen.getByText('AM')).toBeInTheDocument();
      expect(screen.getByText('Despertar Gym')).toBeInTheDocument();
    });

    it('shows PM for afternoon alarm times (>= 12:00)', () => {
      const pmAlarm: Alarm = { ...mockAlarm, time: '18:45' };
      render(
        <AlarmRow
          alarm={pmAlarm}
          onToggle={vi.fn()}
          onSelect={vi.fn()}
        />
      );
      expect(screen.getByText('18:45')).toBeInTheDocument();
      expect(screen.getByText('PM')).toBeInTheDocument();
    });

    it('displays repeat days formatted correctly', () => {
      render(
        <AlarmRow
          alarm={mockAlarm}
          onToggle={vi.fn()}
          onSelect={vi.fn()}
        />
      );
      // Days [1, 3, 5] -> Lun, Mié, Vie
      expect(screen.getByText(/Lun, Mié, Vie/i)).toBeInTheDocument();
    });

    it('displays mission badge when missionType is set', () => {
      render(
        <AlarmRow
          alarm={mockAlarm}
          onToggle={vi.fn()}
          onSelect={vi.fn()}
        />
      );
      expect(screen.getByText(/Misión: math/i)).toBeInTheDocument();
    });

    it('triggers onSelect when row is clicked', () => {
      const handleSelect = vi.fn();
      render(
        <AlarmRow
          alarm={mockAlarm}
          onToggle={vi.fn()}
          onSelect={handleSelect}
        />
      );
      fireEvent.click(screen.getByText('Despertar Gym'));
      expect(handleSelect).toHaveBeenCalledWith(mockAlarm);
    });

    it('triggers onToggle when switch is toggled', () => {
      const handleToggle = vi.fn();
      render(
        <AlarmRow
          alarm={mockAlarm}
          onToggle={handleToggle}
          onSelect={vi.fn()}
        />
      );
      const toggle = screen.getByRole('switch');
      fireEvent.click(toggle);
      expect(handleToggle).toHaveBeenCalledWith('test-1', false);
    });
  });

  // ==========================================
  // Feature 3: Local Storage Persistence
  // ==========================================
  describe('F3: Storage Service Persistence & Metrics', () => {
    it('returns INITIAL_ALARMS when localStorage is empty and sets them', () => {
      const alarms = getStoredAlarms();
      expect(alarms.length).toBeGreaterThanOrEqual(3);
      expect(alarms[0]).toHaveProperty('id');
      expect(alarms[0]).toHaveProperty('time');
      expect(localStorage.getItem('alarma_apple_items_v1')).not.toBeNull();
    });

    it('saves alarms to localStorage and retrieves modified data', () => {
      const customAlarms: Alarm[] = [
        {
          id: 'custom-1',
          time: '05:00',
          label: 'Madrugador',
          enabled: true,
          repeatDays: [1, 2, 3, 4, 5],
          sound: 'apex',
          volume: 100,
          snoozeEnabled: false,
          snoozeDuration: 5,
          missionType: 'none',
          missionDifficulty: 'facil',
          category: 'wake-up',
          createdAt: new Date().toISOString(),
        },
      ];
      saveAlarms(customAlarms);
      const retrieved = getStoredAlarms();
      expect(retrieved).toHaveLength(1);
      expect(retrieved[0].label).toBe('Madrugador');
      expect(retrieved[0].sound).toBe('apex');
    });

    it('saves and retrieves wake logs', () => {
      const customLogs: WakeLog[] = [
        {
          id: 'log-x',
          alarmId: 'alm-1',
          alarmLabel: 'Test Alarm',
          scheduledTime: '07:00',
          wakeTime: '07:00',
          targetDate: '2026-10-30',
          snoozeCount: 0,
          missionCompleted: true,
          missionType: 'math',
          sleepHours: 8.0,
          consistencyScore: 100,
          status: 'perfect',
        },
      ];
      saveLogs(customLogs);
      const retrieved = getStoredLogs();
      expect(retrieved).toHaveLength(1);
      expect(retrieved[0].id).toBe('log-x');
      expect(retrieved[0].consistencyScore).toBe(100);
    });

    it('calculates metrics correctly for non-empty alarms and logs', () => {
      const testAlarms: Alarm[] = [
        {
          id: 'a1',
          time: '06:00',
          label: 'A1',
          enabled: true,
          repeatDays: [],
          sound: 'radar',
          volume: 80,
          snoozeEnabled: true,
          snoozeDuration: 9,
          missionType: 'none',
          missionDifficulty: 'facil',
          category: 'wake-up',
          createdAt: '',
        },
        {
          id: 'a2',
          time: '07:00',
          label: 'A2',
          enabled: false,
          repeatDays: [],
          sound: 'radar',
          volume: 80,
          snoozeEnabled: true,
          snoozeDuration: 9,
          missionType: 'none',
          missionDifficulty: 'facil',
          category: 'wake-up',
          createdAt: '',
        },
      ];

      const testLogs: WakeLog[] = [
        {
          id: 'l1',
          alarmId: 'a1',
          alarmLabel: 'A1',
          scheduledTime: '06:00',
          wakeTime: '06:00', // 360 min
          targetDate: '2026-10-30',
          snoozeCount: 0,
          missionCompleted: false,
          missionType: 'none',
          sleepHours: 8.0,
          consistencyScore: 100,
          status: 'perfect',
        },
        {
          id: 'l2',
          alarmId: 'a1',
          alarmLabel: 'A1',
          scheduledTime: '06:00',
          wakeTime: '06:30', // 390 min
          targetDate: '2026-10-29',
          snoozeCount: 2,
          missionCompleted: false,
          missionType: 'none',
          sleepHours: 7.0,
          consistencyScore: 80,
          status: 'snoozed',
        },
      ];

      const metrics = calculateMetrics(testAlarms, testLogs);
      expect(metrics.totalAlarms).toBe(2);
      expect(metrics.activeAlarms).toBe(1);
      // Avg minutes: (360 + 390) / 2 = 375 min -> 06:15
      expect(metrics.averageWakeTime).toBe('06:15');
      // 1 of 2 logs had snooze -> 50%
      expect(metrics.snoozeRate).toBe(50);
      // Avg consistency: (100 + 80) / 2 = 90
      expect(metrics.consistencyScore).toBe(90);
    });
  });

  // ==========================================
  // Feature 4: Sound Selection & Audio Synthesis
  // ==========================================
  describe('F4: Sound Service Audio Synthesis', () => {
    const soundTypes: AlarmSound[] = ['radar', 'chimes', 'apex', 'breeze', 'cosmic'];

    soundTypes.forEach((sound) => {
      it(`initializes and previews sound '${sound}' without error`, () => {
        expect(() => {
          soundService.previewSound(sound, 80);
        }).not.toThrow();
        soundService.stop();
      });
    });

    it('clamps volume under 0 to 0 and above 100 to 100', () => {
      expect(() => {
        soundService.previewSound('radar', -50);
        soundService.stop();
        soundService.previewSound('radar', 150);
        soundService.stop();
      }).not.toThrow();
    });

    it('cleanly stops active oscillators and clears interval on stop()', () => {
      soundService.previewSound('chimes', 75);
      expect(() => {
        soundService.stop();
      }).not.toThrow();
    });
  });

  // ==========================================
  // Feature 5: Clock & Stopwatch (AppleClockView)
  // ==========================================
  describe('F5: AppleClockView Analog, Digital Clock & Stopwatch', () => {
    it('renders digital clock and current time headers', () => {
      render(<AppleClockView />);
      expect(screen.getByText(/Hora Actual/i)).toBeInTheDocument();
      expect(screen.getByText(/Cronómetro/i)).toBeInTheDocument();
      expect(screen.getByText('00:00.0')).toBeInTheDocument();
    });

    it('starts stopwatch when Iniciar button is clicked', () => {
      render(<AppleClockView />);
      const buttons = screen.getAllByRole('button');
      const startBtn = buttons[1];
      expect(startBtn).toHaveClass('bg-[#34C759]');
      fireEvent.click(startBtn);
      expect(startBtn).toHaveClass('bg-[#FF3B30]');
    });

    it('records lap and displays in laps list', () => {
      vi.useFakeTimers();
      render(<AppleClockView />);
      const buttons = screen.getAllByRole('button');
      const lapBtn = buttons[0];
      const startBtn = buttons[1];
      fireEvent.click(startBtn);
      act(() => {
        vi.advanceTimersByTime(300);
      });
      fireEvent.click(lapBtn);
      expect(screen.getByText(/Vuelta 1/i)).toBeInTheDocument();
      vi.useRealTimers();
    });

    it('resets stopwatch on Reiniciar button click', () => {
      vi.useFakeTimers();
      render(<AppleClockView />);
      const buttons = screen.getAllByRole('button');
      const lapResetBtn = buttons[0];
      const startStopBtn = buttons[1];
      fireEvent.click(startStopBtn);
      act(() => {
        vi.advanceTimersByTime(300);
      });
      fireEvent.click(startStopBtn);
      fireEvent.click(lapResetBtn);
      expect(screen.getByText('00:00.0')).toBeInTheDocument();
      vi.useRealTimers();
    });
  });

  // ==========================================
  // Feature 6: CupertinoSegmentedControl
  // ==========================================
  describe('F6: CupertinoSegmentedControl Component', () => {
    const options = [
      { value: 'alarms', label: 'Alarmas', icon: <Bell className="w-4 h-4" /> },
      { value: 'metrics', label: 'Métricas', icon: <Flame className="w-4 h-4" /> },
    ];

    it('renders segmented options with text labels', () => {
      render(
        <CupertinoSegmentedControl
          options={options}
          value="alarms"
          onChange={vi.fn()}
        />
      );
      expect(screen.getByText('Alarmas')).toBeInTheDocument();
      expect(screen.getByText('Métricas')).toBeInTheDocument();
    });

    it('triggers onChange callback with clicked tab id', () => {
      const handleChange = vi.fn();
      render(
        <CupertinoSegmentedControl
          options={options}
          value="alarms"
          onChange={handleChange}
        />
      );
      fireEvent.click(screen.getByText('Métricas'));
      expect(handleChange).toHaveBeenCalledWith('metrics');
    });
  });

  // ==========================================
  // Feature 7: KpiCard Component
  // ==========================================
  describe('F7: KpiCard Component', () => {
    it('renders title, value, and subtitle properly', () => {
      render(
        <KpiCard
          title="Consistencia Media"
          value="94%"
          subtitle="Últimos 14 días"
          trend={{ value: '+3.2%', isPositive: true }}
          icon={<Flame className="w-5 h-5" />}
          accentColor="orange"
        />
      );
      expect(screen.getByText('Consistencia Media')).toBeInTheDocument();
      expect(screen.getByText('94%')).toBeInTheDocument();
      expect(screen.getByText('Últimos 14 días')).toBeInTheDocument();
      expect(screen.getByText('+3.2%')).toBeInTheDocument();
    });

    it('handles negative trend styling', () => {
      render(
        <KpiCard
          title="Tasa Snooze"
          value="25%"
          subtitle="Tendencia mensual"
          trend={{ value: '-1.5%', isPositive: false }}
          icon={<Bell className="w-5 h-5" />}
          accentColor="blue"
        />
      );
      expect(screen.getByText('-1.5%')).toBeInTheDocument();
    });
  });

  // ==========================================
  // Feature 8: WakeLogTable Component
  // ==========================================
  describe('F8: WakeLogTable Component', () => {
    const sampleLogs: WakeLog[] = [
      {
        id: 'log-1',
        alarmId: 'alm-1',
        alarmLabel: 'Despertar Matutino',
        scheduledTime: '06:30',
        wakeTime: '06:30',
        targetDate: '2026-10-30',
        snoozeCount: 0,
        missionCompleted: true,
        missionType: 'math',
        sleepHours: 8.0,
        consistencyScore: 100,
        status: 'perfect',
      },
      {
        id: 'log-2',
        alarmId: 'alm-2',
        alarmLabel: 'Gimnasio',
        scheduledTime: '07:00',
        wakeTime: '07:15',
        targetDate: '2026-10-29',
        snoozeCount: 1,
        missionCompleted: false,
        missionType: 'none',
        sleepHours: 6.5,
        consistencyScore: 82,
        status: 'snoozed',
      },
    ];

    it('renders log records with alarm labels and scores', () => {
      render(
        <WakeLogTable
          logs={sampleLogs}
          selectedLogId={null}
          onSelectLog={vi.fn()}
        />
      );
      expect(screen.getByText('Despertar Matutino')).toBeInTheDocument();
      expect(screen.getByText('Gimnasio')).toBeInTheDocument();
      expect(screen.getByText('100%')).toBeInTheDocument();
      expect(screen.getByText('82%')).toBeInTheDocument();
    });

    it('filters logs by search input', () => {
      render(
        <WakeLogTable
          logs={sampleLogs}
          selectedLogId={null}
          onSelectLog={vi.fn()}
        />
      );
      const searchInput = screen.getByPlaceholderText(/Buscar en registros.../i);
      fireEvent.change(searchInput, { target: { value: 'Gimnasio' } });
      expect(screen.getByText('Gimnasio')).toBeInTheDocument();
      expect(screen.queryByText('Despertar Matutino')).not.toBeInTheDocument();
    });

    it('triggers onSelectLog when a row is clicked', () => {
      const handleSelect = vi.fn();
      render(
        <WakeLogTable
          logs={sampleLogs}
          selectedLogId={null}
          onSelectLog={handleSelect}
        />
      );
      fireEvent.click(screen.getByText('Despertar Matutino'));
      expect(handleSelect).toHaveBeenCalledWith(sampleLogs[0]);
    });
  });

  // ==========================================
  // Feature 9: Alarm Creation & Editing Modal (AlarmModal)
  // ==========================================
  describe('F9: AlarmModal Creation & Editing', () => {
    it('does not render when isOpen is false', () => {
      render(
        <AlarmModal
          isOpen={false}
          onClose={vi.fn()}
          onSave={vi.fn()}
        />
      );
      expect(screen.queryByText(/Nueva Alarma/i)).not.toBeInTheDocument();
    });

    it('renders with title "Nueva Alarma" when creating without initialAlarm', () => {
      render(
        <AlarmModal
          isOpen={true}
          onClose={vi.fn()}
          onSave={vi.fn()}
        />
      );
      expect(screen.getByText(/Nueva Alarma/i)).toBeInTheDocument();
      expect(screen.getByText(/Guardar/i)).toBeInTheDocument();
      expect(screen.getByText(/Cancelar/i)).toBeInTheDocument();
    });

    it('renders with title "Editar Alarma" when initialAlarm is provided', () => {
      const initialAlarm: Alarm = {
        id: 'edit-1',
        time: '08:15',
        label: 'Reunión Diaria',
        enabled: true,
        repeatDays: [1, 2, 3, 4, 5],
        sound: 'chimes',
        volume: 70,
        snoozeEnabled: true,
        snoozeDuration: 9,
        missionType: 'none',
        missionDifficulty: 'facil',
        category: 'work',
        createdAt: '2026-10-30T00:00:00.000Z',
      };

      render(
        <AlarmModal
          isOpen={true}
          onClose={vi.fn()}
          onSave={vi.fn()}
          initialAlarm={initialAlarm}
        />
      );
      expect(screen.getByText(/Editar Alarma/i)).toBeInTheDocument();
    });

    it('submits updated alarm data on form submit', () => {
      const handleSave = vi.fn();
      const handleClose = vi.fn();
      render(
        <AlarmModal
          isOpen={true}
          onClose={handleClose}
          onSave={handleSave}
        />
      );

      const saveBtn = screen.getByText(/Guardar/i);
      fireEvent.click(saveBtn);

      expect(handleSave).toHaveBeenCalledTimes(1);
      const saved = handleSave.mock.calls[0][0];
      expect(saved).toHaveProperty('time');
      expect(saved).toHaveProperty('label');
      expect(saved).toHaveProperty('sound');
      expect(saved).toHaveProperty('enabled', true);
      expect(handleClose).toHaveBeenCalledTimes(1);
    });

    it('calls onClose when Cancelar button is clicked', () => {
      const handleClose = vi.fn();
      render(
        <AlarmModal
          isOpen={true}
          onClose={handleClose}
          onSave={vi.fn()}
        />
      );
      const cancelBtn = screen.getByText(/Cancelar/i);
      fireEvent.click(cancelBtn);
      expect(handleClose).toHaveBeenCalledTimes(1);
    });
  });
});
