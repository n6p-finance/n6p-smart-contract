import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { useSearchParams } from 'next/navigation';
import VerifyPage from '../page';

// Mock the next/navigation module
jest.mock('next/navigation', () => ({
  useSearchParams: jest.fn(),
}));

// Mock the MCPVerification component
jest.mock('@/components/mcp/MCPVerification', () => (
  { decisionId, signature }: { decisionId: string; signature: string }
) => (
  <div data-testid="mcp-verification">
    Verification for ID: {decisionId}
    <div data-testid="signature">{signature}</div>
  </div>
));

// Mock window.history.pushState
const mockPushState = jest.fn();
Object.defineProperty(window, 'history', {
  writable: true,
  value: { pushState: mockPushState }
});

// Mock URL constructor
global.URL = jest.fn(() => ({
  searchParams: {
    set: jest.fn()
  }
})) as any;

describe('Verify Page', () => {
  // Mock implementation for useSearchParams
  const mockGet = jest.fn();
  const mockSearchParams = { get: mockGet };

  beforeEach(() => {
    jest.clearAllMocks();
    (useSearchParams as jest.Mock).mockReturnValue(mockSearchParams);
  });

  test('renders the verify form when no params are provided', () => {
    // No params in URL
    mockGet.mockImplementation(() => null);
    
    render(<VerifyPage />);
    
    // Check if the page title is rendered
    expect(screen.getByText('MCP Decision Verification')).toBeInTheDocument();
    
    // Check if the form is rendered
    expect(screen.getByText('Verify Decision')).toBeInTheDocument();
    expect(screen.getByLabelText('Decision ID')).toBeInTheDocument();
    expect(screen.getByLabelText('Signature')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Verify Decision' })).toBeInTheDocument();
    
    // Check if the about section is rendered
    expect(screen.getByText('About MCP Verification')).toBeInTheDocument();
    expect(screen.getByText(/The Model Context Protocol \(MCP\) ensures transparency/)).toBeInTheDocument();
  });

  test('renders the MCPVerification component when params are provided', () => {
    // Set params in URL
    mockGet.mockImplementation((param) => {
      if (param === 'id') return '0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234';
      if (param === 'signature') return '0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef';
      return null;
    });
    
    render(<VerifyPage />);
    
    // Check if the MCPVerification component is rendered
    expect(screen.getByTestId('mcp-verification')).toBeInTheDocument();
    expect(screen.getByText('Verification for ID: 0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234')).toBeInTheDocument();
    expect(screen.getByTestId('signature')).toHaveTextContent('0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef');
    
    // Form should not be rendered
    expect(screen.queryByLabelText('Decision ID')).not.toBeInTheDocument();
    expect(screen.queryByLabelText('Signature')).not.toBeInTheDocument();
  });

  test('allows entering decision ID and signature', () => {
    // No params in URL
    mockGet.mockImplementation(() => null);
    
    render(<VerifyPage />);
    
    // Get the input fields
    const decisionIdInput = screen.getByLabelText('Decision ID');
    const signatureInput = screen.getByLabelText('Signature');
    
    // Enter values
    fireEvent.change(decisionIdInput, { target: { value: '0x123456789abcdef' } });
    fireEvent.change(signatureInput, { target: { value: '0xabcdef123456789' } });
    
    // Check if the values are updated
    expect(decisionIdInput).toHaveValue('0x123456789abcdef');
    expect(signatureInput).toHaveValue('0xabcdef123456789');
  });

  test('updates URL when verify button is clicked', () => {
    // No params in URL
    mockGet.mockImplementation(() => null);
    
    render(<VerifyPage />);
    
    // Get the input fields and button
    const decisionIdInput = screen.getByLabelText('Decision ID');
    const signatureInput = screen.getByLabelText('Signature');
    const verifyButton = screen.getByRole('button', { name: 'Verify Decision' });
    
    // Enter values
    fireEvent.change(decisionIdInput, { target: { value: '0x123456789abcdef' } });
    fireEvent.change(signatureInput, { target: { value: '0xabcdef123456789' } });
    
    // Click the verify button
    fireEvent.click(verifyButton);
    
    // Check if window.history.pushState was called
    expect(mockPushState).toHaveBeenCalled();
  });

  test('does not update URL when fields are empty', () => {
    // No params in URL
    mockGet.mockImplementation(() => null);
    
    render(<VerifyPage />);
    
    // Get the verify button
    const verifyButton = screen.getByRole('button', { name: 'Verify Decision' });
    
    // Click the verify button without entering values
    fireEvent.click(verifyButton);
    
    // Check if window.history.pushState was not called
    expect(mockPushState).not.toHaveBeenCalled();
  });
});
