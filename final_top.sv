// modified from lab 8 lab8.sv

module final_top( 
				input               CLOCK_50,
				input        [3:0]  KEY,          //bit 0 is set up as Reset
				output logic [6:0]  HEX0, HEX1,
             // VGA Interface 
             output logic [7:0]  VGA_R,        //VGA Red
                                 VGA_G,        //VGA Green
                                 VGA_B,        //VGA Blue
             output logic        VGA_CLK,      //VGA Clock
                                 VGA_SYNC_N,   //VGA Sync signal
                                 VGA_BLANK_N,  //VGA Blank signal
                                 VGA_VS,       //VGA virtical sync signal
                                 VGA_HS,       //VGA horizontal sync signal
             // CY7C67200 Interface
             inout  wire  [15:0] OTG_DATA,     //CY7C67200 Data bus 16 Bits
             output logic [1:0]  OTG_ADDR,     //CY7C67200 Address 2 Bits
             output logic        OTG_CS_N,     //CY7C67200 Chip Select
                                 OTG_RD_N,     //CY7C67200 Write
                                 OTG_WR_N,     //CY7C67200 Read
                                 OTG_RST_N,    //CY7C67200 Reset
             input               OTG_INT,      //CY7C67200 Interrupt
             // SDRAM Interface for Nios II Software
             output logic [12:0] DRAM_ADDR,    //SDRAM Address 13 Bits
             inout  wire  [31:0] DRAM_DQ,      //SDRAM Data 32 Bits
             output logic [1:0]  DRAM_BA,      //SDRAM Bank Address 2 Bits
             output logic [3:0]  DRAM_DQM,     //SDRAM Data Mast 4 Bits
             output logic        DRAM_RAS_N,   //SDRAM Row Address Strobe
                                 DRAM_CAS_N,   //SDRAM Column Address Strobe
                                 DRAM_CKE,     //SDRAM Clock Enable
                                 DRAM_WE_N,    //SDRAM Write Enable
                                 DRAM_CS_N,    //SDRAM Chip Select
                                 DRAM_CLK,      //SDRAM Clock
				 input logic [1:0] SW
                    );
    
    logic Reset_h, Clk;
    logic [7:0] keycode;
    logic [9:0] DrawX, DrawY;
	 logic is_bird, is_pipe;
    assign Clk = CLOCK_50;
    always_ff @ (posedge Clk) begin
        Reset_h <= ~(KEY[0]);        // The push buttons are active low
    end
    
    logic [1:0] hpi_addr;
    logic [15:0] hpi_data_in, hpi_data_out;
    logic hpi_r, hpi_w, hpi_cs, hpi_reset;
    
    // Interface between NIOS II and EZ-OTG chip
    hpi_io_intf hpi_io_inst(
                            .Clk(Clk),
                            .Reset(Reset_h),
                            // signals connected to NIOS II
                            .from_sw_address(hpi_addr),
                            .from_sw_data_in(hpi_data_in),
                            .from_sw_data_out(hpi_data_out),
                            .from_sw_r(hpi_r),
                            .from_sw_w(hpi_w),
                            .from_sw_cs(hpi_cs),
                            .from_sw_reset(hpi_reset),
                            // signals connected to EZ-OTG chip
                            .OTG_DATA(OTG_DATA),    
                            .OTG_ADDR(OTG_ADDR),    
                            .OTG_RD_N(OTG_RD_N),    
                            .OTG_WR_N(OTG_WR_N),    
                            .OTG_CS_N(OTG_CS_N),
                            .OTG_RST_N(OTG_RST_N),
									 
									 
    );
     
     // You need to make sure that the port names here match the ports in Qsys-generated codes.
     final_soc nios_system(
                             .clk_clk(Clk),         
                             .reset_reset_n(1'b1),    // Never reset NIOS
                             .sdram_wire_addr(DRAM_ADDR), 
                             .sdram_wire_ba(DRAM_BA),   
                             .sdram_wire_cas_n(DRAM_CAS_N),
                             .sdram_wire_cke(DRAM_CKE),  
                             .sdram_wire_cs_n(DRAM_CS_N), 
                             .sdram_wire_dq(DRAM_DQ),   
                             .sdram_wire_dqm(DRAM_DQM),  
                             .sdram_wire_ras_n(DRAM_RAS_N),
                             .sdram_wire_we_n(DRAM_WE_N), 
                             .sdram_clk_clk(DRAM_CLK),
                             .keycode_export(keycode),  
                             .otg_hpi_address_export(hpi_addr),
                             .otg_hpi_data_in_port(hpi_data_in),
                             .otg_hpi_data_out_port(hpi_data_out),
                             .otg_hpi_cs_export(hpi_cs),
                             .otg_hpi_r_export(hpi_r),
                             .otg_hpi_w_export(hpi_w),
                             .otg_hpi_reset_export(hpi_reset)
    );
    
    // Use PLL to generate the 25MHZ VGA_CLK.
    // You will have to generate it on your own in simulation.
    vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));
    
    // connections for the rest of the modules 
	 logic kill_one, kill_out, endgame, start_game;
	 logic [9:0] Bird_Y_Pos_;
	 logic [1:0] state_num;
	 logic [9:0] Pipe_Y_Pos_, Pipe_X_Pos_;
	 logic [7:0] score_curr;
	 
	 always_comb
		begin
			if(keycode == 8'h16)
					begin	
						start_game = 1;
					end
		else
			begin
				start_game = 0;
			end
	 end
	 
	 
    VGA_controller vga_controller_instance(.*, .Reset(Reset_h));
    
    bird bird_instance(.*, .Reset(Reset_h), .frame_clk(VGA_VS), .kill_in(endgame), .is_Bird(is_bird) );
	 
	 pipe pipe_instance(.*, .Reset(Reset_h), .frame_clk(VGA_VS), .is_Pipe(is_pipe), .input_speed(SW) );
	 
	 flipflop regis(.*, .Reset(Reset_h), .Load(1), .D_in(kill_one), .D_Out(kill_out));
	 
	 statemachine control_(.*, .bird_killed(kill_out), .start(start_game), .Reset(Reset_h), .killed_out(endgame)  );
	 
	 collision_kill kill_(.Clk(VGA_VS), .collision(kill_one), .Reset(Reset_h), .bird_y(Bird_Y_Pos_), .pipe_x(Pipe_X_Pos_), .pipe_y(Pipe_Y_Pos_) );
	 
	 score_count score_instance(.Clk(VGA_VS), .bird_killed(endgame), .in(score_curr), .Reset(Reset_h), .pipex(Pipe_X_Pos_), .score_out(score_curr));
	 
    color_mapper color_instance(.*, .Reset(Reset_h));
    
    // Display keycode on hex display
    HexDriver hex_inst_0 (score_curr[3:0], HEX0);
    HexDriver hex_inst_1 (score_curr[7:4], HEX1);
	 HexDriver hex_inst_5 (4'hFFFF, HEX3);
	 HexDriver hex_inst_4 (4'hF, HEX2);
    
endmodule
