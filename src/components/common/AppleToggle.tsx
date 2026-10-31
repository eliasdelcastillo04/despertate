import React from 'react';

interface AppleToggleProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  disabled?: boolean;
  label?: string;
}

export const AppleToggle: React.FC<AppleToggleProps> = ({
  checked,
  onChange,
  disabled = false,
  label,
}) => {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label || 'Interruptor'}
      disabled={disabled}
      onClick={(e) => {
        e.stopPropagation();
        if (!disabled) onChange(!checked);
      }}
      className={`
        relative inline-flex items-center justify-center min-w-[51px] min-h-[44px] shrink-0 cursor-pointer p-0 bg-transparent border-0
        focus:outline-none focus-visible:ring-2 focus-visible:ring-[#007AFF] rounded-full
        ${disabled ? 'opacity-40 cursor-not-allowed' : ''}
      `}
    >
      <span
        aria-hidden="true"
        className={`
          relative inline-flex items-center justify-start h-[31px] w-[51px] shrink-0 rounded-full p-[2px]
          transition-colors duration-250 ease-in-out
          ${checked ? 'bg-[#34C759]' : 'bg-[#E9E9EB] dark:bg-[#39393D]'}
        `}
      >
        <span
          className={`
            pointer-events-none inline-block h-[27px] w-[27px] transform rounded-full bg-white shadow-[0_3px_8px_rgba(0,0,0,0.15),0_1px_1px_rgba(0,0,0,0.16)]
            ring-0 transition-transform duration-250 cubic-bezier(0.2,0.8,0.2,1)
            ${checked ? 'translate-x-[20px]' : 'translate-x-0'}
          `}
        />
      </span>
    </button>
  );
};
