import React from 'react';
import { render, screen, fireEvent, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import MCPVerification from '../MCPVerification';
import { useReadContract } from 'wagmi';

// Mock wagmi hooks
jest.mock('wagmi', () => ({
  useReadContract: jest.fn(),
}));

// Mock contract addresses
jest.mock('@/config/web3', () => ({
  CONTRACT_ADDRESSES: {
    aiDecisionModule: '0x1234567890123456789012345678901234567890',
  },
}));

describe('MCPVerification', () => {
  // Sample props
  const mockProps = {
    decisionId: '0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234',
    signature: '0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef',
  };

  // Reset mocks before each test
  beforeEach(() => {
    jest.clearAllMocks();
    // Reset timers
    jest.useRealTimers();
  });

  test('renders initial state correctly', () => {
    render(<MCPVerification {...mockProps} />);
    
    // Check if component renders with correct data
    expect(screen.getByText(/Verify Decision Authenticity/i)).toBeInTheDocument();
    expect(screen.getByText(mockProps.decisionId)).toBeInTheDocument();
    expect(screen.getByText(mockProps.signature)).toBeInTheDocument();
    
    // Check if verify button is present
    expect(screen.getByText(/Verify Signature/i)).toBeInTheDocument();
  });

  test('shows verifying state when button is clicked', async () => {
    // Use fake timers to control setTimeout
    jest.useFakeTimers();
    
    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });
    render(<MCPVerification {...mockProps} />);
    
    // Click the verify button
    await user.click(screen.getByText(/Verify Signature/i));
    
    // Check if verifying state is shown
    expect(screen.getByText(/Verifying signature\.\.\./i)).toBeInTheDocument();
  });

  test('shows verified state after verification completes', async () => {
    // Use fake timers to control setTimeout
    jest.useFakeTimers();
    
    render(<MCPVerification {...mockProps} />);
    
    // Click the verify button
    fireEvent.click(screen.getByText(/Verify Signature/i));
    
    // Use act to wrap the timer advancement
    await act(async () => {
      // Fast-forward timers
      jest.advanceTimersByTime(2000);
    });
    
    // Check if verified state is shown (now outside of waitFor since act handled the async updates)
    expect(screen.getByText(/Verification Successful/i)).toBeInTheDocument();
    expect(screen.getByText(/Signature verified by MCP Oracle/i)).toBeInTheDocument();
  });

  test('handles custom aiDecisionModuleAddress prop', () => {
    const customAddress = '0x9876543210987654321098765432109876543210';
    render(
      <MCPVerification 
        {...mockProps} 
        aiDecisionModuleAddress={customAddress} 
      />
    );
    
    // Component should render normally with custom address
    expect(screen.getByText(/Verify Decision Authenticity/i)).toBeInTheDocument();
    expect(screen.getByText(/Verify Signature/i)).toBeInTheDocument();
  });
});
