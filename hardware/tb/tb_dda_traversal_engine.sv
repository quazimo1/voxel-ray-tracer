`timescale 1ns/1ps

module tb_dda_traversal_engine;

    localparam integer GRID_SIZE = 16;
    localparam integer FRACTION_BITS = 8;
    localparam integer CLK_PERIOD = 10;

    logic clk = 0;
    logic rst_n = 0;
    logic signed [15:0] ray_origin_x;
    logic signed [15:0] ray_origin_y;
    logic signed [15:0] ray_origin_z;
    logic signed [15:0] ray_dir_x;
    logic signed [15:0] ray_dir_y;
    logic signed [15:0] ray_dir_z;
    logic ray_valid = 0;
    logic ray_ready;
    logic signed [15:0] voxel_addr_x;
    logic signed [15:0] voxel_addr_y;
    logic signed [15:0] voxel_addr_z;
    logic [7:0] voxel_data = 0;
    logic voxel_read_req;
    logic voxel_data_valid = 0;
    logic signed [15:0] hit_pos_x;
    logic signed [15:0] hit_pos_y;
    logic signed [15:0] hit_pos_z;
    logic [7:0] hit_material;
    logic [2:0] hit_face;
    logic [31:0] hit_distance;
    logic hit_valid;
    logic hit_found;
    logic busy;
    logic done;

    logic [7:0] voxel_mem [0:GRID_SIZE-1][0:GRID_SIZE-1][0:GRID_SIZE-1];
    integer failures = 0;

    always #(CLK_PERIOD / 2) clk = ~clk;

    dda_traversal_engine #(
        .GRID_SIZE_X(GRID_SIZE),
        .GRID_SIZE_Y(GRID_SIZE),
        .GRID_SIZE_Z(GRID_SIZE),
        .FRACTION_BITS(FRACTION_BITS)
    ) dut (
        .clk,
        .rst_n,
        .ray_origin_x,
        .ray_origin_y,
        .ray_origin_z,
        .ray_dir_x,
        .ray_dir_y,
        .ray_dir_z,
        .ray_valid,
        .ray_ready,
        .voxel_addr_x,
        .voxel_addr_y,
        .voxel_addr_z,
        .voxel_data,
        .voxel_read_req,
        .voxel_data_valid,
        .hit_pos_x,
        .hit_pos_y,
        .hit_pos_z,
        .hit_material,
        .hit_face,
        .hit_distance,
        .hit_valid,
        .hit_found,
        .busy,
        .done
    );

    always_ff @(posedge clk) begin
        voxel_data_valid <= voxel_read_req;
        if (voxel_read_req &&
            voxel_addr_x >= 0 && voxel_addr_x < GRID_SIZE &&
            voxel_addr_y >= 0 && voxel_addr_y < GRID_SIZE &&
            voxel_addr_z >= 0 && voxel_addr_z < GRID_SIZE) begin
            voxel_data <= voxel_mem[voxel_addr_x][voxel_addr_y][voxel_addr_z];
        end else begin
            voxel_data <= 0;
        end
    end

    task automatic clear_grid;
        integer x;
        integer y;
        integer z;
        begin
            for (x = 0; x < GRID_SIZE; x = x + 1)
                for (y = 0; y < GRID_SIZE; y = y + 1)
                    for (z = 0; z < GRID_SIZE; z = z + 1)
                        voxel_mem[x][y][z] = 0;
        end
    endtask

    task automatic send_ray(
        input logic signed [15:0] ox,
        input logic signed [15:0] oy,
        input logic signed [15:0] oz,
        input logic signed [15:0] dx,
        input logic signed [15:0] dy,
        input logic signed [15:0] dz
    );
        begin
            wait (ray_ready);
            @(negedge clk);
            ray_origin_x = ox;
            ray_origin_y = oy;
            ray_origin_z = oz;
            ray_dir_x = dx;
            ray_dir_y = dy;
            ray_dir_z = dz;
            ray_valid = 1;
            @(negedge clk);
            ray_valid = 0;
            wait (done);
            #1;
        end
    endtask

    task automatic expect_hit(
        input integer expected_x,
        input integer expected_y,
        input integer expected_z,
        input integer expected_material,
        input integer expected_face,
        input integer expected_distance,
        input string name
    );
        begin
            if (!hit_valid || !hit_found ||
                hit_pos_x !== expected_x || hit_pos_y !== expected_y ||
                hit_pos_z !== expected_z || hit_material !== expected_material ||
                hit_face !== expected_face || hit_distance !== expected_distance) begin
                $error("%s failed: found=%0d pos=(%0d,%0d,%0d) material=%0d face=%0d distance=%0d",
                       name, hit_found, hit_pos_x, hit_pos_y, hit_pos_z,
                       hit_material, hit_face, hit_distance);
                failures = failures + 1;
            end
        end
    endtask

    task automatic expect_miss(input string name);
        begin
            if (!hit_valid || hit_found) begin
                $error("%s failed: expected miss, found=%0d valid=%0d", name, hit_found, hit_valid);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        clear_grid();
        voxel_mem[5][3][5] = 8'd2;
        voxel_mem[11][6][4] = 8'd5;
        voxel_mem[4][6][5] = 8'd6;
        voxel_mem[3][3][3] = 8'd9;

        repeat (3) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        // Q8.8: (5.5, 4.5, 5.5), direction (0, -1, 0).
        send_ray(16'sd1408, 16'sd1152, 16'sd1408,
                 16'sd0, -16'sd256, 16'sd0);
        expect_hit(5, 3, 5, 2, 3, 128, "axis-aligned ray");

        // Q8.8: (2.5, 2.5, 2.5), direction (4, 2, 1).
        send_ray(16'sd640, 16'sd640, 16'sd640,
                 16'sd1024, 16'sd512, 16'sd256);
        expect_hit(11, 6, 4, 5, 0, 544, "arbitrary-direction ray");

        // Negative traversal follows the mirrored path and enters through +X.
        send_ray(16'sd3456, 16'sd2688, 16'sd1920,
                 -16'sd1024, -16'sd512, -16'sd256);
        expect_hit(4, 6, 5, 6, 1, 544, "negative arbitrary-direction ray");

        send_ray(16'sd832, 16'sd832, 16'sd832,
                 16'sd256, 16'sd128, 16'sd64);
        expect_hit(3, 3, 3, 9, 7, 0, "ray starting inside occupied voxel");

        send_ray(16'sd384, 16'sd384, 16'sd384,
                 16'sd256, 16'sd0, 16'sd0);
        expect_miss("empty-path ray");

        send_ray(16'sd384, 16'sd384, 16'sd384,
                 16'sd0, 16'sd0, 16'sd0);
        expect_miss("zero-direction ray");

        if (failures != 0) begin
            $fatal(1, "%0d RTL test(s) failed", failures);
        end

        $display("All RTL DDA tests passed");
        $finish;
    end

    initial begin
        $dumpfile("dda_traversal.vcd");
        $dumpvars(0, tb_dda_traversal_engine);
        #(CLK_PERIOD * 5000);
        $fatal(1, "simulation timeout");
    end

endmodule
