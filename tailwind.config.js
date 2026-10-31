/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans: [
          "-apple-system",
          "BlinkMacSystemFont",
          "SF Pro Text",
          "SF Pro Display",
          "system-ui",
          "sans-serif"
        ],
        mono: [
          "SF Mono",
          "ui-monospace",
          "JetBrains Mono",
          "Menlo",
          "monospace"
        ],
      },
      colors: {
        apple: {
          blue: "#007AFF",
          green: "#34C759",
          indigo: "#5856D6",
          orange: "#FF9500",
          pink: "#FF2D55",
          purple: "#AF52DE",
          red: "#FF3B30",
          teal: "#30B0C7",
          yellow: "#FFCC00",
          gray: {
            1: "#8E8E93",
            2: "#AEAEB2",
            3: "#C7C7CC",
            4: "#D1D1D6",
            5: "#E5E5EA",
            6: "#F2F2F7",
          },
          dark: {
            bg: "#000000",
            surface: "#1C1C1E",
            elevated: "#2C2C2E",
            secondary: "#3A3A3C",
            separator: "rgba(84, 84, 88, 0.65)",
          }
        }
      },
      borderRadius: {
        'apple-sm': '10px',
        'apple': '14px',
        'apple-lg': '20px',
        'apple-xl': '28px',
      },
      boxShadow: {
        'apple-subtle': '0 2px 10px rgba(0, 0, 0, 0.04), 0 1px 3px rgba(0, 0, 0, 0.02)',
        'apple-card': '0 8px 30px rgba(0, 0, 0, 0.06)',
        'apple-glass': '0 8px 32px 0 rgba(0, 0, 0, 0.08)',
        'apple-popover': '0 12px 40px rgba(0, 0, 0, 0.18)',
      }
    },
  },
  plugins: [],
}
