import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import ErrorDisplay from '../ErrorDisplay';

describe('ErrorDisplay', () => {
  test('renders with default props', () => {
    const errorMessage = 'Something went wrong';
    render(<ErrorDisplay message={errorMessage} />);
    
    // Check if the error title is rendered
    expect(screen.getByText('Error')).toBeInTheDocument();
    
    // Check if the error message is rendered
    expect(screen.getByText(errorMessage)).toBeInTheDocument();
    
    // Check that retry button is not rendered by default
    expect(screen.queryByTestId('error-retry-button')).not.toBeInTheDocument();
  });
  
  test('renders with custom title', () => {
    const customTitle = 'Connection Error';
    render(<ErrorDisplay title={customTitle} message="Failed to connect" />);
    
    expect(screen.getByText(customTitle)).toBeInTheDocument();
  });
  
  test('renders retry button when onRetry is provided', () => {
    const onRetryMock = jest.fn();
    render(<ErrorDisplay message="Error message" onRetry={onRetryMock} />);
    
    const retryButton = screen.getByTestId('error-retry-button');
    expect(retryButton).toBeInTheDocument();
    
    // Test that the callback is called when the button is clicked
    fireEvent.click(retryButton);
    expect(onRetryMock).toHaveBeenCalledTimes(1);
  });
  
  test('applies different variant styles correctly', () => {
    const { rerender } = render(<ErrorDisplay message="Error message" variant="inline" />);
    
    // Check inline variant
    let errorElement = screen.getByTestId('error-display');
    expect(errorElement).toHaveClass('bg-red-50');
    expect(errorElement).toHaveClass('border-red-200');
    
    // Check card variant
    rerender(<ErrorDisplay message="Error message" variant="card" />);
    errorElement = screen.getByTestId('error-display');
    expect(errorElement).toHaveClass('bg-white');
    expect(errorElement).toHaveClass('shadow-md');
    
    // Check toast variant
    rerender(<ErrorDisplay message="Error message" variant="toast" />);
    errorElement = screen.getByTestId('error-display');
    expect(errorElement).toHaveClass('border-l-4');
    expect(errorElement).toHaveClass('border-l-red-500');
  });
});
