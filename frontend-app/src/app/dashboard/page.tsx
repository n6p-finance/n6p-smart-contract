'use client';

import { NavbarSpacer } from '@/components/Navbar';
import PortfolioPerformance from '@/components/PortfolioPerformance';
import RiskAssessment from '@/components/RiskAssessment';
import React from 'react';

export default function DashboardPage() {
  return (
    <>
      <NavbarSpacer />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-white mb-4">NapFi AI Dashboard</h1>
          <p className="text-gray-300">
            Monitor your portfolio performance and AI-optimized asset allocation.
          </p>
        </div>

        {/* Portfolio Performance Dashboard */}
        <PortfolioPerformance />
        
        {/* Risk Assessment Dashboard */}
        <div className="mt-8">
          <RiskAssessment />
        </div>
      </div>
    </>
  );
}
