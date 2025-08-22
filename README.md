This is a simple price threshold detector written in Verilog.
If price is higher than UPPER_BAND and remains there for 3 clock cycles, we are in HIGH state.
If price is higher than LOWER_BAND and remains there for 3 clock cycles, we are in LOW state.
Otherwise, we're in BAND state.
