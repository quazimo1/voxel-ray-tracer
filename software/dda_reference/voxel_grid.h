#ifndef VOXEL_GRID_H
#define VOXEL_GRID_H

#include <cmath>
#include <cstdint>
#include <vector>

struct Vec3 {
    float x;
    float y;
    float z;

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
        return std::sqrt(x * x + y * y + z * z);
    }

    Vec3 normalize() const {
        const float len = length();
        return len > 0.0f ? Vec3(x / len, y / len, z / len) : Vec3();
    }
};

struct HitResult {
    bool hit = false;
    Vec3 position;
    Vec3 normal;
    std::uint8_t material = 0;
    float distance = 0.0f;
    int face = -1;
};

class VoxelGrid {
public:
    VoxelGrid(int sizeX, int sizeY, int sizeZ);

    void setVoxel(int x, int y, int z, std::uint8_t material);
    std::uint8_t getVoxel(int x, int y, int z) const;
    bool isInBounds(int x, int y, int z) const;

    int getSizeX() const { return sizeX; }
    int getSizeY() const { return sizeY; }
    int getSizeZ() const { return sizeZ; }

private:
    int sizeX;
    int sizeY;
    int sizeZ;
    std::vector<std::uint8_t> data;
};

// Faces: 0=-X, 1=+X, 2=-Y, 3=+Y, 4=-Z, 5=+Z.
HitResult traceRay(const VoxelGrid& grid, const Vec3& origin,
                   const Vec3& direction, float maxDistance);

void createTestScene(VoxelGrid& grid);

#endif
