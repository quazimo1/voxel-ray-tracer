# Project status

## Complete and automated

- C++17 golden model for 3D voxel DDA traversal
- Grid-entry handling for rays starting outside the volume
- Reference scene and PGM renderer
- Unit tests for hits, misses, arbitrary directions, invalid directions, and invalid grids
- Synthesizable Q8.8 SystemVerilog DDA engine
- Bounds checking and configurable traversal limit
- Ready/valid ray input and request/valid voxel-memory interface
- Self-checking RTL tests for axis-aligned hits, arbitrary-direction hits, misses, and zero directions
- CI builds the software, runs both test suites, and invokes Yosys synthesis checks

## Verified locally

- RTL compilation with Icarus Verilog 12
- All self-checking RTL cases pass

The C++ and Yosys jobs are defined in CI because those toolchains are not installed on the development machine used for the current revision.

## Deliberately out of scope

- Board-specific top level, clocks, reset, and pin constraints
- Physical FPGA synthesis, place-and-route, timing closure, and measurement
- PCIe, USB, UART, or another host transport
- Ray batching and multi-engine scheduling
- Minecraft world extraction
- Iris/GLSL integration
- Lighting, compositing, and a real-time frame pipeline

These require a concrete board and integration environment. Until they exist and are measured, this project should be described as a simulation-complete DDA accelerator prototype rather than a finished Minecraft ray tracer.

## Next hardware milestone

Select the FPGA board and host interface, then add:

1. a board top level and constraints;
2. a voxel-memory implementation;
3. transport loopback and host-side tests;
4. timing/resource reports;
5. on-board comparison against C++ golden vectors.
