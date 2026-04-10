#ifndef VOXEL_GRID_H
#define VOXEL_GRID_H

#include <vector>
#include <cstdint>
#include <string>

struct Vec3 {
    float x, y, z;
    
    Vec3() : x(0), y(0), z(0) {}
    Vec3(float x_, float y_, float z_) : x(x_), y(y_), z(z_) {}
    
    Vec3 operator+(const Vec3& other) const {
        return Vec3(x + other.x, y + other.y, z + other.z);
    }
    
    Vec3 operator-(const Vec3& other) const {
        return Vec3(x - other.x, y - other.y, z - other.z);
    }
    
    Vec3 operator*(float scalar) const {
        return Vec3(x * scalar, y * scalar, z * scalar);
    }
    
    float length() const {
        return std::sqrt(x*x + y*y + z*z);
    }
    
    Vec3 normalize() const {
        float len = length();
        if (len > 0) return Vec3(x/len, y/len, z/len);
        return Vec3(0, 0, 0);
    }
};

struct HitResult {
    bool hit;
    Vec3 position;
    Vec3 normal;
    int material;
    float distance;
    int face; // 0-5: -X, +X, -Y, +Y, -Z, +Z
    
    HitResult() : hit(false), material(0), distance(0), face(0) {}
};

class VoxelGrid {
public:
    VoxelGrid(int sizeX, int sizeY, int sizeZ);
    
    void setVoxel(int x, int y, int z, uint8_t material);
    uint8_t getVoxel(int x, int y, int z) const;
    
    bool isInBounds(int x, int y, int z) const;
    
    int getSizeX() const { return sizeX; }
    int getSizeY() const { return sizeY; }
    int getSizeZ() const { return sizeZ; }
    
private:
    int sizeX, sizeY, sizeZ;
    std::vector<uint8_t> data;
};

// DDA Ray Tracing
HitResult traceRay(const VoxelGrid& grid, const Vec3& origin, const Vec3& direction, float maxDist);

// Test scene generation
void createTestScene(VoxelGrid& grid);

#endif // VOXEL_GRID_H
