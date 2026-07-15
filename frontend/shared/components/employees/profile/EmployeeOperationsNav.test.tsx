import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter, useLocation } from 'react-router-dom';

import { EmployeeOperationsNav } from './EmployeeOperationsNav';

function LocationProbe() {
  const location = useLocation();
  return <output data-testid="location">{`${location.pathname}${location.search}`}</output>;
}

describe('EmployeeOperationsNav', () => {
  it('opens the employee orders grid with the employee search applied', () => {
    render(
      <MemoryRouter initialEntries={['/employees']}>
        <EmployeeOperationsNav employeeName="أحمد محمد" activeTab="orders" />
        <LocationProbe />
      </MemoryRouter>,
    );

    expect(screen.queryByRole('button', { name: /الرواتب/ })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /السلف/ })).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /فتح صفحة الطلبات/ }));

    expect(screen.getByTestId('location')).toHaveTextContent(
      `/orders?tab=grid&search=${encodeURIComponent('أحمد محمد')}`,
    );
  });

  it('shows only the independent vehicle assignment action on unrelated tabs', () => {
    render(
      <MemoryRouter>
        <EmployeeOperationsNav employeeName="أحمد محمد" activeTab="overview" />
      </MemoryRouter>,
    );

    expect(screen.getByRole('button', { name: /العهدة/ })).toBeInTheDocument();
    expect(screen.getAllByRole('button')).toHaveLength(1);
  });
});
