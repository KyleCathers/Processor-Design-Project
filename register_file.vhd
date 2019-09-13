library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity register_file is
port(
    rst : in STD_LOGIC;
    clk: in STD_LOGIC;
    
    --read signals
    rd_index1: in STD_LOGIC_VECTOR(2 downto 0); 
    rd_index2: in STD_LOGIC_VECTOR(2 downto 0); 
    rd_data1: out STD_LOGIC_VECTOR(16 downto 0);    -- includes overflow bit
    rd_data2: out STD_LOGIC_VECTOR(16 downto 0);    -- includes overflow bit
    
    --write signals
    wr_index: in STD_LOGIC_VECTOR(2 downto 0); 
    wr_data: in STD_LOGIC_VECTOR(16 downto 0);
    wr_enable: in STD_LOGIC;
    
    switch_data_in: in STD_LOGIC_VECTOR(7 downto 0);
    reg_test_data: out STD_LOGIC_VECTOR(15 downto 0));
end register_file;

architecture behavioural of register_file is
    component display_controller is
        port(
            clk, reset: in STD_LOGIC;
            hex3, hex2, hex1, hex0: in STD_LOGIC_VECTOR(3 downto 0);
            an: out STD_LOGIC_VECTOR(3 downto 0);
            sseg: out STD_LOGIC_VECTOR(6 downto 0));
    end component; 

    type reg_array is array (integer range 0 to 7) of STD_LOGIC_VECTOR(16 downto 0);
    --internals signals
    signal reg_file: reg_array := (others => (others => '0'));
    
begin
    --write operation 
    process(clk, rst)
    begin
        if (rst = '1') then
            for i in 0 to 7 loop
                reg_file(i)<= '0' & x"0000";  -- overflow bit always 0
            end loop;
        end if;
        
        if(clk = '0' and clk'event) then
            if(wr_enable = '1') then
                case wr_index is
                    when "000" => reg_file(0) <= wr_data;
                    when "001" => reg_file(1) <= wr_data;
                    when "010" => reg_file(2) <= wr_data;
                    when "011" => reg_file(3) <= wr_data;
                    when "100" => reg_file(4) <= wr_data;
                    when "101" => reg_file(5) <= wr_data;
                    when "110" => reg_file(6) <= wr_data;
                    when "111" => reg_file(7) <= wr_data;
                      --register file writes value from wr_data to register determined by wr_index
                    when others => NULL;
                end case;
            end if; 
        end if;
        
        case switch_data_in is
            when x"01" =>
                reg_test_data <= reg_file(0)(15 downto 0);
            when x"02" =>
                reg_test_data <= reg_file(1)(15 downto 0);
            when x"04" =>
                reg_test_data <= reg_file(2)(15 downto 0);
            when x"08" =>
                reg_test_data <= reg_file(3)(15 downto 0);
            when x"10" =>
                reg_test_data <= reg_file(4)(15 downto 0);
            when x"20" =>
                reg_test_data <= reg_file(5)(15 downto 0);
            when x"40" =>
                reg_test_data <= reg_file(6)(15 downto 0);
            when x"80" =>
                reg_test_data <= reg_file(7)(15 downto 0);
            when others =>
                reg_test_data <= x"FAFF";
        end case;
        
    end process;
    
    --read operation
    rd_data1 <=	
        reg_file(0) when (rd_index1 = "000") else
        reg_file(1) when (rd_index1 = "001") else
        reg_file(2) when (rd_index1 = "010") else
        reg_file(3) when (rd_index1 = "011") else
        reg_file(4) when (rd_index1 = "100") else
        reg_file(5) when (rd_index1 = "101") else
        reg_file(6) when (rd_index1 = "110") else
        reg_file(7);
    
    rd_data2 <=
        reg_file(0) when (rd_index2 = "000") else
        reg_file(1) when (rd_index2 = "001") else
        reg_file(2) when (rd_index2 = "010") else
        reg_file(3) when (rd_index2 = "011") else
        reg_file(4) when (rd_index2 = "100") else
        reg_file(5) when (rd_index2 = "101") else
        reg_file(6) when (rd_index2 = "110") else
        reg_file(7);
end behavioural;