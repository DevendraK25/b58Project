module Project
    (
        CLOCK_50,                       //  On Board 50 MHz
        // Your inputs and outputs here
        KEY,
        SW,
        LEDR,
        HEX0,
        HEX1,
        // The ports below are for the VGA output.  Do not change.
        VGA_CLK,                        //  VGA Clock
        VGA_HS,                         //  VGA H_SYNC
        VGA_VS,                         //  VGA V_SYNC
        VGA_BLANK_N,                        //  VGA BLANK
        VGA_SYNC_N,                     //  VGA SYNC
        VGA_R,                          //  VGA Red[9:0]
        VGA_G,                          //  VGA Green[9:0]
        VGA_B                           //  VGA Blue[9:0]
    );

    input           CLOCK_50;               //  50 MHz
    input   [17:0]   SW;
    input   [3:0]   KEY;
     output  [6:0] HEX0;
     output    [6:0] HEX1;
    output  [9:0]  LEDR;

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output          VGA_CLK;                //  VGA Clock
    output          VGA_HS;                 //  VGA H_SYNC
    output          VGA_VS;                 //  VGA V_SYNC
    output          VGA_BLANK_N;                //  VGA BLANK
    output          VGA_SYNC_N;             //  VGA SYNC
    output  [9:0]   VGA_R;                  //  VGA Red[9:0]
    output  [9:0]   VGA_G;                  //  VGA Green[9:0]
    output  [9:0]   VGA_B;                  //  VGA Blue[9:0]

     wire resetn;
     assign resetn = SW[5];
     
     wire plot;
    wire loser;
    wire player_w;
    wire player2;
    wire ld_screen;
    wire load1;
    wire load2;
    wire preview;
     wire ldxy;
    wire win;
    wire next;
	 
    assign LEDR[0] = ld_screen;
   //assign LEDR[1] = preview;
   assign LEDR[1] = player_w;
   assign LEDR[2] = load1; 
    assign LEDR[3] = win;
    assign LEDR[4] = loser;
   // Create the colour, x, y and writeEn wires that are inputs to the controller.
    wire [7:0] x; //reg or wire?
    wire [7:0] y; //reg or wire?
    wire [2:0] colour;
     
    //assign colour = 3'b010;
     wire left, right, down, up;
    // Create an Instance of a VGA controller - there can be only one!
    // Define the number of colours as well as the initial background
    // image file (.MIF) for the controller.
    vga_adapter VGA(
            .resetn(~resetn),
            .clock(CLOCK_50),
            .colour(colour),
            .x(x),
            .y(y),
            .plot(plot),
            /* Signalplayers for the DAC to drive the monitor. */
            .VGA_R(VGA_R),
            .VGA_G(VGA_G),
            .VGA_B(VGA_B),
            .VGA_HS(VGA_HS),
            .VGA_VS(VGA_VS),
            .VGA_BLANK(VGA_BLANK_N),
            .VGA_SYNC(VGA_SYNC_N),
            .VGA_CLK(VGA_CLK));
        defparam VGA.RESOLUTION = "160x120";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
        defparam VGA.BACKGROUND_IMAGE = "black.mif";
           
    // Put your code here. Your code should p

    // for the VGA controller, in addition to any other functionality your design may require.
   
    // Instansiate datapath
     //wire clk; 4'b1010;
     

    testdatapath d1(
                      .clk(clk),
                      .left(SW[17]),
                      .right(SW[16]),
                      .down(SW[15]),
                      .up(SW[14]),
                      .ld_screen(ld_screen),
                      .load(load1),
                      .player(player_w),
                      .load2(load2),
                      .player2(player2),
                      .win(win),
                      .loser(loser),
							 .next(next),
                      .colour(colour),
                      .x(x),
                      .y(y));

    // Instansiate FSM control
    //control c0(...);oser
      control c0(.clk(CLOCK_50),
             .go(SW[0]),
             .go1(SW[1]),
             .go2(SW[2]),
             .loser(loser),
             .win(win),
             .reset(SW[9]),
				 .next(next),
             .play(player_w),
             .ld_screen(ld_screen),
             .load1(load1),
             .load2(load2),
            .play2(player2),
             .plot(plot),
             .clock_out(clk));
            
        /*
        wire slow_clk;
        wire [27:0] max_ticks;
        assign max_ticks = 27'd50_000 - 1;*/
        
        /*
        rate_divider rate(
                .enable(slow_clk),
                .par_load(1'b0),
                .max_ticks(max_ticks),
                .clk(clk)
                );*/
        
        //for debugging
        hex_display h0(.IN(x[3:0]),
                    .OUT(HEX0[6:0]));
      hex_display h1(.IN(x[7:4]),
                    .OUT(HEX1[6:0]));
        
