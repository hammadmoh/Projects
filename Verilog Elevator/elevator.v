module elevator (
    input        i_clk,
    input        i_rst,
    input        i_button_pressed,
    input  [2:0] i_button_value,
    
    output reg [2:0] o_floor
);

    localparam 
        s_IDLE  =   2'b00,                                      // IDLE State
        s_UP    =   2'b01,                                      // Elevator moving up state
        s_DOWN  =   2'b10;                                      // Elevator moving down state
        
    integer i = 0;                                              // Loop Increment Variable
    reg[1:0] state = s_IDLE;                                    // Initialize the first state to IDLE
    reg[2:0] target_floor;                                      // Target floor register (3 bits)
    reg[2:0] button_counter;                                    // Counter for button presses during movement
    reg[2:0]requested_floors[7:0];                              // Array to store requested floors after additional button presses

    always @(posedge i_clk) begin
        if(i_rst == 1)begin                                     // Reset logic: reset to initial conditions
            o_floor <= 0;
            state <= s_IDLE;
            button_counter <= 0;
            for (i = 0; i < 7; i = i + 1) begin                 // Reset requested floors array
                requested_floors[i] <= 1'b0;
            end
        end else begin                                          // Main state machine logic
            case (state)  
                s_IDLE: begin
                    button_counter <= 0;                        // Reset button counter when in IDLE
                    if (i_button_pressed) begin                 // Process button press
                        target_floor <= i_button_value;
                        if (i_button_value == o_floor)          // Stay IDLE if target is current floor
                            state <= s_IDLE;
                        else                                    // Move to UP or DOWN state based on comparison
                            state <= (i_button_value > o_floor) ? s_UP : s_DOWN;       
                    end else                                    // Remain IDLE if no button press
                        state <= s_IDLE;
                end
            
                s_UP: begin
                   if(o_floor < target_floor) begin             // Increment floor until target is reached
                            o_floor <= o_floor + 1;
                        end

                        if (i_button_pressed == 1) begin        // If button pressed while moving up
                            button_counter <= button_counter + 1;                   // Increment button counter
                            requested_floors[button_counter] <= i_button_value;     // Store new target floor in queue
                        end

                        else if(o_floor == target_floor)begin   // If target floor reached
                            if(button_counter > 0 ) begin       // If there are more floors to visit
                                target_floor <= requested_floors[0];    // Update target to next in queue
                                button_counter <= button_counter - 1;   // Decrement queue counter
                                for (i = 0; i < 7; i = i + 1) begin     // Shift queue down
                                    requested_floors[i] <= requested_floors[i + 1];
                                end
                                if (requested_floors[0] != o_floor) begin  // If next floor is not the current floor
                                    o_floor <= o_floor + (requested_floors[0] > target_floor ? 1 : -1); // Adjust floor to ensure target floor is not active for two clock cycles
                                    state <= (requested_floors[0] > target_floor ? s_UP : s_DOWN);      // Adjust state
                               end else if (button_counter <= 0) begin     // No more floors to visit
                                    state <= s_IDLE;
                                end
                            end
                        end  
                end
                s_DOWN: begin
                        if(o_floor > target_floor) begin    // Decrement floor until target is reached
                            o_floor <= o_floor - 1;
                        end

                        if (i_button_pressed == 1) begin    // If button pressed while moving down
                            button_counter <= button_counter + 1;                   // Increment button counter
                            requested_floors[button_counter] <= i_button_value;     // Store new target floor in queue
                        end

                         else if(o_floor == target_floor)begin  // If target floor reached
                            if(button_counter > 0 ) begin       // If there are more floors to visit
                                target_floor <= requested_floors[0];    // Update target to next in queue
                                button_counter <= button_counter - 1;   // Decrement queue counter
                                for (i = 0; i < 7; i = i + 1) begin     // Shift queue down
                                    requested_floors[i] <= requested_floors[i + 1];
                                end
                                if (requested_floors[0] != o_floor) begin  // If next floor is not the current floor
                                    o_floor <= o_floor + (requested_floors[0] > target_floor ? 1 : -1); // Adjust floor to ensure target floor is not active for two clock cycles
                                    state <= (requested_floors[0] > target_floor ? s_UP : s_DOWN);      // Adjust state
                               end else if (button_counter <= 0) begin     // No more floors to visit
                                    state <= s_IDLE;
                                end
                            end
                        end  
                end
            endcase
        end
    end
 
endmodule
