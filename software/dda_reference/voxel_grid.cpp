#include "voxel_grid.h"
#include <cmath>
#include <algorithm>
#include <iostream>

VoxelGrid::VoxelGrid(int sizeX, int sizeY, int sizeZ)
    : sizeX(sizeX), sizeY(sizeY), sizeZ(sizeZ) {
    data.resize(sizeX * sizeY * sizeZ, 0);
}

void VoxelGrid::setVoxel(int x, int y, int z, uint8_t material) {
    if (isInBounds(x, y, z)) {
        data[x + y * sizeX + z * sizeX * sizeY] = material;
    }
}

uint8_t VoxelGrid::getVoxel(int x, int y, int z) const {
    if (isInBounds(x, y, z)) {
        return data[x + y * sizeX + z * sizeX * sizeY];
    }
    return 0;
}

bool VoxelGrid::isInBounds(int x, int y, int z) const {
    return x >= 0 && x < sizeX && y >= 0 && y < sizeY && z >= 0 && z < sizeZ;
}

/**
 * 3D DDA Voxel Traversal Algorithm
 * 
 * This is the reference implementation that will be ported to hardware.
 * The algorithm efficiently traverses a voxel grid along a ray path,
 * visiting only voxels that the ray passes through.
 */
HitResult traceRay(const VoxelGrid& grid, const Vec3& origin, const Vec3& direction, float maxDist) {
    HitResult result;
    result.hit = false;
    
    // Normalize direction
    Vec3 dir = direction.normalize();
    if (dir.length() < 0.0001f) return result;
    
    // Starting position (in voxel coordinates)
    Vec3 pos = origin;
    
    // Current voxel
    int x = (int)std::floor(pos.x);
    int y = (int)std::floor(pos.y);
    int z = (int)std::floor(pos.z);
    
    // Step direction
    int stepX = (dir.x > 0) ? 1 : -1;
    int stepY = (dir.y > 0) ? 1 : -1;
    int stepZ = (dir.z > 0) ? 1 : -1;
    
    // Calculate tMax (distance to first boundary)
    float tMaxX = (dir.x != 0) ? ((stepX > 0 ? (x + 1) : x) - pos.x) / dir.x : std::numeric_limits<float>::max();
    float tMaxY = (dir.y != 0) ? ((stepY > 0 ? (y + 1) : y) - pos.y) / dir.y : std::numeric_limits<float>::max();
    float tMaxZ = (dir.z != 0) ? ((stepZ > 0 ? (z + 1) : z) - pos.z) / dir.z : std::numeric_limits<float>::max();
    
    // Calculate tDelta (distance between boundaries)
    float tDeltaX = (dir.x != 0) ? std::abs(1.0f / dir.x) : std::numeric_limits<float>::max();
    float tDeltaY = (dir.y != 0) ? std::abs(1.0f / dir.y) : std::numeric_limits<float>::max();
    float tDeltaZ = (dir.z != 0) ? std::abs(1.0f / dir.z) : std::numeric_limits<float>::max();
    
    float distance = 0.0f;
    int face = 0;
    
    // Traverse
    while (distance < maxDist) {
        // Check if current voxel is occupied
        uint8_t material = grid.getVoxel(x, y, z);
        if (material != 0) {
            result.hit = true;
            result.position = Vec3(
                pos.x + dir.x * distance,
                pos.y + dir.y * distance,
                pos.z + dir.z * distance
            );
            result.normal = Vec3(0, 0, 0);
            result.material = material;
            result.distance = distance;
            result.face = face;
            
            // Calculate normal based on face
            switch(face) {
                case 0: result.normal = Vec3(-1, 0, 0); break; // -X
                case 1: result.normal = Vec3(1, 0, 0); break;  // +X
                case 2: result.normal = Vec3(0, -1, 0); break; // -Y
                case 3: result.normal = Vec3(0, 1, 0); break;  // +Y
                case 4: result.normal = Vec3(0, 0, -1); break; // -Z
                case 5: result.normal = Vec3(0, 0, 1); break;  // +Z
            }
            
            return result;
        }
        
        // Advance to next voxel
        if (tMaxX < tMaxY) {
            if (tMaxX < tMaxZ) {
                x += stepX;
                distance = tMaxX;
                tMaxX += tDeltaX;
                face = (stepX > 0) ? 0 : 1;
            } else {
                z += stepZ;
                distance = tMaxZ;
                tMaxZ += tDeltaZ;
                face = (stepZ > 0) ? 4 : 5;
            }
        } else {
            if (tMaxY < tMaxZ) {
                y += stepY;
                distance = tMaxY;
                tMaxY += tDeltaY;
                face = (stepY > 0) ? 2 : 3;
            } else {
                z += stepZ;
                distance = tMaxZ;
                tMaxZ += tDeltaZ;
                face = (stepZ > 0) ? 4 : 5;
            }
        }
        
        // Check bounds
        if (!grid.isInBounds(x, y, z)) {
            break;
        }
    }
    
    return result;
}

void createTestScene(VoxelGrid& grid) {
    // Create a simple test scene with a floor and some blocks
    
    // Floor
    for (int x = 0; x < grid.getSizeX(); x++) {
        for (int z = 0; z < grid.getSizeZ(); z++) {
            grid.setVoxel(x, 0, z, 1); // Stone floor
        }
    }
    
    // Some blocks
    grid.setVoxel(5, 1, 5, 2);  // Wood
    grid.setVoxel(5, 2, 5, 2);
    grid.setVoxel(5, 3, 5, 2);
    
    grid.setVoxel(8, 1, 8, 3);  // Brick
    grid.setVoxel(9, 1, 8, 3);
    grid.setVoxel(8, 1, 9, 3);
    grid.setVoxel(9, 1, 9, 3);
    grid.setVoxel(8, 2, 8, 3);
    grid.setVoxel(9, 2, 9, 3);
    
    // Wall
    for (int x = 2; x < 6; x++) {
        for (int y = 1; y < 4; y++) {
            grid.setVoxel(x, y, 12, 4); // Glass wall
        }
    }
}
