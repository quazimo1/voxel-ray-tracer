`timescale 1ns/1ps

module dda_traversal_engine #(
    parameter integer GRID_SIZE_X = 16,
    parameter integer GRID_SIZE_Y = 16,
    parameter integer GRID_SIZE_Z = 16,
    parameter integer FRACTION_BITS = 8,
    parameter integer MAX_STEPS = GRID_SIZE_X + GRID_SIZE_Y + GRID_SIZE_Z
)(
    input  logic                        clk,
    input  logic                        rst_n,

    // Origins and directions use signed Q(16-FRACTION_BITS).FRACTION_BITS.
    input  logic signed [15:0]          ray_origin_x,
    input  logic signed [15:0]          ray_origin_y,
    input  logic signed [15:0]          ray_origin_z,
    input  logic signed [15:0]          ray_dir_x,
    input  logic signed [15:0]          ray_dir_y,
    input  logic signed [15:0]          ray_dir_z,
    input  logic                        ray_valid,
    output logic                        ray_ready,

    output logic signed [15:0]          voxel_addr_x,
    output logic signed [15:0]          voxel_addr_y,
    output logic signed [15:0]          voxel_addr_z,
    input  logic [7:0]                  voxel_data,
    output logic                        voxel_read_req,
    input  logic                        voxel_data_valid,

    output logic signed [15:0]          hit_pos_x,
    output logic signed [15:0]          hit_pos_y,
    output logic signed [15:0]          hit_pos_z,
    output logic [7:0]                  hit_material,
    output logic [2:0]                  hit_face,
    output logic [31:0]                 hit_distance,
    output logic                        hit_valid,
    output logic                        hit_found,
    output logic                        busy,
    output logic                        done
);

    localparam logic [31:0] T_INFINITY = 32'h7fff_ffff;
    localparam logic [31:0] ONE = 32'd1 << FRACTION_BITS;
    localparam logic [63:0] ONE_SQUARED = 64'd1 << (2 * FRACTION_BITS);

    typedef enum logic [3:0] {
        IDLE,
        INIT,
        CHECK_BOUNDS,
        REQUEST_VOXEL,
        WAIT_VOXEL,
        ADVANCE,
        RESULT
    } state_t;

    state_t state;
    logic signed [15:0] origin_x;
    logic signed [15:0] origin_y;
    logic signed [15:0] origin_z;
    logic signed [15:0] direction_x;
    logic signed [15:0] direction_y;
    logic signed [15:0] direction_z;
    logic signed [15:0] voxel_x;
    logic signed [15:0] voxel_y;
    logic signed [15:0] voxel_z;
    logic signed [1:0] step_x;
    logic signed [1:0] step_y;
    logic signed [1:0] step_z;
    logic [31:0] t_max_x;
    logic [31:0] t_max_y;
    logic [31:0] t_max_z;
    logic [31:0] t_delta_x;
    logic [31:0] t_delta_y;
    logic [31:0] t_delta_z;
    logic [31:0] current_t;
    logic [15:0] step_count;
    logic [2:0] current_face;

    function automatic logic [31:0] absolute_direction(
        input logic signed [15:0] direction
    );
        logic signed [31:0] extended;
        begin
            extended = direction;
            absolute_direction = extended < 0 ? -extended : extended;
        end
    endfunction

    function automatic logic [31:0] calculate_t_delta(
        input logic signed [15:0] direction
    );
        logic [31:0] magnitude;
        begin
            magnitude = absolute_direction(direction);
            calculate_t_delta = magnitude == 0 ? T_INFINITY : ONE_SQUARED / magnitude;
        end
    endfunction

    function automatic logic [31:0] calculate_initial_t_max(
        input logic signed [15:0] origin,
        input logic signed [15:0] direction
    );
        logic signed [31:0] voxel;
        logic signed [31:0] extended_origin;
        logic [31:0] fraction;
        logic [31:0] distance_to_boundary;
        logic [31:0] magnitude;
        logic [63:0] numerator;
        begin
            if (direction == 0) begin
                calculate_initial_t_max = T_INFINITY;
            end else begin
                extended_origin = origin;
                voxel = extended_origin >>> FRACTION_BITS;
                fraction = extended_origin - (voxel <<< FRACTION_BITS);
                distance_to_boundary = direction > 0 ? ONE - fraction : fraction;
                magnitude = absolute_direction(direction);
                numerator = {32'd0, distance_to_boundary} << FRACTION_BITS;
                calculate_initial_t_max = numerator / magnitude;
            end
        end
    endfunction

    assign ray_ready = state == IDLE;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            hit_valid <= 1'b0;
            hit_found <= 1'b0;
            voxel_read_req <= 1'b0;
            voxel_addr_x <= 0;
            voxel_addr_y <= 0;
            voxel_addr_z <= 0;
            hit_pos_x <= 0;
            hit_pos_y <= 0;
            hit_pos_z <= 0;
            hit_material <= 0;
            hit_face <= 3'd7;
            hit_distance <= 0;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                    hit_valid <= 1'b0;
                    hit_found <= 1'b0;
                    voxel_read_req <= 1'b0;
                    if (ray_valid) begin
                        origin_x <= ray_origin_x;
                        origin_y <= ray_origin_y;
                        origin_z <= ray_origin_z;
                        direction_x <= ray_dir_x;
                        direction_y <= ray_dir_y;
                        direction_z <= ray_dir_z;
                        busy <= 1'b1;
                        state <= INIT;
                    end
                end

                INIT: begin
                    voxel_x <= $signed(origin_x) >>> FRACTION_BITS;
                    voxel_y <= $signed(origin_y) >>> FRACTION_BITS;
                    voxel_z <= $signed(origin_z) >>> FRACTION_BITS;
                    step_x <= direction_x > 0 ? 1 : (direction_x < 0 ? -1 : 0);
                    step_y <= direction_y > 0 ? 1 : (direction_y < 0 ? -1 : 0);
                    step_z <= direction_z > 0 ? 1 : (direction_z < 0 ? -1 : 0);
                    t_max_x <= calculate_initial_t_max(origin_x, direction_x);
                    t_max_y <= calculate_initial_t_max(origin_y, direction_y);
                    t_max_z <= calculate_initial_t_max(origin_z, direction_z);
                    t_delta_x <= calculate_t_delta(direction_x);
                    t_delta_y <= calculate_t_delta(direction_y);
                    t_delta_z <= calculate_t_delta(direction_z);
                    current_t <= 0;
                    current_face <= 3'd7;
                    step_count <= 0;
                    state <= CHECK_BOUNDS;
                end

                CHECK_BOUNDS: begin
                    if ((direction_x == 0 && direction_y == 0 && direction_z == 0) ||
                        voxel_x < 0 || voxel_x >= GRID_SIZE_X ||
                        voxel_y < 0 || voxel_y >= GRID_SIZE_Y ||
                        voxel_z < 0 || voxel_z >= GRID_SIZE_Z ||
                        step_count >= MAX_STEPS) begin
                        hit_found <= 1'b0;
                        hit_valid <= 1'b1;
                        hit_distance <= current_t;
                        state <= RESULT;
                    end else begin
                        voxel_addr_x <= voxel_x;
                        voxel_addr_y <= voxel_y;
                        voxel_addr_z <= voxel_z;
                        voxel_read_req <= 1'b1;
                        state <= REQUEST_VOXEL;
                    end
                end

                REQUEST_VOXEL: begin
                    state <= WAIT_VOXEL;
                end

                WAIT_VOXEL: begin
                    if (voxel_data_valid) begin
                        voxel_read_req <= 1'b0;
                        if (voxel_data != 0) begin
                            hit_pos_x <= voxel_x;
                            hit_pos_y <= voxel_y;
                            hit_pos_z <= voxel_z;
                            hit_material <= voxel_data;
                            hit_face <= current_face;
                            hit_distance <= current_t;
                            hit_found <= 1'b1;
                            hit_valid <= 1'b1;
                            state <= RESULT;
                        end else begin
                            state <= ADVANCE;
                        end
                    end
                end

                ADVANCE: begin
                    if (t_max_x <= t_max_y && t_max_x <= t_max_z) begin
                        voxel_x <= voxel_x + step_x;
                        current_t <= t_max_x;
                        t_max_x <= t_max_x + t_delta_x;
                        current_face <= step_x > 0 ? 3'd0 : 3'd1;
                    end else if (t_max_y <= t_max_z) begin
                        voxel_y <= voxel_y + step_y;
                        current_t <= t_max_y;
                        t_max_y <= t_max_y + t_delta_y;
                        current_face <= step_y > 0 ? 3'd2 : 3'd3;
                    end else begin
                        voxel_z <= voxel_z + step_z;
                        current_t <= t_max_z;
                        t_max_z <= t_max_z + t_delta_z;
                        current_face <= step_z > 0 ? 3'd4 : 3'd5;
                    end
                    step_count <= step_count + 1'b1;
                    state <= CHECK_BOUNDS;
                end

                RESULT: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
