#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Running comprehensive code quality checks..."

echo "📐 Formatting code with alejandra..."
if ! alejandra . ; then
    echo "❌ Code formatting failed! Please fix syntax errors first."
    exit 1
fi

echo "🔎 Linting with statix..."
if ! statix check . ; then
    echo "❌ Linting failed! Please fix all statix warnings and errors."
    echo "💡 Try: statix fix ."
    exit 1
fi

echo "🧹 Checking for dead code with deadnix..."
if deadnix . | grep -q "unused" ; then
    echo "❌ Dead code found! Please remove unused code."
    echo "💡 Try: deadnix --edit ."
    exit 1
fi

echo "✅ Validating flake..."
if ! nix flake check ; then
    echo "❌ Flake validation failed! Please fix configuration errors."
    exit 1
fi

echo "🏗️ Testing build..."
if ! nixos-rebuild build --flake .#h4wkeye-dev ; then
    echo "❌ Build failed! Please fix build errors before committing."
    exit 1
fi

echo "✨ All quality checks passed! Ready to commit."