import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import StrategiesPage from '../page';

describe('Strategies Page', () => {
  test('renders the strategies page with title and description', () => {
    render(<StrategiesPage />);
    
    // Check if the page title is rendered
    expect(screen.getByText('Available Strategies')).toBeInTheDocument();
    
    // Check if the page description is rendered
    expect(screen.getByText(/NapFi AI automatically allocates your funds/)).toBeInTheDocument();
  });
  
  test('renders all strategy cards', () => {
    render(<StrategiesPage />);
    
    // Check if all strategy names are rendered
    expect(screen.getByText('Aave Lending')).toBeInTheDocument();
    expect(screen.getByText('Compound Lending')).toBeInTheDocument();
    expect(screen.getByText('Curve Stablecoin LP')).toBeInTheDocument();
    expect(screen.getByText('Uniswap V3 LP')).toBeInTheDocument();
    expect(screen.getByText('Lido Staking')).toBeInTheDocument();
    expect(screen.getByText('Yearn Vaults')).toBeInTheDocument();
    
    // Check if all strategy descriptions are rendered
    expect(screen.getByText('Deposit assets into Aave lending pools to earn interest from borrowers.')).toBeInTheDocument();
    expect(screen.getByText('Supply assets to Compound protocol to earn interest and COMP tokens.')).toBeInTheDocument();
    
    // Check if APY values are rendered
    expect(screen.getByText('4.2%')).toBeInTheDocument();
    expect(screen.getByText('3.8%')).toBeInTheDocument();
    expect(screen.getByText('5.1%')).toBeInTheDocument();
    expect(screen.getByText('8.5%')).toBeInTheDocument();
    expect(screen.getByText('3.9%')).toBeInTheDocument();
    expect(screen.getByText('6.7%')).toBeInTheDocument();
    
    // Check if risk levels are rendered
    expect(screen.getAllByText('Low').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Medium').length).toBeGreaterThan(0);
    expect(screen.getByText('Medium-High')).toBeInTheDocument();
    
    // Check if TVL values are rendered
    expect(screen.getByText('$1.2B')).toBeInTheDocument();
    expect(screen.getByText('$890M')).toBeInTheDocument();
    expect(screen.getByText('$450M')).toBeInTheDocument();
    expect(screen.getByText('$320M')).toBeInTheDocument();
    expect(screen.getByText('$2.1B')).toBeInTheDocument();
    expect(screen.getByText('$580M')).toBeInTheDocument();
  });
  
  test('renders strategy cards with correct structure and styling', () => {
    const { container } = render(<StrategiesPage />);
    
    // Get all strategy cards
    const strategyCards = container.querySelectorAll('.bg-white.rounded-xl.shadow-md');
    
    // Check if there are 6 strategy cards
    expect(strategyCards.length).toBe(6);
    
    // Check the structure of the first card
    const firstCard = strategyCards[0];
    
    // Check if the card has the correct header
    const header = firstCard.querySelector('.bg-indigo-600.text-white');
    expect(header).toBeInTheDocument();
    expect(header).toHaveTextContent('Aave Lending');
    
    // Check if the card has the correct metrics grid
    const metricsGrid = firstCard.querySelector('.grid.grid-cols-3');
    expect(metricsGrid).toBeInTheDocument();
    
    // Check if the card has the allocate button
    const allocateButton = firstCard.querySelector('button');
    expect(allocateButton).toBeInTheDocument();
    expect(allocateButton).toHaveTextContent('Allocate Funds');
  });
  
  test('handles button click events', () => {
    render(<StrategiesPage />);
    
    // Get all "Allocate Funds" buttons
    const allocateButtons = screen.getAllByText('Allocate Funds');
    expect(allocateButtons.length).toBe(6);
    
    // Mock console.log to check if button clicks are handled
    const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
    
    // Click on the first button
    fireEvent.click(allocateButtons[0]);
    
    // Cleanup
    consoleSpy.mockRestore();
  });
  
  test('renders responsive grid layout', () => {
    const { container } = render(<StrategiesPage />);
    
    // Check if the grid layout has the correct responsive classes
    const gridLayout = container.querySelector('.grid');
    expect(gridLayout).toHaveClass('grid-cols-1');
    expect(gridLayout).toHaveClass('md:grid-cols-2');
    expect(gridLayout).toHaveClass('lg:grid-cols-3');
  });
});
