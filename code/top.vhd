library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top is 
    port(
        IN_PORT: in STD_LOGIC_VECTOR (15 downto 2);
        ACK_SIGNAL: out STD_LOGIC;
        CLOCK: in STD_LOGIC;
        RESETEXECUTE: in STD_LOGIC;
        RESETLOAD: in STD_LOGIC;
        DISPLAY_CLK: in STD_LOGIC;
        SSEG: out STD_LOGIC_VECTOR(6 downto 0);
        AN: out STD_LOGIC_VECTOR(3 downto 0);
        SWITCH_DATA_IN: in STD_LOGIC_VECTOR(15 downto 0);
        HALTPC: out STD_LOGIC;
        BRANCHFLAG: out STD_LOGIC);
end top;

architecture behavioral of Top is
    component Processor is
        port(
            IN_PORT: in STD_LOGIC_VECTOR (15 downto 0);
            OUT_PORT: out STD_LOGIC_VECTOR (15 downto 0);
            CLOCK, RESETEXECUTE, RESETLOAD: in STD_LOGIC;

            -- ROM bus
            addra_ROM: out STD_LOGIC_VECTOR (8 downto 0);
            rsta_ROM, ena_ROM: out STD_LOGIC;
            douta_ROM: in STD_LOGIC_VECTOR(15 downto 0);
            
            -- RAM bus
            rsta_RAM, ena_RAM, rstb_RAM, enb_RAM: out STD_LOGIC;
            wea_RAM: out STD_LOGIC_VECTOR(0 downto 0);
            dina_RAM: out STD_LOGIC_VECTOR(15 downto 0);
            addra_RAM, addrb_RAM: out STD_LOGIC_VECTOR(8 downto 0);
            douta_RAM, doutb_RAM: in STD_LOGIC_VECTOR(15 downto 0);

            -- I/O Signals
            display_out: out STD_LOGIC_VECTOR(15 downto 0) := x"0000";
            switch_data_in: in STD_LOGIC_VECTOR(15 downto 0);
            HALTPC: out STD_LOGIC;
            BRANCHFLAG: out STD_LOGIC);
    end component;
    
    component SPROM is
        port(
            addra: in STD_LOGIC_VECTOR (8 downto 0);
            clka: in STD_LOGIC;
            rsta: in STD_LOGIC;
            ena: in STD_LOGIC;
            douta: out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    component DPDISTRAM is
        port(
             dina: in STD_LOGIC_VECTOR (15 downto 0);
             addra: in STD_LOGIC_VECTOR (8 downto 0);
             addrb: in STD_LOGIC_VECTOR (8 downto 0);
             wea: in STD_LOGIC_VECTOR (0 downto 0);
             clka: in STD_LOGIC;
             rsta: in STD_LOGIC;
             rstb: in STD_LOGIC;
             ena: in STD_LOGIC;
             enb: in STD_LOGIC;
             douta: out STD_LOGIC_VECTOR (15 downto 0);
             doutb: out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    component display_controller is
        port(
            clk, reset: in STD_LOGIC;
            hex3, hex2, hex1, hex0: in STD_LOGIC_VECTOR(3 downto 0);
            an: out STD_LOGIC_VECTOR(3 downto 0);
            sseg: out STD_LOGIC_VECTOR(6 downto 0));
    end component; 

    -- TOP signals
    signal in_port_processor: STD_LOGIC_VECTOR(15 downto 0);
    signal out_port_processor: STD_LOGIC_VECTOR(15 downto 0);
    
    -- processor IO signals
    signal display_out_s: STD_LOGIC_VECTOR(15 downto 0) := x"0000";
    
    -- ROM signals
    signal addra_ROM_s: STD_LOGIC_VECTOR(8 downto 0);
    signal rsta_ROM_s, ena_ROM_s: STD_LOGIC;
    signal douta_ROM_s: STD_LOGIC_VECTOR(15 downto 0);
    
    -- RAM signals
    signal dina_RAM_s, douta_RAM_s, doutb_RAM_s: STD_LOGIC_VECTOR(15 downto 0);
    signal addra_RAM_s, addrb_RAM_s: STD_LOGIC_VECTOR(8 downto 0);
    signal wea_RAM_s: STD_LOGIC_VECTOR(0 downto 0);
    signal rsta_RAM_s, rstb_RAM_s, ena_RAM_s, enb_RAM_s: STD_LOGIC;
    
begin 
    processor_mapping: Processor port map(IN_PORT => in_port_processor, OUT_PORT => out_port_processor, CLOCK => CLOCK,
                RESETEXECUTE => RESETEXECUTE, RESETLOAD => RESETLOAD, addra_ROM => addra_ROM_s, rsta_ROM => rsta_ROM_s,
                ena_ROM => ena_ROM_s, douta_ROM => douta_ROM_s, wea_RAM => wea_RAM_s, rsta_RAM => rsta_RAM_s,
                ena_RAM => ena_RAM_s, rstb_RAM => rstb_RAM_s, enb_RAM => enb_RAM_s, dina_RAM => dina_RAM_s,
                addra_RAM => addra_RAM_s, addrb_RAM => addrb_RAM_s, douta_RAM => douta_RAM_s, doutb_RAM => doutb_RAM_s,
                display_out => display_out_s, switch_data_in => SWITCH_DATA_IN, BRANCHFLAG => BRANCHFLAG, HALTPC => HALTPC);

    rom_mapping: SPROM port map(addra => addra_ROM_s, clka => CLOCK, rsta => rsta_ROM_s, ena => ena_ROM_s, douta => douta_ROM_s);
    
    ram_mapping: DPDISTRAM port map(dina => dina_RAM_s, addra => addra_RAM_s, addrb => addrb_RAM_s,
                wea => wea_RAM_s, clka => CLOCK, rsta => rsta_RAM_s, rstb => rstb_RAM_s,
                ena => ena_RAM_s, enb => enb_RAM_s, douta => douta_RAM_s, doutb => doutb_RAM_s);

    display_mapping: display_controller port map(clk => DISPLAY_CLK, reset => '0', hex3 => display_out_s(15 downto 12), hex2 => display_out_s(11 downto 8),
        hex1 => display_out_s(7 downto 4), hex0 => display_out_s(3 downto 0), an => AN, sseg => SSEG);

    in_port_processor <= IN_PORT  & "00";
    ACK_SIGNAL <= out_port_processor(0);
end behavioral;
