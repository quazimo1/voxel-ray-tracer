#include "voxel_grid.h"

#include <algorithm>
#include <limits>
#include <stdexcept>

namespace {

constexpr float kDirectionEpsilon = 1.0e-8f;
constexpr float kBoundaryEpsilon = 1.0e-4f;

bool intersectSlab(float origin, float direction, float minimum, float maximum,
                   int negativeFace, int positiveFace, float& enter,
                   float& exit, int& enterFace) {
    if (std::abs(direction) < kDirectionEpsilon) {
        return origin >= minimum && origin < maximum;
    }

    float first = (minimum - origin) / direction;
    float second = (maximum - origin) / direction;
    int firstFace = negativeFace;
    if (first > second) {
        std::swap(first, second);
        firstFace = positiveFace;
    }

    if (first > enter) {
        enter = first;
        enterFace = firstFace;
    }
    exit = std::min(exit, second);
    return enter <= exit;
}

Vec3 normalForFace(int face) {
    switch (face) {
        case 0: return Vec3(-1, 0, 0);
        case 1: return Vec3(1, 0, 0);
        case 2: return Vec3(0, -1, 0);
        case 3: return Vec3(0, 1, 0);
        case 4: return Vec3(0, 0, -1);
        case 5: return Vec3(0, 0, 1);
        default: return Vec3();
    }
}

}  // namespace

VoxelGrid::VoxelGrid(int sizeX_, int sizeY_, int sizeZ_)
    : sizeX(sizeX_), sizeY(sizeY_), sizeZ(sizeZ_) {
    if (sizeX <= 0 || sizeY <= 0 || sizeZ <= 0) {
        throw std::invalid_argument("voxel-grid dimensions must be positive");
    }
    data.resize(static_cast<std::size_t>(sizeX) * sizeY * sizeZ, 0);
}

void VoxelGrid::setVoxel(int x, int y, int z, std::uint8_t material) {
    if (isInBounds(x, y, z)) {
        data[static_cast<std::size_t>(x + y * sizeX + z * sizeX * sizeY)] = material;
    }
}

std::uint8_t VoxelGrid::getVoxel(int x, int y, int z) const {
    if (!isInBounds(x, y, z)) {
        return 0;
    }
    return data[static_cast<std::size_t>(x + y * sizeX + z * sizeX * sizeY)];
}

bool VoxelGrid::isInBounds(int x, int y, int z) const {
    return x >= 0 && x < sizeX && y >= 0 && y < sizeY && z >= 0 && z < sizeZ;
}

HitResult traceRay(const VoxelGrid& grid, const Vec3& origin,
                   const Vec3& direction, float maxDistance) {
    HitResult result;
    const Vec3 dir = direction;
    if (dir.length() < kDirectionEpsilon || maxDistance < 0.0f) {
        return result;
    }

    float enter = 0.0f;
    float exit = maxDistance;
    int face = -1;
    if (!intersectSlab(origin.x, dir.x, 0.0f, static_cast<float>(grid.getSizeX()),
                       0, 1, enter, exit, face) ||
        !intersectSlab(origin.y, dir.y, 0.0f, static_cast<float>(grid.getSizeY()),
                       2, 3, enter, exit, face) ||
        !intersectSlab(origin.z, dir.z, 0.0f, static_cast<float>(grid.getSizeZ()),
                       4, 5, enter, exit, face) ||
        exit < 0.0f || enter > maxDistance) {
        return result;
    }

    float distance = std::max(0.0f, enter);
    const Vec3 start = origin + dir * (distance + kBoundaryEpsilon);
    int x = std::clamp(static_cast<int>(std::floor(start.x)), 0, grid.getSizeX() - 1);
    int y = std::clamp(static_cast<int>(std::floor(start.y)), 0, grid.getSizeY() - 1);
    int z = std::clamp(static_cast<int>(std::floor(start.z)), 0, grid.getSizeZ() - 1);

    const int stepX = dir.x > 0.0f ? 1 : -1;
    const int stepY = dir.y > 0.0f ? 1 : -1;
    const int stepZ = dir.z > 0.0f ? 1 : -1;
    const float infinity = std::numeric_limits<float>::infinity();

    float tMaxX = std::abs(dir.x) < kDirectionEpsilon
                      ? infinity
                      : ((stepX > 0 ? x + 1.0f : static_cast<float>(x)) - origin.x) / dir.x;
    float tMaxY = std::abs(dir.y) < kDirectionEpsilon
                      ? infinity
                      : ((stepY > 0 ? y + 1.0f : static_cast<float>(y)) - origin.y) / dir.y;
    float tMaxZ = std::abs(dir.z) < kDirectionEpsilon
                      ? infinity
                      : ((stepZ > 0 ? z + 1.0f : static_cast<float>(z)) - origin.z) / dir.z;
    const float tDeltaX = std::abs(dir.x) < kDirectionEpsilon ? infinity : std::abs(1.0f / dir.x);
    const float tDeltaY = std::abs(dir.y) < kDirectionEpsilon ? infinity : std::abs(1.0f / dir.y);
    const float tDeltaZ = std::abs(dir.z) < kDirectionEpsilon ? infinity : std::abs(1.0f / dir.z);

    while (distance <= exit && distance <= maxDistance && grid.isInBounds(x, y, z)) {
        const std::uint8_t material = grid.getVoxel(x, y, z);
        if (material != 0) {
            result.hit = true;
            result.position = origin + dir * distance;
            result.normal = normalForFace(face);
            result.material = material;
            result.distance = distance;
            result.face = face;
            return result;
        }

        if (tMaxX <= tMaxY && tMaxX <= tMaxZ) {
            x += stepX;
            distance = tMaxX;
            tMaxX += tDeltaX;
            face = stepX > 0 ? 0 : 1;
        } else if (tMaxY <= tMaxZ) {
            y += stepY;
            distance = tMaxY;
            tMaxY += tDeltaY;
            face = stepY > 0 ? 2 : 3;
        } else {
            z += stepZ;
            distance = tMaxZ;
            tMaxZ += tDeltaZ;
            face = stepZ > 0 ? 4 : 5;
        }
    }

    return result;
}

void createTestScene(VoxelGrid& grid) {
    for (int x = 0; x < grid.getSizeX(); ++x) {
        for (int z = 0; z < grid.getSizeZ(); ++z) {
            grid.setVoxel(x, 0, z, 1);
        }
    }

    for (int y = 1; y <= 3; ++y) {
        grid.setVoxel(5, y, 5, 2);
    }

    grid.setVoxel(8, 1, 8, 3);
    grid.setVoxel(9, 1, 8, 3);
    grid.setVoxel(8, 1, 9, 3);
    grid.setVoxel(9, 1, 9, 3);
    grid.setVoxel(8, 2, 8, 3);
    grid.setVoxel(9, 2, 9, 3);

    for (int x = 2; x < 6; ++x) {
        for (int y = 1; y < 4; ++y) {
            grid.setVoxel(x, y, 12, 4);
        }
    }
}
