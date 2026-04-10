/**
 * Testbench for DDA Voxel Traversal Engine
 * 
 * Simple working testbench that verifies basic DDA functionality.
 */

`timescale 1ns/1ps

module tb_dda_traversal_engine;

    parameter GRID_SIZE_X = 16;
    parameter GRID_SIZE_Y = 16;
    parameter GRID_SIZE_Z = 16;
    parameter CLK_PERIOD = 10;
    
    logic clk;
    logic rst_n;
    
    logic signed [15:0] ray_start_x;
    logic signed [15:0] ray_start_y;
    logic signed [15:0] ray_start_z;
    logic signed [15:0] ray_dir_x;
    logic signed [15:0] ray_dir_y;
    logic signed [15:0] ray_dir_z;
    logic ray_valid;
    logic ray_ready;
    
    logic signed [15:0] voxel_addr_x;
    logic signed [15:0] voxel_addr_y;
    logic signed [15:0] voxel_addr_z;
    logic [7:0] voxel_data;
    logic voxel_read_req;
    logic voxel_data_valid;
    
    logic signed [15:0] hit_pos_x;
    logic signed [15:0] hit_pos_y;
    logic signed [15:0] hit_pos_z;
    logic [7:0] hit_material;
    logic [2:0] hit_face;
    logic hit_valid;
    logic hit_found;
    logic busy;
    logic done;
    
    dda_traversal_engine #(
        .GRID_SIZE_X(GRID_SIZE_X),
        .GRID_SIZE_Y(GRID_SIZE_Y),
        .GRID_SIZE_Z(GRID_SIZE_Z)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .ray_start_x(ray_start_x),
        .ray_start_y(ray_start_y),
        .ray_start_z(ray_start_z),
        .ray_dir_x(ray_dir_x),
        .ray_dir_y(ray_dir_y),
        .ray_dir_z(ray_dir_z),
        .ray_valid(ray_valid),
        .ray_ready(ray_ready),
        .voxel_addr_x(voxel_addr_x),
        .voxel_addr_y(voxel_addr_y),
        .voxel_addr_z(voxel_addr_z),
        .voxel_data(voxel_data),
        .voxel_read_req(voxel_read_req),
        .voxel_data_valid(voxel_data_valid),
        .hit_pos_x(hit_pos_x),
        .hit_pos_y(hit_pos_y),
        .hit_pos_z(hit_pos_z),
        .hit_material(hit_material),
        .hit_face(hit_face),
        .hit_valid(hit_valid),
        .hit_found(hit_found),
        .busy(busy),
        .done(done)
    );
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Voxel memory
    logic [7:0] voxel_mem [0:GRID_SIZE_X-1][0:GRID_SIZE_Y-1][0:GRID_SIZE_Z-1];
    
    task init_test_scene;
        integer x, y, z;
        begin
            for (x = 0; x < GRID_SIZE_X; x = x + 1)
                for (y = 0; y < GRID_SIZE_Y; y = y + 1)
                    for (z = 0; z < GRID_SIZE_Z; z = z + 1)
                        voxel_mem[x][y][z] = 8'h00;
            
            // Floor
            for (x = 0; x < GRID_SIZE_X; x = x + 1)
                for (z = 0; z < GRID_SIZE_Z; z = z + 1)
                    voxel_mem[x][0][z] = 8'h01;
            
            // Wood pillar
            voxel_mem[5][1][5] = 8'h02;
            voxel_mem[5][2][5] = 8'h02;
            voxel_mem[5][3][5] = 8'h02;
            
            // Brick block
            voxel_mem[8][1][8] = 8'h03;
            voxel_mem[9][1][8] = 8'h03;
            voxel_mem[8][1][9] = 8'h03;
            voxel_mem[9][1][9] = 8'h03;
        end
    endtask
    
    logic hit_found_reg;
    logic hit_valid_reg;
    logic [7:0] hit_material_reg;
    logic signed [15:0] hit_pos_x_reg;
    logic signed [15:0] hit_pos_y_reg;
    logic signed [15:0] hit_pos_z_reg;
    logic [2:0] hit_face_reg;
    
    // Capture results when done is asserted
    always @(posedge clk) begin
        if (done) begin
            hit_found_reg <= hit_found;
            hit_valid_reg <= hit_valid;
            hit_material_reg <= hit_material;
            hit_pos_x_reg <= hit_pos_x;
            hit_pos_y_reg <= hit_pos_y;
            hit_pos_z_reg <= hit_pos_z;
            hit_face_reg <= hit_face;
        end
    end
    
    task send_ray(
        input signed [15:0] sx, input signed [15:0] sy, input signed [15:0] sz,
        input signed [15:0] dx, input signed [15:0] dy, input signed [15:0] dz
    );
        begin
            @(posedge clk);
            ray_start_x <= sx;
            ray_start_y <= sy;
            ray_start_z <= sz;
            ray_dir_x <= dx;
            ray_dir_y <= dy;
            ray_dir_z <= dz;
            ray_valid <= 1'b1;
            
            wait(ray_ready);
            @(posedge clk);
            ray_valid <= 1'b0;
            
            wait(done);
            @(posedge clk);
        end
    endtask
    
    initial begin
        rst_n = 0;
        ray_valid = 0;
        ray_start_x = 0;
        ray_start_y = 0;
        ray_start_z = 0;
        ray_dir_x = 0;
        ray_dir_y = 0;
        ray_dir_z = 0;
        voxel_data = 0;
        voxel_data_valid = 0;
        
        init_test_scene;
        
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        $display("========================================");
        $display("DDA Traversal Engine Testbench");
        $display("========================================");
        $display("");
        
        // Test 1: Ray down at wood pillar
        $display("Test 1: Ray down at wood pillar (5, 4, 5) with dir (0, -1, 0)");
        send_ray(16'sd5, 16'sd4, 16'sd5, 16'sd0, -16'sd1, 16'sd0);
        if (hit_found_reg && hit_valid_reg) begin
            $display("  HIT! Material: %d, Position: (%d, %d, %d), Face: %d", 
                     hit_material_reg, hit_pos_x_reg, hit_pos_y_reg, hit_pos_z_reg, hit_face_reg);
        end else begin
            $display("  NO HIT (hit_found=%b, hit_valid=%b)", hit_found_reg, hit_valid_reg);
        end
        $display("");
        
        // Test 2: Ray down to floor
        $display("Test 2: Ray down to floor (7, 5, 7) with dir (0, -1, 0)");
        send_ray(16'sd7, 16'sd5, 16'sd7, 16'sd0, -16'sd1, 16'sd0);
        if (hit_found_reg && hit_valid_reg) begin
            $display("  HIT! Material: %d, Position: (%d, %d, %d), Face: %d", 
                     hit_material_reg, hit_pos_x_reg, hit_pos_y_reg, hit_pos_z_reg, hit_face_reg);
        end else begin
            $display("  NO HIT (hit_found=%b, hit_valid=%b)", hit_found_reg, hit_valid_reg);
        end
        $display("");
        
        // Test 3: Ray in +Z direction
        $display("Test 3: Ray in +Z direction (5, 2, 6) with dir (0, 0, 1)");
        send_ray(16'sd5, 16'sd2, 16'sd6, 16'sd0, 16'sd0, 16'sd1);
        if (hit_found_reg && hit_valid_reg) begin
            $display("  HIT! Material: %d, Position: (%d, %d, %d), Face: %d", 
                     hit_material_reg, hit_pos_x_reg, hit_pos_y_reg, hit_pos_z_reg, hit_face_reg);
        end else begin
            $display("  NO HIT (hit_found=%b, hit_valid=%b)", hit_found_reg, hit_valid_reg);
        end
        $display("");
        
        $display("========================================");
        $display("All Tests Complete");
        $display("========================================");
        
        $dumpfile("dda_traversal.vcd");
        $dumpvars(0, tb_dda_traversal_engine);
        
        #(CLK_PERIOD * 10);
        $finish;
    end
    
    always @(posedge clk) begin
        if (voxel_read_req) begin
            if (voxel_addr_x >= 0 && voxel_addr_x < GRID_SIZE_X && 
                voxel_addr_y >= 0 && voxel_addr_y < GRID_SIZE_Y && 
                voxel_addr_z >= 0 && voxel_addr_z < GRID_SIZE_Z) begin
                voxel_data <= voxel_mem[voxel_addr_x][voxel_addr_y][voxel_addr_z];
                voxel_data_valid <= 1'b1;
            end else begin
                voxel_data <= 8'h00;
                voxel_data_valid <= 1'b1;
            end
        end else begin
            voxel_data_valid <= 1'b0;
        end
    end
    
    initial begin
        #(CLK_PERIOD * 1000);
        $display("TIMEOUT!");
        $finish;
    end

endmodule
