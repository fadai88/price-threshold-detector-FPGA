// Testbench file (testbench.sv) - Put this in the LEFT pane
module tb_priceThresholdDetect;

parameter UPPER_BAND = 105;
parameter LOWER_BAND = 95;
parameter DEBOUNCE_CYCLES = 3;
parameter CLK_PERIOD = 10;

logic clk;
logic reset;
logic [7:0] price;
logic [1:0] out;

int test_count = 0;
int pass_count = 0;

// Instantiate DUT
priceThresholdDetect #(
    .UPPER_BAND(UPPER_BAND),
    .LOWER_BAND(LOWER_BAND),
    .DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)
) dut (
    .clk(clk),
    .reset(reset),
    .price(price),
    .out(out)
);

// Clock generation
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Test check task
task check_output(input [1:0] expected, input string description);
    test_count++;
    if (out == expected) begin
        pass_count++;
        $display("PASS: %s - Price=%d, Out=%b", description, price, out);
    end else begin
        $display("FAIL: %s - Price=%d, Out=%b, Expected=%b", description, price, out, expected);
    end
endtask

// Main test
initial begin
    reset = 1;
    price = 100;
    
    repeat(3) @(posedge clk);
    reset = 0;
    @(posedge clk);
    
    $display("=== Starting Tests ===");
    
    // Test 1: Basic BAND state
    price = 100; @(posedge clk);
    check_output(2'b01, "BAND state");
    
    // Test 2: Rise sequence
    price = 110; @(posedge clk);
    check_output(2'b01, "Rise debounce 1");
    price = 106; @(posedge clk);
    check_output(2'b01, "Rise debounce 2");
    price = 107; @(posedge clk);
    check_output(2'b01, "Rise debounce 3");
    price = 115; @(posedge clk);
    check_output(2'b11, "HIGH state");
  
   price = 104; @(posedge clk);
   check_output(2'b11, "Back to BAND");
    
    // Test 3: Fall sequence
    price = 90; @(posedge clk);
    check_output(2'b01, "Fall debounce 1");
    price = 93; @(posedge clk);
    check_output(2'b01, "Fall debounce 2");
    price = 92; @(posedge clk);
    check_output(2'b01, "Fall debounce 3");
    price = 94; @(posedge clk);
    check_output(2'b10, "LOW state");
    
    // Test 4: Return to band
    price = 101; @(posedge clk);
    check_output(2'b10, "Back to BAND");
    
    // Test 5: Interrupted RISE debounce
    price = 110; @(posedge clk);
    check_output(2'b01, "Start rise");
    price = 100; @(posedge clk);
    check_output(2'b01, "Interrupt to BAND");

    // Test 6: Interrupted FALL debounce
    price = 94.5; @(posedge clk);
    check_output(2'b01, "Start rise");
    price = 100.5; @(posedge clk);
    check_output(2'b01, "Interrupt to BAND");

    // Test 7: From Rise sequence straigtly to Fall
    price = 110; @(posedge clk);
    check_output(2'b01, "Rise debounce 1");
    price = 106; @(posedge clk);
    check_output(2'b01, "Rise debounce 2");
    price = 107; @(posedge clk);
    check_output(2'b01, "Rise debounce 3");
    price = 105; @(posedge clk);
    check_output(2'b11, "HIGH state");

    price = 95; @(posedge clk);
    check_output(2'b11, "HIGH state");
    price = 93; @(posedge clk);
    check_output(2'b11, "HIGH state");

    // Test 8: From Fall sequence straigtly to Rise
    price = 92; @(posedge clk);
    check_output(2'b11, "still HIGH");
    price = 107; @(posedge clk);
    check_output(2'b10, "LOW state");

    // Test 9: Return to band
    price = 96; @(posedge clk);
    check_output(2'b10, "still LOW");
    price = 98; @(posedge clk);
  check_output(2'b01, "Back to BAND");
    
    $display("\n=== Test Results ===");
    $display("Passed: %d/%d", pass_count, test_count);
    
    if (pass_count == test_count)
        $display("*** ALL TESTS PASSED! ***");
    else
        $display("*** SOME TESTS FAILED! ***");
    
    $finish;
end

endmodule
