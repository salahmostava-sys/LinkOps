export interface RiderPredictionInput {
  riderId: string;
  riderName: string;
  ordersThisMonthSoFar: number;
  dailyOrdersLast14: number[];
  daysPassedThisMonth: number;
  daysRemainingThisMonth: number;
  ordersLastMonth: number;
  ordersMonth2Ago: number;
  ordersMonth3Ago: number;
  ordersSameMonthLastYear: number;
}

type TrendDirection = 'up' | 'down' | 'stable';
type ConfidenceLevel = 'high' | 'medium' | 'low';

export interface RiderPrediction {
  riderId: string;
  riderName: string;
  predictedTotal: number;
  ordersThisMonthSoFar: number;
  remainingPredicted: number;
  progressPercent: number;
  vsLastMonth: number;
  vsLastMonthPercent: number;
  vs3MonthAvg: number;
  dailyAvgLast14: number;
  dailyAvgLast7: number;
  dailyAvgPrev7: number;
  trend: TrendDirection;
  trendPercent: number;
  confidence: ConfidenceLevel;
  confidenceReason: string;
}

function getTrend(trendPercent: number): TrendDirection {
  if (trendPercent > 5) return 'up';
  if (trendPercent < -5) return 'down';
  return 'stable';
}

function getConfidenceLevel(last14Length: number, ordersMonth3Ago: number): ConfidenceLevel {
  if (last14Length >= 14 && ordersMonth3Ago > 0) return 'high';
  if (last14Length >= 7) return 'medium';
  return 'low';
}

function getConfidenceReasonText(confidence: ConfidenceLevel): string {
  if (confidence === 'high') return 'بيانات كافية (14 يوم + 3 شهور)';
  if (confidence === 'medium') return 'بيانات جزئية (أقل من 14 يوم)';
  return 'بيانات غير كافية للتنبؤ الدقيق';
}

export function predictRiderMonth(input: RiderPredictionInput): RiderPrediction {
  const avg = (arr: number[]) =>
    arr.length > 0 ? arr.reduce((a, b) => a + b, 0) / arr.length : 0;

  const last14 = input.dailyOrdersLast14.slice(-14);
  const last7 = input.dailyOrdersLast14.slice(-7);
  const prev7 = input.dailyOrdersLast14.slice(-14, -7);

  const dailyAvgLast14 = avg(last14);
  const dailyAvgLast7 = avg(last7);
  const dailyAvgPrev7 = avg(prev7);

  const projected = dailyAvgLast14 * input.daysRemainingThisMonth;
  const fullMonthFromRecent = input.ordersThisMonthSoFar + projected;
  const threeMonthAvg =
    (input.ordersLastMonth + input.ordersMonth2Ago + input.ordersMonth3Ago) / 3;

  const seasonalFactor =
    input.ordersSameMonthLastYear > 0 && threeMonthAvg > 0
      ? Math.min(Math.max(input.ordersSameMonthLastYear / threeMonthAvg, 0.7), 1.3)
      : 1;

  const predictedTotal = Math.round(
    fullMonthFromRecent * 0.4 +
      threeMonthAvg * 0.35 * seasonalFactor +
      input.ordersLastMonth * 0.25
  );

  const trendPercent =
    dailyAvgPrev7 > 0 ? ((dailyAvgLast7 - dailyAvgPrev7) / dailyAvgPrev7) * 100 : 0;
  const trend = getTrend(trendPercent);

  const confidence = getConfidenceLevel(last14.length, input.ordersMonth3Ago);
  const confidenceReason = getConfidenceReasonText(confidence);

  const vsLastMonth = predictedTotal - input.ordersLastMonth;
  const vsLastMonthPercent =
    input.ordersLastMonth > 0 ? Math.round((vsLastMonth / input.ordersLastMonth) * 100) : 0;

  return {
    riderId: input.riderId,
    riderName: input.riderName,
    predictedTotal,
    ordersThisMonthSoFar: input.ordersThisMonthSoFar,
    remainingPredicted: Math.max(predictedTotal - input.ordersThisMonthSoFar, 0),
    progressPercent:
      predictedTotal > 0 ? Math.min(Math.round((input.ordersThisMonthSoFar / predictedTotal) * 100), 100) : 0,
    vsLastMonth,
    vsLastMonthPercent,
    vs3MonthAvg: Math.round(predictedTotal - threeMonthAvg),
    dailyAvgLast14: Math.round(dailyAvgLast14 * 10) / 10,
    dailyAvgLast7: Math.round(dailyAvgLast7 * 10) / 10,
    dailyAvgPrev7: Math.round(dailyAvgPrev7 * 10) / 10,
    trend,
    trendPercent: Math.round(trendPercent),
    confidence,
    confidenceReason,
  };
}
