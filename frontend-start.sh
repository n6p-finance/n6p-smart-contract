#!/bin/bash
# Quick startup script for N6P Frontend

set -e

echo "🚀 Starting N6P Frontend (Vite + React)"
echo ""

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Install Node.js v18+ from https://nodejs.org"
    exit 1
fi

echo "✅ Node.js: $(node --version)"
echo "✅ npm: $(npm --version)"
echo ""

cd "$(dirname "$0")/frontend"

echo "📦 Installing dependencies..."
npm install

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Starting dev server on http://localhost:5173"
echo "Press Ctrl+C to stop."
echo ""

npm run dev
