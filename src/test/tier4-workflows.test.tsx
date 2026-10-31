import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { App } from '../App';
import { getStoredAlarms, saveAlarms, saveLogs, getStoredLogs } from '../services/storageService';
import { LockInStateMachine } from './helpers/alarmEngine';
import { Alarm, WakeLog } from '../types/alarm';

describe('Tier 4: Real-World Workflows', () => {
  const initialTestAlarms: Alarm[] = [
    {
      id: 'alm-init-1',
      time: '06:30',
      label: 'Despertar Productivo',
      enabled: true,
      repeatDays: [1, 2, 3, 4, 5],
      sound: 'radar',
      volume: 80,
      snoozeEnabled: true,
      snoozeDuration: 9,
      missionType: 'math',
      missionDifficulty: 'medio',
      category: 'wake-up',
      createdAt: '2026-10-30T00:00:00.000Z',
    },
    {
      id: 'alm-init-2',
      time: '08:00',
      label: 'Gimnasio y Cardio',
      enabled: false,
      repeatDays: [2, 4],
      sound: 'apex',
      volume: 90,
      snoozeEnabled: false,
      snoozeDuration: 5,
      missionType: 'none',
      missionDifficulty: 'facil',
      category: 'exercise',
      createdAt: '2026-10-30T00:00:00.000Z',
    },
  ];

  beforeEach(() => {
    localStorage.clear();
    saveAlarms(initialTestAlarms);
  });

  // ==========================================
  // Workflow 1: Complete Alarm Creation & Persistence Flow
  // ==========================================
  describe('W1: Complete Alarm Creation & Persistence Flow', () => {
    it('creates a new math-gated alarm through UI modal and persists it', () => {
      const { container } = render(<App />);

      expect(screen.getByText('Tus Alarmas (2)')).toBeInTheDocument();

      // Step 1: Open creation modal via header button
      const addBtn = screen.getByRole('button', { name: /Añadir/i });
      fireEvent.click(addBtn);

      expect(screen.getByText('Nueva Alarma')).toBeInTheDocument();

      // Step 2: Fill alarm time and label
      const timeInput = screen.getByLabelText(/Hora de Activación/i);
      fireEvent.change(timeInput, { target: { value: '05:45' } });

      const labelInput = screen.getByPlaceholderText(/Ej. Despertar Productivo/i);
      fireEvent.change(labelInput, { target: { value: 'Vuelo Temprano' } });

      // Step 3: Select "Laborables (L-V)" preset
      const presetBtn = screen.getByText('Laborables (L-V)');
      fireEvent.click(presetBtn);

      // Step 4: Select sound
      const soundSelect = container.querySelector('#alarm-sound-select') as HTMLSelectElement;
      expect(soundSelect).not.toBeNull();
      fireEvent.change(soundSelect, { target: { value: 'cosmic' } });

      // Step 5: Select math challenge
      const mathMissionBtn = screen.getByText(/🧮 Cálculo/i);
      fireEvent.click(mathMissionBtn);

      // Step 6: Submit form via Guardar
      const saveBtn = screen.getByText('Guardar');
      fireEvent.click(saveBtn);

      // Verify modal is closed
      expect(screen.queryByText('Nueva Alarma')).not.toBeInTheDocument();

      // Verify new alarm appears in alarms list
      expect(screen.getByText('Tus Alarmas (3)')).toBeInTheDocument();
      expect(screen.getAllByText('05:45').length).toBeGreaterThanOrEqual(1);
      expect(screen.getAllByText('Vuelo Temprano').length).toBeGreaterThanOrEqual(1);

      // Verify persisted in localStorage
      const stored = getStoredAlarms();
      expect(stored).toHaveLength(3);
      const created = stored.find((a) => a.label === 'Vuelo Temprano');
      expect(created).toBeDefined();
      expect(created?.time).toBe('05:45');
      expect(created?.sound).toBe('cosmic');
      expect(created?.missionType).toBe('math');
    });
  });

  // ==========================================
  // Workflow 2: Alarm Inspection & Editing Flow
  // ==========================================
  describe('W2: Alarm Inspection & Editing Flow', () => {
    it('inspects alarm details and updates time/label through edit modal', () => {
      render(<App />);

      // Select first alarm from list
      const alarmRow = screen.getByText('Despertar Productivo');
      fireEvent.click(alarmRow);

      // Detail card should display active alarm info
      expect(screen.getByText('Detalle de Alarma')).toBeInTheDocument();
      expect(screen.getByText('Seleccionada')).toBeInTheDocument();

      // Open Edit Modal from detail card
      const editBtn = screen.getByRole('button', { name: /Editar Alarma/i });
      fireEvent.click(editBtn);

      expect(screen.getByText('Editar Alarma')).toBeInTheDocument();

      // Modify time and label
      const timeInput = screen.getByLabelText(/Hora de Activación/i);
      fireEvent.change(timeInput, { target: { value: '07:15' } });

      const labelInput = screen.getByLabelText(/Etiqueta de la alarma/i);
      fireEvent.change(labelInput, { target: { value: 'Despertar Relajado' } });

      // Save changes
      const saveBtn = screen.getByText('Guardar');
      fireEvent.click(saveBtn);

      // Modal closed and UI updated
      expect(screen.queryByText('Editar Alarma')).not.toBeInTheDocument();
      expect(screen.getAllByText('07:15').length).toBeGreaterThanOrEqual(1);
      expect(screen.getAllByText('Despertar Relajado').length).toBeGreaterThanOrEqual(1);

      // Verify persistence
      const stored = getStoredAlarms();
      const updated = stored.find((a) => a.id === 'alm-init-1');
      expect(updated?.time).toBe('07:15');
      expect(updated?.label).toBe('Despertar Relajado');
    });
  });

  // ==========================================
  // Workflow 3: Alarm Deletion & Empty State Recovery Flow
  // ==========================================
  describe('W3: Alarm Deletion & Empty State Recovery Flow', () => {
    it('deletes alarms until empty state and recovers by creating a new alarm', () => {
      render(<App />);

      expect(screen.getByText('Tus Alarmas (2)')).toBeInTheDocument();

      // Step 1: Select first alarm and delete
      fireEvent.click(screen.getByText('Despertar Productivo'));
      const deleteBtn1 = screen.getByRole('button', { name: /Eliminar/i });
      fireEvent.click(deleteBtn1);

      expect(screen.getByText('Tus Alarmas (1)')).toBeInTheDocument();
      expect(screen.queryByText('Despertar Productivo')).not.toBeInTheDocument();

      // Step 2: Select remaining alarm and delete
      fireEvent.click(screen.getByText('Gimnasio y Cardio'));
      const deleteBtn2 = screen.getByRole('button', { name: /Eliminar/i });
      fireEvent.click(deleteBtn2);

      // Empty state reached
      expect(screen.getByText('Tus Alarmas (0)')).toBeInTheDocument();
      expect(
        screen.getByText(/Selecciona cualquier alarma de la lista para ver su configuración completa y editarla/i)
      ).toBeInTheDocument();

      // Step 3: Recover from empty state by adding a new alarm
      const addBtn = screen.getByRole('button', { name: /Añadir/i });
      fireEvent.click(addBtn);

      const timeInput = screen.getByLabelText(/Hora de Activación/i);
      fireEvent.change(timeInput, { target: { value: '09:00' } });

      const labelInput = screen.getByPlaceholderText(/Ej. Despertar Productivo/i);
      fireEvent.change(labelInput, { target: { value: 'Nuevo Inicio' } });

      const saveBtn = screen.getByText('Guardar');
      fireEvent.click(saveBtn);

      // Successfully recovered
      expect(screen.getByText('Tus Alarmas (1)')).toBeInTheDocument();
      expect(screen.getAllByText('09:00').length).toBeGreaterThanOrEqual(1);
      expect(screen.getAllByText('Nuevo Inicio').length).toBeGreaterThanOrEqual(1);
    });
  });

  // ==========================================
  // Workflow 4: Wake Mission Execution & Analytics Sidepanel Flow
  // ==========================================
  describe('W4: Wake Mission Execution & Analytics Sidepanel Flow', () => {
    it('executes wake mission lifecycle and inspects wake log in metrics sidepanel', () => {
      // Setup LockIn state machine simulating waking up with math challenge
      const fsm = new LockInStateMachine();
      const alarm = initialTestAlarms[0]; // math alarm 06:30
      fsm.trigger(alarm, new Date('2026-10-31T06:30:00'));

      // Request dismiss -> triggers math challenge
      expect(fsm.requestDismiss()).toBe('challenge_required');
      const problem = fsm.getCurrentProblem()!;
      expect(problem).toBeDefined();

      // Solve problem correctly
      expect(fsm.submitAnswer(problem.answer)).toBe(true);

      // Generate wake log
      const wakeLog = fsm.createWakeLog('06:30', '2026-10-31');
      expect(wakeLog.consistencyScore).toBe(100);
      expect(wakeLog.status).toBe('perfect');

      // Save log to storage
      saveLogs([wakeLog]);

      // Render App and navigate to Metrics tab
      render(<App />);
      const metricsTab = screen.getAllByRole('tab', { name: /Métricas & Logs/i })[0];
      fireEvent.click(metricsTab);

      // Check log appears in table
      expect(screen.getByText('Despertar Productivo')).toBeInTheDocument();
      expect(screen.getByText('100%')).toBeInTheDocument();

      // Click row to open InvestigationSidePanel
      const row = screen.getByText('Despertar Productivo');
      fireEvent.click(row);

      // Sidepanel is open with details
      expect(screen.getByText('Inspección de Registro')).toBeInTheDocument();
      expect(screen.getByLabelText(/Cerrar panel de inspección/i)).toBeInTheDocument();

      // Close sidepanel
      const closePanelBtn = screen.getByLabelText(/Cerrar panel de inspección/i);
      fireEvent.click(closePanelBtn);

      expect(screen.queryByText('Inspección de Registro')).not.toBeInTheDocument();
    });
  });

  // ==========================================
  // Workflow 5: Tab Navigation & Theme Switching Flow
  // ==========================================
  describe('W5: Tab Navigation & Theme Switching Flow', () => {
    it('switches between all 3 Cupertino tabs and toggles Dark/Light mode', () => {
      render(<App />);

      // Initially on Alarms tab
      expect(screen.getByText(/Tus Alarmas/i)).toBeInTheDocument();

      // Switch to Reloj & Timer tab (first occurrence of tab)
      const clockTab = screen.getAllByRole('tab', { name: /Reloj & Timer/i })[0];
      fireEvent.click(clockTab);
      expect(screen.getByText('Hora Actual')).toBeInTheDocument();
      expect(screen.getByText('Cronómetro')).toBeInTheDocument();

      // Switch to Métricas & Logs tab
      const metricsTab = screen.getAllByRole('tab', { name: /Métricas & Logs/i })[0];
      fireEvent.click(metricsTab);
      expect(screen.getByText('Evolución de Consistencia y Snooze')).toBeInTheDocument();
      expect(screen.getByText('Bitácora & Registros de Despertar')).toBeInTheDocument();

      // Toggle Dark/Light mode in header
      const themeBtn = screen.getByTitle(/Modo Claro|Modo Oscuro/i);
      const hadDarkBefore = document.documentElement.classList.contains('dark');

      fireEvent.click(themeBtn);
      const hasDarkAfter = document.documentElement.classList.contains('dark');
      expect(hasDarkAfter).toBe(!hadDarkBefore);

      // Toggle back
      fireEvent.click(themeBtn);
      expect(document.documentElement.classList.contains('dark')).toBe(hadDarkBefore);
    });
  });
});
