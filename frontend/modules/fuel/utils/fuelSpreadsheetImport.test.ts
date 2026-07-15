import { describe, expect, it } from 'vitest';
import { buildFuelMetricTemplateRows } from './fuelSpreadsheetImport';

describe('buildFuelMetricTemplateRows', () => {
  it('prefills one blank daily row for every rider name', () => {
    expect(buildFuelMetricTemplateRows(
      [1, 2, 3],
      [{ name: 'أحمد محمد' }, { name: 'خالد علي' }],
    )).toEqual([
      ['اسم المندوب', 'اليوم 1', 'اليوم 2', 'اليوم 3'],
      ['أحمد محمد', '', '', ''],
      ['خالد علي', '', '', ''],
    ]);
  });
});
