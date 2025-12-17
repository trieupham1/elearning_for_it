#!/bin/bash
# ==========================================
# Flutter Web Build for GitHub Pages
# ==========================================

echo "🚀 Building Flutter Web for GitHub Pages..."

# Navigate to Flutter project root
cd "$(dirname "$0")"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build web with release mode and proper base href for GitHub Pages
echo "🔨 Building web release..."
flutter build web --release --web-renderer html --base-href "/elearning_for_it/"

# Check if build was successful
if [ -d "build/web" ]; then
    echo "✅ Web build successful!"
    echo "📁 Build output: build/web/"
    
    # Copy to docs folder for GitHub Pages (if using docs folder method)
    # mkdir -p ../docs
    # cp -r build/web/* ../docs/
    
    echo ""
    echo "Next steps:"
    echo "1. The built files are in: build/web/"
    echo "2. Push to GitHub and enable GitHub Pages from Settings"
    echo "3. Set source to 'gh-pages' branch or 'docs' folder"
else
    echo "❌ Build failed!"
    exit 1
fi
