#!/bin/bash
# Simulation script for DDA Traversal Engine
# Uses iVerilog and GTKWave (already installed)

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

TESTBENCH=${1:-tb_dda_traversal_engine}
OUTPUT="${SCRIPT_DIR}/${TESTBENCH}.vvp"
WAVES="${SCRIPT_DIR}/${TESTBENCH}.vcd"

echo "=== Simulating DDA Traversal Engine ==="
echo "Testbench: $TESTBENCH"
echo ""

# Compile
echo "Compiling with iVerilog..."
iverilog -g2012 -o $OUTPUT \
    "$PROJECT_DIR/hardware/rtl/dda_traversal_engine.sv" \
    "$PROJECT_DIR/hardware/tb/${TESTBENCH}.sv"

if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    echo ""
    
    # Run simulation
    echo "Running simulation..."
    vvp $OUTPUT
    
    echo ""
    echo "=== Simulation Complete ==="
    echo "Waveform saved to: $WAVES"
    echo ""
    echo "To view waves in GTKWave:"
    echo "  gtkwave $WAVES"
else
    echo "Compilation failed!"
    exit 1
fi
