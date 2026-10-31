import React, { useState, useEffect, useMemo } from 'react';
import {
  Alarm,
  WakeLog,
  AlarmMetrics,
} from './types/alarm';
import {
  getStoredAlarms,
  saveAlarms,
  getStoredLogs,
  saveLogs,
  calculateMetrics,
} from './services/storageService';
import { KpiCard } from './components/common/KpiCard';
import { CupertinoSegmentedControl, SegmentOption } from './components/common/CupertinoSegmentedControl';
import { AlarmRow } from './components/alarms/AlarmRow';
import { AlarmModal } from './components/alarms/AlarmModal';
import { WakeConsistencyChart } from './components/analytics/WakeConsistencyChart';
import { SleepPhaseWeeklyChart } from './components/analytics/SleepPhaseWeeklyChart';
import { WakeLogTable } from './components/table/WakeLogTable';
import { InvestigationSidePanel } from './components/sidepanel/InvestigationSidePanel';
import { AppleClockView } from './components/clock/AppleClockView';
import { DataChatDrawer } from './components/chat/DataChatDrawer';
import {
  Bell,
  BellOff,
  BarChart3,
  Timer,
  Plus,
  Sun,
  Moon,
  Sparkles,
  Clock,
  Activity,
  CheckCircle,
} from 'lucide-react';

type TabType = 'alarms' | 'metrics' | 'clock';

