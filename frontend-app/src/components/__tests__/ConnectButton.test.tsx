import React from 'react';
import { render, screen } from '@testing-library/react';
import ConnectButton from '../ConnectButton';

// The RainbowKit imports are automatically mocked
// based on our jest.config.js and the mock files we created

describe('ConnectButton', () => {
  test('renders chain and account info when connected', () => {
    render(<ConnectButton />);
    
    // Check if the chain name is displayed
    expect(screen.getByText('Ethereum')).toBeInTheDocument();
    
    // Check if the account address is displayed
    expect(screen.getByText('0x1234...7890')).toBeInTheDocument();
  });

  test('renders buttons with correct styling', () => {
    render(<ConnectButton />);
    
    // Check if the buttons have the correct styling classes
    const chainButton = screen.getByText('Ethereum').closest('button');
    expect(chainButton).toHaveClass('bg-gray-100');
    expect(chainButton).toHaveClass('hover:bg-gray-200');
    
    const accountButton = screen.getByText('0x1234...7890').closest('button');
    expect(accountButton).toHaveClass('bg-blue-600');
    expect(accountButton).toHaveClass('hover:bg-blue-700');
  });
});
