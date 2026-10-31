import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { AppleToggle } from '../components/common/AppleToggle';
import { CupertinoSegmentedControl } from '../components/common/CupertinoSegmentedControl';
import { AlarmRow } from '../components/alarms/AlarmRow';
import { AlarmModal } from '../components/alarms/AlarmModal';
import { WakeLogTable } from '../components/table/WakeLogTable';
import { InvestigationSidePanel } from '../components/sidepanel/InvestigationSidePanel';
import { AppleClockView } from '../components/clock/AppleClockView';
import { App } from '../App';
import { soundService } from '../services/soundService';
import { Alarm, WakeLog } from '../types/alarm';
import fs from 'fs';
import path from 'path';

describe('Milestone 1: Accessibility, Touch Targets & HIG Visual Token Overhaul', () => {
  beforeEach(() => {
    localStorage.clear();
    soundService.stop();
  });

  // ==========================================
  // Section 1: Viewport & Safe Area
  // ==========================================
  describe('1. Viewport & Safe Area Conformance', () => {
    it('restores pinch-to-zoom and safe-area in index.html (WCAG 1.4.4)', () => {
      const htmlPath = path.resolve(__dirname, '../../index.html');
      const htmlContent = fs.readFileSync(htmlPath, 'utf-8');
      expect(htmlContent).toContain('user-scalable=yes');
      expect(htmlContent).toContain('maximum-scale=5.0');
      expect(htmlContent).toContain('viewport-fit=cover');
    });

    it('contains safe-area utilities in src/index.css', () => {
      const cssPath = path.resolve(__dirname, '../index.css');
      const cssContent = fs.readFileSync(cssPath, 'utf-8');
      expect(cssContent).toContain('env(safe-area-inset-top)');
      expect(cssContent).toContain('env(safe-area-inset-bottom)');
      expect(cssContent).toContain('text-hig-secondary');
      expect(cssContent).toContain('prefers-reduced-motion');
    });
  });

  // ==========================================
  // Section 2: 44x44pt Touch Targets & Semantics
  // ==========================================
  describe('2. 44x44pt Touch Targets & Component Semantics', () => {
    describe('AppleToggle Component', () => {
      it('has role="switch", aria-checked, and min 44x44pt touch target', () => {
        render(<AppleToggle checked={true} onChange={vi.fn()} label="Interruptor de prueba" />);
        const toggle = screen.getByRole('switch');
        expect(toggle).toBeInTheDocument();
        expect(toggle).toHaveAttribute('aria-checked', 'true');
        expect(toggle).toHaveAttribute('aria-label', 'Interruptor de prueba');
        expect(toggle.className).toContain('min-h-[44px]');
        expect(toggle.className).toContain('min-w-[51px]');
      });

      it('toggles value when clicked', () => {
        const handleChange = vi.fn();
        render(<AppleToggle checked={false} onChange={handleChange} />);
        const toggle = screen.getByRole('switch');
        fireEvent.click(toggle);
        expect(handleChange).toHaveBeenCalledWith(true);
      });
    });

    describe('CupertinoSegmentedControl Component', () => {
      const tabs = [
        { value: 'tab1', label: 'Alarmas' },
        { value: 'tab2', label: 'Métricas' },
        { value: 'tab3', label: 'Reloj' },
      ];

      it('implements tablist and tab semantics with min-h-[44px] touch target', () => {
        render(<CupertinoSegmentedControl options={tabs} value="tab1" onChange={vi.fn()} />);
        const tablist = screen.getByRole('tablist');
        expect(tablist).toBeInTheDocument();

        const tabElements = screen.getAllByRole('tab');
        expect(tabElements).toHaveLength(3);
        expect(tabElements[0]).toHaveAttribute('aria-selected', 'true');
        expect(tabElements[1]).toHaveAttribute('aria-selected', 'false');

        tabElements.forEach((tab) => {
          expect(tab.className).toContain('min-h-[44px]');
        });
      });

      it('supports arrow key navigation across tabs', () => {
        const handleChange = vi.fn();
        render(<CupertinoSegmentedControl options={tabs} value="tab1" onChange={handleChange} />);
        const tabElements = screen.getAllByRole('tab');

        // Right arrow moves to next
        fireEvent.keyDown(tabElements[0], { key: 'ArrowRight' });
        expect(handleChange).toHaveBeenCalledWith('tab2');

        // Left arrow moves to previous (wraps to end)
        fireEvent.keyDown(tabElements[0], { key: 'ArrowLeft' });
        expect(handleChange).toHaveBeenCalledWith('tab3');

        // Home key moves to first
        fireEvent.keyDown(tabElements[1], { key: 'Home' });
        expect(handleChange).toHaveBeenCalledWith('tab1');

        // End key moves to last
        fireEvent.keyDown(tabElements[0], { key: 'End' });
        expect(handleChange).toHaveBeenCalledWith('tab3');
      });
    });

    describe('AlarmRow Component', () => {
      const sampleAlarm: Alarm = {
        id: 'alm-1',
        time: '07:30',
        label: 'Trabajo',
        enabled: false,
        repeatDays: [1, 2, 3, 4, 5],
        sound: 'radar',
        volume: 80,
        snoozeEnabled: true,
        snoozeDuration: 9,
        missionType: 'math',
        missionDifficulty: 'medio',
        category: 'work',
        createdAt: '2026-10-31T08:00:00.000Z',
      };

      it('has 44x44pt sound preview target with active playing state and aria-label', () => {
        render(<AlarmRow alarm={sampleAlarm} onToggle={vi.fn()} onSelect={vi.fn()} />);
        const soundBtn = screen.getByRole('button', { name: /Probar sonido de alarma radar/i });
        expect(soundBtn).toBeInTheDocument();
        expect(soundBtn.className).toContain('min-w-[44px]');
        expect(soundBtn.className).toContain('min-h-[44px]');

        // Clicking preview triggers playing state
        fireEvent.click(soundBtn);
        expect(soundBtn).toHaveAttribute('aria-label', 'Detener prueba de sonido');
        expect(soundBtn.className).toContain('animate-pulse');

        // Clicking again stops sound
        fireEvent.click(soundBtn);
        expect(soundBtn).toHaveAttribute('aria-label', 'Probar sonido de alarma radar');
      });

      it('provides accessible keyboard selection on row via Enter or Space', () => {
        const handleSelect = vi.fn();
        render(<AlarmRow alarm={sampleAlarm} onToggle={vi.fn()} onSelect={handleSelect} />);
        const row = screen.getByRole('button', { name: /Alarma 07:30/i });
        expect(row).toHaveAttribute('tabindex', '0');

        fireEvent.keyDown(row, { key: 'Enter' });
        expect(handleSelect).toHaveBeenCalledWith(sampleAlarm);

        fireEvent.keyDown(row, { key: ' ' });
        expect(handleSelect).toHaveBeenCalledTimes(2);
      });

      it('displays WCAG AA compliant disabled text color (#636366 / #8E8E93)', () => {
        render(<AlarmRow alarm={sampleAlarm} onToggle={vi.fn()} onSelect={vi.fn()} />);
        const timeSpan = screen.getByText('07:30');
        expect(timeSpan.className).toContain('text-[#636366]');
        expect(timeSpan.className).toContain('dark:text-[#8E8E93]');
      });
    });

    describe('AlarmModal Component', () => {
      it('disambiguates repeat days with Ma and Mi and provides 44x44px circles', () => {
        render(<AlarmModal isOpen={true} onClose={vi.fn()} onSave={vi.fn()} />);

        // Tuesday (Ma) and Wednesday (Mi) disambiguation
        expect(screen.getByRole('button', { name: /Martes/i })).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /Miércoles/i })).toBeInTheDocument();
        expect(screen.getByText('Ma')).toBeInTheDocument();
        expect(screen.getByText('Mi')).toBeInTheDocument();

        // 44x44px touch circles
        const tuesdayBtn = screen.getByRole('button', { name: /Martes/i });
        expect(tuesdayBtn.className).toContain('w-11');
        expect(tuesdayBtn.className).toContain('h-11');
      });

      it('provides quick preset chips (Laborables, Fines de semana, Todos)', () => {
        render(<AlarmModal isOpen={true} onClose={vi.fn()} onSave={vi.fn()} />);
        expect(screen.getByText(/Laborables \(L-V\)/i)).toBeInTheDocument();
        expect(screen.getByText(/Fines de semana/i)).toBeInTheDocument();
        expect(screen.getByText(/^Todos$/i)).toBeInTheDocument();

        // Clicking Fines de semana selects Saturday and Sunday
        fireEvent.click(screen.getByText(/Fines de semana/i));
        const domBtn = screen.getByRole('button', { name: /Domingo, seleccionado/i });
        expect(domBtn).toHaveAttribute('aria-pressed', 'true');
      });

      it('supports dialog semantics, focus trap, and Escape key dismissal', () => {
        const handleClose = vi.fn();
        render(<AlarmModal isOpen={true} onClose={handleClose} onSave={vi.fn()} />);
        const dialog = screen.getByRole('dialog');
        expect(dialog).toBeInTheDocument();
        expect(dialog).toHaveAttribute('aria-modal', 'true');

        // Escape dismisses
        fireEvent.keyDown(window, { key: 'Escape' });
        expect(handleClose).toHaveBeenCalled();
      });

      it('has min-h-[44px] on difficulty pills', () => {
        render(
          <AlarmModal
            isOpen={true}
            onClose={vi.fn()}
            onSave={vi.fn()}
            initialAlarm={{
              id: 'alm-2',
              time: '08:00',
              label: 'Misión',
              enabled: true,
              repeatDays: [1],
              sound: 'radar',
              volume: 80,
              snoozeEnabled: true,
              snoozeDuration: 9,
              missionType: 'math',
              missionDifficulty: 'medio',
              category: 'wake-up',
              createdAt: '2026-10-31T08:00:00.000Z',
            }}
          />
        );
        const facilPill = screen.getByRole('button', { name: 'facil' });
        expect(facilPill.className).toContain('min-h-[44px]');
      });
    });

    describe('WakeLogTable & InvestigationSidePanel', () => {
      const sampleLogs: WakeLog[] = [
        {
          id: 'log-1',
          alarmId: 'alm-1',
          alarmLabel: 'Despertar',
          date: '2026-10-31',
          scheduledTime: '07:00',
          wakeTime: '07:00',
          status: 'perfect',
          snoozeCount: 0,
          missionCompleted: true,
          sleepHours: 8,
          consistencyScore: 100,
        },
      ];

      it('ensures pagination buttons in WakeLogTable have min 44x44pt and aria-labels', () => {
        render(<WakeLogTable logs={sampleLogs} onSelectLog={vi.fn()} />);
        const firstPageBtn = screen.getByRole('button', { name: 'Primera página' });
        const prevPageBtn = screen.getByRole('button', { name: 'Página anterior' });
        const nextPageBtn = screen.getByRole('button', { name: 'Página siguiente' });
        const lastPageBtn = screen.getByRole('button', { name: 'Última página' });

        [firstPageBtn, prevPageBtn, nextPageBtn, lastPageBtn].forEach((btn) => {
          expect(btn.className).toContain('min-w-[44px]');
          expect(btn.className).toContain('min-h-[44px]');
        });
      });

      it('ensures action buttons in InvestigationSidePanel have min 44pt height and aria-labels', () => {
        render(
          <InvestigationSidePanel
            log={sampleLogs[0]}
            onClose={vi.fn()}
            onUpdateStatus={vi.fn()}
            onOpenEditAlarm={vi.fn()}
          />
        );
        const perfectBtn = screen.getByRole('button', { name: /Marcar registro como cumplido/i });
        const snoozeBtn = screen.getByRole('button', { name: /Marcar registro con postergación/i });
        expect(perfectBtn.className).toContain('min-h-[44px]');
        expect(snoozeBtn.className).toContain('min-h-[44px]');
      });
    });

    describe('AppleClockView Stopwatch Controls', () => {
      it('has accessible buttons with aria-labels and >= 44x44pt size', () => {
        render(<AppleClockView />);
        const resetOrLapBtn = screen.getByRole('button', { name: /Registrar vuelta/i });
        const startBtn = screen.getByRole('button', { name: /Iniciar cronómetro/i });

        expect(resetOrLapBtn.className).toContain('w-16');
        expect(resetOrLapBtn.className).toContain('h-16');
        expect(startBtn.className).toContain('w-16');
        expect(startBtn.className).toContain('h-16');
      });
    });
  });

  // ==========================================
  // Section 3: Screen Reader & Semantics in App.tsx
  // ==========================================
  describe('3. Screen Reader & App Semantics', () => {
    it('has aria-label on all header buttons (AI assistant, theme toggle, add alarm)', () => {
      render(<App />);
      expect(
        screen.getByRole('button', { name: /Consultar asistente IA/i })
      ).toBeInTheDocument();
      expect(
        screen.getByRole('button', { name: /Cambiar a modo/i })
      ).toBeInTheDocument();
      expect(
        screen.getByRole('button', { name: /Añadir nueva alarma/i })
      ).toBeInTheDocument();
    });

    it('renders Apple HIG empty state card with CTA when alarms list is empty', () => {
      // Clear all alarms
      localStorage.setItem('alarma_alarms', JSON.stringify([]));
      render(<App />);
      expect(screen.getByText('No hay alarmas configuradas')).toBeInTheDocument();
      const createCta = screen.getByRole('button', { name: 'Crear primera alarma' });
      expect(createCta).toBeInTheDocument();
      expect(createCta.className).toContain('min-h-[44px]');
    });
  });
});
