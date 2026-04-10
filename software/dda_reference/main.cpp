#include "voxel_grid.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <cmath>

void testDDA() {
    std::cout << "=== DDA Voxel Traversal Reference Implementation ===" << std::endl;
    
    // Create 16x16x16 voxel grid
    VoxelGrid grid(16, 16, 16);
    createTestScene(grid);
    
    std::cout << "\nTest Scene Created:" << std::endl;
    std::cout << "- Stone floor at y=0" << std::endl;
    std::cout << "- Wood pillar at (5,1-3,5)" << std::endl;
    std::cout << "- Brick block at (8-9,1-2,8-9)" << std::endl;
    std::cout << "- Glass wall at x=2-5, y=1-3, z=12" << std::endl;
    
    // Test rays
    struct TestRay {
        Vec3 origin;
        Vec3 direction;
        std::string description;
    };
    
    TestRay testRays[] = {
        {Vec3(7.5f, 8.0f, 0.0f), Vec3(0, 0, 1), "Ray through center (+Z)"},
        {Vec3(5.5f, 4.0f, 5.5f), Vec3(0, -1, 0), "Ray down at wood pillar"},
        {Vec3(8.5f, 3.0f, 8.5f), Vec3(0, -1, 0), "Ray down at brick block"},
        {Vec3(4.0f, 2.0f, 13.0f), Vec3(0, 0, -1), "Ray at glass wall (-Z)"},
        {Vec3(7.5f, 8.0f, 0.0f), Vec3(1, 1, 1), "Diagonal ray"},
    };
    
    std::cout << "\n=== Ray Tracing Results ===" << std::endl;
    
    for (const auto& ray : testRays) {
        HitResult hit = traceRay(grid, ray.origin, ray.direction, 100.0f);
        
        std::cout << "\n" << ray.description << std::endl;
        std::cout << "  Origin: (" << ray.origin.x << ", " << ray.origin.y << ", " << ray.origin.z << ")" << std::endl;
        std::cout << "  Direction: (" << ray.direction.x << ", " << ray.direction.y << ", " << ray.direction.z << ")" << std::endl;
        
        if (hit.hit) {
            std::cout << "  HIT at distance: " << hit.distance << std::endl;
            std::cout << "  Position: (" << hit.position.x << ", " << hit.position.y << ", " << hit.position.z << ")" << std::endl;
            std::cout << "  Normal: (" << hit.normal.x << ", " << hit.normal.y << ", " << hit.normal.z << ")" << std::endl;
            std::cout << "  Material: " << hit.material << std::endl;
            std::cout << "  Face: " << hit.face << std::endl;
        } else {
            std::cout << "  NO HIT" << std::endl;
        }
    }
    
    // Render a simple view to file
    std::cout << "\n=== Rendering 64x64 view ===" << std::endl;
    
    int width = 64;
    int height = 64;
    std::vector<float> image(width * height, 0.0f);
    
    Vec3 cameraPos(7.5f, 8.0f, -2.0f);
    Vec3 lookAt(7.5f, 8.0f, 10.0f);
    Vec3 up(0, 1, 0);
    
    // Simple camera basis
    Vec3 forward = (lookAt - cameraPos).normalize();
    Vec3 right = Vec3(forward.y * up.z - forward.z * up.y,
                      forward.z * up.x - forward.x * up.z,
                      forward.x * up.y - forward.y * up.x).normalize();
    Vec3 camUp = Vec3(right.y * forward.z - right.z * forward.y,
                      right.z * forward.x - right.x * forward.z,
                      right.x * forward.y - right.y * forward.x);
    
    float fov = 1.0f;
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            float u = (2.0f * (x + 0.5f) / width - 1.0f) * fov;
            float v = (2.0f * (y + 0.5f) / height - 1.0f) * fov;
            
            Vec3 dir = forward + right * u + camUp * v;
            HitResult hit = traceRay(grid, cameraPos, dir, 100.0f);
            
            if (hit.hit) {
                // Simple diffuse lighting
                Vec3 lightDir = Vec3(0.5f, 1.0f, 0.3f).normalize();
                float diffuse = std::max(0.0f, hit.normal.x * lightDir.x + 
                                                hit.normal.y * lightDir.y + 
                                                hit.normal.z * lightDir.z);
                float brightness = 0.2f + 0.8f * diffuse; // Ambient + diffuse
                
                // Material colors
                float r, g, b;
                switch(hit.material) {
                    case 1: r = 0.5f; g = 0.5f; b = 0.5f; break; // Stone
                    case 2: r = 0.6f; g = 0.4f; b = 0.2f; break; // Wood
                    case 3: r = 0.7f; g = 0.3f; b = 0.2f; break; // Brick
                    case 4: r = 0.8f; g = 0.9f; b = 0.9f; break; // Glass
                    default: r = 1.0f; g = 0.0f; b = 1.0f; break; // Error
                }
                
                image[y * width + x] = brightness * (r + g + b) / 3.0f;
            } else {
                image[y * width + x] = 0.0f; // Sky (black for now)
            }
        }
    }
    
    // Save as simple PGM image
    std::ofstream out("rendered_output.pgm");
    out << "P2" << std::endl;
    out << width << " " << height << std::endl;
    out << "255" << std::endl;
    
    for (int i = 0; i < width * height; i++) {
        int val = (int)(image[i] * 255.0f);
        val = std::max(0, std::min(255, val));
        out << val << " ";
        if ((i + 1) % width == 0) out << std::endl;
    }
    
    out.close();
    std::cout << "Rendered image saved to rendered_output.pgm" << std::endl;
}

int main() {
    testDDA();
    return 0;
}
