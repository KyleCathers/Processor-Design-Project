----------------------- OPCODES --------------------------
-- "0000000"                                  -- NOP
-- "0000001"                                  -- ADD
-- "0000010"                                  -- SUB
-- "0000011"                                  -- MUL
-- "0000100"                                  -- NAND
-- "0000101"                                  -- SHL
-- "0000110"                                  -- SHR
-- "0000111"                                  -- TEST
-- "0100000"                                  -- OUT
-- "0100001"                                  -- IN
-- "1000000"                                  -- BRR
-- "1000001"                                  -- BRR.N
-- "1000010"                                  -- BRR.Z
-- "1000011"                                  -- BR
-- "1000100"                                  -- BR.N
-- "1000101"                                  -- BR.Z
-- "1000110"                                  -- BR.SUB
-- "1000111"                                  -- RETURN
-- "0010000"                                  -- LOAD
-- "0010001"                                  -- STORE
-- "0010010"                                  -- LOADIMM
-- "0010011"                                  -- MOV
-- "1100000"                                  -- PUSH
-- "1100001"                                  -- POP
-- "1100010"                                  -- LOAD.SP
-- "1100011"                                  -- RTI
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Processor is
    port(
        IN_PORT: in STD_LOGIC_VECTOR(15 downto 0);
        OUT_PORT: out STD_LOGIC_VECTOR(15 downto 0);
        CLOCK, RESETEXECUTE, RESETLOAD: in STD_LOGIC;
        
        -- ROM bus
        addra_ROM: out STD_LOGIC_VECTOR(8 downto 0) := "000000000";
        rsta_ROM: out STD_LOGIC := '0';
        ena_ROM: out STD_LOGIC := '1';
        douta_ROM: in STD_LOGIC_VECTOR(15 downto 0);
        
        -- RAM bus
        rsta_RAM, rstb_RAM: out STD_LOGIC := '0';
        ena_RAM, enb_RAM: out STD_LOGIC := '1';
        wea_RAM: out STD_LOGIC_VECTOR(0 downto 0) := "0";
        dina_RAM: out STD_LOGIC_VECTOR(15 downto 0) := x"0000";
        addra_RAM, addrb_RAM: out STD_LOGIC_VECTOR(8 downto 0) := "000000000";
        douta_RAM, doutb_RAM: in STD_LOGIC_VECTOR(15 downto 0);
        
        -- I/O Signals
        display_out: out STD_LOGIC_VECTOR(15 downto 0) := x"0000";
        switch_data_in: in STD_LOGIC_VECTOR(15 downto 0);
        HALTPC: out STD_LOGIC;
        BRANCHFLAG: out STD_LOGIC);
end processor;

