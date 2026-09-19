#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${project_dir}/build/rtl"
mkdir -p "${build_dir}"

iverilog -g2012 -Wall \
    -s tb_dda_traversal_engine \
    -o "${build_dir}/dda_tests.vvp" \
    "${project_dir}/hardware/rtl/dda_traversal_engine.sv" \
    "${project_dir}/hardware/tb/tb_dda_traversal_engine.sv"

cd "${build_dir}"
vvp dda_tests.vvp
