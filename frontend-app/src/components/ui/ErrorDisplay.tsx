'use client';

import React from 'react';

interface ErrorDisplayProps {
  title?: string;
  message: string;
  variant?: 'inline' | 'card' | 'toast';
  onRetry?: () => void;
}

/**
 * A reusable error display component
 */
const ErrorDisplay: React.FC<ErrorDisplayProps> = ({
  title = 'Error',
  message,
  variant = 'inline',
  onRetry
}) => {
  // Variant-specific styling
  const variantClasses = {
    inline: 'p-3 bg-red-50 border border-red-200 rounded-md',
    card: 'p-5 bg-white rounded-xl shadow-md border border-red-200',
    toast: 'p-4 bg-white rounded-lg shadow-lg border-l-4 border-l-red-500'
  };

  return (
    <div 
      className={variantClasses[variant]} 
      role="alert"
      data-testid="error-display"
    >
      <div className="flex items-center">
        <svg 
          className="w-5 h-5 text-red-500 mr-2" 
          fill="currentColor" 
          viewBox="0 0 20 20"
        >
          <path 
            fillRule="evenodd" 
            d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" 
            clipRule="evenodd" 
          />
        </svg>
        <h3 className="text-sm font-medium text-red-800">{title}</h3>
      </div>
      <p className="mt-2 text-sm text-red-700">{message}</p>
      
      {onRetry && (
        <button
          onClick={onRetry}
          className="mt-3 text-sm font-medium text-red-600 hover:text-red-800 transition-colors"
          data-testid="error-retry-button"
        >
          Try again
        </button>
      )}
    </div>
  );
};

export default ErrorDisplay;
