# Hardware-Accelerated Voxel Ray Tracer for Minecraft

FPGA-accelerated voxel ray tracing for Minecraft with GLSL shader integration.

## Project Overview

This project implements a hardware-accelerated ray tracing engine for Minecraft voxel rendering. The FPGA handles computationally expensive ray-voxel intersection tests using a hardware DDA (Digital Differential Analyzer) traversal engine, while GLSL shaders manage ray generation, lighting, and compositing.

### Architecture

```
Minecraft → GLSL Shader → Host Driver → FPGA (DDA Engine) → Hit Results → Lighting → Screen
```

### Key Components

- **Hardware (SystemVerilog)**: DDA voxel traversal engine, ray scheduler, voxel cache
- **Shader (GLSL)**: Ray generation, hit processing, lighting, compositing
- **Software (C++)**: FPGA driver, ray batch management, world data extraction

## Getting Started

### Prerequisites

**Simulation:**
- iVerilog + GTKWave (already installed)
- Yosys + nextpnr (for synthesis, optional initially)

**Development:**
- C++17 compiler (clang/gcc)
- OpenGL + GLSL support
- Minecraft with Iris Shaders mod

### Directory Structure

```
voxel_ray_tracer/
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

## Development Roadmap

### Phase 1: Software Prototype
- [x] Project planning and architecture
- [ ] C++ reference DDA implementation
- [ ] Basic GLSL ray tracing shader
- [ ] Software-only ray tracing demo

### Phase 2: Hardware Design
- [ ] DDA traversal unit (SystemVerilog)
- [ ] Testbench and simulation
- [ ] Ray FIFO and scheduler
- [ ] Top-level integration

### Phase 3: Integration
- [ ] Host-side FPGA driver
- [ ] Shader-FPGA communication
- [ ] End-to-end pipeline
- [ ] Performance optimization

### Phase 4: Optimization
- [ ] Pipeline optimization
- [ ] Visual enhancements
- [ ] Target: 60+ FPS

## Hardware Target

**Recommended:** Lattice iCE40 UP5K (iCEBreaker board)
- Open-source toolchain (Yosys, nextpnr)
- No vendor lock-in
- Sufficient resources for initial prototype

**Alternative:** Any FPGA with sufficient BRAM for voxel cache

## Building and Simulation

### Run Simulation
```bash
cd hardware
./scripts/simulate.sh tb_dda_traversal
gtkwave waves.vcd
```

### Synthesize (iCE40)
```bash
cd hardware/syn
yosys -c synth.ys
nextpnr-ice40 --up5k --package sg48 --json design.json --asc design.asc
icepack design.asc design.bin
```

## Resources

- [iCE40 Documentation](https://clifford.at/icestorm/)
- [SystemVerilog Reference](https://ieeexplore.ieee.org/document/8299595)
- [Iris Shaders](https://irisshaders.net/)
- [Ray Tracing in One Weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html)

## License

MIT
