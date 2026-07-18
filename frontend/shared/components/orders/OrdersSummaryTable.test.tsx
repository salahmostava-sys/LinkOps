import { render, screen, fireEvent } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { OrdersSummaryTable } from './OrdersSummaryTable';

vi.mock('@shared/hooks/useAppColors', () => ({
  getAppColor: () => ({ bg: '#ff660022', val: '#ff6600' }),
}));

describe('OrdersSummaryTable', () => {
  it('renders employee row and supports sorting callback', () => {
    const onSort = vi.fn();

    render(
      <OrdersSummaryTable
        loading={false}
        apps={[{ id: 'app-1', name: 'Talabat' }]}
        appColorsList={[
          {
            id: 'app-1',
            name: 'Talabat',
            brand_color: '#ff6600',
            text_color: '#ffffff',
            is_active: true,
            custom_columns: [],
          },
        ]}
        sortedEmployees={[{ id: 'emp-1', name: 'Ahmed Ali' }]}
        employeesCount={1}
        data={{ 'emp-1::app-1::1': 12 }}
        dayArr={[1]}
        empTotal={() => 12}
        appGrandTotal={() => 12}
        grandTotal={12}
        shortName={(v) => v}
        sortField="name"
        sortDir="asc"
        onSort={onSort}
      />
    );

    expect(screen.getByText('Ahmed Ali')).toBeInTheDocument();
    expect(screen.getAllByText('12').length).toBeGreaterThan(0);

    fireEvent.click(screen.getByText(/المندوب/i));
    expect(onSort).toHaveBeenCalled();
  });

  it('renders loading skeleton rows', () => {
    const { container } = render(
      <OrdersSummaryTable
        loading
        apps={[{ id: 'app-1', name: 'Talabat' }]}
        appColorsList={[]}
        sortedEmployees={[]}
        employeesCount={0}
        data={{}}
        dayArr={[1]}
        empTotal={() => 0}
        appGrandTotal={() => 0}
        grandTotal={0}
        shortName={(v) => v}
        sortField="name"
        sortDir="asc"
        onSort={vi.fn()}
      />
    );

    expect(container.querySelectorAll('.animate-pulse').length).toBeGreaterThan(0);
  });

  it('calculates the daily average from days with orders and counts a multi-platform day once', () => {
    render(
      <OrdersSummaryTable
        loading={false}
        apps={[
          { id: 'app-1', name: 'Keeta' },
          { id: 'app-2', name: 'HungerStation' },
        ]}
        appColorsList={[]}
        sortedEmployees={[{ id: 'emp-1', name: 'Ahmed Ali' }]}
        employeesCount={1}
        data={{
          'emp-1::app-1::1': 10,
          'emp-1::app-2::1': 5,
          'emp-1::app-1::2': 0,
          'emp-1::app-2::3': 15,
        }}
        dayArr={[1, 2, 3]}
        empTotal={() => 30}
        appGrandTotal={(appId) => appId === 'app-1' ? 10 : 20}
        grandTotal={30}
        shortName={(value) => value}
        sortField="name"
        sortDir="asc"
        onSort={vi.fn()}
      />
    );

    const averageHeader = screen.getByText('متوسط يومي');
    const averageColumnIndex = (averageHeader.closest('th')?.cellIndex ?? 1) + 1;
    const employeeRow = screen.getByText('Ahmed Ali').closest('tr');
    expect(employeeRow?.querySelector(`td:nth-child(${averageColumnIndex})`)).toHaveTextContent('15');
    expect(employeeRow).toHaveTextContent('متوسط');
  });
});
