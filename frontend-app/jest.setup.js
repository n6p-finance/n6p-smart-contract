// Import Jest DOM extensions
import '@testing-library/jest-dom';

// Mock next/router
jest.mock('next/navigation', () => ({
  useRouter: () => ({
    push: jest.fn(),
    replace: jest.fn(),
    prefetch: jest.fn(),
    back: jest.fn(),
    pathname: '/',
    query: {},
  }),
  useSearchParams: () => ({
    get: jest.fn().mockImplementation(param => {
      if (param === 'id') return '0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234';
      if (param === 'signature') return '0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef';
      return null;
    }),
  }),
}));

// Mock environment variables
process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID = 'test-project-id';

// Mock window.matchMedia for responsive design tests
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});
