import React, { useState } from 'react';
import { Alarm, WakeLog, AlarmMetrics } from '../../types/alarm';
import { Sparkles, Send, Bot, User, X } from 'lucide-react';

interface DataChatDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  alarms: Alarm[];
  logs: WakeLog[];
  metrics: AlarmMetrics;
}

interface Message {
  id: string;
  sender: 'ai' | 'user';
  text: string;
  timestamp: string;
}

export const DataChatDrawer: React.FC<DataChatDrawerProps> = ({
  isOpen,
  onClose,
  alarms,
  logs,
  metrics,
}) => {
  if (!isOpen) return null;

  const [inputQuery, setInputQuery] = useState('');
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 'm1',
      sender: 'ai',
      text: `¡Hola! Soy tu asistente inteligente de sueño y alarmas basado en Apple HIG y análisis de datos. Tienes ${metrics.activeAlarms} alarmas activas y un índice de consistencia del ${metrics.consistencyScore}%. ¿Qué te gustaría consultar sobre tus hábitos o métricas de descanso?`,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    },
  ]);

  const quickPrompts = [
    '¿Cuál es mi porcentaje de snooze?',
    '¿Cuál es mi hora promedio de despertar?',
    '¿Cómo puedo mejorar mi consistencia?',
    '¿Qué alarmas tienen retos activados?',
  ];

  const handleSend = (text: string) => {
    if (!text.trim()) return;

    const userMsg: Message = {
      id: `u-${Date.now()}`,
      sender: 'user',
      text,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputQuery('');

    // Generate intelligent data-driven answer
    setTimeout(() => {
      let reply = '';
      const queryLower = text.toLowerCase();

      if (queryLower.includes('snooze') || queryLower.includes('postergar')) {
        reply = `Actualmente tu tasa de snooze es del **${metrics.snoozeRate}%**. En los últimos registros has utilizado snooze en ${
          logs.filter((l) => l.snoozeCount > 0).length
        } ocasiones. Según las recomendaciones de Apple Salud, reducir la postergación a 0 disminuye el cansancio matutino (inercia del sueño).`;
      } else if (queryLower.includes('hora') || queryLower.includes('promedio') || queryLower.includes('despertar')) {
        reply = `Tu hora promedio de despertar se sitúa en las **${metrics.averageWakeTime}**. Tu alarma más temprana activa está programada a las ${
          alarms.find((a) => a.enabled)?.time || '06:30'
        }. Mantener una desviación menor a 15 minutos en fines de semana optimizará tu ritmo circadiano.`;
      } else if (queryLower.includes('consistencia') || queryLower.includes('mejorar')) {
        reply = `Tu consistencia general es de **${metrics.consistencyScore}/100** (Nivel Óptimo). Consejos para alcanzar el 100%:\n1. Acostarte dentro del mismo intervalo de 30 minutos.\n2. Mantener la alarma 'Despertar Productivo' activa con reto de cálculo mental.`;
      } else if (queryLower.includes('reto') || queryLower.includes('misión') || queryLower.includes('mision')) {
        const withMissions = alarms.filter((a) => a.missionType !== 'none');
        reply = `Tienes **${withMissions.length} alarmas con reto de despertar**: ${withMissions
          .map((a) => `\n- **${a.label}** (${a.time}) con reto de ${a.missionType}`)
          .join('')}.`;
      } else {
        reply = `Analizando tu historial de ${logs.length} registros: tu tiempo promedio de sueño es de ${(
          logs.reduce((acc, l) => acc + l.sleepHours, 0) / (logs.length || 1)
        ).toFixed(1)} horas diarias. Tus datos muestran una recuperación adecuada y alta regularidad.`;
      }

      const aiMsg: Message = {
        id: `a-${Date.now()}`,
        sender: 'ai',
        text: reply,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages((prev) => [...prev, aiMsg]);
    }, 450);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-end bg-black/40 backdrop-blur-sm transition-opacity">
      <div className="w-full max-w-md h-full bg-white dark:bg-[#1C1C1E] border-l border-zinc-200 dark:border-zinc-800 flex flex-col shadow-2xl animate-in slide-in-from-right duration-250">
        {/* Header */}
        <div className="p-4 border-b border-zinc-200 dark:border-zinc-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="p-2 rounded-xl bg-[#007AFF]/10 text-[#007AFF]">
              <Sparkles className="w-4 h-4" />
            </span>
            <div>
              <h3 className="text-sm font-semibold text-zinc-900 dark:text-white">
                Asistente de Datos de Sueño
              </h3>
              <p className="text-[11px] text-zinc-400">Consultas en lenguaje natural</p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-800"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Chat message stream */}
        <div className="flex-1 p-4 overflow-y-auto space-y-3.5 text-xs">
          {messages.map((m) => (
            <div
              key={m.id}
              className={`flex gap-2.5 ${
                m.sender === 'user' ? 'justify-end' : 'justify-start'
              }`}
            >
              {m.sender === 'ai' && (
                <div className="w-6 h-6 rounded-full bg-[#007AFF]/15 text-[#007AFF] flex items-center justify-center shrink-0 mt-0.5">
                  <Bot className="w-3.5 h-3.5" />
                </div>
              )}
              <div
                className={`max-w-[82%] p-3 rounded-2xl leading-relaxed ${
                  m.sender === 'user'
                    ? 'bg-[#007AFF] text-white rounded-tr-sm'
                    : 'bg-zinc-100 dark:bg-zinc-800 text-zinc-800 dark:text-zinc-100 rounded-tl-sm border border-zinc-200/60 dark:border-zinc-700/60 whitespace-pre-line'
                }`}
              >
                {m.text}
                <div
                  className={`text-[9px] mt-1 text-right ${
                    m.sender === 'user' ? 'text-blue-100' : 'text-zinc-400'
                  }`}
                >
                  {m.timestamp}
                </div>
              </div>
              {m.sender === 'user' && (
                <div className="w-6 h-6 rounded-full bg-zinc-200 dark:bg-zinc-700 text-zinc-700 dark:text-zinc-200 flex items-center justify-center shrink-0 mt-0.5">
                  <User className="w-3.5 h-3.5" />
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Quick Suggestion Chips */}
        <div className="px-4 py-2 border-t border-zinc-100 dark:border-zinc-800/80 flex items-center gap-1.5 overflow-x-auto no-scrollbar">
          {quickPrompts.map((q, idx) => (
            <button
              key={idx}
              type="button"
              onClick={() => handleSend(q)}
              className="px-2.5 py-1 text-[11px] rounded-full bg-zinc-100 dark:bg-zinc-800 hover:bg-[#007AFF]/10 hover:text-[#007AFF] text-zinc-600 dark:text-zinc-300 border border-zinc-200/60 dark:border-zinc-700/60 whitespace-nowrap transition-colors"
            >
              {q}
            </button>
          ))}
        </div>

        {/* Input Bar */}
        <div className="p-4 border-t border-zinc-200 dark:border-zinc-800 flex items-center gap-2">
          <input
            type="text"
            value={inputQuery}
            onChange={(e) => setInputQuery(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSend(inputQuery);
            }}
            placeholder="Pregunta algo sobre tu descanso o tus alarmas..."
            className="flex-1 px-3.5 py-2 text-xs rounded-xl bg-zinc-100 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#007AFF]"
          />
          <button
            type="button"
            onClick={() => handleSend(inputQuery)}
            disabled={!inputQuery.trim()}
            className="p-2 rounded-xl bg-[#007AFF] text-white hover:bg-blue-600 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          >
            <Send className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