export const App: React.FC = () => {
  const [alarms, setAlarms] = useState<Alarm[]>(getStoredAlarms);
  const [logs, setLogs] = useState<WakeLog[]>(getStoredLogs);
  const [selectedTab, setSelectedTab] = useState<TabType>('alarms');
  const [isDarkMode, setIsDarkMode] = useState<boolean>(() => {
    return document.documentElement.classList.contains('dark') || true;
  });

  // Modal and drawer states
  const [isAlarmModalOpen, setIsAlarmModalOpen] = useState(false);
  const [editingAlarm, setEditingAlarm] = useState<Alarm | null>(null);
  const [isChatOpen, setIsChatOpen] = useState(false);

  // Selection states
  const [selectedAlarmId, setSelectedAlarmId] = useState<string | null>(null);
  const [selectedLog, setSelectedLog] = useState<WakeLog | null>(null);

  // Sync dark mode class on document
  useEffect(() => {
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [isDarkMode]);

  // Save changes
  useEffect(() => {
    saveAlarms(alarms);
  }, [alarms]);

  useEffect(() => {
    saveLogs(logs);
  }, [logs]);

  // Derived metrics
  const metrics: AlarmMetrics = useMemo(() => {
    return calculateMetrics(alarms, logs);
  }, [alarms, logs]);

  // Toggle alarm enable/disable
  const handleToggleAlarm = (id: string, enabled: boolean) => {
    setAlarms((prev) =>
      prev.map((a) => (a.id === id ? { ...a, enabled } : a))
    );
  };

  // Save new or edited alarm
  const handleSaveAlarm = (alarmData: Partial<Alarm>) => {
    if (editingAlarm) {
      setAlarms((prev) =>
        prev.map((a) => (a.id === editingAlarm.id ? ({ ...a, ...alarmData } as Alarm) : a))
      );
    } else {
      setAlarms((prev) => [alarmData as Alarm, ...prev]);
    }
    setEditingAlarm(null);
  };

  // Update wake log status from investigation panel
  const handleUpdateLogStatus = (logId: string, newStatus: WakeLog['status']) => {
    setLogs((prev) =>
      prev.map((l) => (l.id === logId ? { ...l, status: newStatus } : l))
    );
    if (selectedLog && selectedLog.id === logId) {
      setSelectedLog({ ...selectedLog, status: newStatus });
    }
  };

  // Tab options for Cupertino segmented control
  const tabOptions: SegmentOption<TabType>[] = [
    { value: 'alarms', label: 'Alarmas', icon: <Bell className="w-3.5 h-3.5" /> },
    { value: 'metrics', label: 'Métricas & Logs', icon: <BarChart3 className="w-3.5 h-3.5" /> },
    { value: 'clock', label: 'Reloj & Timer', icon: <Timer className="w-3.5 h-3.5" /> },
  ];

  // Selected alarm object for details panel
  const activeSelectedAlarm = useMemo(() => {
    return alarms.find((a) => a.id === selectedAlarmId) || null;
  }, [alarms, selectedAlarmId]);

  // Find next alarm for hero countdown badge
  const nextAlarm = useMemo(() => {
    const active = alarms.filter((a) => a.enabled);
    if (active.length === 0) return null;
    return active.sort((a, b) => a.time.localeCompare(b.time))[0];
  }, [alarms]);

  return (
    <div className="min-h-screen bg-[#F2F2F7] dark:bg-[#000000] text-zinc-900 dark:text-zinc-100 flex flex-col transition-colors duration-200">
      {/* Apple HIG Translucent Navigation Bar with Safe Area Top */}
      <header className="sticky top-0 z-40 apple-glass border-b border-black/5 dark:border-white/10 transition-colors pt-[env(safe-area-inset-top)]">
        <div className="max-w-[1500px] mx-auto px-4 sm:px-6 h-16 flex items-center justify-between gap-4">
          {/* Brand */}
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-2xl bg-gradient-to-br from-[#FF9500] to-[#FF5E3A] flex items-center justify-center text-white shadow-sm">
              <Clock className="w-5 h-5 stroke-[2.5]" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-semibold text-lg tracking-tight text-zinc-950 dark:text-white">
                  Alarma
                </span>
                <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-md bg-[#FF9500]/15 text-[#B25000] dark:text-[#FF9F0A] uppercase tracking-wider">
                  Apple HIG
                </span>
              </div>
              <p className="text-[11px] text-[#636366] dark:text-[#8E8E93] hidden sm:block">
                Gestión Inteligente & Dashboard de Descanso
              </p>
            </div>
          </div>

          {/* Cupertino Segmented Tabs */}
          <div className="hidden md:block">
            <CupertinoSegmentedControl
              options={tabOptions}
              value={selectedTab}
              onChange={setSelectedTab}
            />
          </div>

          {/* Right Actions */}
          <div className="flex items-center gap-2 sm:gap-3">
            {/* AI Data Chat Assistant button */}
            <button
              type="button"
              onClick={() => setIsChatOpen(true)}
              aria-label="Consultar asistente IA de análisis de sueño"
              className="inline-flex items-center justify-center gap-1.5 min-h-[44px] min-w-[44px] px-3.5 py-2 text-xs font-medium rounded-xl bg-purple-500/10 text-purple-600 dark:text-purple-400 hover:bg-purple-500/20 border border-purple-500/20 transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-purple-500"
            >
              <Sparkles className="w-4 h-4" />
              <span className="hidden sm:inline">Consultar IA</span>
            </button>

            {/* Dark / Light Toggle */}
            <button
              type="button"
              onClick={() => setIsDarkMode(!isDarkMode)}
              title={isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'}
              aria-label={isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'}
              className="min-h-[44px] min-w-[44px] flex items-center justify-center rounded-xl text-[#636366] dark:text-[#8E8E93] hover:bg-black/5 dark:hover:bg-white/10 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
            >
              {isDarkMode ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4" />}
            </button>

            {/* Add Alarm Primary Apple Button */}
            <button
              type="button"
              onClick={() => {
                setEditingAlarm(null);
                setIsAlarmModalOpen(true);
              }}
              aria-label="Añadir nueva alarma"
              className="inline-flex items-center justify-center gap-1.5 min-h-[44px] px-4 py-2 text-xs sm:text-sm font-semibold rounded-xl bg-[#007AFF] hover:bg-[#0066d6] text-white transition-all shadow-sm active:scale-95 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
            >
              <Plus className="w-4 h-4" />
              <span>Añadir</span>
            </button>
          </div>
        </div>

        {/* Mobile Tab Bar */}
        <div className="md:hidden px-4 pb-2.5 flex justify-center">
          <CupertinoSegmentedControl
            options={tabOptions}
            value={selectedTab}
            onChange={setSelectedTab}
            className="w-full justify-between"
          />
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 max-w-[1500px] w-full mx-auto p-4 sm:p-6 lg:p-8 space-y-6">
        {/* Next Alarm Banner */}
        {nextAlarm && (
          <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-[#FF9500]/10 via-[#FF9500]/5 to-transparent border border-[#FF9500]/20 p-4 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="p-2.5 rounded-xl bg-[#FF9500] text-white">
                <Bell className="w-5 h-5" />
              </div>
              <div>
                <p className="text-xs font-semibold text-[#B25000] dark:text-[#FF9F0A] uppercase tracking-wider">
                  Próxima Alarma
                </p>
                <div className="flex items-baseline gap-2">
                  <span className="text-2xl font-mono font-bold text-zinc-950 dark:text-white">
                    {nextAlarm.time}
                  </span>
                  <span className="text-xs text-zinc-500 dark:text-zinc-400">
                    "{nextAlarm.label}"
                  </span>
                </div>
              </div>
            </div>
            <span className="hidden sm:inline-flex items-center gap-1 text-xs font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/40 px-2.5 py-1 rounded-full">
              <CheckCircle className="w-3.5 h-3.5" />
              Programada
            </span>
          </div>
        )}

        {/* KPI Cards Row (Strictly per building-data-apps) */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <KpiCard
            title="Alarmas Activas"
            value={`${metrics.activeAlarms} / ${metrics.totalAlarms}`}
            subtitle={`${alarms.filter((a) => a.missionType !== 'none').length} con misiones de despertar`}
            icon={<Bell className="w-5 h-5" />}
            trend={{
              value: '+1 hoy',
              isPositive: true,
            }}
            accentColor="orange"
          />
          <KpiCard
            title="Hora Promedio Despertar"
            value={metrics.averageWakeTime}
            subtitle="Basado en los últimos 10 registros"
            icon={<Clock className="w-5 h-5" />}
            trend={{
              value: '-12 min',
              isPositive: true,
            }}
            accentColor="blue"
          />
          <KpiCard
            title="Tasa de Snooze"
            value={`${metrics.snoozeRate}%`}
            subtitle="Objetivo sugerido: < 10%"
            icon={<Activity className="w-5 h-5" />}
            trend={{
              value: '-4.2%',
              isPositive: true,
            }}
            accentColor="green"
          />
          <KpiCard
            title="Score de Consistencia"
            value={`${metrics.consistencyScore}/100`}
            subtitle="Nivel Óptimo de regularidad"
            icon={<Sparkles className="w-5 h-5" />}
            trend={{
              value: `+${metrics.weeklyTrend}%`,
              isPositive: true,
            }}
            accentColor="purple"
          />
        </div>

        {/* View Switcher based on Selected Tab */}
        {selectedTab === 'alarms' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Alarms List */}
            <div className="lg:col-span-2 space-y-4">
              <div className="flex items-center justify-between px-1">
                <h2 className="text-base font-semibold text-zinc-900 dark:text-white">
                  Tus Alarmas ({alarms.length})
                </h2>
                <span className="text-xs text-zinc-500">
                  Toca una alarma para ver o modificar detalles
                </span>
              </div>

              <div className="space-y-3">
                {alarms.length === 0 ? (
                  <div className="rounded-3xl border border-dashed border-zinc-300 dark:border-zinc-700 bg-white/50 dark:bg-[#1C1C1E]/50 p-8 text-center space-y-4">
                    <div className="w-16 h-16 mx-auto rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center text-[#636366] dark:text-[#8E8E93]">
                      <BellOff className="w-8 h-8" />
                    </div>
                    <div className="space-y-1">
                      <h3 className="text-base font-semibold text-zinc-950 dark:text-white">
                        No hay alarmas configuradas
                      </h3>
                      <p className="text-xs text-[#636366] dark:text-[#8E8E93] max-w-sm mx-auto">
                        Crea tu primera alarma matutina o programa un recordatorio con retos interactivos de despertar.
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={() => {
                        setEditingAlarm(null);
                        setIsAlarmModalOpen(true);
                      }}
                      aria-label="Crear primera alarma"
                      className="inline-flex items-center gap-2 px-4 py-2.5 min-h-[44px] rounded-xl bg-[#007AFF] hover:bg-[#0066d6] text-white text-xs font-semibold shadow-sm transition-all active:scale-95 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
                    >
                      <Plus className="w-4 h-4" />
                      <span>Crear Primera Alarma</span>
                    </button>
                  </div>
                ) : (
                  alarms.map((alarm) => (
                    <AlarmRow
                      key={alarm.id}
                      alarm={alarm}
                      isSelected={selectedAlarmId === alarm.id}
                      onToggle={handleToggleAlarm}
                      onSelect={(a) => {
                        if (selectedAlarmId === a.id) {
                          setSelectedAlarmId(null);
                        } else {
                          setSelectedAlarmId(a.id);
                        }
                      }}
                    />
                  ))
                )}
              </div>
            </div>

            {/* Quick Inspection Card for selected Alarm */}
            <div className="lg:col-span-1">
              <div className="rounded-3xl bg-white/80 dark:bg-[#1C1C1E]/80 backdrop-blur-xl border border-zinc-200/80 dark:border-zinc-800/80 p-6 shadow-apple-subtle space-y-4">
                <h3 className="text-sm font-semibold text-zinc-900 dark:text-white">
                  {activeSelectedAlarm ? 'Detalle de Alarma' : 'Información Rápida'}
                </h3>

                {activeSelectedAlarm ? (
                  <div className="space-y-4 text-xs">
                    <div className="p-4 rounded-2xl bg-zinc-100/70 dark:bg-zinc-800/60 space-y-1">
                      <span className="text-[10px] uppercase font-bold text-[#007AFF]">
                        Seleccionada
                      </span>
                      <div className="text-2xl font-mono font-bold text-zinc-900 dark:text-white">
                        {activeSelectedAlarm.time}
                      </div>
                      <p className="text-zinc-600 dark:text-zinc-300 font-medium">
                        {activeSelectedAlarm.label}
                      </p>
                    </div>

                    <div className="space-y-2">
                      <div className="flex justify-between py-1 border-b border-zinc-100 dark:border-zinc-800">
                        <span className="text-[#636366] dark:text-[#8E8E93]">Sonido:</span>
                        <span className="font-semibold capitalize text-zinc-800 dark:text-zinc-200">
                          {activeSelectedAlarm.sound}
                        </span>
                      </div>
                      <div className="flex justify-between py-1 border-b border-zinc-100 dark:border-zinc-800">
                        <span className="text-[#636366] dark:text-[#8E8E93]">Volumen:</span>
                        <span className="font-mono text-zinc-800 dark:text-zinc-200">
                          {activeSelectedAlarm.volume}%
                        </span>
                      </div>
                      <div className="flex justify-between py-1 border-b border-zinc-100 dark:border-zinc-800">
                        <span className="text-[#636366] dark:text-[#8E8E93]">Misión:</span>
                        <span className="font-semibold text-[#AF52DE] capitalize">
                          {activeSelectedAlarm.missionType}
                        </span>
                      </div>
                      <div className="flex justify-between py-1 border-b border-zinc-100 dark:border-zinc-800">
                        <span className="text-[#636366] dark:text-[#8E8E93]">Snooze (Apple HIG):</span>
                        <span className="text-zinc-800 dark:text-zinc-200">
                          {activeSelectedAlarm.snoozeEnabled
                            ? `${activeSelectedAlarm.snoozeDuration} min`
                            : 'Desactivado'}
                        </span>
                      </div>
                    </div>

                    <div className="pt-2 flex gap-2">
                      <button
                        type="button"
                        onClick={() => {
                          setEditingAlarm(activeSelectedAlarm);
                          setIsAlarmModalOpen(true);
                        }}
                        aria-label="Editar configuración de alarma seleccionada"
                        className="flex-1 min-h-[44px] py-2 px-3 rounded-xl bg-[#007AFF] text-white text-xs font-semibold hover:bg-blue-600 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF] flex items-center justify-center"
                      >
                        Editar Alarma
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setAlarms(alarms.filter((a) => a.id !== activeSelectedAlarm.id));
                          setSelectedAlarmId(null);
                        }}
                        aria-label="Eliminar alarma seleccionada"
                        className="min-h-[44px] px-4 py-2 rounded-xl bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 text-xs font-semibold hover:bg-rose-100 dark:hover:bg-rose-900/40 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-rose-500 flex items-center justify-center"
                      >
                        Eliminar
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="text-center py-10 text-[#636366] dark:text-[#8E8E93] space-y-2">
                    <Clock className="w-8 h-8 mx-auto stroke-1 opacity-50" />
                    <p className="text-xs">
                      Selecciona cualquier alarma de la lista para ver su configuración completa y editarla.
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {selectedTab === 'metrics' && (
          <div className="space-y-6">
            {/* Charts Section: Strict 1 or 2 per row constraint per building-data-apps */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Chart 1 */}
              <div className="p-5 rounded-2xl bg-white/80 dark:bg-[#1C1C1E]/80 backdrop-blur-xl border border-zinc-200/80 dark:border-zinc-800/80 shadow-apple-subtle">
                <div className="mb-2">
                  <h3 className="text-sm font-semibold text-zinc-900 dark:text-white">
                    Evolución de Consistencia y Snooze
                  </h3>
                  <p className="text-xs text-zinc-500">
                    Puntuación diaria de regularidad y conteo de postergaciones
                  </p>
                </div>
                <WakeConsistencyChart logs={logs} isDarkMode={isDarkMode} />
              </div>

              {/* Chart 2 */}
              <div className="p-5 rounded-2xl bg-white/80 dark:bg-[#1C1C1E]/80 backdrop-blur-xl border border-zinc-200/80 dark:border-zinc-800/80 shadow-apple-subtle">
                <div className="mb-2">
                  <h3 className="text-sm font-semibold text-zinc-900 dark:text-white">
                    Horas de Sueño Semanales vs Meta
                  </h3>
                  <p className="text-xs text-zinc-500">
                    Comparación con el estándar óptimo de 8.0 horas
                  </p>
                </div>
                <SleepPhaseWeeklyChart logs={logs} isDarkMode={isDarkMode} />
              </div>
            </div>

            {/* Split Data Table and Investigation Panel per building-data-apps */}
            <div className="space-y-2">
              <div className="flex items-center justify-between px-1">
                <h3 className="text-base font-semibold text-zinc-900 dark:text-white">
                  Bitácora & Registros de Despertar
                </h3>
                <span className="text-xs text-zinc-500">
                  Haz clic en cualquier fila para inspeccionar y realizar acciones
                </span>
              </div>

              {/* Split container: Normal w-full, Selected w-2/3 & w-1/3 */}
              <div className="flex flex-col lg:flex-row gap-6 transition-all duration-300">
                <div
                  className={`transition-all duration-300 ${
                    selectedLog ? 'lg:w-2/3' : 'w-full'
                  }`}
                >
                  <WakeLogTable
                    logs={logs}
                    selectedLogId={selectedLog ? selectedLog.id : null}
                    onSelectLog={(log) => setSelectedLog(log)}
                  />
                </div>

                {selectedLog && (
                  <div className="lg:w-1/3 animate-in fade-in slide-in-from-right duration-250">
                    <InvestigationSidePanel
                      log={selectedLog}
                      associatedAlarm={alarms.find((a) => a.id === selectedLog.alarmId)}
                      onClose={() => setSelectedLog(null)}
                      onUpdateStatus={handleUpdateLogStatus}
                      onOpenEditAlarm={(alarm) => {
                        setEditingAlarm(alarm);
                        setIsAlarmModalOpen(true);
                      }}
                    />
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {selectedTab === 'clock' && (
          <div className="space-y-6">
            <AppleClockView />
          </div>
        )}
      </main>

      {/* Footer with Safe Area Bottom */}
      <footer className="border-t border-zinc-200/60 dark:border-zinc-800/60 py-6 px-4 text-center text-xs text-[#636366] dark:text-[#8E8E93] pb-[max(24px,env(safe-area-inset-bottom))]">
        <p>Alarma • Diseñado según las pautas de Apple Human Interface Guidelines (HIG)</p>
        <p className="text-[11px] text-[#636366] dark:text-[#8E8E93] mt-1">
          Integrado con arquitectura de datos modular para análisis con ECharts y Graphify
        </p>
      </footer>

      {/* Alarm Modal (Create / Edit) */}
      <AlarmModal
        isOpen={isAlarmModalOpen}
        onClose={() => {
          setIsAlarmModalOpen(false);
          setEditingAlarm(null);
        }}
        onSave={handleSaveAlarm}
        initialAlarm={editingAlarm}
      />

      {/* Natural Language AI Data Chat Drawer */}
      <DataChatDrawer
        isOpen={isChatOpen}
        onClose={() => setIsChatOpen(false)}
        alarms={alarms}
        logs={logs}
        metrics={metrics}
      />
    </div>
  );
};

export default App;
