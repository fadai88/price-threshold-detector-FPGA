module priceThresholdDetect #
                            (parameter UPPER_BAND = 105,
                             parameter LOWER_BAND = 95,
			     			 parameter DEBOUNCE_CYCLES = 3)
                            (input logic clk, reset,
                             input logic [7:0] price,
                             output logic [1:0] out);

initial begin
    assert(UPPER_BAND >= LOWER_BAND);
	else 
		$error("UPPER_BAND must be >= LOWER_BAND");
end
// Hysteresis: out = 2'11 when price > UPPER_BAND for some time, out = 2'10 when price < LOWER_BAND for some time, out = 2'b01 when price is within BAND; in IDLE,out = 2'b00

// Example idea: Allow the threshold to be set via an input signal or a register that can be updated by an external control signal.


logic [$clog2(DEBOUNCE_CYCLES+1)-1:0] counter;

typedef enum logic [2:0] {IDLE=0, COUNT_RISE=1, COUNT_FALL=2, HIGH=3, LOW=4, BAND=5} state_t;
state_t state, next_state;

always_comb begin
	next_state = state;
	case (state)
		IDLE: begin
			if (price >= UPPER_BAND) begin
				next_state = COUNT_RISE;
			end
			else if (price <= LOWER_BAND) begin
				next_state = COUNT_FALL;
			end
			else begin
				next_state = BAND;
			end
		end

		COUNT_RISE: begin
			if (price >= UPPER_BAND) begin
                if (counter == DEBOUNCE_CYCLES - 1)
                    next_state = HIGH;
                else
                    next_state = COUNT_RISE;
            end
            else if (price <= LOWER_BAND) begin
                next_state = COUNT_FALL;
			end
            else begin
                next_state = BAND;
			end
		end
		
		COUNT_FALL: begin
            if (price <= LOWER_BAND) begin
                if (counter == DEBOUNCE_CYCLES - 1)
                    next_state = LOW;
                else
                    next_state = COUNT_FALL;
            end
            else if (price >= UPPER_BAND) begin
                next_state = COUNT_RISE;
			end
            else begin
                next_state = BAND;
			end
        end

		BAND: begin
			if (price >= UPPER_BAND) begin
				next_state = COUNT_RISE;
			end
			else if (price <= LOWER_BAND) begin
				next_state = COUNT_FALL;
			end
			else begin
				next_state = BAND;
			end
		end

		HIGH: begin
			if (price <= LOWER_BAND) begin
				next_state = COUNT_FALL;
			end
			else if (price > LOWER_BAND && price < UPPER_BAND) begin
				next_state = BAND;
			end
			else begin
				next_state = HIGH;
			end
		end

		LOW: begin
			if (price >= UPPER_BAND) begin
				next_state = COUNT_RISE;
			end
			else if (price > LOWER_BAND && price < UPPER_BAND) begin
				next_state = BAND;
			end
			else begin
				next_state = LOW;
			end
		end
		//default: next_state = IDLE;
	endcase
end

always_ff @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
        out <= 2'b00;
        counter <= 0;
    end
    else begin
        state <= next_state;
        case (next_state)
            IDLE: begin
                out <= 2'b00;
                counter <= 0;
            end
            BAND: begin
                out <= 2'b01;
                counter <= 0;
            end
            COUNT_RISE: begin
                out <= out;  // Hold previous out during debounce
                if (price >= UPPER_BAND) begin
                    counter <= counter + 1;
                end
                else begin
                    counter <= 0;
                end
            end
            COUNT_FALL: begin
                out <= out;  // Hold previous out during debounce
                if (price <= LOWER_BAND) begin
                    counter <= counter + 1;
                end
                else begin
                    counter <= 0;
                end
            end
            HIGH: begin
                out <= 2'b11;
                counter <= 0;
            end
            LOW: begin
                out <= 2'b10;
                counter <= 0;
            end
            default: begin
                out <= out;
                counter <= 0;
            end
        endcase
    end
end
                               
endmodule
