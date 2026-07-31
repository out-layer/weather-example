#!/bin/bash
set -e

echo "Building weather-example for wasm32-wasip2..."

# Check if wasm32-wasip2 target is installed
if ! rustup target list --installed | grep -q wasm32-wasip2; then
    echo "Installing wasm32-wasip2 target..."
    rustup target add wasm32-wasip2
fi

# Build release version
cargo build --target wasm32-wasip2 --release

# Copy to root for easy access
cp target/wasm32-wasip2/release/weather-example.wasm ./weather-example.wasm

# Show file size
ls -lh weather-example.wasm

echo "✅ Build complete: weather-example.wasm"
echo ""
echo "To test locally (needs an OpenWeather API key in the environment):"
echo "  echo '{\"city\":\"Paris\",\"units\":\"metric\"}' | wasmtime weather-example.wasm"
echo ""
echo "To deploy with NEAR OutLayer:"
echo "  Push to GitHub and call outlayer.testnet request_execution"
