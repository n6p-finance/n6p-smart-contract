import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { useSearchParams } from 'next/navigation';
import DecisionsPage from '../page';

// Mock the next/navigation module
jest.mock('next/navigation', () => ({
  useSearchParams: jest.fn(),
}));

// Mock the MCP components
jest.mock('@/components/mcp/MCPDecisionCard', () => ({ decisionId }: { decisionId: string }) => (
  <div data-testid="mcp-decision-card">
    Decision Card for ID: {decisionId}
  </div>
));

jest.mock('@/components/mcp/MCPVerification', () => (
  { decisionId, signature }: { decisionId: string; signature: string }
) => (
  <div data-testid="mcp-verification">
    Verification for ID: {decisionId}
    <div data-testid="signature">{signature}</div>
  </div>
));

describe('Decisions Page', () => {
  // Mock implementation for useSearchParams
  const mockGet = jest.fn();
  const mockSearchParams = { get: mockGet };

  beforeEach(() => {
    jest.clearAllMocks();
    (useSearchParams as jest.Mock).mockReturnValue(mockSearchParams);
  });

  test('renders the decisions page with default decision selected', () => {
    // No ID in URL params
    mockGet.mockReturnValue(null);
    
    render(<DecisionsPage />);
    
    // Check if the page title is rendered
    expect(screen.getByText('AI Decision History')).toBeInTheDocument();
    
    // Check if the decision list is rendered
    expect(screen.getByText('Decision History')).toBeInTheDocument();
    expect(screen.getByText('Initial allocation')).toBeInTheDocument();
    expect(screen.getByText('Rebalance due to market change')).toBeInTheDocument();
    expect(screen.getByText('Added new strategy')).toBeInTheDocument();
    
    // Check if the first decision is selected by default
    expect(screen.getByText('Initial allocation').closest('button')).toHaveClass('bg-blue-50');
    
    // Check if the MCPDecisionCard is rendered with the correct decision ID
    expect(screen.getByTestId('mcp-decision-card')).toBeInTheDocument();
    
    // Check if the MCPVerification component is rendered
    expect(screen.getByTestId('mcp-verification')).toBeInTheDocument();
  });

  test('renders the decisions page with URL-specified decision selected', () => {
    // Set ID in URL params to the second decision
    mockGet.mockReturnValue('0x234567890abcdef234567890abcdef234567890abcdef234567890abcdef2345');
    
    render(<DecisionsPage />);
    
    // Check if the second decision is selected
    expect(screen.getByText('Rebalance due to market change').closest('button')).toHaveClass('bg-blue-50');
    
    // Check if the MCPDecisionCard is rendered with the correct decision ID
    const decisionCard = screen.getByTestId('mcp-decision-card');
    expect(decisionCard).toBeInTheDocument();
    expect(decisionCard).toHaveTextContent('0x234567890abcdef234567890abcdef234567890abcdef234567890abcdef2345');
    
    // Check if the MCPVerification component is rendered with the correct signature
    const verification = screen.getByTestId('mcp-verification');
    expect(verification).toBeInTheDocument();
    expect(screen.getByTestId('signature')).toHaveTextContent('0xbcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab');
  });

  test('allows selecting a different decision', () => {
    // No ID in URL params initially
    mockGet.mockReturnValue(null);
    
    render(<DecisionsPage />);
    
    // Initially, the first decision should be selected
    expect(screen.getByText('Initial allocation').closest('button')).toHaveClass('bg-blue-50');
    
    // Click on the second decision
    fireEvent.click(screen.getByText('Rebalance due to market change'));
    
    // Now the second decision should be selected
    expect(screen.getByText('Rebalance due to market change').closest('button')).toHaveClass('bg-blue-50');
    
    // The MCPDecisionCard should be updated with the new decision ID
    const decisionCard = screen.getByTestId('mcp-decision-card');
    expect(decisionCard).toHaveTextContent('0x234567890abcdef234567890abcdef234567890abcdef234567890abcdef2345');
    
    // The MCPVerification component should be updated with the new signature
    const verification = screen.getByTestId('mcp-verification');
    expect(screen.getByTestId('signature')).toHaveTextContent('0xbcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab');
  });

  test('handles responsive layout correctly', () => {
    mockGet.mockReturnValue(null);
    
    const { container } = render(<DecisionsPage />);
    
    // Check if the grid layout has the correct responsive classes
    const gridLayout = container.querySelector('.grid');
    expect(gridLayout).toHaveClass('grid-cols-1');
    expect(gridLayout).toHaveClass('lg:grid-cols-3');
    
    // Check if the decision list has the correct column span
    const decisionList = screen.getByText('Decision History').closest('.bg-white');
    expect(decisionList?.parentElement).toHaveClass('lg:col-span-1');
    
    // Check if the decision details section has the correct column span
    const decisionDetails = screen.getByTestId('mcp-decision-card').closest('div');
    expect(decisionDetails?.parentElement).toHaveClass('lg:col-span-2');
  });
});
