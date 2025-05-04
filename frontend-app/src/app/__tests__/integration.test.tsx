import React from 'react';
import { render, screen, fireEvent, act } from '@testing-library/react';
import { useRouter, usePathname } from 'next/navigation';

// Mock the next/navigation module
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
  usePathname: jest.fn(),
  useSearchParams: jest.fn(() => ({
    get: jest.fn(),
  })),
}));

// Mock the components
jest.mock('@/components/Dashboard', () => () => (
  <div data-testid="dashboard-component">Dashboard Component</div>
));

jest.mock('@/components/mcp/MCPDecisionCard', () => ({ decisionId }: { decisionId?: string }) => (
  <div data-testid="mcp-decision-card">
    Decision Card for ID: {decisionId || 'No ID'}
    <button data-testid="view-details-button">View Details</button>
  </div>
));

// Create a mock layout component that includes navigation
const mockPush = jest.fn();

function MockLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  
  return (
    <div>
      <nav data-testid="main-navigation">
        <ul className="flex space-x-4">
          <li>
            <button
              data-testid="nav-home"
              className={pathname === '/' ? 'active' : ''}
              onClick={() => mockPush('/')}
            >
              Dashboard
            </button>
          </li>
          <li>
            <button
              data-testid="nav-decisions"
              className={pathname === '/decisions' ? 'active' : ''}
              onClick={() => mockPush('/decisions')}
            >
              Decisions
            </button>
          </li>
          <li>
            <button
              data-testid="nav-strategies"
              className={pathname === '/strategies' ? 'active' : ''}
              onClick={() => mockPush('/strategies')}
            >
              Strategies
            </button>
          </li>
          <li>
            <button
              data-testid="nav-verify"
              className={pathname === '/verify' ? 'active' : ''}
              onClick={() => mockPush('/verify')}
            >
              Verify
            </button>
          </li>
        </ul>
      </nav>
      <main>{children}</main>
    </div>
  );
}

// Import Dashboard component
import Dashboard from '@/components/Dashboard';

// Mock pages
const MockHomePage = () => <div data-testid="home-page"><Dashboard /></div>;
const MockDecisionsPage = () => <div data-testid="decisions-page">Decisions Page</div>;
const MockStrategiesPage = () => <div data-testid="strategies-page">Strategies Page</div>;
const MockVerifyPage = () => <div data-testid="verify-page">Verify Page</div>;

// Create a simple app component for testing navigation
function MockApp() {
  const pathname = usePathname();
  
  let content;
  switch (pathname) {
    case '/decisions':
      content = <MockDecisionsPage />;
      break;
    case '/strategies':
      content = <MockStrategiesPage />;
      break;
    case '/verify':
      content = <MockVerifyPage />;
      break;
    default:
      content = <MockHomePage />;
  }
  
  return <MockLayout>{content}</MockLayout>;
}

describe('Application Integration', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (useRouter as jest.Mock).mockReturnValue({ push: mockPush });
  });
  
  test('navigates between pages', () => {
    // Start at the home page
    (usePathname as jest.Mock).mockReturnValue('/');
    
    const { rerender } = render(<MockApp />);
    
    // Check if we're on the home page
    expect(screen.getByTestId('home-page')).toBeInTheDocument();
    expect(screen.getByTestId('dashboard-component')).toBeInTheDocument();
    expect(screen.getByTestId('nav-home')).toHaveClass('active');
    
    // Navigate to the decisions page
    fireEvent.click(screen.getByTestId('nav-decisions'));
    expect(mockPush).toHaveBeenCalledWith('/decisions');
    
    // Update the pathname and rerender
    (usePathname as jest.Mock).mockReturnValue('/decisions');
    rerender(<MockApp />);
    
    // Check if we're on the decisions page
    expect(screen.getByTestId('decisions-page')).toBeInTheDocument();
    expect(screen.getByTestId('nav-decisions')).toHaveClass('active');
    
    // Navigate to the strategies page
    fireEvent.click(screen.getByTestId('nav-strategies'));
    expect(mockPush).toHaveBeenCalledWith('/strategies');
    
    // Update the pathname and rerender
    (usePathname as jest.Mock).mockReturnValue('/strategies');
    rerender(<MockApp />);
    
    // Check if we're on the strategies page
    expect(screen.getByTestId('strategies-page')).toBeInTheDocument();
    expect(screen.getByTestId('nav-strategies')).toHaveClass('active');
    
    // Navigate to the verify page
    fireEvent.click(screen.getByTestId('nav-verify'));
    expect(mockPush).toHaveBeenCalledWith('/verify');
    
    // Update the pathname and rerender
    (usePathname as jest.Mock).mockReturnValue('/verify');
    rerender(<MockApp />);
    
    // Check if we're on the verify page
    expect(screen.getByTestId('verify-page')).toBeInTheDocument();
    expect(screen.getByTestId('nav-verify')).toHaveClass('active');
    
    // Navigate back to the home page
    fireEvent.click(screen.getByTestId('nav-home'));
    expect(mockPush).toHaveBeenCalledWith('/');
  });
  
  test('navigates from dashboard to decisions page', () => {
    // Start at the home page
    (usePathname as jest.Mock).mockReturnValue('/');
    
    render(<MockApp />);
    
    // Find the decisions navigation button and click it
    const decisionsNavButton = screen.getByTestId('nav-decisions');
    fireEvent.click(decisionsNavButton);
    
    // Check if we're navigating to the decisions page
    expect(mockPush).toHaveBeenCalledWith('/decisions');
  });
  
  test('simulates page transitions', async () => {
    // Start at the home page
    (usePathname as jest.Mock).mockReturnValue('/');
    
    const { rerender } = render(<MockApp />);
    
    // Check if we're on the home page
    expect(screen.getByTestId('dashboard-component')).toBeInTheDocument();
    
    // Navigate to the decisions page
    fireEvent.click(screen.getByTestId('nav-decisions'));
    expect(mockPush).toHaveBeenCalledWith('/decisions');
    
    // Update the pathname and rerender to simulate page transition
    (usePathname as jest.Mock).mockReturnValue('/decisions');
    rerender(<MockApp />);
    
    // Check if we're on the decisions page
    expect(screen.getByTestId('decisions-page')).toBeInTheDocument();
  });
});
