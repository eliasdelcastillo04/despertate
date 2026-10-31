import React, { useState, useEffect, useRef } from 'react';
import { Alarm, DayOfWeek } from '../../types/alarm';
import { AppleToggle } from '../common/AppleToggle';
import { Volume2, Square, Sparkles, Repeat, BellRing } from 'lucide-react';
import { soundService } from '../../services/soundService';

interface AlarmRowProps {
  alarm: Alarm;
  isSelected?: boolean;
  onToggle: (id: string, enabled: boolean) => void;
  onSelect: (alarm: Alarm) => void;
}

const DAY_NAMES = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

export const AlarmRow: React.FC<AlarmRowProps> = ({
  alarm,
  isSelected = false,
  onToggle,
  onSelect,
}) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const stopTimeoutRef = useRef<number | null>(null);

  useEffect(() => {
    return () => {
      if (stopTimeoutRef.current) {
        window.clearTimeout(stopTimeoutRef.current);
      }
    };
  }, []);

  const formatDays = (days: DayOfWeek[]) => {
    if (days.length === 0) return 'Una sola vez';
    if (days.length === 7) return 'Todos los días';
    if (days.length === 5 && !days.includes(0) && !days.includes(6)) return 'Días laborales';
    if (days.length === 2 && days.includes(0) && days.includes(6)) return 'Fines de semana';
    return days.map((d) => DAY_NAMES[d]).join(', ');
  };

  const handleTestSound = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (isPlaying) {
      soundService.stop();
      setIsPlaying(false);
      if (stopTimeoutRef.current) {
        window.clearTimeout(stopTimeoutRef.current);
        stopTimeoutRef.current = null;
      }
    } else {
      soundService.previewSound(alarm.sound, alarm.volume);
      setIsPlaying(true);
      stopTimeoutRef.current = window.setTimeout(() => {
        setIsPlaying(false);
        stopTimeoutRef.current = null;
      }, 2500);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.target === e.currentTarget && (e.key === 'Enter' || e.key === ' ')) {
      e.preventDefault();
      onSelect(alarm);
    }
  };

  return (
    <div
      role="button"
      tabIndex={0}
      aria-label={`Alarma ${alarm.time}, ${alarm.label}, ${alarm.enabled ? 'activada' : 'desactivada'}`}
      onClick={() => onSelect(alarm)}
      onKeyDown={handleKeyDown}
      className={`
        group relative flex items-center justify-between p-4 sm:p-5 rounded-2xl cursor-pointer transition-all duration-200
        border backdrop-blur-xl focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]
        ${
          isSelected
            ? 'bg-[#007AFF]/10 dark:bg-[#007AFF]/20 border-[#007AFF]/40 ring-1 ring-[#007AFF]/30'
            : 'bg-white/70 dark:bg-[#1C1C1E]/70 border-zinc-200/80 dark:border-zinc-800/80 hover:bg-white dark:hover:bg-[#2C2C2E]/80 shadow-sm'
        }
      `}
    >
      <div className="flex flex-col gap-1.5 flex-1 min-w-0 pr-4">
        {/* Apple Clock large time presentation */}
        <div className="flex items-baseline gap-2">
          <span
            className={`text-4xl sm:text-5xl font-light tracking-tight font-mono transition-opacity duration-200 ${
              alarm.enabled
                ? 'text-zinc-950 dark:text-white font-medium'
                : 'text-[#636366] dark:text-[#8E8E93] opacity-65'
            }`}
          >
            {alarm.time}
          </span>
          <span
            className={`text-sm font-semibold uppercase tracking-wider ${
              alarm.enabled
                ? 'text-[#B25000] dark:text-[#FF9F0A]'
                : 'text-[#636366] dark:text-[#8E8E93] opacity-65'
            }`}
          >
            {parseInt(alarm.time.split(':')[0], 10) >= 12 ? 'PM' : 'AM'}
          </span>
        </div>

        {/* Alarm info & labels with WCAG AA compliant text colors */}
        <div className="flex items-center flex-wrap gap-2 text-xs text-[#636366] dark:text-[#8E8E93]">
          <span className="font-medium text-zinc-900 dark:text-zinc-200 truncate max-w-[200px]">
            {alarm.label}
          </span>
          <span className="text-zinc-400 dark:text-zinc-600">•</span>
          <span className="flex items-center gap-1">
            <Repeat className="w-3 h-3 text-[#636366] dark:text-[#8E8E93]" />
            {formatDays(alarm.repeatDays)}
          </span>

          {alarm.missionType !== 'none' && (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#AF52DE]/10 text-[#AF52DE] dark:bg-[#AF52DE]/20 font-medium">
              <Sparkles className="w-3 h-3" />
              Misión: {alarm.missionType}
            </span>
          )}

          {alarm.snoozeEnabled && (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-zinc-100 dark:bg-zinc-800 text-xs text-[#636366] dark:text-[#8E8E93]">
              <BellRing className="w-3 h-3" />
              {alarm.snoozeDuration}m snooze
            </span>
          )}
        </div>
      </div>

      {/* Actions: Sound preview & Apple Toggle */}
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={handleTestSound}
          title={isPlaying ? 'Detener sonido' : `Probar sonido ${alarm.sound}`}
          aria-label={isPlaying ? 'Detener prueba de sonido' : `Probar sonido de alarma ${alarm.sound}`}
          className={`min-w-[44px] min-h-[44px] p-2.5 rounded-xl flex items-center justify-center transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF] ${
            isPlaying
              ? 'bg-[#007AFF] text-white shadow-sm ring-2 ring-[#007AFF]/40 animate-pulse'
              : 'text-[#636366] dark:text-[#8E8E93] hover:text-[#007AFF] hover:bg-[#007AFF]/10 dark:hover:bg-[#007AFF]/20'
          }`}
        >
          {isPlaying ? <Square className="w-4 h-4 fill-current" /> : <Volume2 className="w-4 h-4" />}
        </button>

        <AppleToggle
          checked={alarm.enabled}
          onChange={(val) => onToggle(alarm.id, val)}
          label={`Activar alarma ${alarm.label}`}
        />
      </div>
    </div>
  );
};