endmodule


module control(
    input clk,
    input go,
    input go1,
    input go2,
    input loser,
     input win,
    input reset, //RESET USELESS ATM
	 input next,
    output reg play,
    output reg ld_screen,
    output reg load1, 
    output reg load2,
    output reg play2,
     output reg plot,
     output reg clock_out);
        
        
     wire vsync_wire;
    reg[5:0] current_state, next_state;

    localparam  LOADINGSCREEN = 5'd0,
                LOAD1 = 5'd1,
                LEVEL1 = 5'd2,
                     CLEAR = 5'd3,
                LOAD2 = 5'd4,
                LEVEL2 = 5'd5,
                END = 5'd6;
                     //DELAY = 5'd4;
     
    wire [27:0] DELAY_MAX;     
    always@(*)
    begin : state_table
        case(current_state)
            LOADINGSCREEN : next_state = go ? LOAD1 : LOADINGSCREEN;
            LOAD1 : next_state = go1 ? LEVEL1 : LOAD1;

            LEVEL1 : next_state = win ? CLEAR : LEVEL1; 
            LEVEL1 : next_state = loser ? LOADINGSCREEN : LEVEL1;
				/*CLEAR : begin
					if (go)
							next_state <= LOAD2;
					else if (go1)
							next_state <= LEVEL2;
					else
							next_state <= next_state;*/
					
            CLEAR : next_state = go ? LOAD2 : CLEAR;
            CLEAR : next_state = go1 ? LEVEL2 : CLEAR;
				LOAD2 : next_state = next ? CLEAR : LOAD2;
            LEVEL2 : next_state = win ? END : LEVEL2;
				LEVEL2 : next_state = loser ? END : LEVEL2;
            END : next_state = LOADINGSCREEN;
                
                default:    next_state = LOADINGSCREEN;
        endcase        
    end
        
     wire slow_clk;
	  wire faster_clk;

    rate_divider(clk, slow_clk);
	 rate_divider2(clk, faster_clk);
    
    
     //ld_screen, load, player
    always @(*)             
    begin: enable_signals
        play = 1'b0;
        play2 = 1'b0;
        ld_screen = 1'b0;
        load1 = 1'b0;
        load2 = 1'b0;
         plot = 1'b0;
        case(current_state)
            LOADINGSCREEN: begin
               ld_screen = 1'b1;
               plot = 1'b1;
				   play = 1'b0;
					play2 = 1'b0;
					load2 = 1'b0;
				//	load1 = 1'b0;`
					clock_out = clk;
				 end
            LOAD1 : begin
                ld_screen = 1'b0;
                load1 = 1'b1;    
                plot = 1'b1;
                play = 1'b0;
					 play2 = 1'b0;
					 load2 = 1'b0;
                clock_out = clk;
                end
            LEVEL1 : begin
                clock_out = slow_clk;
                load1 = 1'b0;
                play = 1'b1;
                plot = 1'b1;
					 load2 = 1'b0;
					 play2 = 1'b0;
					 ld_screen = 1'b0;
                end
            CLEAR : begin
                clock_out = clk;
                play = 1'b0;
                ld_screen = 1'b1;
                plot = 1'b1;
                load2 = 1'b0;
                end
            LOAD2 : begin
                clock_out = faster_clk;
                //play = 1'b0;
                load2 = 1'b1;
                plot = 1'b1;
                     end
            LEVEL2 : begin
					ld_screen = 1'b0;
                clock_out = slow_clk;
                //play = 1'b0;
                load2 = 1'b0;
                play2 = 1'b1;
                plot = 1'b1;
                end
            default: begin
                load1 = 1'b0;
                load2 = 1'b0;
                plot = 1'b0;
                play = 1'b0;
                play2 = 1'b0;
                ld_screen = 1'b0;
            end
        endcase
    end
    always@(posedge clk)
    begin: state_FFs
        if (loser)
            current_state <= LOADINGSCREEN;
			else if (go1 == 1'b1 && current_state == CLEAR)
				current_state <= LEVEL2;
        else 
            current_state <= next_state;
    end
endmodule

module testdatapath(
    input clk,
    input left,
    input right,
    input down,
    input up,
    input ld_screen,
    input load,
    input player,
    input load2,
    input player2,
	 output reg next,
    output reg win,
    output reg loser,
    output reg[2:0] colour,
    output reg[7:0] x,
    output reg[7:0] y);
    
    reg[7:0] fill_x = 8'b00000000;
    reg[7:0] fill_y = 8'b00000000;

    reg[4:0] counter = 5'b00000;

    reg[7:0] prev_x = 8'b00000000;
    reg[7:0] prev_y = 8'b00000000;
	 
	 reg[7:0] preview_counter = 8'b0000000;
	 
	 reg check;
    always@(posedge clk)
    begin
         next <= 1'b0; 
        if (ld_screen) begin //fill up the screen with w/e color;
            counter <= 5'b00000;
            colour <= 3'b000;
				//check <= 1'b0;
            if (fill_x == 8'b0000000 && fill_y == 8'b00000000) begin
                x <= 8'b00000000;
                y <= 8'b00000000;
                fill_x = 8'b00000001;
                fill_y = 8'b00000001;
            end
            else if (fill_x != 8'b10100000 || fill_y != 8'b01111000) begin
                if (fill_x != 8'b10100000) begin
                    x <= fill_x;
                    fill_x <= fill_x + 1'b1;
                          end
                else begin
                    fill_x = 8'b00000000;
                    fill_y <= fill_y + 1'b1;
                          
                    x <= fill_x;
                    y <= fill_y;
                end 
                end
                else begin
                    fill_x <= 0;
                    fill_y <= 0;
            end
                loser <= 1'b0;
        end

    if (load) begin
            if (counter == 5'b00000) begin
            //BLOCK 1
                x[7:0] <= 8'b00000101; //5
                y[7:0] <= 8'b00001011; //11
                colour <= 3'b000;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b00001) begin
                //BLOCK 2
                x[7:0] <= 8'b00010010; //18
                y[7:0] <= 8'b00001010; //10
                colour <= 3'b011;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b00010) begin
                //BLOCK 3
                x[7:0] <= 8'b00010001; //17
                y[7:0] <= 8'b00011001; //25
               
                colour <= 3'b011;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b00011) begin
                //BLOCK 4
                x[7:0] <= 8'b00001001; //9
                y[7:0] <= 8'b00011000; //24
               
                colour <= 3'b111;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b00100) begin
            //BLOCK 5
                x[7:0] <= 8'b00001010; //10
                y[7:0] <= 8'b01000100; //68
                colour <= 3'b011;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b00101) begin
                //BLOCK 6
                x[7:0] <= 8'b01010001; //81
                y[7:0] <= 8'b01000011; //67
                colour <= 3'b111;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b00110) begin
            //BLOCK 7
                x[7:0] <= 8'b01010000; //80
                y[7:0] <= 8'b00101000; //40
                colour <= 3'b011;
                counter <= counter + 1'b1;
            end
            //BLOCK 8

            else if (counter == 5'b00111) begin
                x[7:0] <= 8'b01101111; //111
                y[7:0] <= 8'b00101001; //41
                colour <= 3'b111;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b01000) begin
                //END
                x[7:0] <= 8'b01101110; //110
                y[7:0] <= 8'b00001100; //12
                colour <= 3'b010;
                counter <= counter + 1'b1;
            end

            //BAITS
            else if (counter == 5'b01001) begin
                x[7:0] <= 8'b00011000; //24
                y[7:0] <= 8'b00110111; //55
                colour <= 3'b111;
                counter <= counter + 1'b1;
            end
            else if (counter == 5'b01010) begin
                x[7:0] <= 8'b00101000; //40
                y[7:0] <= 8'b00110010; //50
                colour <= 3'b011;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b01011) begin
                x[7:0] <= 8'b00001111; //15
                y[7:0] <= 8'b01100100; //100
                colour <= 3'b011;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b01100) begin
                x[7:0] <= 8'b01010101; //85
                y[7:0] <= 8'b01101110; //110
                colour <= 3'b111;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b01101) begin
                x[7:0] <= 8'b10001100; //140
                y[7:0] <= 8'b00010010; //50
                colour <= 3'b011;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b01110) begin
                x[7:0] <= 8'b00010010; //50
                y[7:0] <= 8'b00010010; //18
                colour <= 3'b011;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b01111) begin
                x[7:0] <= 8'b10010001; //145
                y[7:0] <= 8'b00100011; //35
                colour <= 3'b111;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b10000) begin
                x[7:0] <= 8'b01011010; //90
                y[7:0] <= 8'b00111100; //60
                colour <= 3'b111;
                counter <= counter + 1'b1;
            end
               
            else if (counter == 5'b10001) begin
                    x[7:0] <= 8'b10101010;
                    y[7:0] <= 8'b10000000;
                    colour <= 3'b111;
                    counter <= counter + 1'b1;
                end
            else if (counter == 5'b10010) begin
                //First 2x2 block
                x[7:0] <= 8'b00000100; //4
                y[7:0] <= 8'b00001011; //11
                colour <= 3'b111;
                counter <= counter + 1'b1;
                end
              else if (counter == 5'b10011) begin
                x[7:0] <= 8'b00000101; //5
                y[7:0] <= 8'b00001100; //12
                colour <= 3'b111;
                counter <= counter + 1'b1;
                end
              else if (counter == 5'b10100) begin
                x[7:0] <= 8'b00000100; //4
                y[7:0] <= 8'b00001100; //12
                colour <= 3'b111;
                counter <= counter + 1'b1;
                end
				  else if (counter == 5'b10101) begin
					x[7:0] <= 8'b00000101;
					y[7:0] <= 8'b00001011;
					colour <=3'b111;
					counter <= counter + 1'b1;
					end
              else if (counter == 5'b10110) begin
                    //LOAD PLAYER;
                    x[7:0] <= 8'b00000101; //5
                    y[7:0] <= 8'b00000011; //3
                    win <= 1'b0;
                    loser <= 1'b0;
                    colour <= 3'b110;
                    prev_x <= x;
                    prev_y <= y;
           end
        end
        if (player) begin
            colour <= 3'b110;
            //LEFT
            if (left == 1'b1) begin
                prev_y <= y;
                if (prev_x[7:0] == 8'b00010001 && y[7:0] == 8'b00011000)
                    colour <= 3'b110;
                else if (x[7:0] == 8'b00000000)
                    loser <= 1'b1;
                else if (x[7:0] == 8'b10100000)
                    loser <= 1'b1;
                else if (x[7:0] == 8'b00001010 && y[7:0] == 8'b00011000) //(10,24)
                    x[7:0] <= 8'b00001010;
                else
                    x[7:0] <= x - 8'b00000001;
                prev_x <= x - 1'b1;
            end

            //RIGHT
            else if (right == 1'b1) begin
                prev_y <= y;
                if (prev_x == 8'b00000101 && y[7:0] == 8'b00001010 || prev_x == 8'b00001010 && y[7:0] == 8'b01000011 || prev_x[7:0] == 8'b01010000 && y[7:0] == 8'b00101001) //Erasing present position
                    colour<= 3'b110;
                else if (x[7:0] == 8'b00000000)
                    loser <= 1'b1;
                else if (x[7:0] == 8'b10100000)
                    loser <= 1'b1;
                else if (x[7:0] == 8'b00010001 && y[7:0] == 8'b00001010) begin //(17,10)
                          colour <= 3'b110;
                    x <= 8'b00010001;
                    end
                else if (x[7:0] == 8'b01010000 && y[7:0] == 8'b01000011) //(80, 67)
                    x <= 8'b01010000;
                else if (x[7:0] == 8'b01101110 && y[7:0] == 8'b00101001) // (110, 41)
                    x <= 8'b01101110;
                else
                    x[7:0] <= x + 8'b00000001;
                prev_x <= x + 1'b1;
            end

            //UP
            else if (up == 1'b1) begin
                prev_x <= x;
                if (prev_y[7:0] == 8'b01000011 && x[7:0] == 8'b01010000 || prev_y[7:0] == 8'b00101001 && x[7:0] == 8'b01101110)
                    colour <= 3'b110; 
                else if (y[7:0] == 8'b00000000)
                    loser <= 1'b1;
                else if (y[7:0] == 8'b01111000)
                    loser <= 1'b1;
                else if (x[7:0] == 8'b01010000 && y[7:0] == 8'b00101001) // (80, 41)
                    y <= 8'b00101001;
                else if (x[7:0] == 8'b01101110 && y[7:0] == 8'b00001101) begin// (110, 13)
                    y <= 8'b00001101;
                    win <= 1'b1;
                    end
                else 
                    y[7:0] <= y - 8'b00000001;
                prev_y <= y - 1'b1;
            end

            //DOWN
            else if (down == 1'b1) begin
                prev_x <= x;                    
                if (prev_y == 8'b00000011 && x == 8'b00000101|| prev_y == 8'b00011000 && x == 8'b00001010 || prev_y[7:0] == 8'b00001010 && x[7:0] == 8'b00010001)
                        colour <= 3'b110;
                else if (y[7:0] == 8'b00000000)
                    loser <= 1'b1;
                else if (y[7:0] == 8'b01111000)
                    loser <= 1'b1;
                else if (x[7:0] == 8'b00000101 && y[7:0] == 8'b00001010) begin //(5,10) 
                    y <= 8'b00001010;
                          end
                else if (x[7:0] == 8'b00010001 && y[7:0] == 8'b00011000) //(17,24)
                    y <= 8'b00011000;
                else if (x[7:0] == 8'b00001010 && y[7:0] == 8'b01000011) //(10, 67)
                            y <= 8'b01000011;
                else 
                    y[7:0] <= y + 8'b00000001;
                prev_y <= y + 1'b1;
            end
                else 
                    colour <= 3'b110;
        end

        if (load2) begin
				if (counter == 5'b00000) begin
            //BLOCK 1
                x[7:0] <= 8'b01011111; //95
                y[7:0] <= 8'b00101000; //40
                colour <= 3'b000;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b00001) begin
                //BLOCK 2
                x[7:0] <= 8'b01011110; //94
                y[7:0] <= 8'b00111111; //63
                colour <= 3'b111;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b00010) begin
                //BLOCK 3
                x[7:0] <= 8'b00111101; //61
                y[7:0] <= 8'b00111110; //62
                colour <= 3'b111;
                counter <= counter + 1'b1;
            end

            else if (counter == 5'b00011) begin
                //BLOCK 4
                x[7:0] <= 8'b00111110; //62
                y[7:0] <= 8'b00011010; //26
                colour <= 3'b111;
                counter <= counter + 1'b1;
            end
				
				else if (counter == 5'b00100) begin
					//BLOCK 5
					x[7:0] <= 8'b00101001; //41
					y[7:0] <= 8'b00011011; //27
					colour <= 3'b010;
					counter <= counter + 1'b1;
				end
				
				else if (counter == 5'b00101) begin
					//BLOCK 6
					x[7:0] <= 8'b01011111; //95
					y[7:0] <= 8'b00101000; //41
					colour <= 3'b111;
					counter <= counter + 1'b1;
				end
				
				else if (counter == 5'b00110) begin
					//BLOCK 7
					x[7:0] <= 8'b01100000; //96
					y[7:0] <= 8'b00101000; //41
					colour <= 3'b111;
					counter <= counter + 1'b1;
				end
				
				else if (counter == 5'b00111) begin
					//BLOCK 8
					x[7:0] <= 8'b01100000; //96
					y[7:0] <= 8'b00100111; //40
					colour <= 3'b111;
					counter <= counter + 1'b1;
				end
					
				else if (counter == 5'b01000) begin
					//BLOCK 9
					x[7:0] <= 8'b01011110; //94 
					y[7:0] <= 8'b01000000; //64
					colour <= 3'b111;
					counter <= counter + 1'b1;
				end
				
				else if (counter == 5'b01001) begin
					//BLOCK 10
					x[7:0] <= 8'b01011111; //95
					y[7:0] <= 8'b01000000; //64
					colour <= 3'b111;
					counter <= counter + 1'b1;
				end
				
				else if (counter == 5'b01010) begin
					//BLOCK 11
					x[7:0] <= 8'b01011111; //95
					y[7:0] <= 8'b00111111; //63
					colour <= 3'b111;
					counter <= counter + 1'b1;
				end
				
				else if (counter == 5'b01011) begin
					//BLOCK 12
					x[7:0] <= 8'b01011111; //95
					y[7:0] <= 8'b00111111; //63
					colour <= 3'b111;
					counter <= counter + 1'b1;
				end				
				
				else if (counter == 5'b01100) begin
					//BLOCK 13
					x[7:0] <= 8'b00111101; //61
					y[7:0] <= 8'b00111111; //63
					colour <= 3'b111;
					counter <= counter + 1'b1;
				end
				
            else if (counter == 5'b01101) begin
                    //LOAD PLAYER;
                    x[7:0] <= 8'b01010000; 
                    y[7:0] <= 8'b00101000;
                    win <= 1'b0;
                    loser <= 1'b0;
                    colour <= 3'b110;
                    prev_x <= x;
                    prev_y <= y;
            end
				preview_counter <= preview_counter + 1'b1;
				if (preview_counter == 8'b1111111)
					next <= 1'b1;
        end

        if (player2) begin
				if (counter == 5'b00000) begin
					x[7:0] <= 8'b01010000; //80
					y[7:0] <= 8'b00101000; //40
					colour <= 3'b110;
					counter <= counter + 5'b00001;
				end
				else begin
					colour <= 3'b110;
					//LEFT
					if (left == 1'b1) begin
						 prev_y <= y;
						 if (x[7:0] == 8'b00000000)
								loser <= 1'b1;
						 else if (x[7:0] == 8'b10100000)
								loser <= 1'b1;
						 else if (x[7:0] == 8'b00111110 && y[7:0] == 8'b00111110)
								x[7:0] <= 8'b00111110;
						 else if (x[7:0] == 8'b00101010 && y[7:0] == 8'b00011011) begin
								x[7:0] <= 8'b00101010;
								win <= 1'b1;
								end
						 else 
								x[7:0] <= x - 8'b00000001;
						 prev_x <= x - 1'b1;
					end

					//RIGHT
					else if (right == 1'b1) begin
						 prev_y <= y;
						 if (x[7:0] == 8'b00000000)
								loser <= 1'b1;
						 else if (x[7:0] == 10100000)
								loser <= 1'b1;
						 else if (x[7:0] == 8'b01011110 && y[7:0] == 8'b00101000) //94 , 40
								x <= 8'b01011110;
						 else 
								x[7:0] <= x + 8'b00000001;
						 prev_x <= x + 1'b1;
					end

					//UP
					else if (up == 1'b1) begin
						 prev_x <= x;
						 if (y[7:0] == 8'b00000000)
								loser <= 1'b1;
						 else if (y[7:0] == 8'b01111000)
								loser <= 1'b1;
						 else if (x[7:0] == 8'b00111110 && y[7:0] == 8'b00011011)
								y <= 8'b00011011;
						 else
								y[7:0] <= y - 8'b00000001;
						 prev_y <= y - 1'b1;
					end

					//DOWN
					else if (down == 1'b1) begin
						 prev_x <= x;     
						 if (y[7:0] == 8'b00000000)
								loser <= 1'b1;
						 else if (y[7:0] == 8'b01111000)
								loser <= 1'b1;
						 else if (x[7:0] == 8'b01011110 && y[7:0] == 8'b00111110)
								y <= 8'b00111110;
						 else 
								y <= y + 8'b00000001;
						 prev_y <= y + 1'b1;
					end
					
					else 
						 colour <= 3'b110;
					//end
			  end
		  end
	end

endmodule
 
module hex_display(IN, OUT);
    input [3:0] IN;
     output reg [7:0] OUT;
     
     always @(*)
     begin
        case(IN[3:0])
            4'b0000: OUT = 7'b1000000;
            4'b0001: OUT = 7'b1111001;
            4'b0010: OUT = 7'b0100100;
            4'b0011: OUT = 7'b0110000;
            4'b0100: OUT = 7'b0011001;
            4'b0101: OUT = 7'b0010010;
            4'b0110: OUT = 7'b0000010;
            4'b0111: OUT = 7'b1111000;
            4'b1000: OUT = 7'b0000000;
            4'b1001: OUT = 7'b0011000;
            4'b1010: OUT = 7'b0001000;
            4'b1011: OUT = 7'b0000011;
            4'b1100: OUT = 7'b1000110;
            4'b1101: OUT = 7'b0100001;
            4'b1110: OUT = 7'b0000110;
            4'b1111: OUT = 7'b0001110;
            
            default: OUT = 7'b0111111;
        endcase

    end
endmodule

/*
module rate_divider(clkin, slow, clkout);
		input clkin;
		input [24:0] slow;
		output reg clkout = 1'b0;
		reg [24:0] counter;
		counter = slow;
 
    always @(posedge clkin) begin
         if (counter == 0) begin
              counter <= slow; //24'b00000011100000000000000;
              clkout <= ~clkout;
         end else begin
              counter <= counter - 1'b1;
         end
    end
endmodule*/

module rate_divider(clkin, clkout);
    reg [24:0] counter = 24'b00000011100000000000000;
    output reg clkout = 1'b0;
    input clkin;
    always @(posedge clkin) begin
         if (counter == 0) begin
              counter <= 24'b00000011100000000000000;
              clkout <= ~clkout;
         end else begin
              counter <= counter - 1'b1;
         end
    end
endmodule

module rate_divider2(clkin, clkout);
    reg [24:0] counter = 24'b00101000000000000000000;
    output reg clkout = 1'b0;
    input clkin;
    always @(posedge clkin) begin
         if (counter == 0) begin
              counter <= 24'b00101000000000000000000;
              clkout <= ~clkout;
         end else begin
              counter <= counter - 1'b1;
         end
    end
endmodule

