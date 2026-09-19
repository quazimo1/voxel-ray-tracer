#include "voxel_grid.h"

#include <cmath>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {

void require(bool condition, const std::string& message) {
    if (!condition) {
        throw std::runtime_error(message);
    }
}

void requireNear(float actual, float expected, const std::string& message) {
    require(std::abs(actual - expected) < 1.0e-3f, message);
}

void testAxisAlignedHit() {
    VoxelGrid grid(16, 16, 16);
    createTestScene(grid);

    const HitResult hit = traceRay(grid, Vec3(5.5f, 4.5f, 5.5f), Vec3(0, -1, 0), 100.0f);
    require(hit.hit, "downward ray should hit the wood pillar");
    require(hit.material == 2, "wood pillar should have material 2");
    require(hit.face == 3, "downward ray should enter through the +Y face");
    requireNear(hit.position.y, 4.0f, "wood hit should occur at y=4 boundary");
}

void testRayStartsOutsideGrid() {
    VoxelGrid grid(16, 16, 16);
    grid.setVoxel(7, 7, 0, 4);

    const HitResult hit = traceRay(grid, Vec3(7.5f, 7.5f, -2.0f), Vec3(0, 0, 1), 100.0f);
    require(hit.hit, "ray should enter the grid and hit the front voxel");
    require(hit.material == 4, "front voxel should have material 4");
    require(hit.face == 4, "ray should enter through the -Z face");
    requireNear(hit.distance, 2.0f, "front-grid hit distance should be two units");
}

void testArbitraryDirection() {
    VoxelGrid grid(16, 16, 16);
    grid.setVoxel(11, 6, 4, 5);
    grid.setVoxel(4, 6, 5, 6);

    const HitResult hit = traceRay(grid, Vec3(2.5f, 2.5f, 2.5f), Vec3(4, 2, 1), 100.0f);
    require(hit.hit, "non-axis-aligned ray should hit its target voxel");
    require(hit.material == 5, "arbitrary-direction target should have material 5");
    require(hit.face == 0, "target should be entered through the -X face");
    requireNear(hit.distance, 2.125f, "arbitrary-direction hit distance should match ray parameter");

    const HitResult negativeHit =
        traceRay(grid, Vec3(13.5f, 10.5f, 7.5f), Vec3(-4, -2, -1), 100.0f);
    require(negativeHit.hit, "negative arbitrary-direction ray should hit its target voxel");
    require(negativeHit.material == 6, "negative-direction target should have material 6");
    require(negativeHit.face == 1, "negative ray should enter through the +X face");
    requireNear(negativeHit.distance, 2.125f,
                "negative-direction hit distance should match ray parameter");
}

void testOriginInsideOccupiedVoxel() {
    VoxelGrid grid(4, 4, 4);
    grid.setVoxel(2, 2, 2, 9);

    const HitResult hit = traceRay(grid, Vec3(2.25f, 2.25f, 2.25f), Vec3(1, 0.5f, 0.25f), 10.0f);
    require(hit.hit, "ray should hit its starting voxel");
    require(hit.material == 9, "starting voxel should have material 9");
    require(hit.face == -1, "a hit inside the starting voxel has no entry face");
    requireNear(hit.distance, 0.0f, "starting-voxel hit distance should be zero");
}

void testMissAndInvalidDirection() {
    VoxelGrid grid(4, 4, 4);
    require(!traceRay(grid, Vec3(1.5f, 1.5f, 1.5f), Vec3(1, 0, 0), 100.0f).hit,
            "ray through empty grid should miss");
    require(!traceRay(grid, Vec3(1.5f, 1.5f, 1.5f), Vec3(), 100.0f).hit,
            "zero-length direction should miss");
    require(!traceRay(grid, Vec3(-1, 2, 2), Vec3(-1, 0, 0), 100.0f).hit,
            "ray pointing away from grid should miss");
}

void testInvalidGridDimensions() {
    bool threw = false;
    try {
        VoxelGrid invalid(0, 4, 4);
    } catch (const std::invalid_argument&) {
        threw = true;
    }
    require(threw, "non-positive grid dimensions should be rejected");
}

}  // namespace

int main() {
    try {
        testAxisAlignedHit();
        testRayStartsOutsideGrid();
        testArbitraryDirection();
        testOriginInsideOccupiedVoxel();
        testMissAndInvalidDirection();
        testInvalidGridDimensions();
    } catch (const std::exception& error) {
        std::cerr << "FAILED: " << error.what() << '\n';
        return 1;
    }

    std::cout << "All C++ DDA tests passed\n";
    return 0;
}
