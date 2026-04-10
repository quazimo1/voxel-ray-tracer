#!/bin/bash
# Build and run the DDA reference implementation

echo "=== Building DDA Reference Implementation ==="

# Compile
g++ -std=c++17 -O2 -o dda_reference main.cpp voxel_grid.cpp -lm

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo ""
    echo "=== Running DDA Reference ==="
    ./dda_reference
else
    echo "Build failed!"
    exit 1
fi
