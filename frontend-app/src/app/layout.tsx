import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

import Web3Provider from "@/components/providers/Web3Provider";
import Navbar from "@/components/Navbar";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "NapFi AI - DeFi Yield Optimizer",
  description: "AI-powered DeFi protocol that automatically routes user funds to the most profitable and secure staking or yield farming opportunities",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Web3Provider>
          <div className="min-h-screen bg-gray-50">
            <Navbar />
            <main>{children}</main>
          </div>
        </Web3Provider>
      </body>
    </html>
  );
}
