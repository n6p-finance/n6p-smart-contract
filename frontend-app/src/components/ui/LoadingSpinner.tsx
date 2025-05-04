'use client';

import React from 'react';

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  color?: 'primary' | 'secondary' | 'white';
  fullScreen?: boolean;
  text?: string;
}

/**
 * A reusable loading spinner component
 */
const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  size = 'md',
  color = 'primary',
  fullScreen = false,
  text
}) => {
  // Size classes
  const sizeClasses = {
    sm: 'h-4 w-4 border-2',
    md: 'h-8 w-8 border-2',
    lg: 'h-12 w-12 border-3',
  };
  
  // Color classes
  const colorClasses = {
    primary: 'border-blue-600',
    secondary: 'border-indigo-600',
    white: 'border-white',
  };
  
  const spinnerClasses = `
    animate-spin rounded-full
    ${sizeClasses[size]}
    border-t-transparent
    ${colorClasses[color]}
  `;
  
  const containerClasses = fullScreen
    ? 'fixed inset-0 flex items-center justify-center bg-gray-900 bg-opacity-50 z-50'
    : 'flex flex-col items-center justify-center';
  
  return (
    <div className={containerClasses} data-testid="loading-spinner">
      <div className={spinnerClasses}></div>
      {text && (
        <p className={`mt-2 text-sm ${color === 'white' ? 'text-white' : 'text-gray-600'}`}>
          {text}
        </p>
      )}
    </div>
  );
};

export default LoadingSpinner;
