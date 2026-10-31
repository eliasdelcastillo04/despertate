import React from 'react';

export interface SegmentOption<T extends string> {
  value?: T;
  id?: T;
  label: string;
  icon?: React.ReactNode | React.ComponentType<{ className?: string }>;
}

interface CupertinoSegmentedControlProps<T extends string> {
  options: SegmentOption<T>[];
  value?: T;
  selectedId?: T;
  onChange: (value: T) => void;
  className?: string;
}

export function CupertinoSegmentedControl<T extends string>({
  options,
  value,
  selectedId,
  onChange,
  className = '',
}: CupertinoSegmentedControlProps<T>) {
  const activeValue = value ?? selectedId ?? ((options[0]?.value ?? options[0]?.id) as T);

  const handleKeyDown = (e: React.KeyboardEvent, currentIndex: number) => {
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
      e.preventDefault();
      const nextIndex = (currentIndex + 1) % options.length;
      const nextVal = (options[nextIndex].value ?? options[nextIndex].id) as T;
      onChange(nextVal);
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
      e.preventDefault();
      const prevIndex = (currentIndex - 1 + options.length) % options.length;
      const prevVal = (options[prevIndex].value ?? options[prevIndex].id) as T;
      onChange(prevVal);
    } else if (e.key === 'Home') {
      e.preventDefault();
      const firstVal = (options[0].value ?? options[0].id) as T;
      onChange(firstVal);
    } else if (e.key === 'End') {
      e.preventDefault();
      const lastVal = (options[options.length - 1].value ?? options[options.length - 1].id) as T;
      onChange(lastVal);
    }
  };

  const renderIcon = (icon?: React.ReactNode | React.ComponentType<{ className?: string }>) => {
    if (!icon) return null;
    if (React.isValidElement(icon)) return icon;
    if (typeof icon === 'function' || (typeof icon === 'object' && icon !== null && 'render' in (icon as any))) {
      const IconComp = icon as React.ComponentType<{ className?: string }>;
      return <IconComp className="w-4 h-4" />;
    }
    return null;
  };

  return (
    <div
      role="tablist"
      aria-orientation="horizontal"
      className={`inline-flex items-center p-1 rounded-xl bg-zinc-200/70 dark:bg-zinc-800/80 backdrop-blur-md border border-black/5 dark:border-white/5 ${className}`}
    >
      {options.map((opt, idx) => {
        const optVal = (opt.value ?? opt.id) as T;
        const isActive = optVal === activeValue;
        return (
          <button
            key={optVal || idx}
            role="tab"
            aria-selected={isActive}
            tabIndex={isActive ? 0 : -1}
            onClick={() => onChange(optVal)}
            onKeyDown={(e) => handleKeyDown(e, idx)}
            className={`
              relative flex items-center justify-center gap-1.5 px-3.5 py-2 min-h-[44px] text-xs sm:text-sm font-medium rounded-lg transition-all duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF]
              ${
                isActive
                  ? 'bg-white dark:bg-[#2C2C2E] text-zinc-950 dark:text-white shadow-sm font-semibold'
                  : 'text-[#636366] dark:text-[#8E8E93] hover:text-zinc-900 dark:hover:text-zinc-200'
              }
            `}
          >
            {opt.icon && <span className="w-4 h-4 flex items-center justify-center">{renderIcon(opt.icon)}</span>}
            <span>{opt.label}</span>
          </button>
        );
      })}
    </div>
  );
}