architecture behavioral of Processor is
    -- fetch (program counter)
    component reg_PC is
        port(
            clk: in STD_LOGIC;
            halt: in STD_LOGIC;
            write_en: in STD_LOGIC;
            resetexecute: in STD_LOGIC;
            resetload: in STD_LOGIC;
            address_assign: in STD_LOGIC_VECTOR (15 downto 0);
            address: out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    -- decode
    component reg_IF_ID is  
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
            
            branch_flag: out STD_LOGIC);
    end component;
    
    -- execute
    component reg_ID_EX is  
        port(
            clk: in STD_LOGIC;
            reset: in STD_LOGIC;
                   
            opcode_in: in STD_LOGIC_VECTOR (6 downto 0);
            data1_in, data2_in: in STD_LOGIC_VECTOR (16 downto 0);
            shift_in: in STD_LOGIC_VECTOR (3 downto 0);
            ra_in: in STD_LOGIC_VECTOR (2 downto 0);
            rb_in: in STD_LOGIC_VECTOR (2 downto 0);
            rc_in: in STD_LOGIC_VECTOR (2 downto 0);
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
            rb_out: out STD_LOGIC_VECTOR (2 downto 0);
            rc_out: out STD_LOGIC_VECTOR (2 downto 0);
            m_out: out STD_LOGIC;
            imm_out: out STD_LOGIC_VECTOR(7 downto 0);
            
            branch_flag: out STD_LOGIC);
    end component;
    
    -- memory access
    component reg_EX_MEM is  
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
            
            branch_flag: out STD_LOGIC);
    end component;
    
    -- writeback
    component reg_MEM_WB is  
        port(
            clk: in STD_LOGIC;
            reset: in STD_LOGIC;

            opcode_in: in STD_LOGIC_VECTOR (6 downto 0);
            result_in: in STD_LOGIC_VECTOR (16 downto 0);
            ra_in: in STD_LOGIC_VECTOR (2 downto 0);
            addr_in: in STD_LOGIC_VECTOR (15 downto 0);
            
            addr_out: out STD_LOGIC_VECTOR (15 downto 0);
            opcode_out: out STD_LOGIC_VECTOR (6 downto 0);
            result_out: out STD_LOGIC_VECTOR (16 downto 0);
            ra_out: out STD_LOGIC_VECTOR (2 downto 0));
    end component;

    component ALU is
        port(
            ALUIN1,ALUIN2: in STD_LOGIC_VECTOR (16 downto 0);
            OPCODE: in STD_LOGIC_VECTOR (6 downto 0);
            SHIFT: in STD_LOGIC_VECTOR (3 downto 0);
            RESET: in STD_LOGIC;
            ALUOUT: out STD_LOGIC_VECTOR (16 downto 0);
            Z_FLAG, N_FLAG, OVERFLOW_FLAG: out STD_LOGIC);
    end component;
    
    component register_file is
        port(
            rst : in std_logic;
            clk: in std_logic;
            
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
    end component;
       
    -- processor flags
    signal branch_flag: STD_LOGIC := '0';
    
    -- PC signals
    signal halt_pc_s: STD_LOGIC := '0';
    signal write_en_pc_s: STD_LOGIC := '0';
    signal addr_assign_s, addr_PC_s: STD_LOGIC_VECTOR(15 downto 0);
   
    -- register file signals
    signal rst_s: STD_LOGIC;
    signal wr_enable_s: STD_LOGIC := '0';
    signal rd_index1_s, rd_index2_s: STD_LOGIC_VECTOR (2 downto 0);
    signal rd_data1_s, rd_data2_s: STD_LOGIC_VECTOR(16 downto 0);
    signal wr_index_s: STD_LOGIC_VECTOR (2 downto 0);
    signal wr_data_s: STD_LOGIC_VECTOR (16 downto 0);
    
    -- ALU signals
    signal aluin1_s, aluin2_s: STD_LOGIC_VECTOR(16 downto 0);
    signal opcode_s: STD_LOGIC_VECTOR(6 downto 0);
    signal shift_s: STD_LOGIC_VECTOR(3 downto 0);
    signal aluout_s: STD_LOGIC_VECTOR(16 downto 0);
    signal z_flag_s, n_flag_s, overflow_flag_s: STD_LOGIC;
    
    -- IF/ID register signals
    signal instruction_dec: STD_LOGIC_VECTOR (15 downto 0) := x"0000";
    signal addr_in_IFID: STD_LOGIC_VECTOR(15 downto 0) := x"0000";
    signal addr_out_IFID: STD_LOGIC_VECTOR (15 downto 0);
    signal opcode_out_dec:  STD_LOGIC_VECTOR (6 downto 0);
    signal ra_out_dec, rb_out_dec, rc_out_dec:  STD_LOGIC_VECTOR (2 downto 0);
    signal displ_out_dec: STD_LOGIC_VECTOR (8 downto 0);
    signal disps_out_dec: STD_LOGIC_VECTOR (5 downto 0);
    signal shift_out_dec: STD_LOGIC_VECTOR (3 downto 0);
    signal m_out_dec: STD_LOGIC;
    signal imm_out_dec: STD_LOGIC_VECTOR(7 downto 0);
    signal branch_flag_out_dec: STD_LOGIC;
          
    -- ID/EX signals
    signal opcode_in_ex: STD_LOGIC_VECTOR (6 downto 0) := "0000000";
    signal data1_in_ex, data2_in_ex: STD_LOGIC_VECTOR (16 downto 0) := '0' & x"0000";
    signal shift_in_ex: STD_LOGIC_VECTOR (3 downto 0) := x"0";
    signal ra_in_ex, rb_in_ex, rc_in_ex: STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal addr_in_IDEX: STD_LOGIC_VECTOR (15 downto 0) := x"0000";
    signal displ_in_ex: STD_LOGIC_VECTOR (8 downto 0) := "000000000";
    signal disps_in_ex: STD_LOGIC_VECTOR (5 downto 0) := "000000";
    signal m_in_ex: STD_LOGIC := '0';
    signal imm_in_ex: STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal addr_out_IDEX: STD_LOGIC_VECTOR (15 downto 0);
    signal opcode_out_ex: STD_LOGIC_VECTOR (6 downto 0);
    signal data1_out_ex, data2_out_ex: STD_LOGIC_VECTOR (16 downto 0);
    signal shift_out_ex: STD_LOGIC_VECTOR (3 downto 0);
    signal displ_out_ex: STD_LOGIC_VECTOR (8 downto 0);
    signal disps_out_ex: STD_LOGIC_VECTOR (5 downto 0);
    signal ra_out_ex, rb_out_ex, rc_out_ex: STD_LOGIC_VECTOR (2 downto 0);
    signal m_out_ex: STD_LOGIC;
    signal imm_out_ex: STD_LOGIC_VECTOR(7 downto 0);
    signal branch_flag_out_ex: STD_LOGIC;
       
    -- EX/MEM signals
    signal opcode_in_mem: STD_LOGIC_VECTOR (6 downto 0) := "0000000";
    signal result_in_mem: STD_LOGIC_VECTOR (16 downto 0) := '0' & x"0000";
    signal ra_in_mem: STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal addr_in_EXMEM: STD_LOGIC_VECTOR (15 downto 0) := x"0000";
    signal pc_target_in_mem: STD_LOGIC_VECTOR (15 downto 0) := x"0000";
    signal dest_data_in_mem: STD_LOGIC_VECTOR (15 downto 0) := x"0000";
    signal addr_out_EXMEM: STD_LOGIC_VECTOR (15 downto 0);
    signal opcode_out_mem: STD_LOGIC_VECTOR (6 downto 0);
    signal result_out_mem: STD_LOGIC_VECTOR (16 downto 0);
    signal ra_out_mem: STD_LOGIC_VECTOR (2 downto 0);
    signal pc_target_out_mem: STD_LOGIC_VECTOR (15 downto 0);
    signal dest_data_out_mem: STD_LOGIC_VECTOR (15 downto 0);
    signal branch_flag_out_mem: STD_LOGIC;
       
    -- MEM/WB signals
    signal opcode_in_wb: STD_LOGIC_VECTOR (6 downto 0) := "0000000";
    signal result_in_wb: STD_LOGIC_VECTOR (16 downto 0) := '0' & x"0000";
    signal ra_in_wb: STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal addr_in_MEMWB: STD_LOGIC_VECTOR (15 downto 0) := x"0000";
    signal addr_out_MEMWB: STD_LOGIC_VECTOR (15 downto 0);
    signal opcode_out_wb: STD_LOGIC_VECTOR (6 downto 0);
    signal result_out_wb: STD_LOGIC_VECTOR (16 downto 0);
    signal ra_out_wb: STD_LOGIC_VECTOR (2 downto 0);
        
    -- debug signals
    signal reg_test_data_s: STD_LOGIC_VECTOR(15 downto 0); 
    signal display_store: STD_LOGIC_VECTOR(15 downto 0) := x"0000"; 
    signal out_port_s: STD_LOGIC_VECTOR(15 downto 0); 
       
begin
    -- constant signal assignments
    branch_flag <= branch_flag_out_dec OR branch_flag_out_ex OR branch_flag_out_mem;
    BRANCHFLAG <= branch_flag;
    HALTPC <= halt_pc_s;
    rst_s <= RESETEXECUTE OR RESETLOAD;

    -- fetch stage signal-to-port mapping
    program_counter: reg_PC port map(clk => CLOCK, halt => halt_PC_s, write_en => write_en_PC_s,
            resetexecute => RESETEXECUTE, resetload => RESETLOAD, address_assign => addr_assign_s, address => addr_PC_s);

    -- decode stage signal-to-port mapping
    reg_ifid: reg_IF_ID port map(clk => CLOCK, instruction => instruction_dec, addr_in => addr_in_IFID,
            addr_out => addr_out_IFID, opcode_out => opcode_out_dec, ra_out => ra_out_dec, rb_out => rb_out_dec,
            rc_out => rc_out_dec, disps_out => disps_out_dec, displ_out => displ_out_dec, shift_out => shift_out_dec,
            m_out => m_out_dec, imm_out => imm_out_dec, reset => rst_s, branch_flag => branch_flag_out_dec);
    
    reg_file: register_file port map(rst => rst_s, clk => CLOCK, rd_index1 => rd_index1_s, wr_data => wr_data_s,
            rd_index2 => rd_index2_s, rd_data1 => rd_data1_s, rd_data2 => rd_data2_s, wr_index => wr_index_s, wr_enable => wr_enable_s,
            switch_data_in => switch_data_in(7 downto 0), reg_test_data => reg_test_data_s);
    
    -- execute stage signal-to-port mapping
    reg_idex: reg_ID_EX port map(clk => CLOCK, opcode_in => opcode_in_ex, data1_in => data1_in_ex, data2_in => data2_in_ex,
            shift_in => shift_in_ex, ra_in => ra_in_ex, rb_in => rb_in_ex, rc_in => rc_in_ex, addr_in => addr_in_IDEX,
            displ_in => displ_in_ex, disps_in => disps_in_ex, m_in => m_in_ex, imm_in => imm_in_ex, addr_out => addr_out_IDEX,
            opcode_out => opcode_out_ex, data1_out => data1_out_ex, data2_out => data2_out_ex, shift_out => shift_out_ex,
            displ_out => displ_out_ex, disps_out => disps_out_ex, ra_out => ra_out_ex, rb_out => rb_out_ex, rc_out => rc_out_ex,
            m_out => m_out_ex, imm_out => imm_out_ex, reset => rst_s, branch_flag => branch_flag_out_ex);
    
    alu_stage: ALU port map(ALUIN1 => aluin1_s, ALUIN2 => aluin2_s, OPCODE => opcode_s, SHIFT => shift_s,
            ALUOUT => aluout_s, Z_FLAG => z_flag_s, N_FLAG => n_flag_s, OVERFLOW_FLAG => overflow_flag_s, RESET => rst_s);
    
    -- memory stage signal-to-port mapping
    reg_exmem: reg_EX_MEM port map(clk => CLOCK, opcode_in => opcode_in_mem, result_in => result_in_mem,
            ra_in => ra_in_mem, addr_in => addr_in_EXMEM, pc_target_in => pc_target_in_mem, dest_data_in => dest_data_in_mem,
            addr_out => addr_out_EXMEM, opcode_out => opcode_out_mem, result_out => result_out_mem, ra_out => ra_out_mem,
            pc_target_out => pc_target_out_mem, dest_data_out => dest_data_out_mem, reset => rst_s, branch_flag => branch_flag_out_mem);
    
    -- writeback signal-to-port mapping
    reg_memwb: reg_MEM_WB port map(clk => CLOCK, opcode_in => opcode_in_wb, result_in => result_in_wb,
            ra_in => ra_in_wb, addr_in => addr_in_MEMWB, addr_out => addr_out_MEMWB,
            opcode_out => opcode_out_wb, result_out => result_out_wb, ra_out => ra_out_wb, reset => rst_s);
            
    -- display debugging
    process(CLOCK, switch_data_in, reg_test_data_s, instruction_dec, display_store, addr_PC_s, out_port_s, opcode_out_mem, rst_s, dest_data_out_mem)
    begin         
        if FALLING_EDGE(CLOCK) then 
            if opcode_out_mem = "0100000" then
                OUT_PORT <= out_port_s;
            end if;
            
            if opcode_out_mem = "0010001" AND dest_data_out_mem = x"FFF2" then
                display_out <= display_store;
            end if;

            -- debug function
            --case switch_data_in is
            --    when x"0001" | x"0002" | x"0004" | x"0008" | x"0010" | x"0020" | x"0040"| x"0080" =>
            --        display_out <= reg_test_data_s;
            --    when x"0100" =>
            --        display_out <= addr_PC_s;
            --    when x"0200" =>
            --        display_out <= instruction_dec;
            --    when x"0400" =>
            --        if opcode_out_mem = "0010001" AND dest_data_out_mem = x"FFF2" then
            --            display_out <= display_store;
            --        end if;
            --    when x"0800" => 
            --        display_out <= dest_data_out_mem;
            --    when others => 
            --        display_out <= x"0000";
            --end case; 
        end if;
    end process;

    -- pipeline
    process(CLOCK, ra_out_dec, rb_out_dec, rc_out_dec, shift_out_dec, opcode_out_dec,
            rd_data1_s, rd_data2_s, data1_out_ex, data2_out_ex, shift_out_ex, ra_out_ex, opcode_out_ex,
            aluout_s, z_flag_s, n_flag_s, overflow_flag_s, result_out_mem, ra_out_mem,
            opcode_out_mem, result_out_wb, ra_out_wb, opcode_out_wb, douta_RAM, rst_s,
            doutb_RAM, douta_ROM, addr_PC_s, addr_assign_s, halt_PC_s, write_en_PC_s, display_store,
            aluin1_s, aluin2_s, opcode_s, shift_s, branch_flag, RESETEXECUTE, RESETLOAD, reg_test_data_s)
    begin
        write_en_PC_s <= '0';
        
        -- pass opcodes to next stage
        opcode_in_ex <= opcode_out_dec;                 -- decode -> execute
        opcode_in_mem <= opcode_out_ex;                 -- execute -> memory access
        opcode_in_wb <= opcode_out_mem;                 -- memory access -> writeback
        
        -- pass PC address to next stage
        addr_in_IFID <= addr_PC_s;                      -- PC -> decode
        addr_in_IDEX <= addr_out_IFID;                  -- decode -> execute
        addr_in_EXMEM <= addr_out_IDEX;                 -- execute -> memory access
        addr_in_MEMWB <= addr_out_EXMEM;                -- memory access -> writeback


----- FETCH Stage -------------------------------------------------------------------------------------------------------------------
        if (RESETEXECUTE = '0') AND (RESETLOAD = '0') then
            if branch_flag = '1' then                       -- feed NOPs while halted
                instruction_dec <= x"0000";
                halt_PC_s <= '1';
            else                                            -- continue normally while not halted
                if addr_PC_s < x"0400" then
                    addra_ROM <= addr_PC_s(9 downto 1);    -- send address to ROM (Bootloader)
                    instruction_dec <= douta_ROM;           -- pass instruction (ROM output) to next stage
                else
                    addrb_RAM <= addr_PC_s(9 downto 1);    -- send address to RAM (processor)
                    instruction_dec <= doutb_RAM;           -- pass instruction (RAM port B output) to next stage
                end if;
                halt_PC_s <= '0';
            end if;
        else
            instruction_dec <= x"0000";
        end if;

----- DECODE Stage ------------------------------------------------------------------------------------------------------------------
        case opcode_out_dec is
            -- NOP
            when "0000000" => NULL;
                
            -- a1 format
            when "0000001" | "0000010" | "0000011" | "0000100" =>
                rd_index1_s <= rb_out_dec;          -- read rb data from regfile
                rd_index2_s <= rc_out_dec;          -- read rc data from regfile
                ra_in_ex <= ra_out_dec;             -- pass ra to next stage
                rb_in_ex <= rb_out_dec;             -- pass rb to next stage
                data1_in_ex <= rd_data1_s;          -- pass rb data to next stage
                rc_in_ex <= rc_out_dec;             -- pass rc to next stage
                data2_in_ex <= rd_data2_s;          -- pass rc data to next stage
               
            -- a2 format
            when "0000101" | "0000110" =>
                rd_index1_s <= ra_out_dec;          -- read rb data from regfile
                ra_in_ex <= ra_out_dec;             -- pass ra to next stage
                shift_in_ex <= shift_out_dec;       -- pass shift to next stage
                rb_in_ex <= rb_out_dec;             -- pass rb to next stage
                data1_in_ex <= rd_data1_s;          -- pass rb data to next stage
                
            -- TEST or OUT instructions
            when "0000111" | "0100000" =>
                rd_index1_s <= ra_out_dec;          -- read ra data from regfile
                data1_in_ex <= rd_data1_s;          -- pass ra data to next stage
                ra_in_ex <= ra_out_dec;             -- pass ra to next stage
                
            -- IN instruction
            when "0100001" =>
                ra_in_ex <= ra_out_dec;             -- pass ra to next stage
                
            -- b1 format
            when "1000000" | "1000001" | "1000010" | "1001000" =>
                displ_in_ex <= displ_out_dec;       -- pass displacement to next stage
                                    
            -- b2 format
            when "1000011" | "1000100" | "1000101" | "1000110" =>
                rd_index1_s <= ra_out_dec;          -- read ra data from regfile
                data1_in_ex <= rd_data1_s;          -- pass ra data to next stage
                disps_in_ex <= disps_out_dec;       -- pass displacement to next stage
     
            -- RETURN
            when "1000111" =>
                rd_index1_s <= "111";               -- read r7 data from regfile
                data1_in_ex <= rd_data1_s;          -- pass r7 data to next stage
            
            -- LOADIMM
            when "0010010" =>
                rd_index1_s <= ra_out_dec;          -- read r7 data from regfile
                data1_in_ex <= rd_data1_s;          -- pass r7 data to next stage
                m_in_ex <= m_out_dec;               -- pass m to next stage
                imm_in_ex <= imm_out_dec;           -- pass imm to next stage
                ra_in_ex <= ra_out_dec;             -- pass r7 to next stage

            -- LOAD & MOV
            when "0010000" | "0010011" =>
                rd_index1_s <= rb_out_dec;          -- read SRC register data from regfile
                data1_in_ex <= rd_data1_s;          -- pass SRC register data to next stage
                ra_in_ex <= ra_out_dec;             -- pass destination to next stage
                rb_in_ex <= rb_out_dec;             -- pass sourcde to next stage
            
            -- STORE
            when "0010001" =>
                rd_index1_s <= rb_out_dec;          -- read SRC register data from regfile
                data1_in_ex <= rd_data1_s;          -- pass SRC register data to next stage
                rd_index2_s <= ra_out_dec;          -- read DEST register data from regfile
                data2_in_ex <= rd_data2_s;          -- pass DEST register data to next stage
                ra_in_ex <= ra_out_dec;             -- pass destination index to next stage
                rb_in_ex <= rb_out_dec;             -- pass source index to next stage

            when others => NULL;
        end case;
        
------ EXECUTE Stage -----------------------------------------------------------------------------------------------------------------
        case opcode_out_ex is                                                                 
            -- NOP
            when "0000000" => NULL;
            
            -- a1 format
            when "0000001" | "0000010" | "0000011" | "0000100" =>
                opcode_s <= opcode_out_ex;      -- pass opcode to ALU
               
                -- ALUIN1 forwarding
                -- check for EXMEM hazrd
                -- if previous instruction writes to reg file
                --      and destination of previous instruction = source for operand 2 data
                if (opcode_out_mem = "0000001" or opcode_out_mem = "0000010"
                        or opcode_out_mem = "0000011" or opcode_out_mem = "0000100"
                        or opcode_out_mem = "0000101" or opcode_out_mem = "0000110"
                        or opcode_out_mem = "0100001" or opcode_out_mem = "0010010"
                        or opcode_out_mem = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_mem = rb_out_ex) then
                    aluin1_s <= result_out_mem; -- then grab result from prev inst
                
                -- check for MEMWB hazard
                -- if instruction 2 cycles ago writes to reg file
                --      and destination of inst 2 cycles ago = source for operand 2 data
                elsif (opcode_out_wb = "0000001" or opcode_out_wb = "0000010"
                        or opcode_out_wb = "0000011" or opcode_out_wb = "0000100"
                        or opcode_out_wb = "0000101" or opcode_out_wb = "0000110"
                        or opcode_out_wb = "0100001" or opcode_out_wb = "0010010"
                        or opcode_out_wb = "0010011" or opcode_out_wb = "0010000")
                        AND (ra_out_wb = rb_out_ex) then
                    aluin1_s <= result_out_wb; -- then grab result from instr 2 cycles ago
                        
                -- otherwise no hazard
                else
                    aluin1_s <= data1_out_ex; -- grab result from decode
                end if;
                                  
                -- ALUIN2 forwarding
                -- check for EXMEM hazrd
                -- if previous instruction writes to reg file
                --      and destination of previous instruction = source for operand 2 data
                if (opcode_out_mem = "0000001" or opcode_out_mem = "0000010"
                        or opcode_out_mem = "0000011" or opcode_out_mem = "0000100"
                        or opcode_out_mem = "0000101" or opcode_out_mem = "0000110"
                        or opcode_out_mem = "0100001" or opcode_out_mem = "0010010"
                        or opcode_out_mem = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_mem = rc_out_ex) then
                    aluin2_s <= result_out_mem; -- then grab result from prev inst
                
                -- check for MEMWB hazard
                -- if instruction 2 cycles ago writes to reg file
                --      and destination of inst 2 cycles ago = source for operand 2 data
                elsif (opcode_out_wb = "0000001" or opcode_out_wb = "0000010"
                        or opcode_out_wb = "0000011" or opcode_out_wb = "0000100"
                        or opcode_out_wb = "0000101" or opcode_out_wb = "0000110"
                        or opcode_out_wb = "0100001" or opcode_out_wb = "0010010"
                        or opcode_out_wb = "0010011" or opcode_out_wb = "0010000")
                        AND (ra_out_wb = rc_out_ex) then
                    aluin2_s <= result_out_wb; -- then grab result from instr 2 cycles ago
                        
                -- otherwise no hazard
                else
                    aluin2_s <= data2_out_ex;   -- grab result from decode
                end if;
                
                result_in_mem <= aluout_s;      -- pass result to next stage
                ra_in_mem <= ra_out_ex;         -- pass ra to next stage               
                
            -- a2 format
            when "0000101" | "0000110" =>
                opcode_s <= opcode_out_ex;      -- pass opcode to ALU

                -- ALUIN1 forwarding
                -- check for EXMEM hazrd
                -- if previous instruction writes to reg file
                --      and destination of previous instruction = source for operand 2 data
                if (opcode_out_mem = "0000001" or opcode_out_mem = "0000010"
                        or opcode_out_mem = "0000011" or opcode_out_mem = "0000100"
                        or opcode_out_mem = "0000101" or opcode_out_mem = "0000110"
                        or opcode_out_mem = "0100001" or opcode_out_mem = "0010010"
                        or opcode_out_mem = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_mem = ra_out_ex) then
                    aluin1_s <= result_out_mem; -- then grab result from prev inst
                
                -- check for MEMWB hazard
                -- if instruction 2 cycles ago writes to reg file
                --      and destination of inst 2 cycles ago = source for operand 2 data
                elsif (opcode_out_wb = "0000001" or opcode_out_wb = "0000010"
                        or opcode_out_wb = "0000011" or opcode_out_wb = "0000100"
                        or opcode_out_wb = "0000101" or opcode_out_wb = "0000110"
                        or opcode_out_wb = "0100001" or opcode_out_wb = "0010010"
                        or opcode_out_wb = "0010011" or opcode_out_wb = "0010000")
                        AND (ra_out_wb = ra_out_ex) then
                    aluin1_s <= result_out_wb; -- then grab result from instr 2 cycles ago
                        
                -- otherwise no hazard
                else
                    aluin1_s <= data1_out_ex;   -- grab result from decode
                end if;
              
                shift_s <= shift_out_ex;        -- pass shift to ALU
                result_in_mem <= aluout_s;      -- pass result to next stage
                ra_in_mem <= ra_out_ex;         -- pass ra to next stage
                
            -- a3 format
            when "0000111" =>                   -- TEST instruction
                opcode_s <= opcode_out_ex;      -- pass opcode to ALU
                     
                -- ALUIN1 forwarding
                -- check for EXMEM hazrd
                -- if previous instruction writes to reg file
                --      and destination of previous instruction = source for operand 2 data
                if (opcode_out_mem = "0000001" or opcode_out_mem = "0000010"
                        or opcode_out_mem = "0000011" or opcode_out_mem = "0000100"
                        or opcode_out_mem = "0000101" or opcode_out_mem = "0000110"
                        or opcode_out_mem = "0100001" or opcode_out_mem = "0010010"
                        or opcode_out_mem = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_mem = ra_out_ex) then
                    aluin1_s <= result_out_mem; -- then grab result from prev inst
                
                -- check for MEMWB hazard
                -- if instruction 2 cycles ago writes to reg file
                --      and destination of inst 2 cycles ago = source for operand 2 data
                elsif (opcode_out_wb = "0000001" or opcode_out_wb = "0000010"
                        or opcode_out_wb = "0000011" or opcode_out_wb = "0000100"
                        or opcode_out_wb = "0000101" or opcode_out_wb = "0000110"
                        or opcode_out_wb = "0100001" or opcode_out_wb = "0010010"
                        or opcode_out_wb = "0010011" or opcode_out_wb = "0010000")
                        AND (ra_out_wb = ra_out_ex) then
                    aluin1_s <= result_out_wb; -- then grab result from instr 2 cycles ago
                        
                -- otherwise no hazard
                else
                    aluin1_s <= data1_out_ex;   -- grab result from decode
                end if;
            
            when "0100001"  =>  -- IN instruction
                result_in_mem <= '0' & IN_PORT;              -- grab IN port data (overflow = 0 by default)
                ra_in_mem <= ra_out_ex;                      -- pass ra to next stage
            
            when "0100000" =>   -- OUT instruction
                result_in_mem <= data1_out_ex;  -- pass ra data to next port

            -- b1 formats
            when "1000000" => -- BRR
                -- PC = PC + 2*disp.l
                pc_target_in_mem <= STD_LOGIC_VECTOR(SIGNED(addr_out_IDEX) + RESIZE((SIGNED(displ_out_ex) & '0'), 16));
            
            when "1000001" => -- BRR.N
                if n_flag_s = '1' then      -- if negative, PC = PC + 2*disp.l
                    pc_target_in_mem <= STD_LOGIC_VECTOR(SIGNED(addr_out_IDEX) + RESIZE((SIGNED(displ_out_ex) & '0'), 16));
                else                        -- if not negative, PC = PC + 2
                    pc_target_in_mem <= STD_LOGIC_VECTOR(UNSIGNED(addr_out_IDEX) + 2);
                end if;
                 
            when "1000010" => -- BRR.Z
                if z_flag_s = '1' then      -- if zero, PC = PC + 2*disp.l
                    pc_target_in_mem <= STD_LOGIC_VECTOR(SIGNED(addr_out_IDEX) + RESIZE((SIGNED(displ_out_ex) & '0'), 16));
                else                        -- if not zero, PC = PC + 2
                    pc_target_in_mem <= STD_LOGIC_VECTOR(UNSIGNED(addr_out_IDEX) + 2);
                end if;
                
            when "1001000" => -- BRR.O
                if overflow_flag_s = '1' then
                    pc_target_in_mem <= STD_LOGIC_VECTOR(SIGNED(addr_out_IDEX) + RESIZE((SIGNED(displ_out_ex) & '0'), 16));
                else                        -- if not zero, PC = PC + 2
                    pc_target_in_mem <= STD_LOGIC_VECTOR(UNSIGNED(addr_out_IDEX) + 2);
                end if;

            -- b2 format
            when "1000011" | "1000110" => -- BR or BR.SUB
                pc_target_in_mem <= STD_LOGIC_VECTOR(SIGNED(data1_out_ex(15 downto 1)) + RESIZE(SIGNED(disps_out_ex), 15)) & '0';
                
            when "1000100" => -- BR.N
                if n_flag_s = '1' then      -- if negative, PC = R[ra] + 2*disp.s {sign extended}
                    pc_target_in_mem <= STD_LOGIC_VECTOR(SIGNED(data1_out_ex(15 downto 1)) + RESIZE(SIGNED(disps_out_ex), 15)) & '0';
                else                        -- if not negative, PC = PC + 2
                    pc_target_in_mem <= STD_LOGIC_VECTOR(UNSIGNED(addr_out_IDEX) + 2);
                end if;
                
            when "1000101" => -- BR.Z
                if z_flag_s = '1' then      -- if zero, PC = R[ra] + 2*disp.s {sign extended}
                    pc_target_in_mem <= STD_LOGIC_VECTOR(SIGNED(data1_out_ex(15 downto 1)) + RESIZE(SIGNED(disps_out_ex), 15)) & '0';
                else                        -- if not zero, PC = PC + 2
                    pc_target_in_mem <= STD_LOGIC_VECTOR(UNSIGNED(addr_out_IDEX) + 2);
                end if;

            -- RETURN
            when "1000111" =>
                -- pass r7 data to next stage (w/ forwarding)
                -- check for EXMEM hazrd
                -- if previous instruction writes to reg file and destination of previous instruction = r7
                if (opcode_out_mem = "0000001" or opcode_out_mem = "0000010"
                        or opcode_out_mem = "0000011" or opcode_out_mem = "0000100"
                        or opcode_out_mem = "0000101" or opcode_out_mem = "0000110"
                        or opcode_out_mem = "0100001" or opcode_out_mem = "0010010"
                        or opcode_out_mem = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_mem = "111") then
                    -- pass result of prev instruction
                    result_in_mem <= result_out_mem;
                
                -- check for MEMWB hazard
                -- if instruction 2 cycles ago writes to reg file and destination of inst 2 cycles ago = r7
                elsif (opcode_out_wb = "0000001" or opcode_out_wb = "0000010"
                        or opcode_out_wb = "0000011" or opcode_out_wb = "0000100"
                        or opcode_out_wb = "0000101" or opcode_out_wb = "0000110"
                        or opcode_out_wb = "0100001" or opcode_out_wb = "0010010"
                        or opcode_out_wb = "0010011" or opcode_out_wb = "0010000")
                        AND (ra_out_wb = "111") then
                    -- pass result of instruction 2 cycles ago
                    result_in_mem <= result_out_wb;
                
                -- otherwise no hazard
                else
                    result_in_mem <= data1_out_ex;
                end if;

            -- LOADIMM
            when "0010010" =>
                -- calculate new R7 data, port forwarding for data hazards
                -- check for EXMEM hazrd
                --      if previous instruction writes to reg file and destination of previous instruction = r7
                if (opcode_out_mem = "0000001" or opcode_out_mem = "0000010"
                        or opcode_out_mem = "0000011" or opcode_out_mem = "0000100"
                        or opcode_out_mem = "0000101" or opcode_out_mem = "0000110"
                        or opcode_out_mem = "0100001" or opcode_out_mem = "0010010"
                        or opcode_out_mem = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_mem = ra_out_ex) then
                    -- operate on result of prev instruction
                    if m_out_ex = '1' then          -- write to upper bits
                        result_in_mem <= result_out_mem(16) & imm_out_ex & result_out_mem(7 downto 0);
                    else                            -- write to lower bits
                        result_in_mem <= result_out_mem(16 downto 8) & imm_out_ex;
                    end if;
                
                -- check for MEMWB hazard
                -- if instruction 2 cycles ago writes to reg file and destination of inst 2 cycles ago = r7
                elsif (opcode_out_wb = "0000001" or opcode_out_wb = "0000010"
                        or opcode_out_wb = "0000011" or opcode_out_wb = "0000100"
                        or opcode_out_wb = "0000101" or opcode_out_wb = "0000110"
                        or opcode_out_wb = "0100001" or opcode_out_wb = "0010010"
                        or opcode_out_wb = "0010011" or opcode_out_wb = "0010000")
                        AND (ra_out_wb = ra_out_ex) then
                    if m_out_ex = '1' then          -- write to upper bits
                        result_in_mem <= result_out_mem(16) & imm_out_ex & result_out_wb(7 downto 0);
                    else                            -- write to lower bits
                        result_in_mem <= result_out_wb(16 downto 8) & imm_out_ex;
                    end if;
                
                -- otherwise no hazard
                else
                    if m_out_ex = '1' then          -- write to upper bits
                        result_in_mem <= data1_out_ex(16) & imm_out_ex & data1_out_ex(7 downto 0);
                    else                            -- write to lower bits
                        result_in_mem <= data1_out_ex(16 downto 8) & imm_out_ex;
                    end if;
                end if;
                
                ra_in_mem <= ra_out_ex;         -- pass r7 to next stage              
            
            -- STORE
            when "0010001" =>
                -- SRC data forwarding
                -- check for EXMEM hazard
                -- if previous instruction writes to reg file
                --      and destination of previous instruction = register of SRC data
                if (opcode_out_mem = "0000001" or opcode_out_mem = "0000010"
                        or opcode_out_mem = "0000011" or opcode_out_mem = "0000100"
                        or opcode_out_mem = "0000101" or opcode_out_mem = "0000110"
                        or opcode_out_mem = "0100001" or opcode_out_mem = "0010010"
                        or opcode_out_mem = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_mem = rb_out_ex) then
                    result_in_mem <= result_out_mem; -- then grab SRC address from prev inst
                
                -- check for MEMWB hazard
                -- if instruction 2 cycles ago writes to reg file
                --      and destination of inst 2 cycles ago = source for operand 2 data
                elsif (opcode_out_wb = "0000001" or opcode_out_wb = "0000010"
                        or opcode_out_wb = "0000011" or opcode_out_wb = "0000100"
                        or opcode_out_wb = "0000101" or opcode_out_wb = "0000110"
                        or opcode_out_wb = "0100001" or opcode_out_wb = "0010010"
                        or opcode_out_wb = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_wb = rb_out_ex) then
                    result_in_mem <= result_out_wb; -- then grab SRC address from instr 2 cycles ago
                        
                -- otherwise no hazard
                else
                    result_in_mem <= data1_out_ex; -- grab SRC address from decode
                end if;
                
                -- DEST data forwarding
                -- check for EXMEM hazard
                -- if previous instruction writes to reg file
                --      and destination of previous instruction = register of DEST data
                if (opcode_out_mem = "0000001" or opcode_out_mem = "0000010"
                        or opcode_out_mem = "0000011" or opcode_out_mem = "0000100"
                        or opcode_out_mem = "0000101" or opcode_out_mem = "0000110"
                        or opcode_out_mem = "0100001" or opcode_out_mem = "0010010"
                        or opcode_out_mem = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_mem = ra_out_ex) then
                    dest_data_in_mem <= result_out_mem(15 downto 0); -- then grab DEST data from prev inst
                
                -- check for MEMWB hazard
                -- if instruction 2 cycles ago writes to reg file
                --      and destination of inst 2 cycles ago = register of DEST data
                elsif (opcode_out_wb = "0000001" or opcode_out_wb = "0000010"
                        or opcode_out_wb = "0000011" or opcode_out_wb = "0000100"
                        or opcode_out_wb = "0000101" or opcode_out_wb = "0000110"
                        or opcode_out_wb = "0100001" or opcode_out_wb = "0010010"
                        or opcode_out_wb = "0010011" or opcode_out_wb = "0010000")
                        AND (ra_out_wb = ra_out_ex) then
                    dest_data_in_mem <= result_out_wb(15 downto 0); -- then grab DEST data from instr 2 cycles ago
                        
                -- otherwise no hazard
                else
                    dest_data_in_mem <= data2_out_ex(15 downto 0); -- grab DEST data from decode
                end if;
            
            -- LOAD & MOV
            when "0010000" | "0010011" =>
                -- forwarding for SRC register data
                -- check for EXMEM hazrd
                -- if previous instruction writes to reg file
                --      and destination of previous instruction = source for operand 2 data
                if (opcode_out_mem = "0000001" or opcode_out_mem = "0000010"
                        or opcode_out_mem = "0000011" or opcode_out_mem = "0000100"
                        or opcode_out_mem = "0000101" or opcode_out_mem = "0000110"
                        or opcode_out_mem = "0100001" or opcode_out_mem = "0010010"
                        or opcode_out_mem = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_mem = rb_out_ex) then
                    result_in_mem <= result_out_mem; -- then grab result from prev inst
                
                -- check for MEMWB hazard
                -- if instruction 2 cycles ago writes to reg file
                --      and destination of inst 2 cycles ago = source for operand 2 data
                elsif (opcode_out_wb = "0000001" or opcode_out_wb = "0000010"
                        or opcode_out_wb = "0000011" or opcode_out_wb = "0000100"
                        or opcode_out_wb = "0000101" or opcode_out_wb = "0000110"
                        or opcode_out_wb = "0100001" or opcode_out_wb = "0010010"
                        or opcode_out_wb = "0010011" or opcode_out_mem = "0010000")
                        AND (ra_out_wb = rb_out_ex) then
                    result_in_mem <= result_out_wb; -- then grab result from instr 2 cycles ago
                        
                -- otherwise no hazard
                else
                    result_in_mem <= data1_out_ex; -- grab result from decode
                end if;
                
                ra_in_mem <= ra_out_ex;         -- pass destination to next stage
                    
            when others => NULL;
        end case;
        
----- MEMORY ACCESS Stage --------------------------------------------------------------------------------------------------------------
        case opcode_out_mem is                                                                 
            -- NOP or test instruction
            when "0000000" | "0000111" =>
                write_en_pc_s <= '0';                        -- disable PC writes if enabled
                wea_RAM <= "0";                              -- disable RAM port A writes (if enabled)
                
            -- a1 or a2 format
            when "0000001" | "0000010" | "0000011" | "0000100" | "0000101" | "0000110" =>
                write_en_pc_s <= '0';                        -- disable PC writes if enabled
                wea_RAM <= "0";                              -- disable RAM port A writes (if enabled)
                result_in_wb <= result_out_mem;              -- pass result to next stage
                ra_in_wb <= ra_out_mem;                      -- pass ra to next stage
                
            -- OUT instruction
            when "0100000" =>
                write_en_pc_s <= '0';                        -- disable PC writes if enabled
                wea_RAM <= "0";                              -- disable RAM port A writes (if enabled)
                out_port_s <= result_out_mem(15 downto 0);     -- send data to OUT port
            
            -- IN instruction
            when "0100001" =>
                write_en_pc_s <= '0';                        -- disable PC writes if enabled
                wea_RAM <= "0";                              -- disable RAM port A writes (if enabled)
                result_in_wb <= result_out_mem;              -- pass data to next stage
                ra_in_wb <= ra_out_mem;                      -- pass ra to next stage 
                
            -- branch format
            when "1000000" | "1000001" | "1000010" | "1000011" | "1000100" | "1000101" | "1001000" =>
                write_en_pc_s <= '1';                        -- enable PC writes
                wea_RAM <= "0";                              -- disable RAM port A writes (if enabled)
                addr_assign_s <= pc_target_out_mem;          -- write target address to PC
            
            -- br.sub handling
            when "1000110" =>
                write_en_pc_s <= '1';                        -- enable PC writes
                wea_RAM <= "0";                              -- disable RAM port A writes (if enabled)
                addr_assign_s <= pc_target_out_mem;          -- write target address to PC
                
            -- RETURN
            when "1000111" =>
                write_en_pc_s <= '1';                        -- enable PC writes
                wea_RAM <= "0";                              -- disable RAM port A writes (if enabled)
                addr_assign_s <= result_out_mem(15 downto 0); -- write r7 data to PC
                
            -- LOADIMM
            when "0010010" =>
                write_en_pc_s <= '0';                        -- disable PC writes if enabled
                wea_RAM <= "0";                              -- disable RAM port A writes (if enabled)
                result_in_wb <= result_out_mem;              -- pass r7 data to next stage
                ra_in_wb <= ra_out_mem;                      -- pass r7 to next stage
        
            -- LOAD
            when "0010000" =>
                write_en_pc_s <= '0';                        -- disable PC writes (if enabled)
                wea_RAM <= "0";                              -- disable RAM port A writes (if enabled)
                
                if result_out_mem = '0' & x"FFF0" then      -- read from BASYS switches
                    result_in_wb <= '0' & switch_data_in;
                else                                        -- read from RAM
                    addra_RAM <= result_out_mem(9 downto 1);     -- pass address to RAM for read
                    result_in_wb <= '0' & douta_RAM;             -- read data from RAM, pass to next stage
                end if;
                
                ra_in_wb <= ra_out_mem;                      -- pass destination to next stage
            
            -- STORE
            when "0010001" => 
                write_en_pc_s <= '0';                        -- disable PC writes (if enabled)
                wea_RAM <= "1";                              -- enable RAM port A writes
                
                if dest_data_out_mem = x"FFF2" then     -- write to HEX display
                    display_store <= result_out_mem(15 downto 0);     -- data to write
                else                                    -- write to RAM port A
                    addra_RAM <= dest_data_out_mem(9 downto 1);     -- address to write to
                    dina_RAM <= result_out_mem(15 downto 0);        -- data to write
                end if;
                
            -- MOV
            when "0010011" =>
                write_en_pc_s <= '0';                        -- disable PC writes if enabled
                wea_RAM <= "0";                              -- disable RAM port A writes (if enabled)
                result_in_wb <= result_out_mem;              -- pass SRC register data to next stage
                ra_in_wb <= ra_out_mem;                      -- pass destination to next stage

            when others => NULL;
        end case; 
        
----- WRITEBACK Stage -------------------------------------------------------------------------------------------------------------------
        case opcode_out_wb is                                                                 
            -- a1 or a2 format, IN, LOAD, LOADIMM, & MOV instruction
            when "0000001" | "0000010" | "0000011" | "0000100" | "0000101" | "0000110"
                    | "0100001" | "0010000" | "0010011" | "0010010" =>
                wr_enable_s <= '1';
                wr_data_s <= result_out_wb;                 -- write data
                wr_index_s <= ra_out_wb;                    -- write index

            -- br.sub handling, write address to R7
            when "1000110" =>
                wr_enable_s <= '1';
                                                             -- reg file write data = PC+2
                wr_data_s <= "0" & STD_LOGIC_VECTOR(UNSIGNED(addr_out_MEMWB) + 2);
                wr_index_s <= "111";                         -- reg file write index = r7
                
            -- branch, NOP, test, out, or store
            when others =>
                wr_enable_s <= '0';
        end case;
    end process;
end behavioral;