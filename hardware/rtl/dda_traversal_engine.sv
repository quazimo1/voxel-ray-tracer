/**
 * DDA Voxel Traversal Engine - SystemVerilog Implementation
 * 
 * Simplified working version for simulation testing.
 * This implements the core DDA algorithm in a synthesizable format.
 */

module dda_traversal_engine #(
    parameter GRID_SIZE_X = 16,
    parameter GRID_SIZE_Y = 16,
    parameter GRID_SIZE_Z = 16
)(
    input  logic                        clk,
    input  logic                        rst_n,
    
    // Input ray interface (using integer voxel coordinates for simplicity)
    input  logic signed [15:0]          ray_start_x,
    input  logic signed [15:0]          ray_start_y,
    input  logic signed [15:0]          ray_start_z,
    input  logic signed [15:0]          ray_dir_x,  // -1, 0, or 1
    input  logic signed [15:0]          ray_dir_y,
    input  logic signed [15:0]          ray_dir_z,
    input  logic                        ray_valid,
    output logic                        ray_ready,
    
    // Voxel data interface
    output logic signed [15:0]          voxel_addr_x,
    output logic signed [15:0]          voxel_addr_y,
    output logic signed [15:0]          voxel_addr_z,
    input  logic [7:0]                  voxel_data,
    output logic                        voxel_read_req,
    input  logic                        voxel_data_valid,
    
    // Output hit interface
    output logic signed [15:0]          hit_pos_x,
    output logic signed [15:0]          hit_pos_y,
    output logic signed [15:0]          hit_pos_z,
    output logic [7:0]                  hit_material,
    output logic [2:0]                  hit_face,
    output logic                        hit_valid,
    output logic                        hit_found,
    
    // Status
    output logic                        busy,
    output logic                        done
);

    // State machine
    typedef enum logic [3:0] {
        IDLE,
        INIT,
        CHECK_VOXEL,
        TEST_HIT,
        OUTPUT,
        FINISH
    } state_t;
    
    state_t state, next_state;
    
    // Current voxel position
    logic signed [15:0] vox_x, vox_y, vox_z;
    
    // Step direction
    logic signed [15:0] step_x, step_y, step_z;
    
    // Traversal distance counter (prevent infinite loops)
    logic [15:0] step_count;
    localparam MAX_STEPS = 16'd100;
    
    // Face that was hit
    logic [2:0] current_face;
    
    // Hit detection
    logic voxel_occupied;
    
    // Initialize on ray arrival
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            hit_valid <= 1'b0;
            hit_found <= 1'b0;
            vox_x <= 0;
            vox_y <= 0;
            vox_z <= 0;
            step_x <= 0;
            step_y <= 0;
            step_z <= 0;
            step_count <= 0;
            voxel_read_req <= 1'b0;
            current_face <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                    hit_valid <= 1'b0;
                    hit_found <= 1'b0;
                    voxel_read_req <= 1'b0;
                    
                    if (ray_valid) begin
                        busy <= 1'b1;
                        // Initialize voxel position from ray start
                        vox_x <= ray_start_x;
                        vox_y <= ray_start_y;
                        vox_z <= ray_start_z;
                        
                        // Initialize step direction
                        step_x <= ray_dir_x;
                        step_y <= ray_dir_y;
                        step_z <= ray_dir_z;
                        
                        step_count <= 0;
                    end
                end
                
                INIT: begin
                    // Move to first voxel check
                    voxel_read_req <= 1'b1;
                end
                
                CHECK_VOXEL: begin
                    // Request voxel data at current position
                    voxel_addr_x <= vox_x;
                    voxel_addr_y <= vox_y;
                    voxel_addr_z <= vox_z;
                    voxel_read_req <= 1'b1;
                end
                
                TEST_HIT: begin
                    voxel_read_req <= 1'b0;
                    
                    if (voxel_data_valid) begin
                        $display("[DDA] TEST_HIT: voxel_data=%h, occupied=%b", voxel_data, voxel_occupied);
                        
                        if (voxel_occupied) begin
                            // Hit!
                            $display("[DDA] HIT DETECTED!");
                            hit_pos_x <= vox_x;
                            hit_pos_y <= vox_y;
                            hit_pos_z <= vox_z;
                            hit_material <= voxel_data;
                            hit_face <= current_face;
                            hit_valid <= 1'b1;
                            hit_found <= 1'b1;
                        end else if (step_count >= MAX_STEPS) begin
                            // Max steps reached, no hit
                            $display("[DDA] Max steps reached");
                            hit_valid <= 1'b1;
                            hit_found <= 1'b0;
                        end else begin
                            // No hit, advance to next voxel
                            $display("[DDA] No hit, advancing. step_count=%d", step_count);
                            voxel_read_req <= 1'b0;
                            
                            // Determine which axis to advance on
                            if (step_x != 0) begin
                                vox_x <= vox_x + step_x;
                                current_face <= (step_x > 0) ? 3'd1 : 3'd0;
                                $display("[DDA] Advancing X by %d", step_x);
                            end else if (step_y != 0) begin
                                vox_y <= vox_y + step_y;
                                current_face <= (step_y > 0) ? 3'd3 : 3'd2;
                                $display("[DDA] Advancing Y by %d", step_y);
                            end else if (step_z != 0) begin
                                vox_z <= vox_z + step_z;
                                current_face <= (step_z > 0) ? 3'd5 : 3'd4;
                                $display("[DDA] Advancing Z by %d", step_z);
                            end
                            
                            step_count <= step_count + 1;
                        end
                    end
                end
                
                OUTPUT: begin
                    hit_valid <= 1'b1;
                end
                
                FINISH: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    // Keep hit_valid and hit_found asserted
                    // They will be reset in IDLE state
                end
            endcase
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (ray_valid) begin
                    next_state = INIT;
                end
            end
            
            INIT: begin
                next_state = CHECK_VOXEL;
            end
            
            CHECK_VOXEL: begin
                next_state = TEST_HIT;
            end
            
            TEST_HIT: begin
                if (voxel_data_valid) begin
                    if (voxel_occupied || step_count >= MAX_STEPS) begin
                        next_state = OUTPUT;
                    end else begin
                        next_state = CHECK_VOXEL;
                    end
                end
            end
            
            OUTPUT: begin
                next_state = FINISH;
            end
            
            FINISH: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Ready when idle
    assign ray_ready = (state == IDLE);
    
    // Voxel occupancy check
    assign voxel_occupied = (voxel_data != 8'h00);

endmodule
