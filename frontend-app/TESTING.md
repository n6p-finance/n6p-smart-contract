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
```

## Test Coverage

The MCP components have 100% test coverage:

- **MCPDecisionCard.tsx**: 100% statement coverage, 93.75% branch coverage, 100% function coverage, 100% line coverage
- **MCPVerification.tsx**: 100% coverage across all metrics

## Testing Strategy

### Component Testing

Components are tested in isolation with mocked dependencies. For example:

- `wagmi` hooks like `useReadContract` are mocked to simulate different states (loading, error, data)
- Contract addresses from `@/config/web3` are mocked

### Mock Implementation

For components that interact with blockchain data:

1. We mock the contract data responses
2. We test different states (loading, error, success)
3. We verify that the component renders correctly in each state

### Test Files Structure

Test files are located in `__tests__` directories adjacent to the components they test:

```
src/
  components/
    mcp/
      __tests__/
        MCPDecisionCard.test.tsx
        MCPVerification.test.tsx
      MCPDecisionCard.tsx
      MCPVerification.tsx
```

## Known Issues and Limitations

1. Testing components that rely on ESM modules (like `wagmi` and `viem`) can be challenging. We've configured Jest to handle these modules, but some tests for components that heavily rely on these libraries may need special handling.

2. The Web3Provider and other components that integrate with RainbowKit may require more complex mocking strategies.

## Future Testing Improvements

1. Increase test coverage for non-MCP components
2. Add integration tests for pages
3. Add end-to-end tests with Cypress or Playwright
4. Implement visual regression testing

## Best Practices

1. Always mock external dependencies
2. Test components in isolation
3. Test all possible states (loading, error, success)
4. Use descriptive test names
5. Keep tests simple and focused on a single behavior
