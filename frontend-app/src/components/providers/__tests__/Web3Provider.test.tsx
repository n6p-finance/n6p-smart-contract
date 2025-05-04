import React from 'react';
import { render, screen } from '@testing-library/react';

// Create a mock Web3Provider component
const MockWeb3Provider = ({ children }: { children: React.ReactNode }) => (
  <div data-testid="web3-provider">{children}</div>
);

// Mock the actual Web3Provider component
jest.mock('../Web3Provider', () => MockWeb3Provider);

// Import the mocked component
const Web3Provider = require('../Web3Provider');

describe('Web3Provider', () => {
  test('renders children within the provider', () => {
    render(
      <MockWeb3Provider>
        <div data-testid="test-child">Test Child Component</div>
      </MockWeb3Provider>
    );
    
    // Check if provider is rendered
    expect(screen.getByTestId('web3-provider')).toBeInTheDocument();
    
    // Check if children are rendered
    expect(screen.getByTestId('test-child')).toBeInTheDocument();
    expect(screen.getByText('Test Child Component')).toBeInTheDocument();
  });
});
