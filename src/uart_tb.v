`timescale 1ns / 10ps
module uart_tb;

  // Testbench uses a 25 MHz clock
  // Want to interface to 115200 baud UART
  // 25000000 / 115200 = 217 Clocks Per Bit.
  //parameter c_CLOCK_PERIOD_NS = 40;		// 25Mhz == 40ns
  parameter c_CLOCK_PERIOD_NS = 8;		// 120Mhz == 8ns
  parameter c_CLKS_PER_BIT    = 217;
  parameter c_BIT_PERIOD      = 8600;   //115200	

	reg CLK = 0;
	reg RES = 0;
	reg RX = 1;   		//default is always high. No transmission 
	wire TX;
    wire [7:0] led;

	// Takes in input byte and serializes it
	task UART_WRITE_BYTE;
		input [7:0] i_Data;
		integer 	ii;
		begin
			// send Start Bit
			RX <= 1'b0;

			#(c_BIT_PERIOD);		// Serial CLK 217 times of 40ns 
			//#1000;		// why delay another 1u?

			// send data byte
			for (ii=0; ii<8; ii=ii+1)
				begin
					RX <= i_Data[ii];
					#(c_BIT_PERIOD);
				end

			// send stop bit
			RX <= 1'b1;
			#(c_BIT_PERIOD);
		end
	endtask // UART_WRITE_BYTE


	always 
		#(c_CLOCK_PERIOD_NS/2) CLK <= !CLK;

	//integer jj;
	initial
	begin
		$display("reset (startup)");
		#1e3 		RES = 1;			// out of reset state
		// send a command to the UART (exercise Rx)
		$display("Initiating Rx");
		//@(posedge CLK);
		UART_WRITE_BYTE(8'h95);			// serial write to RX
		//@(posedge CLK);

		// second round of RX. need to delay clk
		//for (jj=0; jj<10; jj=jj+1)
		//begin
		//	#(c_BIT_PERIOD);
		//end
        // Cannot back to back write. If not TX is busy when TX en is high
        #1e3;
        UART_WRITE_BYTE(8'hAA);

        #1e3;
        UART_WRITE_BYTE(8'hFF);

        #1000e3;
		// this is need to end the vvp runtime. else it will run forever
		$finish(); 
	end


    // check the output continuously
    always @*
    begin
		//check that the correct command was received
		if (led != 8'hf0)
        begin
            //shall print %t with scaled in ns (-9), with 2 precision digits, and would print the " ns" string
            $timeformat(-9, 2, " ns", 20);
            $display("time: %0t", $time);

            if (led == 8'h95)
			    $display("Test Passed - Correct Byte Received: %x", led);
		    else
			    $display("Test Failed - Incorrect Byte Received: %x", led);
    
        end	
    end

uart_top uart0 (
  .clk(CLK),
  .reset(RES),
  .uart_rxd(RX),
  .uart_txd(TX),
  .led(led),
  .sw_1()
);



  initial 
  begin
    // Required to dump signals to EPWave
    $dumpfile("uart.vcd");
    $dumpvars(0);
  end

endmodule