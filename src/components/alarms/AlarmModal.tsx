import React, { useState, useEffect, useRef } from 'react';
import { Alarm, DayOfWeek, AlarmSound, MissionType, AlarmCategory } from '../../types/alarm';
import { AppleToggle } from '../common/AppleToggle';
import { Play, Square, Sparkles, Volume2 } from 'lucide-react';
import { soundService } from '../../services/soundService';

interface AlarmModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (alarmData: Partial<Alarm>) => void;
  initialAlarm?: Alarm | null;
}

const DAY_OPTIONS: { day: DayOfWeek; short: string; full: string }[] = [
  { day: 0, short: 'D', full: 'Domingo' },
  { day: 1, short: 'L', full: 'Lunes' },
  { day: 2, short: 'Ma', full: 'Martes' },
  { day: 3, short: 'Mi', full: 'Miércoles' },
  { day: 4, short: 'J', full: 'Jueves' },
  { day: 5, short: 'V', full: 'Viernes' },
  { day: 6, short: 'S', full: 'Sábado' },
];

const SOUND_OPTIONS: { id: AlarmSound; name: string }[] = [
  { id: 'radar', name: 'Radar (Clásico Apple)' },
  { id: 'chimes', name: 'Campanas Zen' },
  { id: 'apex', name: 'Apex Pulso' },
  { id: 'breeze', name: 'Brisa Matutina' },
  { id: 'cosmic', name: 'Cosmos Suave' },
];

