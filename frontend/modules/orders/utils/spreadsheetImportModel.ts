import type { App, DailyData } from '@modules/orders/types';
import { ImportFactory } from './import/importFactory';
import { MatrixImportStrategy } from './import/matrixStrategy';
import {
  type AppEmployeeIdsMap,
  type SpreadsheetMergeResult,
  type ImportTargetResolution,
  getEmployeeAssignedApps,
  clearEmployeeAppMonthData,
  resolveImportTargetAppsForEmployee,
  validateCellValue,
} from './import/sharedTypes';

export type { AppEmployeeIdsMap, SpreadsheetMergeResult, ImportTargetResolution };
export {
  getEmployeeAssignedApps,
  clearEmployeeAppMonthData,
  resolveImportTargetAppsForEmployee,
  validateCellValue,
};



export function mergeImportedOrdersFromMatrixWithMapping(params: {
  headerRow?: string[];
  matrixRows: unknown[][];
  dayArr: number[];
  apps: App[];
  prev: DailyData;
  targetAppId?: string;
  nameMapping: Map<string, string>;
  appEmployeeIds: AppEmployeeIdsMap;
}): SpreadsheetMergeResult {
  const { headerRow = [], matrixRows, dayArr, apps, prev, targetAppId, nameMapping, appEmployeeIds } = params;

  const imported = 0;
  const skipped = 0;
  const errors: string[] = [];
  const newData = { ...prev };

  if (apps.length === 0) {
    errors.push('لا توجد منصات طلبات نشطة');
    return { newData, imported, skipped, errors };
  }

  // If we don't have headerRow (e.g. from old code calling without it), we assume Matrix
  // Otherwise we let Factory detect it, fallback to Matrix if undetected for backward compatibility
  let strategy = ImportFactory.detectStrategy(headerRow);
  strategy ??= new MatrixImportStrategy();

  return strategy.parse({
    matrixRows,
    dayArr,
    apps,
    prev,
    targetAppId,
    nameMapping,
    appEmployeeIds,
  });
}
