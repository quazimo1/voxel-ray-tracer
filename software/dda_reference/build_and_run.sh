#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_dir="${script_dir}/build"

cmake -S "${script_dir}" -B "${build_dir}" -DCMAKE_BUILD_TYPE=Release
cmake --build "${build_dir}"
ctest --test-dir "${build_dir}" --output-on-failure
cd "${script_dir}"
"${build_dir}/dda_reference"