export const AlarmModal: React.FC<AlarmModalProps> = ({
  isOpen,
  onClose,
  onSave,
  initialAlarm,
}) => {
  if (!isOpen) return null;

  const [time, setTime] = useState(initialAlarm?.time || '07:00');
  const [label, setLabel] = useState(initialAlarm?.label || 'Alarma');
  const [repeatDays, setRepeatDays] = useState<DayOfWeek[]>(initialAlarm?.repeatDays || [1, 2, 3, 4, 5]);
  const [sound, setSound] = useState<AlarmSound>(initialAlarm?.sound || 'radar');
  const [volume, setVolume] = useState<number>(initialAlarm?.volume || 80);
  const [snoozeEnabled, setSnoozeEnabled] = useState(initialAlarm?.snoozeEnabled ?? true);
  const [snoozeDuration, setSnoozeDuration] = useState(initialAlarm?.snoozeDuration || 9);
  const [missionType, setMissionType] = useState<MissionType>(initialAlarm?.missionType || 'none');
  const [missionDifficulty, setMissionDifficulty] = useState<'facil' | 'medio' | 'dificil'>(
    initialAlarm?.missionDifficulty || 'medio'
  );
  const [category, setCategory] = useState<AlarmCategory>(initialAlarm?.category || 'wake-up');
  const [isPlayingAudio, setIsPlayingAudio] = useState(false);

  const modalRef = useRef<HTMLDivElement>(null);
  const cancelButtonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    // Focus cancel button on open
    cancelButtonRef.current?.focus();

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        soundService.stop();
        setIsPlayingAudio(false);
        onClose();
        return;
      }

      if (e.key === 'Tab' && modalRef.current) {
        const focusableElements = modalRef.current.querySelectorAll<HTMLElement>(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        if (focusableElements.length === 0) return;
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];

        if (e.shiftKey) {
          if (document.activeElement === firstElement) {
            e.preventDefault();
            lastElement?.focus();
          }
        } else {
          if (document.activeElement === lastElement) {
            e.preventDefault();
            firstElement?.focus();
          }
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      soundService.stop();
    };
  }, [onClose]);

  const toggleDay = (day: DayOfWeek) => {
    if (repeatDays.includes(day)) {
      setRepeatDays(repeatDays.filter((d) => d !== day));
    } else {
      setRepeatDays([...repeatDays, day].sort());
    }
  };

  const handleTestSound = () => {
    if (isPlayingAudio) {
      soundService.stop();
      setIsPlayingAudio(false);
    } else {
      soundService.previewSound(sound, volume);
      setIsPlayingAudio(true);
    }
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    soundService.stop();
    setIsPlayingAudio(false);
    onSave({
      id: initialAlarm ? initialAlarm.id : `alm-${Date.now()}`,
      time,
      label,
      enabled: true,
      repeatDays,
      sound,
      volume,
      snoozeEnabled,
      snoozeDuration,
      missionType,
      missionDifficulty,
      category,
      createdAt: initialAlarm?.createdAt || new Date().toISOString(),
    });
    onClose();
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="alarm-modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-md transition-opacity safe-top safe-bottom"
    >
      <div
        ref={modalRef}
        className="relative w-full max-w-lg overflow-hidden rounded-3xl bg-[#FFFFFF] dark:bg-[#1C1C1E] border border-black/10 dark:border-white/10 shadow-apple-popover animate-in fade-in zoom-in-95 duration-200"
      >
        {/* Apple Modal Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-zinc-200/80 dark:border-zinc-800/80">
          <button
            ref={cancelButtonRef}
            type="button"
            onClick={() => {
              soundService.stop();
              onClose();
            }}
            className="min-h-[44px] min-w-[44px] flex items-center text-sm font-normal text-[#007AFF] hover:opacity-75 transition-opacity focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF] rounded-lg"
          >
            Cancelar
          </button>
          <h2 id="alarm-modal-title" className="text-base font-semibold text-zinc-950 dark:text-white">
            {initialAlarm ? 'Editar Alarma' : 'Nueva Alarma'}
          </h2>
          <button
            type="button"
            onClick={handleSave}
            className="min-h-[44px] min-w-[44px] flex items-center justify-end text-sm font-semibold text-[#007AFF] hover:opacity-75 transition-opacity focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF] rounded-lg"
          >
            Guardar
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSave} className="p-6 space-y-6 max-h-[80vh] overflow-y-auto">
          {/* Apple Time Wheel / Input */}
          <div className="flex flex-col items-center justify-center py-4 bg-zinc-100/60 dark:bg-zinc-900/60 rounded-2xl border border-zinc-200/50 dark:border-zinc-800/50">
            <label htmlFor="alarm-time-input" className="text-xs font-semibold uppercase tracking-wider text-[#636366] dark:text-[#8E8E93] mb-2">
              Hora de Activación
            </label>
            <input
              id="alarm-time-input"
              type="time"
              value={time}
              onChange={(e) => setTime(e.target.value)}
              className="text-5xl font-mono font-light bg-transparent text-zinc-900 dark:text-white text-center focus:outline-none focus:ring-2 focus:ring-[#007AFF]/30 rounded-xl px-4 py-1"
              required
            />
          </div>

          {/* Label Input */}
          <div className="space-y-1.5">
            <label htmlFor="alarm-label-input" className="text-xs font-medium text-[#636366] dark:text-[#8E8E93]">
              Etiqueta de la alarma
            </label>
            <input
              id="alarm-label-input"
              type="text"
              value={label}
              onChange={(e) => setLabel(e.target.value)}
              placeholder="Ej. Despertar Productivo"
              className="w-full px-3.5 py-2.5 min-h-[44px] rounded-xl bg-zinc-100 dark:bg-zinc-800/80 border border-zinc-200/80 dark:border-zinc-700/80 text-sm text-zinc-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#007AFF] transition-all"
            />
          </div>

          {/* Repeat Days Selector with Presets & Disambiguated Labels */}
          <div className="space-y-2.5">
            <div className="flex items-center justify-between">
              <label className="text-xs font-medium text-[#636366] dark:text-[#8E8E93]">
                Repetir días
              </label>
              <span className="text-[11px] text-[#636366] dark:text-[#8E8E93]">
                {repeatDays.length === 0 ? 'Una sola vez' : repeatDays.length === 7 ? 'Todos los días' : `${repeatDays.length} días`}
              </span>
            </div>

            {/* Quick preset chips */}
            <div className="flex flex-wrap items-center gap-1.5">
              <button
                type="button"
                onClick={() => setRepeatDays([1, 2, 3, 4, 5])}
                className="min-h-[36px] px-3 py-1.5 text-xs font-medium rounded-lg bg-zinc-100 dark:bg-zinc-800 text-zinc-800 dark:text-zinc-200 hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#FF9500]"
              >
                Laborables (L-V)
              </button>
              <button
                type="button"
                onClick={() => setRepeatDays([0, 6])}
                className="min-h-[36px] px-3 py-1.5 text-xs font-medium rounded-lg bg-zinc-100 dark:bg-zinc-800 text-zinc-800 dark:text-zinc-200 hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#FF9500]"
              >
                Fines de semana
              </button>
              <button
                type="button"
                onClick={() => setRepeatDays([0, 1, 2, 3, 4, 5, 6])}
                className="min-h-[36px] px-3 py-1.5 text-xs font-medium rounded-lg bg-zinc-100 dark:bg-zinc-800 text-zinc-800 dark:text-zinc-200 hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#FF9500]"
              >
                Todos
              </button>
            </div>

            {/* 44x44px Day Circles with Ma/Mi and aria-pressed */}
            <div className="flex items-center justify-between gap-1 sm:gap-1.5 pt-1">
              {DAY_OPTIONS.map(({ day, short, full }) => {
                const isSelected = repeatDays.includes(day);
                return (
                  <button
                    key={day}
                    type="button"
                    aria-pressed={isSelected}
                    aria-label={`${full}, ${isSelected ? 'seleccionado' : 'no seleccionado'}`}
                    onClick={() => toggleDay(day)}
                    className={`
                      w-11 h-11 rounded-full text-xs font-semibold flex items-center justify-center transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-[#FF9500]
                      ${
                        isSelected
                          ? 'bg-[#FF9500] text-white shadow-sm scale-105'
                          : 'bg-zinc-100 dark:bg-zinc-800 text-[#636366] dark:text-[#8E8E93] hover:text-zinc-900 dark:hover:text-white'
                      }
                    `}
                  >
                    {short}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Sound & Volume */}
          <div className="space-y-3 p-4 rounded-2xl bg-zinc-50 dark:bg-zinc-900/40 border border-zinc-200/60 dark:border-zinc-800/60">
            <div className="flex items-center justify-between">
              <label htmlFor="alarm-sound-select" className="text-xs font-medium text-zinc-800 dark:text-zinc-200 flex items-center gap-1.5">
                <Volume2 className="w-4 h-4 text-[#007AFF]" />
                Sonido de Alarma
              </label>
              <button
                type="button"
                onClick={handleTestSound}
                aria-label={isPlayingAudio ? 'Detener prueba de sonido' : `Escuchar sonido ${sound}`}
                className="min-h-[44px] inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-xl bg-[#007AFF]/10 text-[#007AFF] hover:bg-[#007AFF]/20 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
              >
                {isPlayingAudio ? (
                  <>
                    <Square className="w-3.5 h-3.5 fill-current" /> Detener
                  </>
                ) : (
                  <>
                    <Play className="w-3.5 h-3.5 fill-current" /> Escuchar
                  </>
                )}
              </button>
            </div>

            <select
              id="alarm-sound-select"
              value={sound}
              onChange={(e) => {
                setSound(e.target.value as AlarmSound);
                if (isPlayingAudio) {
                  soundService.previewSound(e.target.value as AlarmSound, volume);
                }
              }}
              className="w-full min-h-[44px] px-3.5 py-2.5 rounded-xl bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-sm text-zinc-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#007AFF]"
            >
              {SOUND_OPTIONS.map((opt) => (
                <option key={opt.id} value={opt.id}>
                  {opt.name}
                </option>
              ))}
            </select>

            <div className="pt-2">
              <div className="flex justify-between text-xs text-[#636366] dark:text-[#8E8E93] mb-1 font-medium">
                <label htmlFor="volume-range-input">Volumen</label>
                <span>{volume}%</span>
              </div>
              <input
                id="volume-range-input"
                type="range"
                min="20"
                max="100"
                value={volume}
                onChange={(e) => setVolume(Number(e.target.value))}
                aria-label={`Volumen ${volume}%`}
                className="w-full accent-[#007AFF] cursor-pointer"
              />
            </div>
          </div>

          {/* Mission Challenge */}
          <div className="space-y-2 p-4 rounded-2xl bg-zinc-50 dark:bg-zinc-900/40 border border-zinc-200/60 dark:border-zinc-800/60">
            <div className="flex items-center justify-between">
              <label className="text-xs font-medium text-zinc-800 dark:text-zinc-200 flex items-center gap-1.5">
                <Sparkles className="w-4 h-4 text-[#AF52DE]" />
                Misión para Despertar
              </label>
              <span className="text-[11px] text-[#AF52DE] font-semibold">Garantiza despertar</span>
            </div>

            <div className="grid grid-cols-2 gap-2 pt-1">
              {[
                { id: 'none', label: 'Sin reto' },
                { id: 'math', label: '🧮 Cálculo' },
                { id: 'shake', label: '📱 Agitar' },
                { id: 'qr', label: '📷 Escanear QR' },
              ].map((m) => (
                <button
                  key={m.id}
                  type="button"
                  onClick={() => setMissionType(m.id as MissionType)}
                  className={`
                    px-3.5 py-2.5 min-h-[44px] text-xs font-medium rounded-xl border transition-all text-left flex items-center focus:outline-none focus-visible:ring-2 focus-visible:ring-[#AF52DE]
                    ${
                      missionType === m.id
                        ? 'bg-[#AF52DE]/15 border-[#AF52DE] text-[#AF52DE] font-semibold'
                        : 'bg-white dark:bg-zinc-800 border-zinc-200 dark:border-zinc-700 text-zinc-700 dark:text-zinc-300'
                    }
                  `}
                >
                  {m.label}
                </button>
              ))}
            </div>

            {missionType !== 'none' && (
              <div className="pt-2 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
                <span className="text-[#636366] dark:text-[#8E8E93] font-medium">Dificultad del reto:</span>
                <div className="inline-flex rounded-xl bg-zinc-200/70 dark:bg-zinc-800 p-1 gap-1">
                  {(['facil', 'medio', 'dificil'] as const).map((d) => (
                    <button
                      key={d}
                      type="button"
                      onClick={() => setMissionDifficulty(d)}
                      className={`min-h-[44px] px-3.5 py-2 rounded-lg capitalize text-xs font-medium transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-[#AF52DE] ${
                        missionDifficulty === d
                          ? 'bg-white dark:bg-zinc-700 text-[#AF52DE] font-semibold shadow-xs'
                          : 'text-[#636366] dark:text-[#8E8E93] hover:text-zinc-900 dark:hover:text-zinc-200'
                      }`}
                    >
                      {d}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Category Selector */}
          <div className="space-y-1.5">
            <label className="text-xs font-medium text-[#636366] dark:text-[#8E8E93]">
              Categoría
            </label>
            <div className="flex flex-wrap gap-2">
              {(
                [
                  { id: 'wake-up', label: 'Despertar' },
                  { id: 'fitness', label: 'Ejercicio' },
                  { id: 'work', label: 'Trabajo' },
                  { id: 'meds', label: 'Salud / Medicinas' },
                  { id: 'custom', label: 'Personalizado' },
                ] as const
              ).map((cat) => (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => setCategory(cat.id)}
                  className={`min-h-[44px] px-3.5 py-2 rounded-xl text-xs font-medium transition-all flex items-center focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF] ${
                    category === cat.id
                      ? 'bg-[#007AFF] text-white shadow-xs font-semibold'
                      : 'bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300 hover:bg-zinc-200 dark:hover:bg-zinc-700'
                  }`}
                >
                  {cat.label}
                </button>
              ))}
            </div>
          </div>

          {/* Snooze Toggle & Duration */}
          <div className="space-y-2 py-2 border-t border-zinc-200/60 dark:border-zinc-800/60">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-zinc-900 dark:text-white">
                  Permitir Postergación (Snooze)
                </p>
                <p className="text-xs text-[#636366] dark:text-[#8E8E93]">
                  Pausar {snoozeDuration} minutos (estándar Apple)
                </p>
              </div>
              <AppleToggle checked={snoozeEnabled} onChange={setSnoozeEnabled} label="Permitir Postergación" />
            </div>

            {snoozeEnabled && (
              <div className="flex items-center justify-between pt-1 text-xs">
                <label htmlFor="snooze-duration-select" className="text-[#636366] dark:text-[#8E8E93] font-medium">
                  Duración del snooze:
                </label>
                <select
                  id="snooze-duration-select"
                  value={snoozeDuration}
                  onChange={(e) => setSnoozeDuration(Number(e.target.value))}
                  className="min-h-[44px] px-3 py-2 rounded-xl bg-zinc-100 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-sm text-zinc-800 dark:text-zinc-200 focus:outline-none focus:ring-2 focus:ring-[#007AFF]"
                >
                  <option value={5}>5 minutos</option>
                  <option value={9}>9 minutos (Apple HIG)</option>
                  <option value={15}>15 minutos</option>
                </select>
              </div>
            )}
          </div>
        </form>
      </div>
    </div>
  );
};
