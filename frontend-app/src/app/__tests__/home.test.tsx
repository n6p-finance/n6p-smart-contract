import React from 'react';
import { render, screen } from '@testing-library/react';
import Home from '../page';

// Mock the Dashboard component
jest.mock('@/components/Dashboard', () => () => (
  <div data-testid="mock-dashboard">Mocked Dashboard Component</div>
));

describe('Home Page', () => {
  test('renders the Dashboard component', () => {
    render(<Home />);
    
    // Check if the Dashboard component is rendered
    const dashboardElement = screen.getByTestId('mock-dashboard');
    expect(dashboardElement).toBeInTheDocument();
    expect(dashboardElement).toHaveTextContent('Mocked Dashboard Component');
  });
});
