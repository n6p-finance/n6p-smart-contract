# NapFi AI Frontend Testing Documentation

This document outlines the testing strategy and implementation for the NapFi AI frontend application, with a focus on the Model Context Protocol (MCP) components.

## Testing Setup

The project uses the following testing tools:

- **Jest**: Test runner and assertion library
- **React Testing Library**: Component testing utilities
- **Jest DOM**: DOM testing utilities
- **User Event**: Simulating user interactions

## Test Configuration

The testing environment is configured in the following files:

- `jest.config.js`: Jest configuration
- `jest.setup.js`: Test setup and mocks
- `src/types/jest.d.ts`: TypeScript declarations for Jest matchers

## Running Tests

The following npm scripts are available for running tests:

```bash
# Run all tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run tests with coverage report
pnpm test:coverage

# Run only MCP component tests
pnpm test:mcp

# Run only component tests
pnpm test:components

# Run only page-level tests
pnpm test:pages

# Run only integration tests
pnpm test:integration

# Run all tests with verbose output
pnpm test:all
```

## Test Coverage

### Component Tests

The MCP components have 100% test coverage:

- **MCPDecisionCard.tsx**: 100% statement coverage, 93.75% branch coverage, 100% function coverage, 100% line coverage
- **MCPVerification.tsx**: 100% coverage across all metrics

UI components also have 100% test coverage:

- **LoadingSpinner.tsx**: 100% coverage across all metrics
- **ErrorDisplay.tsx**: 100% coverage across all metrics

### Page-Level Tests

All application pages have comprehensive test coverage:

- **Home Page**: Tests Dashboard component integration
- **Decisions Page**: Tests decision history, selection, and MCP component integration
- **Strategies Page**: Tests strategy cards rendering and responsive layout
- **Verify Page**: Tests verification form and MCP verification component integration

## Testing Strategy

### Component Testing

Components are tested in isolation with mocked dependencies. For example:

- `wagmi` hooks like `useReadContract` are mocked to simulate different states (loading, error, data)
- Contract addresses from `@/config/web3` are mocked

### Page-Level Testing

Pages are tested with mocked components to verify proper integration:

- Navigation and routing are tested with mocked `next/navigation` hooks
- Component interactions within pages are tested
- Responsive layouts are verified
- State transitions between pages are tested

### Integration Testing

Integration tests verify that components work together correctly across the application:

- Navigation between pages
- Data flow between components
- State management across page transitions
- Loading and error states during navigation

### Mock Implementation

For components that interact with blockchain data:

1. We mock the contract data responses
2. We test different states (loading, error, success)
3. We verify that the component renders correctly in each state

### Test Files Structure

Test files are located in `__tests__` directories adjacent to the components and pages they test:

```
src/
  components/
    mcp/
      __tests__/
        MCPDecisionCard.test.tsx
        MCPVerification.test.tsx
      MCPDecisionCard.tsx
      MCPVerification.tsx
    ui/
      __tests__/
        LoadingSpinner.test.tsx
        ErrorDisplay.test.tsx
      LoadingSpinner.tsx
      ErrorDisplay.tsx
    __tests__/
      Dashboard.test.tsx
      Dashboard.loading.test.tsx
      ConnectButton.test.tsx
  app/
    __tests__/
      home.test.tsx
      integration.test.tsx
    decisions/
      __tests__/
        decisions.test.tsx
    strategies/
      __tests__/
        strategies.test.tsx
    verify/
      __tests__/
        verify.test.tsx
```

## Known Issues and Limitations

1. Testing components that rely on ESM modules (like `wagmi` and `viem`) can be challenging. We've configured Jest to handle these modules, but some tests for components that heavily rely on these libraries may need special handling.

2. The Web3Provider and other components that integrate with RainbowKit may require more complex mocking strategies.

## End-to-End Testing

The project uses Playwright for end-to-end testing to verify that components work together correctly in a real browser environment.

### Setup

Playwright is configured in `playwright.config.ts` to run tests against multiple browsers and device configurations:

- Chromium (Desktop Chrome)
- Firefox (Desktop Firefox)
- WebKit (Desktop Safari)
- Mobile Chrome (Pixel 5)
- Mobile Safari (iPhone 12)

### Test Files

End-to-end tests are located in the `e2e` directory and are organized by feature:

```
e2e/
  navigation.spec.ts      # Tests for navigation between pages
  dashboard.spec.ts       # Tests for the dashboard page
  decisions.spec.ts       # Tests for the decisions page
  strategies.spec.ts      # Tests for the strategies page
  verify.spec.ts          # Tests for the verification page
  wallet-connection.spec.ts  # Tests for wallet connection functionality
```

### Running End-to-End Tests

The following npm scripts are available for running end-to-end tests:

```bash
# Run all end-to-end tests
pnpm test:e2e

# Run tests with UI mode for debugging
pnpm test:e2e:ui

# Run tests in debug mode
pnpm test:e2e:debug

# View the HTML test report
pnpm test:e2e:report
```

### Test Coverage

End-to-end tests cover the following user flows:

1. **Navigation** - Testing navigation between all pages
2. **Dashboard** - Testing dashboard components and responsive layout
3. **Decisions** - Testing decision history, selection, and MCP component integration
4. **Strategies** - Testing strategy cards, metrics, and responsive layout
5. **Verification** - Testing the verification form and MCP verification process
6. **Wallet Connection** - Testing wallet connection flow and network switching

## Future Testing Improvements

1. Implement visual regression testing
2. Add performance testing for critical user flows
3. Implement accessibility testing
4. Expand end-to-end test coverage for error scenarios

## Best Practices

1. Always mock external dependencies
2. Test components in isolation
3. Test all possible states (loading, error, success)
4. Use descriptive test names
5. Keep tests simple and focused on a single behavior
