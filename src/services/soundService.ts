import { AlarmSound } from '../types/alarm';

class SoundService {
  private audioCtx: AudioContext | null = null;
  private activeOscillators: OscillatorNode[] = [];
  private isPlaying = false;
  private intervalId: number | null = null;

  private initContext() {
    if (!this.audioCtx) {
      const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      this.audioCtx = new AudioContextClass();
    }
    if (this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
  }

  public previewSound(sound: AlarmSound, volume = 80) {
    this.stop();
    this.initContext();
    if (!this.audioCtx) return;

    this.isPlaying = true;
    const gainValue = Math.min(1, Math.max(0, volume / 100)) * 0.35;

    switch (sound) {
      case 'radar':
        this.playRadarPattern(gainValue);
        break;
      case 'chimes':
        this.playChimesPattern(gainValue);
        break;
      case 'apex':
        this.playApexPattern(gainValue);
        break;
      case 'breeze':
        this.playBreezePattern(gainValue);
        break;
      case 'cosmic':
      default:
        this.playCosmicPattern(gainValue);
        break;
    }
  }

  private playRadarPattern(gainValue: number) {
    if (!this.audioCtx) return;
    const playBeep = () => {
      if (!this.audioCtx || !this.isPlaying) return;
      const ctx = this.audioCtx;
      const now = ctx.currentTime;

      // First pip
      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(880, now); // A5
      gain1.gain.setValueAtTime(gainValue, now);
      gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.09);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start(now);
      osc1.stop(now + 0.1);

      // Second higher pip
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.type = 'sine';
      osc2.frequency.setValueAtTime(1760, now + 0.12); // A6
      gain2.gain.setValueAtTime(gainValue * 1.1, now + 0.12);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now + 0.12);
      osc2.stop(now + 0.26);
    };

    playBeep();
    this.intervalId = window.setInterval(playBeep, 800);
  }

  private playChimesPattern(gainValue: number) {
    if (!this.audioCtx) return;
    const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
    const playChord = () => {
      if (!this.audioCtx || !this.isPlaying) return;
      const ctx = this.audioCtx;
      const now = ctx.currentTime;

      notes.forEach((freq, idx) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, now + idx * 0.15);
        gain.gain.setValueAtTime(gainValue * 0.8, now + idx * 0.15);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + idx * 0.15 + 0.7);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now + idx * 0.15);
        osc.stop(now + idx * 0.15 + 0.72);
      });
    };

    playChord();
    this.intervalId = window.setInterval(playChord, 1500);
  }

  private playApexPattern(gainValue: number) {
    if (!this.audioCtx) return;
    const playPulse = () => {
      if (!this.audioCtx || !this.isPlaying) return;
      const ctx = this.audioCtx;
      const now = ctx.currentTime;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(440, now);
      osc.frequency.exponentialRampToValueAtTime(880, now + 0.18);
      gain.gain.setValueAtTime(0.001, now);
      gain.gain.linearRampToValueAtTime(gainValue, now + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.35);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.36);
    };
    playPulse();
    this.intervalId = window.setInterval(playPulse, 700);
  }

  private playBreezePattern(gainValue: number) {
    if (!this.audioCtx) return;
    const playSweep = () => {
      if (!this.audioCtx || !this.isPlaying) return;
      const ctx = this.audioCtx;
      const now = ctx.currentTime;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(329.63, now); // E4
      osc.frequency.linearRampToValueAtTime(493.88, now + 0.4); // B4
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(gainValue * 0.9, now + 0.2);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.8);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.82);
    };
    playSweep();
    this.intervalId = window.setInterval(playSweep, 1800);
  }

  private playCosmicPattern(gainValue: number) {
    if (!this.audioCtx) return;
    const playCosmic = () => {
      if (!this.audioCtx || !this.isPlaying) return;
      const ctx = this.audioCtx;
      const now = ctx.currentTime;
      [587.33, 880].forEach((f, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(f, now + i * 0.1);
        gain.gain.setValueAtTime(gainValue * 0.4, now + i * 0.1);
        gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.1 + 0.3);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now + i * 0.1);
        osc.stop(now + i * 0.1 + 0.32);
      });
    };
    playCosmic();
    this.intervalId = window.setInterval(playCosmic, 1000);
  }

  public stop() {
    this.isPlaying = false;
    if (this.intervalId !== null) {
      window.clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.activeOscillators.forEach((osc) => {
      try {
        osc.stop();
      } catch {
        // already stopped
      }
    });
    this.activeOscillators = [];
  }
}

export const soundService = new SoundService();
