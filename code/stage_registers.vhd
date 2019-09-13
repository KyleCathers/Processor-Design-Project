-------------- program counter (IF register) ---------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity reg_PC is
    port(
        clk: in STD_LOGIC;                                  -- Clock
        halt: in STD_LOGIC;                                 -- Halt
        write_en: in STD_LOGIC;
        resetexecute: in STD_LOGIC;
        resetload: in STD_LOGIC;
        address_assign: in STD_LOGIC_VECTOR (15 downto 0);   -- Address assigned value
        address: out STD_LOGIC_VECTOR (15 downto 0) := x"0000");        -- Address output
end reg_PC;

architecture Behavioral of reg_PC is
    signal programCounter : STD_LOGIC_VECTOR(15 downto 0) := x"0000";
begin
    process (clk, address_assign, programCounter, write_en, resetexecute, resetload)
    begin
        if (resetexecute = '1') then
            programCounter <= x"0000";                         -- vector to 0
        elsif (resetload = '1') then
            programCounter <= x"0002";                         -- vector to 2
        elsif (RISING_EDGE(clk)) then
            if (write_en = '1') then
                -- Set PC to new value (from address_assign)
                programCounter <= address_assign(15 downto 1) & '0'; -- ensure even bytes   
            elsif (halt /= '1') then
                programCounter <= STD_LOGIC_VECTOR(UNSIGNED(programCounter) + 2);
            end if;
        end if;
        address <= programCounter; 
    end process;
end Behavioral;

---------------------- IF/ID register ----------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg_IF_ID is
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        
        instruction: in STD_LOGIC_VECTOR (15 downto 0);
        addr_in: in STD_LOGIC_VECTOR (15 downto 0);
        
        addr_out: out STD_LOGIC_VECTOR (15 downto 0);
        opcode_out: out STD_LOGIC_VECTOR (6 downto 0);
        ra_out, rb_out, rc_out: out STD_LOGIC_VECTOR (2 downto 0);
        displ_out: out STD_LOGIC_VECTOR (8 downto 0);
        disps_out: out STD_LOGIC_VECTOR (5 downto 0);
        shift_out: out STD_LOGIC_VECTOR (3 downto 0);
        m_out: out STD_LOGIC;
        imm_out: out STD_LOGIC_VECTOR(7 downto 0);
        
        branch_flag: out STD_LOGIC := '0');
end reg_IF_ID;

architecture behavioral of reg_IF_ID is
begin
    process (clk, instruction)
    begin
        if RISING_EDGE(clk) then
            if reset = '1' then
                opcode_out <= "0000000";
                branch_flag <= '0';
            else
                opcode_out <= instruction(15 downto 9);
                addr_out <= addr_in;
                case instruction(15 downto 9) is
                    -- a0 format
                    when "0000000" =>
                        branch_flag <= '0';
                    -- a1 format
                    when "0000001" | "0000010" | "0000011" | "0000100" =>
                        ra_out <= instruction(8 downto 6);
                        rb_out <= instruction(5 downto 3);
                        rc_out <= instruction(2 downto 0);
                        branch_flag <= '0';
                    -- a2 format
                    when "0000101" | "0000110" =>
                        ra_out <= instruction(8 downto 6);
                        shift_out <= instruction(3 downto 0);
                        branch_flag <= '0';
                    -- a3 format
                    when "0000111" | "0100000" | "0100001" =>
                        ra_out <= instruction(8 downto 6);
                        branch_flag <= '0';
                    -- b1 format
                    when "1000000" | "1000001" | "1000010" | "1001000" =>
                        displ_out <= instruction(8 downto 0);
                        branch_flag <= '1';
                    -- b2 format
                    when "1000011" | "1000100" | "1000101" | "1000110" =>
                        ra_out <= instruction(8 downto 6);
                        disps_out <= instruction(5 downto 0);
                        branch_flag <= '1';
                    -- L1 format (loadimm)
                    when "0010010" =>
                        m_out <= instruction(8);
                        imm_out <= instruction(7 downto 0);
                        ra_out <= "111";
                        branch_flag <= '0';
                    -- L2 format
                    when "0010000" | "0010001" | "0010011" =>
                        ra_out <= instruction(8 downto 6);      -- r.dest
                        rb_out <= instruction(5 downto 3);      -- r.src
                        branch_flag <= '0';
                    when others => NULL;
                end case;
            end if;
        end if;
    end process;
end behavioral;

