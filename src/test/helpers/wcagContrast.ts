/**
 * WCAG 2.1 AA Contrast Ratio Calculator
 * Reference: https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
 */

function hexToRgb(hex: string): [number, number, number] {
  let clean = hex.replace('#', '');
  if (clean.length === 3) {
    clean = clean.split('').map((c) => c + c).join('');
  }
  const num = parseInt(clean, 16);
  return [(num >> 16) & 255, (num >> 8) & 255, num & 255];
}

function getChannelLuminance(val: number): number {
  const srgb = val / 255;
  return srgb <= 0.03928 ? srgb / 12.92 : Math.pow((srgb + 0.055) / 1.055, 2.4);
}

export function getRelativeLuminance(hex: string): number {
  const [r, g, b] = hexToRgb(hex);
  return (
    0.2126 * getChannelLuminance(r) +
    0.7152 * getChannelLuminance(g) +
    0.0722 * getChannelLuminance(b)
  );
}

export function getContrastRatio(foregroundHex: string, backgroundHex: string): number {
  const l1 = getRelativeLuminance(foregroundHex);
  const l2 = getRelativeLuminance(backgroundHex);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

export function meetsWcagAA(
  foregroundHex: string,
  backgroundHex: string,
  isLargeText = false
): boolean {
  const ratio = getContrastRatio(foregroundHex, backgroundHex);
  return isLargeText ? ratio >= 3.0 : ratio >= 4.5;
}
