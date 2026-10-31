import React from 'react';
import ReactECharts from 'echarts-for-react';
import { WakeLog } from '../../types/alarm';

interface WakeConsistencyChartProps {
  logs: WakeLog[];
  isDarkMode: boolean;
}

export const WakeConsistencyChart: React.FC<WakeConsistencyChartProps> = ({
  logs,
  isDarkMode,
}) => {
  // Sort logs by date ascending
  const sorted = [...logs].sort((a, b) => a.targetDate.localeCompare(b.targetDate));
  const dates = sorted.map((l) => l.targetDate.slice(5)); // 'MM-DD'
  const scores = sorted.map((l) => l.consistencyScore);
  const snoozes = sorted.map((l) => l.snoozeCount);

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
      formatter: (params: Array<{ seriesName: string; value: number; name: string }>) => {
        let res = `<div style="font-weight:600;margin-bottom:4px;">Fecha: ${params[0]?.name}</div>`;
        params.forEach((p) => {
          res += `<div style="display:flex;align-items:center;gap:6px;font-size:12px;">
            <span>${p.seriesName}:</span>
            <span style="font-weight:bold;font-family:JetBrains Mono;">${p.value}${p.seriesName.includes('Score') ? '%' : ''}</span>
          </div>`;
        });
        return res;
      },
    },
    legend: {
      data: ['Consistencia de Despertar', 'Snooze Realizados'],
      top: '0%',
      right: '2%',
      textStyle: {
        color: isDarkMode ? '#98989D' : '#8E8E93',
        fontSize: 12,
      },
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '5%',
      top: '15%',
      containLabel: true,
    },
    xAxis: {
      type: 'category',
      data: dates,
      axisLine: {
        lineStyle: { color: isDarkMode ? '#3A3A3C' : '#E5E5EA' },
      },
      axisLabel: {
        color: isDarkMode ? '#8E8E93' : '#636366',
        fontSize: 11,
      },
    },
    yAxis: [
      {
        type: 'value',
        name: 'Score (%)',
        min: 60,
        max: 100,
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
      {
        type: 'value',
        name: 'Snoozes',
        min: 0,
        max: 3,
        splitLine: { show: false },
        axisLabel: {
          color: isDarkMode ? '#8E8E93' : '#636366',
          fontSize: 11,
        },
      },
    ],
    series: [
      {
        name: 'Consistencia de Despertar',
        type: 'line',
        smooth: true,
        data: scores,
        itemStyle: { color: '#007AFF' },
        lineStyle: { width: 3 },
        areaStyle: {
          color: {
            type: 'linear',
            x: 0,
            y: 0,
            x2: 0,
            y2: 1,
            colorStops: [
              { offset: 0, color: 'rgba(0, 122, 255, 0.35)' },
              { offset: 1, color: 'rgba(0, 122, 255, 0.01)' },
            ],
          },
        },
      },
      {
        name: 'Snooze Realizados',
        type: 'bar',
        yAxisIndex: 1,
        data: snoozes,
        barWidth: '24%',
        itemStyle: {
          color: '#FF9500',
          borderRadius: [4, 4, 0, 0],
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
