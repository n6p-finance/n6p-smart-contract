'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import ConnectButton from './ConnectButton';
import { useAccount } from 'wagmi';

/**
 * Navigation bar component with modern UI/UX for NapFi AI
 */
const Navbar: React.FC = () => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const pathname = usePathname();
  const { isConnected } = useAccount();
  
  // Handle scroll effect for navbar
  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 10) {
        setScrolled(true);
      } else {
        setScrolled(false);
      }
    };
    
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);
  
  // Close mobile menu when changing routes
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [pathname]);
  
  // Navigation items
  const navItems = [
    { name: 'Dashboard', href: '/' },
    { name: 'Vault', href: '/vault' },
    { name: 'Strategies', href: '/strategies' },
    { name: 'AI Decisions', href: '/decisions' },
  ];

  return (
    <nav 
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled ? 'bg-white/95 backdrop-blur-md shadow-md' : 'bg-white/80 backdrop-blur-sm'}`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          {/* Logo and desktop navigation */}
          <div className="flex items-center">
            <Link href="/" className="flex-shrink-0 flex items-center group">
              <div className="flex items-center space-x-2">
                <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center text-white font-bold text-lg shadow-md group-hover:shadow-lg transition-all duration-300 transform group-hover:scale-105">
                  N
                </div>
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-purple-600 text-xl font-bold">NapFi AI</span>
              </div>
            </Link>
            
            {/* Desktop navigation */}
            <div className="hidden md:ml-10 md:flex md:space-x-1">
              {navItems.map((item) => {
                const isActive = pathname === item.href;
                return (
                  <Link 
                    key={item.name}
                    href={item.href}
                    className={`px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200 ${isActive 
                      ? 'bg-blue-50 text-blue-700' 
                      : 'text-gray-600 hover:text-blue-600 hover:bg-blue-50'}`}
                  >
                    {item.name}
                  </Link>
                );
              })}
            </div>
          </div>
          
          {/* Right side - Connect button and status */}
          <div className="hidden md:flex md:items-center md:space-x-4">
            {isConnected && (
              <div className="bg-green-50 text-green-700 px-3 py-1 rounded-full text-xs font-medium flex items-center">
                <span className="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
                Connected
              </div>
            )}
            <ConnectButton />
          </div>
          
          {/* Mobile menu button */}
          <div className="flex items-center md:hidden">
            <button
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="inline-flex items-center justify-center p-2 rounded-lg text-gray-500 hover:text-blue-600 hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors"
              aria-expanded={isMobileMenuOpen}
            >
              <span className="sr-only">{isMobileMenuOpen ? 'Close menu' : 'Open menu'}</span>
              {!isMobileMenuOpen ? (
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                </svg>
              ) : (
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile menu */}
      <div 
        className={`${isMobileMenuOpen ? 'max-h-screen opacity-100' : 'max-h-0 opacity-0'} md:hidden overflow-hidden transition-all duration-300 ease-in-out`}
      >
        <div className="px-2 pt-2 pb-3 space-y-1 bg-white/95 backdrop-blur-md shadow-lg rounded-b-lg">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.name}
                href={item.href}
                className={`block px-3 py-2 rounded-lg text-base font-medium transition-colors ${isActive 
                  ? 'bg-blue-50 text-blue-700' 
                  : 'text-gray-600 hover:text-blue-600 hover:bg-blue-50'}`}
              >
                {item.name}
              </Link>
            );
          })}
          
          <div className="pt-4 pb-3 border-t border-gray-200 mt-4">
            <div className="px-3 py-2">
              <h3 className="text-sm font-medium text-gray-500">Wallet</h3>
              <div className="mt-3">
                <ConnectButton />
              </div>
            </div>
            
            {isConnected && (
              <div className="mt-3 px-3 py-2">
                <div className="flex items-center">
                  <div className="bg-green-50 text-green-700 px-3 py-1 rounded-full text-xs font-medium flex items-center">
                    <span className="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
                    Connected to Sepolia
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
};

/**
 * NavbarSpacer component to provide space for the fixed navbar
 */
export const NavbarSpacer: React.FC = () => {
  return <div className="h-16"></div>;
};

export default Navbar;
