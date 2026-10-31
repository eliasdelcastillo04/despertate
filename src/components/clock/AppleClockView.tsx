import React, { useState, useEffect } from 'react';
import { Play, Pause, RotateCcw, Flag } from 'lucide-react';

export const AppleClockView: React.FC = () => {
  const [time, setTime] = useState(new Date());
  const [stopwatchTime, setStopwatchTime] = useState(0); // in tenths of a second
  const [isRunning, setIsRunning] = useState(false);
  const [laps, setLaps] = useState<number[]>([]);

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    let interval: number | null = null;
    if (isRunning) {
      interval = window.setInterval(() => {
        setStopwatchTime((prev) => prev + 1);
      }, 100);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isRunning]);

  const formatStopwatch = (tenths: number) => {
    const mins = Math.floor(tenths / 600);
    const secs = Math.floor((tenths % 600) / 10);
    const ms = tenths % 10;
    return `${mins.toString().padStart(2, '0')}:${secs
      .toString()
      .padStart(2, '0')}.${ms}`;
  };

  const handleLap = () => {
    setLaps([stopwatchTime, ...laps]);
  };

  const handleReset = () => {
    setIsRunning(false);
    setStopwatchTime(0);
    setLaps([]);
  };

  // Clock hands calculation
  const seconds = time.getSeconds();
  const minutes = time.getMinutes();
  const hours = time.getHours();

  const secAngle = seconds * 6;
  const minAngle = minutes * 6 + seconds * 0.1;
  const hourAngle = (hours % 12) * 30 + minutes * 0.5;

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {/* Apple Analog & Digital Clock Card */}
      <div className="flex flex-col items-center justify-center p-8 rounded-3xl bg-white/80 dark:bg-[#1C1C1E]/80 backdrop-blur-xl border border-zinc-200/80 dark:border-zinc-800/80 shadow-apple-subtle">
        <h3 className="text-xs font-semibold uppercase tracking-wider text-[#636366] dark:text-[#8E8E93] mb-6">
          Hora Actual
        </h3>

        {/* Minimalist Apple Watch / Clock Face */}
        <div className="relative w-48 h-48 rounded-full border-4 border-zinc-200 dark:border-zinc-800 flex items-center justify-center bg-white dark:bg-black shadow-inner">
          {/* Tick marks */}
          {[...Array(12)].map((_, i) => (
            <div
              key={i}
              className="absolute w-0.5 h-3 bg-zinc-300 dark:bg-zinc-700"
              style={{
                top: 4,
                transform: `rotate(${i * 30}deg)`,
                transformOrigin: '0 92px',
              }}
            />
          ))}

          {/* Hour Hand */}
          <div
            className="absolute w-1.5 h-14 bg-zinc-800 dark:bg-zinc-200 rounded-full"
            style={{
              top: '40px',
              transform: `rotate(${hourAngle}deg)`,
              transformOrigin: '50% 56px',
            }}
          />

          {/* Minute Hand */}
          <div
            className="absolute w-1 h-20 bg-zinc-700 dark:bg-zinc-300 rounded-full"
            style={{
              top: '20px',
              transform: `rotate(${minAngle}deg)`,
              transformOrigin: '50% 76px',
            }}
          />

          {/* Second Hand (Apple Orange) */}
          <div
            className="absolute w-0.5 h-22 bg-[#FF9500] rounded-full"
            style={{
              top: '16px',
              transform: `rotate(${secAngle}deg)`,
              transformOrigin: '50% 80px',
            }}
          />

          {/* Center Pin */}
          <div className="absolute w-3 h-3 rounded-full bg-[#FF9500] ring-2 ring-white dark:ring-black z-10" />
        </div>

        {/* Big Digital Display */}
        <div className="mt-6 text-center">
          <div className="text-4xl font-mono font-light tracking-tight text-zinc-950 dark:text-white">
            {time.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
          </div>
          <div className="text-xs text-zinc-500 capitalize mt-1">
            {time.toLocaleDateString('es-ES', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
          </div>
        </div>
      </div>

      {/* Apple Stopwatch Card */}
      <div className="flex flex-col p-6 rounded-3xl bg-white/80 dark:bg-[#1C1C1E]/80 backdrop-blur-xl border border-zinc-200/80 dark:border-zinc-800/80 shadow-apple-subtle">
        <h3 className="text-xs font-semibold uppercase tracking-wider text-[#636366] dark:text-[#8E8E93] mb-4">
          Cronómetro
        </h3>

        <div className="flex-1 flex flex-col items-center justify-center my-4">
          <span className="text-5xl font-mono font-extralight tracking-tight text-zinc-950 dark:text-white">
            {formatStopwatch(stopwatchTime)}
          </span>
        </div>

        {/* Buttons with >= 44x44pt target and descriptive aria-labels */}
        <div className="flex items-center justify-between px-4 py-3">
          <button
            type="button"
            onClick={stopwatchTime > 0 && !isRunning ? handleReset : handleLap}
            disabled={stopwatchTime === 0}
            title={stopwatchTime > 0 && !isRunning ? 'Reiniciar cronómetro' : 'Registrar vuelta'}
            aria-label={stopwatchTime > 0 && !isRunning ? 'Reiniciar cronómetro' : 'Registrar vuelta'}
            className="w-16 h-16 rounded-full bg-zinc-100 dark:bg-zinc-800/80 border border-zinc-300 dark:border-zinc-700 text-zinc-700 dark:text-zinc-200 text-xs font-medium flex items-center justify-center transition-all disabled:opacity-40 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
          >
            {stopwatchTime > 0 && !isRunning ? (
              <RotateCcw className="w-5 h-5" />
            ) : (
              <Flag className="w-5 h-5" />
            )}
          </button>

          <button
            type="button"
            onClick={() => setIsRunning(!isRunning)}
            title={isRunning ? 'Pausar cronómetro' : 'Iniciar cronómetro'}
            aria-label={isRunning ? 'Pausar cronómetro' : 'Iniciar cronómetro'}
            className={`w-16 h-16 rounded-full text-white text-xs font-medium flex items-center justify-center shadow-md transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-[#34C759] ${
              isRunning ? 'bg-[#FF3B30] hover:bg-[#e03429]' : 'bg-[#34C759] hover:bg-[#2eb34f]'
            }`}
          >
            {isRunning ? (
              <Pause className="w-6 h-6 fill-current" />
            ) : (
              <Play className="w-6 h-6 fill-current ml-0.5" />
            )}
          </button>
        </div>

        {/* Laps List */}
        {laps.length > 0 && (
          <div className="mt-4 border-t border-zinc-200 dark:border-zinc-800 max-h-36 overflow-y-auto divide-y divide-zinc-100 dark:divide-zinc-800/60 text-xs">
            {laps.map((lap, i) => (
              <div
                key={i}
                className="flex items-center justify-between py-2 px-2 text-zinc-600 dark:text-zinc-300 font-mono"
              >
                <span>Vuelta {laps.length - i}</span>
                <span className="font-semibold">{formatStopwatch(lap)}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
