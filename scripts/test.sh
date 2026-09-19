#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"${project_dir}/software/dda_reference/build_and_run.sh"
"${project_dir}/scripts/simulate.sh"

if command -v yosys >/dev/null 2>&1; then
    cd "${project_dir}"
    yosys -q -s hardware/syn/synth.ys
fi
