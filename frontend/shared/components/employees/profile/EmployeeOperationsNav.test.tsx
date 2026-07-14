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
        <EmployeeOperationsNav employeeName="أحمد محمد" />
        <LocationProbe />
      </MemoryRouter>,
    );

    fireEvent.click(screen.getByRole('button', { name: /الطلبات/ }));

    expect(screen.getByTestId('location')).toHaveTextContent(
      `/orders?tab=grid&search=${encodeURIComponent('أحمد محمد')}`,
    );
  });
});
