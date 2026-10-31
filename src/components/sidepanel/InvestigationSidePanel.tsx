import React from 'react';
import { WakeLog, Alarm } from '../../types/alarm';
import {
  X,
  Clock,
  Sparkles,
  Bed,
  CheckCircle,
  AlertTriangle,
  RotateCcw,
  Sliders,
} from 'lucide-react';

interface InvestigationSidePanelProps {
  log: WakeLog;
  associatedAlarm?: Alarm;
  onClose: () => void;
  onUpdateStatus: (logId: string, newStatus: WakeLog['status']) => void;
  onOpenEditAlarm: (alarm: Alarm) => void;
}

export const InvestigationSidePanel: React.FC<InvestigationSidePanelProps> = ({
  log,
  associatedAlarm,
  onClose,
  onUpdateStatus,
  onOpenEditAlarm,
}) => {
  return (
    <div className="w-full flex flex-col h-full bg-white dark:bg-[#1C1C1E] border border-zinc-200 dark:border-zinc-800 rounded-2xl p-5 shadow-apple-card transition-all duration-300">
      {/* Header */}
      <div className="flex items-center justify-between pb-4 border-b border-zinc-200 dark:border-zinc-800">
        <div className="flex items-center gap-2">
          <span className="p-1.5 rounded-lg bg-[#007AFF]/10 text-[#007AFF]">
            <Clock className="w-4 h-4" />
          </span>
          <h3 className="text-sm font-semibold text-zinc-950 dark:text-white">
            Inspección de Registro
          </h3>
        </div>
        <button
          type="button"
          onClick={onClose}
          aria-label="Cerrar panel de inspección"
          className="min-w-[44px] min-h-[44px] flex items-center justify-center rounded-xl text-[#636366] dark:text-[#8E8E93] hover:text-zinc-900 dark:hover:text-zinc-100 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      {/* Content Details */}
      <div className="py-4 space-y-3.5 flex-1 overflow-y-auto text-xs">
        {/* Block 1: Event & Alarm info */}
        <div className="bg-zinc-50 dark:bg-zinc-900/80 border border-zinc-200/80 dark:border-zinc-800 rounded-xl p-3.5 space-y-2">
          <div className="text-xs font-semibold uppercase tracking-wider text-[#636366] dark:text-[#8E8E93]">
            Alarma Asociada
          </div>
          <div className="text-sm font-bold text-zinc-900 dark:text-zinc-100">
            {log.alarmLabel}
          </div>
          <div className="grid grid-cols-2 gap-2 text-zinc-700 dark:text-zinc-300 pt-1">
            <div>
              <span className="block text-xs font-medium text-[#636366] dark:text-[#8E8E93]">Objetivo</span>
              <span className="font-mono font-medium text-zinc-900 dark:text-zinc-100">
                {log.scheduledTime}
              </span>
            </div>
            <div>
              <span className="block text-xs font-medium text-[#636366] dark:text-[#8E8E93]">Hora Real</span>
              <span className="font-mono font-medium text-zinc-900 dark:text-zinc-100">
                {log.wakeTime}
              </span>
            </div>
          </div>
        </div>

        {/* Block 2: Sleep & Health metrics */}
        <div className="bg-zinc-50 dark:bg-zinc-900/80 border border-zinc-200/80 dark:border-zinc-800 rounded-xl p-3.5 space-y-2">
          <div className="text-xs font-semibold uppercase tracking-wider text-[#636366] dark:text-[#8E8E93]">
            Diagnóstico de Despertar
          </div>
          <div className="grid grid-cols-2 gap-2.5">
            <div className="flex items-center gap-2">
              <Bed className="w-4 h-4 text-[#30B0C7]" />
              <div>
                <span className="block text-xs font-medium text-[#636366] dark:text-[#8E8E93]">Horas Sueño</span>
                <span className="font-mono font-semibold text-zinc-900 dark:text-zinc-100">
                  {log.sleepHours} hrs
                </span>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-[#AF52DE]" />
              <div>
                <span className="block text-xs font-medium text-[#636366] dark:text-[#8E8E93]">Consistencia</span>
                <span className="font-mono font-semibold text-zinc-900 dark:text-zinc-100">
                  {log.consistencyScore}%
                </span>
              </div>
            </div>
          </div>

          <div className="pt-2 border-t border-zinc-200/60 dark:border-zinc-800 flex justify-between items-center">
            <span className="text-[#636366] dark:text-[#8E8E93] font-medium">Misión Completada</span>
            <span
              className={`font-semibold ${
                log.missionCompleted ? 'text-emerald-600 dark:text-emerald-400' : 'text-[#636366] dark:text-[#8E8E93]'
              }`}
            >
              {log.missionCompleted ? 'Sí (Superada)' : 'Sin misión'}
            </span>
          </div>

          <div className="flex justify-between items-center">
            <span className="text-[#636366] dark:text-[#8E8E93] font-medium">Snoozes</span>
            <span className="font-mono font-semibold text-[#B25000] dark:text-[#FF9F0A]">
              {log.snoozeCount} veces ({log.snoozeCount * 9}m)
            </span>
          </div>
        </div>

        {/* Block 3: User Notes */}
        {log.notes && (
          <div className="bg-zinc-50 dark:bg-zinc-900/80 border border-zinc-200/80 dark:border-zinc-800 rounded-xl p-3.5 space-y-1">
            <div className="text-xs font-semibold uppercase tracking-wider text-[#636366] dark:text-[#8E8E93]">
              Bitácora
            </div>
            <p className="text-xs text-zinc-700 dark:text-zinc-300 italic">
              "{log.notes}"
            </p>
          </div>
        )}
      </div>

      {/* Action Buttons with 44pt touch targets and descriptive aria-labels */}
      <div className="pt-4 border-t border-zinc-200 dark:border-zinc-800 space-y-2">
        <button
          type="button"
          onClick={() => onUpdateStatus(log.id, 'perfect')}
          aria-label="Marcar registro como cumplido a tiempo"
          className="w-full min-h-[44px] py-2.5 px-3 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-medium flex items-center justify-center gap-1.5 transition-colors shadow-sm focus:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500"
        >
          <CheckCircle className="w-4 h-4" />
          Marcar como Cumplida
        </button>

        <div className="grid grid-cols-2 gap-2">
          <button
            type="button"
            onClick={() => onUpdateStatus(log.id, 'snoozed')}
            aria-label="Marcar registro con postergación snooze"
            className="min-h-[44px] py-2.5 px-3 rounded-xl bg-zinc-100 dark:bg-zinc-800 hover:bg-zinc-200 dark:hover:bg-zinc-700 text-zinc-800 dark:text-zinc-200 font-medium flex items-center justify-center gap-1.5 transition-colors text-xs focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            Marcar Snooze
          </button>

          {associatedAlarm ? (
            <button
              type="button"
              onClick={() => onOpenEditAlarm(associatedAlarm)}
              aria-label={`Editar alarma asociada ${associatedAlarm.label}`}
              className="min-h-[44px] py-2.5 px-3 rounded-xl bg-[#007AFF]/10 hover:bg-[#007AFF]/20 text-[#007AFF] font-medium flex items-center justify-center gap-1.5 transition-colors text-xs focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
            >
              <Sliders className="w-3.5 h-3.5" />
              Editar Alarma
            </button>
          ) : (
            <button
              type="button"
              onClick={() => onUpdateStatus(log.id, 'delayed')}
              aria-label="Marcar registro con retraso"
              className="min-h-[44px] py-2.5 px-3 rounded-xl bg-rose-50 dark:bg-rose-950/30 text-rose-600 dark:text-rose-400 font-medium flex items-center justify-center gap-1.5 transition-colors text-xs focus:outline-none focus-visible:ring-2 focus-visible:ring-rose-500"
            >
              <AlertTriangle className="w-3.5 h-3.5" />
              Retraso
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
