# Contributing to Voxel Ray Tracer

## Development Workflow

### Branch Structure

```
master              ← Stable, release-ready code
  └── IceSimulation ← Active development (FPGA simulation)
        └── feature/* ← Individual features
```

### How to Contribute

1. **Create a feature branch** from `IceSimulation`:
   ```bash
   git checkout IceSimulation
   git checkout -b feature/your-feature-name
   ```

2. **Make changes** and commit:
   ```bash
   git add .
   git commit -m "Description of changes"
   git push origin feature/your-feature-name
   ```

3. **Open a Pull Request** to `IceSimulation`:
   ```bash
   gh pr create --base IceSimulation --title "Feature title" --body "Description"
   ```

4. **Merge after review** - Once approved, merge via PR (no direct pushes)

### Promoting to Master

When `IceSimulation` is stable:
```bash
gh pr create --base master --title "Merge IceSimulation into master" --body "Release notes"
```

---

## Setup

### Prerequisites

- **iVerilog** + **GTKWave** - Simulation (already installed)
- **Yosys** + **nextpnr** - FPGA synthesis (optional)
- **g++** with C++17 support - Software reference
- **GitHub CLI** (`gh`) - Repository management

### Install Dependencies (macOS)

```bash
brew install icarus-verilog gtkwave yosys nextpnr
```

### Install Dependencies (Ubuntu/Debian)

```bash
sudo apt install iverilog gtkwave yosys nextpnr-ice40 g++
```

---

## Running Tests

### Simulate Hardware Design

```bash
cd scripts
./simulate.sh tb_dda_traversal_engine
```

### View Waveforms

```bash
gtkwave scripts/tb_dda_traversal_engine.vcd
```

### Build Software Reference

```bash
cd software/dda_reference
./build_and_run.sh
```

---

## Code Style

### SystemVerilog

- Use `snake_case` for signals and modules
- Use `UPPER_CASE` for parameters and constants
- 4-space indentation
- Always use explicit port connections
- Add comments for complex logic

```systemverilog
module my_module #(
    parameter WIDTH = 8
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);
```

### C++

- Use `snake_case` for functions and variables
- Use `PascalCase` for classes and structs
- Use `UPPER_CASE` for macros and constants
- 4-space indentation
- Header guards with `#ifndef`

---

## Commit Messages

Follow conventional commits:

```
type: short description

Longer description if needed
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `refactor` - Code refactoring
- `test` - Test additions/fixes
- `chore` - Maintenance tasks

**Example:**
```
feat: add full DDA tMax/tDelta calculations

Implement proper fixed-point arithmetic for
arbitrary ray directions instead of simplified
axis-aligned stepping.
```

---

## Project Structure

```
voxel-ray-tracer/
├── hardware/
│   ├── rtl/           # SystemVerilog source files
│   ├── tb/            # Testbenches
│   ├── syn/           # Synthesis scripts
│   └── constraints/   # FPGA pin constraints
├── software/
│   ├── dda_reference/ # C++ reference DDA implementation
│   ├── driver/        # FPGA host driver
│   └── shader/        # GLSL shaders
├── docs/              # Documentation
├── test/              # Test data and scripts
└── scripts/           # Build and simulation scripts
```

---

## Questions?

Open an issue or reach out to the maintainer.
