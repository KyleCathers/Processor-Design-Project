library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- clk is the 50Mhz system clock FPGA pin B8
-- reset is is FPGA pin B18
-- hex3, hex2,hex1 and hex0 are four bit arrays used to store hex display character
-- an (an0,an1, an2, an3) four bit array that connect to the display transistors
-- sseg 7bit array that stores the individual segments of the hex display
-- refer to ucf file and Nexys2 manual

entity display_controller is
	port(
		clk, reset: in STD_LOGIC;
		hex3, hex2, hex1, hex0: in STD_LOGIC_VECTOR(3 downto 0);
		an: out STD_LOGIC_VECTOR(3 downto 0);
		sseg: out STD_LOGIC_VECTOR(6 downto 0)
	);
end display_controller;

-- This architecture below describes the behavior of the multiplexer using its individual processes as well as
-- its seven-segment decoder to display numbers on the anodes using cathodes. 

architecture arch of display_controller is 
	-- each 7-seg led enabled (2^18/4)*25 ns (40 ms)
	constant N: integer:=18;
	
	-- These signals are operations within the FPGA that help the processes overall but that we cannot see.
	--q_reg and q_next are 18 bit arrays, in this application N=18
        --sel is a 2 bit array that selects the hex display
        --hex is a 4 bit array the contains the hex value to be displayed
	signal q_reg, q_next: UNSIGNED(1 downto 0);
	signal sel: STD_LOGIC_VECTOR(1 downto 0);
	signal hex: STD_LOGIC_VECTOR(3 downto 0);
	
	signal clk_out: STD_LOGIC;
	signal temp: STD_LOGIC;
	signal count: integer range 0 to 124999 := 0;
		
begin

    -- This process divides the clock down to 200Hz
    -- the division down is based on the scale factor
    -- obtained by: scale=fin/fout
    --                   =50Mhz/200Hz
    --                   =250000
    divider: process(clk,reset) begin
        if(reset = '1') then
            temp <= '0';
            count <= 0;
        elsif rising_edge(clk) then
            if (count = 124999) then
                temp <= NOT(temp);
                count <= 0;
            else
                count <= count + 1;
            end if;
        end if;
    end process;
    
    clk_out <= temp;

	-- This process controls the reset button of the clock.
	process(clk_out, reset)
	begin
		if reset='1' then                       --If button pressed all  bits in q_reg set to 0
			q_reg <= (others=>'0');
		elsif (clk_out'event and clk_out='1') then       --If clock is rising q_next assigned to q_reg
			q_reg <= q_next;
		end if;
	end process;
	
	-- State logic for the counter                  --Increment q_reg and assign to q_next
	q_next <= q_reg + 1;
	
	-- 2 MSBs of counter to control 4-to-1 multiplexing 
	--assign bits17 and 16 to sel array
    sel <= STD_LOGIC_VECTOR(q_reg);   
	
	-- This is the 2:4 decoder, which converts a two-bit input into a four-bit input for the seven-segment decoder.
	
        --The value in the sel array will determine which of the Case statements is selected. Since 
        -- the sel array is two bits then there are only four possible cases 0,1,2,3.
        --The value in an will determine which transistor is turned on that selects one of four hex
        --displays.
        --The hex0, hex1, hex2, and hex3 value comes from the Counter.vhd file

	process(sel, hex0, hex1, hex2, hex3)
	begin
		case sel is
			when "00" =>
				an <= "1110";
				hex <= hex0;
			when "01" =>
				an <= "1101";
				hex <= hex1;
			when "10" =>
				an <= "1011";
				hex <= hex2;
			when others =>
				an <= "0111";
				hex <= hex3;
		end case;
	end process;
	
	-- The value that was assigned to the hex array is used to assign the sseg array. Example: If   
        -- the hex array contained the value 1001 (9) then the sseg array would be assigned the 
        -- value 0010000 which would display a 9 on the selected hex display. See reference 
        --if needed
	
	with hex select
		sseg(6 downto 0) <=
			"1000000" when "0000", -- 0
			"1111001" when "0001", -- 1
			"0100100" when "0010", -- 2
			"0110000" when "0011", -- 3
			"0011001" when "0100", -- 4
			"0010010" when "0101", -- 5
			"0000010" when "0110", -- 6
			"1111000" when "0111", -- 7
			"0000000" when "1000", -- 8
			"0010000" when "1001", -- 9
			"0001000" when "1010", -- A, which signifies "10"
			"0000011" when "1011", -- B, which signifies "11"
			"1000110" when "1100", -- C, which signifies "12"
			"0100001" when "1101", -- D, which signifies "13"
			"0000110" when "1110", -- E, which signifies "14"
			"0001110" when others;  -- F, which signifies "15"
end arch;