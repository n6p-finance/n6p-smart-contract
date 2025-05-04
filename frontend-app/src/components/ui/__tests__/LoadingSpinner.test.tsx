import React from 'react';
import { render, screen } from '@testing-library/react';
import LoadingSpinner from '../LoadingSpinner';

describe('LoadingSpinner', () => {
  test('renders with default props', () => {
    render(<LoadingSpinner />);
    
    const spinner = screen.getByTestId('loading-spinner');
    expect(spinner).toBeInTheDocument();
    
    // Check that no text is rendered by default
    expect(spinner.textContent).toBe('');
  });
  
  test('renders with custom text', () => {
    const loadingText = 'Loading data...';
    render(<LoadingSpinner text={loadingText} />);
    
    expect(screen.getByText(loadingText)).toBeInTheDocument();
  });
  
  test('applies fullScreen class when fullScreen is true', () => {
    render(<LoadingSpinner fullScreen />);
    
    const spinner = screen.getByTestId('loading-spinner');
    expect(spinner).toHaveClass('fixed');
    expect(spinner).toHaveClass('inset-0');
    expect(spinner).toHaveClass('z-50');
  });
  
  test('applies different sizes correctly', () => {
    const { rerender } = render(<LoadingSpinner size="sm" />);
    
    let spinnerElement = screen.getByTestId('loading-spinner').firstChild as HTMLElement;
    expect(spinnerElement).toHaveClass('h-4');
    expect(spinnerElement).toHaveClass('w-4');
    
    rerender(<LoadingSpinner size="lg" />);
    spinnerElement = screen.getByTestId('loading-spinner').firstChild as HTMLElement;
    expect(spinnerElement).toHaveClass('h-12');
    expect(spinnerElement).toHaveClass('w-12');
  });
  
  test('applies different colors correctly', () => {
    const { rerender } = render(<LoadingSpinner color="primary" />);
    
    let spinnerElement = screen.getByTestId('loading-spinner').firstChild as HTMLElement;
    expect(spinnerElement).toHaveClass('border-blue-600');
    
    rerender(<LoadingSpinner color="secondary" />);
    spinnerElement = screen.getByTestId('loading-spinner').firstChild as HTMLElement;
    expect(spinnerElement).toHaveClass('border-indigo-600');
    
    rerender(<LoadingSpinner color="white" />);
    spinnerElement = screen.getByTestId('loading-spinner').firstChild as HTMLElement;
    expect(spinnerElement).toHaveClass('border-white');
  });
});
