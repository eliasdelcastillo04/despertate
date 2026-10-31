import React from 'react';
import { TrendingUp, TrendingDown } from 'lucide-react';

interface KpiCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon?: React.ReactNode | React.ComponentType<{ className?: string }>;
  trend?:
    | {
        value: number | string;
        isPositive: boolean;
        label?: string;
      }
    | string;
  trendPositive?: boolean;
  accentColor?: 'blue' | 'green' | 'orange' | 'purple' | 'red' | string;
}

export const KpiCard: React.FC<KpiCardProps> = ({
  title,
  value,
  subtitle,
  icon,
  trend,
  trendPositive,
  accentColor = 'blue',
}) => {
  const getAccentClass = (accent: string) => {
    if (accent === 'orange' || accent === '#FF9500') {
      return 'text-[#B25000] dark:text-[#FF9F0A] bg-[#FF9500]/10 dark:bg-[#FF9500]/15';
    }
    if (accent === 'green' || accent === '#34C759') {
      return 'text-[#248A3D] dark:text-[#30D158] bg-[#34C759]/10 dark:bg-[#34C759]/15';
    }
    if (accent === 'purple' || accent === '#AF52DE') {
      return 'text-[#AF52DE] bg-[#AF52DE]/10 dark:bg-[#AF52DE]/15';
    }
    if (accent === 'red' || accent === '#FF3B30') {
      return 'text-[#FF3B30] bg-[#FF3B30]/10 dark:bg-[#FF3B30]/15';
    }
    return 'text-[#0062D6] dark:text-[#0A84FF] bg-[#007AFF]/10 dark:bg-[#007AFF]/15';
  };

  const renderIcon = () => {
    if (!icon) return null;
    if (React.isValidElement(icon)) return icon;
    if (typeof icon === 'function' || (typeof icon === 'object' && icon !== null && 'render' in (icon as any))) {
      const IconComp = icon as React.ComponentType<{ className?: string }>;
      return <IconComp className="w-5 h-5" />;
    }
    return null;
  };

  const hasTrend = trend !== undefined && trend !== null;
  const isPositive =
    typeof trend === 'object'
      ? trend.isPositive
      : (trendPositive ?? (typeof trend === 'string' && !trend.startsWith('-')));
  const trendValue = typeof trend === 'object' ? trend.value : trend;

  return (
    <div className="relative overflow-hidden rounded-2xl bg-white/80 dark:bg-[#1C1C1E]/80 backdrop-blur-xl border border-zinc-200/80 dark:border-zinc-800/80 p-5 shadow-apple-subtle transition-all duration-300 hover:shadow-apple-card hover:-translate-y-0.5">
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs font-semibold uppercase tracking-wider text-[#636366] dark:text-[#8E8E93]">
          {title}
        </span>
        <div className={`p-2 rounded-xl ${getAccentClass(accentColor)}`}>
          {renderIcon()}
        </div>
      </div>

      <div className="flex items-baseline justify-between gap-2">
        <span className="text-3xl font-bold font-mono tracking-tight text-zinc-950 dark:text-white">
          {value}
        </span>

        {hasTrend && (
          <div
            className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
              isPositive
                ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-400'
                : 'bg-rose-100 text-rose-800 dark:bg-rose-900/30 dark:text-rose-400'
            }`}
          >
            {isPositive ? (
              <TrendingUp className="w-3 h-3" />
            ) : (
              <TrendingDown className="w-3 h-3" />
            )}
            <span>{trendValue}</span>
          </div>
        )}
      </div>

      {subtitle && (
        <p className="mt-2 text-xs text-[#636366] dark:text-[#8E8E93] flex items-center gap-1">
          {subtitle}
        </p>
      )}
    </div>
  );
};