----------------------- ID/EX register ------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg_ID_EX is
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;

        opcode_in: in STD_LOGIC_VECTOR (6 downto 0);
        data1_in, data2_in: in STD_LOGIC_VECTOR (16 downto 0);  -- read from register file
        shift_in: in STD_LOGIC_VECTOR (3 downto 0);
        ra_in: in STD_LOGIC_VECTOR (2 downto 0);    -- target register for WB
        rb_in: in STD_LOGIC_VECTOR (2 downto 0);    -- RB index (data1_in operand)
        rc_in: in STD_LOGIC_VECTOR (2 downto 0);    -- RC index (data2_in operand)
        addr_in: in STD_LOGIC_VECTOR (15 downto 0);
        displ_in: in STD_LOGIC_VECTOR (8 downto 0);
        disps_in: in STD_LOGIC_VECTOR (5 downto 0);
        m_in: in STD_LOGIC;
        imm_in: in STD_LOGIC_VECTOR(7 downto 0);
        
        addr_out: out STD_LOGIC_VECTOR (15 downto 0);
        opcode_out: out STD_LOGIC_VECTOR (6 downto 0);
        data1_out, data2_out: out STD_LOGIC_VECTOR (16 downto 0);
        shift_out: out STD_LOGIC_VECTOR (3 downto 0);
        displ_out: out STD_LOGIC_VECTOR (8 downto 0);
        disps_out: out STD_LOGIC_VECTOR (5 downto 0);
        ra_out: out STD_LOGIC_VECTOR (2 downto 0);
        rb_out: out STD_LOGIC_VECTOR (2 downto 0);    -- RB index (data1_out operand)
        rc_out: out STD_LOGIC_VECTOR (2 downto 0);    -- RC index (data2_out operand)
        m_out: out STD_LOGIC;
        imm_out: out STD_LOGIC_VECTOR(7 downto 0);
        
        branch_flag: out STD_LOGIC := '0');
end reg_ID_EX;

architecture behavioral of reg_ID_EX is
begin
    process (clk, opcode_in, data1_in, data2_in, shift_in, ra_in)
    begin
        if RISING_EDGE(clk) then
            if reset = '1' then
                opcode_out <= "0000000";
                branch_flag <= '0';
            else
                opcode_out <= opcode_in;
                case opcode_in is
                    when "1000000" | "1000001" | "1000010" | "1000011" |
                        "1000100" | "1000101" | "1000110" | "1000111" | "1001000" =>
                        branch_flag <= '1';
                    when others =>
                        branch_flag <= '0';
                end case;
            end if;
            
            
            ra_out <= ra_in;
            rb_out <= rb_in;
            rc_out <= rc_in;
            shift_out <= shift_in;
            data1_out <= data1_in;
            data2_out <= data2_in;
            addr_out <= addr_in;
            disps_out <= disps_in;
            displ_out <= displ_in;
            m_out <= m_in;
            imm_out <= imm_in;
        end if;
    end process;
end behavioral;


----------------------- EX/MEM register ------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg_EX_MEM is
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        
        opcode_in: in STD_LOGIC_VECTOR (6 downto 0);
        result_in: in STD_LOGIC_VECTOR (16 downto 0);
        ra_in: in STD_LOGIC_VECTOR (2 downto 0);
        addr_in: in STD_LOGIC_VECTOR (15 downto 0);
        pc_target_in: in STD_LOGIC_VECTOR (15 downto 0);
        dest_data_in: in STD_LOGIC_VECTOR (15 downto 0);
        
        addr_out: out STD_LOGIC_VECTOR (15 downto 0);
        opcode_out: out STD_LOGIC_VECTOR (6 downto 0);
        result_out: out STD_LOGIC_VECTOR (16 downto 0);
        ra_out: out STD_LOGIC_VECTOR (2 downto 0);
        pc_target_out: out STD_LOGIC_VECTOR (15 downto 0);
        dest_data_out: out STD_LOGIC_VECTOR (15 downto 0);
        
        branch_flag: out STD_LOGIC := '0');
        
end reg_EX_MEM;

architecture Behavioral of reg_EX_MEM is
begin
    process (clk, opcode_in, result_in, ra_in)
    begin
        if RISING_EDGE(clk) then
            if reset = '1' then
                opcode_out <= "0000000";
                branch_flag <= '0';
            else
                opcode_out <= opcode_in;
                case opcode_in is
                    when "1000000" | "1000001" | "1000010" | "1000011" |
                        "1000100" | "1000101" | "1000110" | "1000111" | "1001000" =>
                        branch_flag <= '1';
                    when others =>
                        branch_flag <= '0';
                end case;
            end if;
            
            result_out <= result_in;
            ra_out <= ra_in;
            addr_out <= addr_in;
            pc_target_out <= pc_target_in;
            dest_data_out <= dest_data_in;
        end if;
    end process;
end behavioral;

----------------------- MEM/WB register ------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg_MEM_WB is
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        
        opcode_in: in STD_LOGIC_VECTOR (6 downto 0);
        result_in: in STD_LOGIC_VECTOR (16 downto 0);   -- result from ALU
        ra_in: in STD_LOGIC_VECTOR (2 downto 0);        -- target register for WB
        addr_in: in STD_LOGIC_VECTOR (15 downto 0);
        
        addr_out: out STD_LOGIC_VECTOR (15 downto 0);
        opcode_out: out STD_LOGIC_VECTOR (6 downto 0);
        result_out: out STD_LOGIC_VECTOR (16 downto 0);
        ra_out: out STD_LOGIC_VECTOR (2 downto 0));

end reg_MEM_WB;

architecture behavioral of reg_MEM_WB is
begin
    process (clk, opcode_in, result_in, ra_in)
    begin
        if RISING_EDGE(clk) then
            if reset = '1' then
                opcode_out <= "0000000";
            else
                opcode_out <= opcode_in;
            end if;
            
            result_out <= result_in;
            ra_out <= ra_in;
            addr_out <= addr_in;
        end if;
    end process;
end behavioral;
