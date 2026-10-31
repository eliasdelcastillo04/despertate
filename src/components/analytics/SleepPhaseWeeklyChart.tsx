import React from 'react';
import ReactECharts from 'echarts-for-react';
import { WakeLog } from '../../types/alarm';

interface SleepPhaseWeeklyChartProps {
  logs: WakeLog[];
  isDarkMode: boolean;
}

export const SleepPhaseWeeklyChart: React.FC<SleepPhaseWeeklyChartProps> = ({
  logs,
  isDarkMode,
}) => {
  const recentLogs = [...logs].slice(-7);
  const categories = recentLogs.map((l) => l.targetDate.slice(5));
  const sleepHours = recentLogs.map((l) => l.sleepHours);

  const option = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      backgroundColor: isDarkMode ? 'rgba(28, 28, 30, 0.95)' : 'rgba(255, 255, 255, 0.95)',
      borderColor: isDarkMode ? '#3A3A3C' : '#E5E5EA',
      textStyle: {
        color: isDarkMode ? '#FFFFFF' : '#1C1C1E',
        fontFamily: '-apple-system, SF Pro Text, sans-serif',
      },
      formatter: (params: Array<{ name: string; value: number }>) => {
        const item = params[0];
        return `<div style="font-weight:600;margin-bottom:4px;">${item?.name}</div>
          <div style="font-size:12px;">Horas dormidas: <b>${item?.value}h</b> (Meta: 8.0h)</div>`;
      },
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '6%',
      top: '12%',
      containLabel: true,
    },
    xAxis: {
      type: 'category',
      data: categories,
      axisLine: {
        lineStyle: { color: isDarkMode ? '#3A3A3C' : '#E5E5EA' },
      },
      axisLabel: {
        color: isDarkMode ? '#8E8E93' : '#636366',
        fontSize: 11,
      },
    },
    yAxis: {
      type: 'value',
      name: 'Horas',
      min: 4,
      max: 10,
      splitLine: {
        lineStyle: {
          color: isDarkMode ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.05)',
        },
      },
      axisLabel: {
        color: isDarkMode ? '#8E8E93' : '#636366',
        fontSize: 11,
      },
    },
    series: [
      {
        name: 'Horas de Sueño',
        type: 'bar',
        data: sleepHours,
        barWidth: '40%',
        itemStyle: {
          color: {
            type: 'linear',
            x: 0,
            y: 0,
            x2: 0,
            y2: 1,
            colorStops: [
              { offset: 0, color: '#34C759' },
              { offset: 1, color: '#30B0C7' },
            ],
          },
          borderRadius: [6, 6, 0, 0],
        },
        markLine: {
          symbol: 'none',
          data: [{ yAxis: 8, name: 'Meta 8h' }],
          lineStyle: {
            type: 'dashed',
            color: '#AF52DE',
            width: 1.5,
          },
          label: {
            formatter: 'Meta: 8h',
            position: 'end',
            color: '#AF52DE',
            fontSize: 10,
          },
        },
      },
    ],
  };

  return (
    <div className="w-full h-[280px]">
      <ReactECharts option={option} style={{ height: '100%', width: '100%' }} />
    </div>
  );
};
