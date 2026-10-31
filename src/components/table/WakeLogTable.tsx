import React, { useState, useMemo } from 'react';
import { WakeLog } from '../../types/alarm';
import {
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  Search,
  Filter,
  CheckCircle2,
  Clock,
  AlertCircle,
  XCircle,
} from 'lucide-react';

interface WakeLogTableProps {
  logs: WakeLog[];
  selectedLogId?: string | null;
  onSelectLog: (log: WakeLog | null) => void;
}

const ITEMS_PER_PAGE = 6;

export const WakeLogTable: React.FC<WakeLogTableProps> = ({
  logs,
  selectedLogId = null,
  onSelectLog,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'perfect' | 'snoozed' | 'delayed'>('all');
  const [currentPage, setCurrentPage] = useState(1);

  // Filter without mutating source data
  const filteredLogs = useMemo(() => {
    return logs.filter((log) => {
      const matchesSearch =
        log.alarmLabel.toLowerCase().includes(searchQuery.toLowerCase()) ||
        log.targetDate.includes(searchQuery) ||
        log.scheduledTime.includes(searchQuery);

      const matchesStatus =
        statusFilter === 'all' || log.status === statusFilter;

      return matchesSearch && matchesStatus;
    });
  }, [logs, searchQuery, statusFilter]);

  // Pagination calculation
  const totalPages = Math.max(1, Math.ceil(filteredLogs.length / ITEMS_PER_PAGE));
  const currentLogs = useMemo(() => {
    const start = (currentPage - 1) * ITEMS_PER_PAGE;
    return filteredLogs.slice(start, start + ITEMS_PER_PAGE);
  }, [filteredLogs, currentPage]);

  const handlePageChange = (page: number) => {
    if (page >= 1 && page <= totalPages) {
      setCurrentPage(page);
    }
  };

  const getStatusBadge = (status: WakeLog['status']) => {
    switch (status) {
      case 'perfect':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-400">
            <CheckCircle2 className="w-3 h-3" /> A tiempo
          </span>
        );
      case 'snoozed':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-800 dark:bg-amber-950/40 dark:text-amber-400">
            <Clock className="w-3 h-3" /> Postergada
          </span>
        );
      case 'delayed':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-rose-100 text-rose-800 dark:bg-rose-950/40 dark:text-rose-400">
            <AlertCircle className="w-3 h-3" /> Retraso
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-zinc-100 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-400">
            <XCircle className="w-3 h-3" /> Pérdida
          </span>
        );
    }
  };

  return (
    <div className="flex flex-col bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-2xl overflow-hidden shadow-apple-subtle">
      {/* Table Toolbar */}
      <div className="p-4 border-b border-zinc-200 dark:border-zinc-800 flex flex-wrap items-center justify-between gap-3 relative z-30">
        <div className="flex items-center gap-2 flex-1 min-w-[200px]">
          <div className="relative w-full max-w-xs">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#636366] dark:text-[#8E8E93]" />
            <input
              type="text"
              placeholder="Buscar en registros..."
              aria-label="Buscar en registros de sueño"
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full min-h-[44px] pl-9 pr-3 py-2 text-xs sm:text-sm rounded-xl bg-zinc-100 dark:bg-zinc-800/80 border border-transparent focus:border-[#007AFF] focus:bg-white dark:focus:bg-zinc-900 focus:outline-none transition-all"
            />
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1 text-xs text-[#636366] dark:text-[#8E8E93] font-medium">
            <Filter className="w-3.5 h-3.5" />
            <label htmlFor="wake-log-filter">Filtro:</label>
          </div>
          <select
            id="wake-log-filter"
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value as typeof statusFilter);
              setCurrentPage(1);
            }}
            className="min-h-[44px] text-xs sm:text-sm px-3 py-2 rounded-xl bg-zinc-100 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-1 focus:ring-[#007AFF]"
          >
            <option value="all">Todos los estados</option>
            <option value="perfect">A tiempo</option>
            <option value="snoozed">Con Snooze</option>
            <option value="delayed">Retrasadas</option>
          </select>
        </div>
      </div>

      {/* Responsive Table Container */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse text-xs sm:text-sm">
          {/* Sticky Header */}
          <thead className="sticky top-0 bg-zinc-100/90 dark:bg-zinc-900/90 backdrop-blur-md z-10 text-[#636366] dark:text-[#8E8E93] font-semibold border-b border-zinc-200 dark:border-zinc-800 uppercase text-[11px] tracking-wider">
            <tr>
              <th className="py-3 px-4">Fecha</th>
              <th className="py-3 px-4">Alarma</th>
              <th className="py-3 px-4">Programada / Real</th>
              <th className="py-3 px-4">Consistencia</th>
              <th className="py-3 px-4">Snoozes</th>
              <th className="py-3 px-4">Estado</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-zinc-100 dark:divide-zinc-800/60">
            {currentLogs.length === 0 ? (
              <tr>
                <td colSpan={6} className="text-center py-8 text-zinc-400">
                  No se encontraron registros con los filtros actuales.
                </td>
              </tr>
            ) : (
              currentLogs.map((log) => {
                const isSelected = selectedLogId === log.id;
                return (
                  <tr
                    key={log.id}
                    onClick={() => onSelectLog(isSelected ? null : log)}
                    className={`
                      cursor-pointer transition-colors
                      ${
                        isSelected
                          ? 'bg-blue-50 dark:bg-blue-900/30 text-zinc-950 dark:text-white font-medium'
                          : 'text-zinc-800 dark:text-zinc-200 hover:bg-zinc-50 dark:hover:bg-zinc-800/50'
                      }
                    `}
                  >
                    <td className="py-3.5 px-4 font-mono text-xs text-zinc-500 dark:text-zinc-400">
                      {log.targetDate}
                    </td>
                    <td className="py-3.5 px-4 font-medium max-w-[160px] truncate">
                      {log.alarmLabel}
                    </td>
                    <td className="py-3.5 px-4 font-mono text-xs">
                      <span className="text-zinc-400">{log.scheduledTime}</span>
                      <span className="mx-1 text-zinc-300 dark:text-zinc-600">→</span>
                      <span className="font-semibold text-zinc-900 dark:text-zinc-100">
                        {log.wakeTime}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 min-w-[130px]">
                      {/* Horizontal progress bar / sparkline indicator */}
                      <div className="flex items-center gap-2">
                        <div className="w-16 h-2 rounded-full bg-zinc-200 dark:bg-zinc-700 overflow-hidden">
                          <div
                            className={`h-full rounded-full ${
                              log.consistencyScore >= 90
                                ? 'bg-emerald-500'
                                : log.consistencyScore >= 80
                                ? 'bg-orange-400'
                                : 'bg-rose-500'
                            }`}
                            style={{ width: `${log.consistencyScore}%` }}
                          />
                        </div>
                        <span className="font-mono text-xs text-[#636366] dark:text-[#8E8E93]">
                          {log.consistencyScore}%
                        </span>
                      </div>
                    </td>
                    <td className="py-3.5 px-4 font-mono text-xs">
                      {log.snoozeCount === 0 ? (
                        <span className="text-[#636366] dark:text-[#8E8E93]">0</span>
                      ) : (
                        <span className="font-semibold text-[#B25000] dark:text-[#FF9F0A]">
                          {log.snoozeCount}x ({log.snoozeCount * 9}m)
                        </span>
                      )}
                    </td>
                    <td className="py-3.5 px-4">{getStatusBadge(log.status)}</td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination Controls */}
      <div className="p-3.5 border-t border-zinc-200 dark:border-zinc-800 flex flex-wrap items-center justify-between gap-2 text-xs text-[#636366] dark:text-[#8E8E93] font-medium">
        <div>
          Página {currentPage} de {totalPages} ({filteredLogs.length} registros)
        </div>
        <div className="flex items-center gap-1.5">
          <button
            type="button"
            onClick={() => handlePageChange(1)}
            disabled={currentPage === 1}
            title="Primera página"
            aria-label="Primera página"
            className="min-w-[44px] min-h-[44px] flex items-center justify-center rounded-xl border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-100 dark:hover:bg-zinc-800 disabled:opacity-30 disabled:cursor-not-allowed transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
          >
            <ChevronsLeft className="w-4 h-4 text-zinc-700 dark:text-zinc-300" />
          </button>
          <button
            type="button"
            onClick={() => handlePageChange(currentPage - 1)}
            disabled={currentPage === 1}
            title="Página anterior"
            aria-label="Página anterior"
            className="min-w-[44px] min-h-[44px] flex items-center justify-center rounded-xl border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-100 dark:hover:bg-zinc-800 disabled:opacity-30 disabled:cursor-not-allowed transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
          >
            <ChevronLeft className="w-4 h-4 text-zinc-700 dark:text-zinc-300" />
          </button>
          <button
            type="button"
            onClick={() => handlePageChange(currentPage + 1)}
            disabled={currentPage === totalPages}
            title="Página siguiente"
            aria-label="Página siguiente"
            className="min-w-[44px] min-h-[44px] flex items-center justify-center rounded-xl border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-100 dark:hover:bg-zinc-800 disabled:opacity-30 disabled:cursor-not-allowed transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
          >
            <ChevronRight className="w-4 h-4 text-zinc-700 dark:text-zinc-300" />
          </button>
          <button
            type="button"
            onClick={() => handlePageChange(totalPages)}
            disabled={currentPage === totalPages}
            title="Última página"
            aria-label="Última página"
            className="min-w-[44px] min-h-[44px] flex items-center justify-center rounded-xl border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-100 dark:hover:bg-zinc-800 disabled:opacity-30 disabled:cursor-not-allowed transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]"
          >
            <ChevronsRight className="w-4 h-4 text-zinc-700 dark:text-zinc-300" />
          </button>
        </div>
      </div>
    </div>
  );
};
