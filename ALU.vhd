library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    port(
        ALUIN1,ALUIN2: in STD_LOGIC_VECTOR (16 downto 0);
        OPCODE: in STD_LOGIC_VECTOR (6 downto 0);
        SHIFT: in STD_LOGIC_VECTOR (3 downto 0);
        RESET: in STD_LOGIC;
        ALUOUT: out STD_LOGIC_VECTOR (16 downto 0);
        Z_FLAG, N_FLAG, OVERFLOW_FLAG: out STD_LOGIC := '0');
end ALU;

architecture behavioral of ALU is
    -- signals, components
    component adder is
        port(
            rb,rc: in STD_LOGIC_VECTOR (15 downto 0);
            ra: out STD_LOGIC_VECTOR (15 downto 0);
            overflow: out STD_LOGIC);
    end component;
    
    component subtractor is
        port(
            rb,rc: in STD_LOGIC_VECTOR (15 downto 0);
            ra: out STD_LOGIC_VECTOR (15 downto 0);
            overflow: out STD_LOGIC);
    end component;
    
    component multiplier is
        port(
            rb,rc: in STD_LOGIC_VECTOR (15 downto 0);
            ra: out STD_LOGIC_VECTOR (15 downto 0);
            overflow: out STD_LOGIC);
    end component;
    
    component left_shifter is
        port(
            n: in STD_LOGIC_VECTOR (3 downto 0);
            rin: in STD_LOGIC_VECTOR (15 downto 0);
            rout: out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    component right_shifter is
        port(
            n: in STD_LOGIC_VECTOR (3 downto 0);
            rin: in STD_LOGIC_VECTOR (15 downto 0);
            rout: out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    signal shl_out, shr_out, nand_out, add_out, sub_out, mult_out: STD_LOGIC_VECTOR(15 downto 0);
    signal add_overflow, sub_overflow, mult_overflow: STD_LOGIC;
    
begin
    add: adder port map(rb => ALUIN1(15 downto 0), rc => ALUIN2(15 downto 0), ra => add_out, overflow => add_overflow);
    subtract: subtractor port map(rb => ALUIN1(15 downto 0), rc => ALUIN2(15 downto 0), ra => sub_out, overflow => sub_overflow);
    multiply: multiplier port map(rb => ALUIN1(15 downto 0), rc => ALUIN2(15 downto 0), ra => mult_out, overflow => mult_overflow);
    shiftleft: left_shifter port map(n => SHIFT, rin => ALUIN1(15 downto 0), rout => shl_out);
    shiftright: right_shifter port map(n => SHIFT, rin => ALUIN1(15 downto 0), rout => shr_out);
    
    -- processes
    process (ALUIN1, ALUIN2, SHIFT, OPCODE, shl_out, shr_out, nand_out, add_out, sub_out, mult_out, add_overflow,
            sub_overflow, mult_overflow, RESET)
    begin
        if RESET = '1' then
            N_FLAG <= '0';
            Z_FLAG <= '0';
            OVERFLOW_FLAG <= '0';
        else
            case OPCODE is
                when "0000000" => NULL;             -- NOP
                when "0000001" =>                   -- ADD
                    ALUOUT(15 downto 0) <= add_out;
                    ALUOUT(16) <= add_overflow;
                when "0000010" =>                   -- SUB
                    ALUOUT(15 downto 0) <= sub_out;
                    ALUOUT(16) <= sub_overflow;
                when "0000011" =>                   -- MUL
                    ALUOUT(15 downto 0) <= mult_out;
                    ALUOUT(16) <= mult_overflow;
                when "0000100" =>                   -- NAND
                    ALUOUT(15 downto 0) <= ALUIN1(15 downto 0) NAND ALUIN2(15 downto 0);
                    ALUOUT(16) <= '0';    
                when "0000101" =>                   -- SHL
                    ALUOUT(15 downto 0) <= shl_out;
                    ALUOUT(16) <= '0';
                when "0000110" =>                   -- SHR
                    ALUOUT(15 downto 0) <= shr_out;
                    ALUOUT(16) <= '0';    
                when "0000111" =>                   -- TEST
                    if ALUIN1(15 downto 0) = x"0000" then
                        Z_FLAG <= '1';           -- zero flag
                        N_FLAG <= '0';
                    elsif ALUIN1(15) = '1' then  -- negative flag
                        Z_FLAG <= '0';
                        N_FLAG <= '1';
                    else
                        Z_FLAG <= '0';
                        N_FLAG <= '0';
                    end if;
                    OVERFLOW_FLAG <= ALUIN1(16); -- overflow flag
    
                when others => NULL;
            end case;
        end if;
    end process;
end behavioral;

----------------------------------- 16-bit multiplier -----------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multiplier is
    port(
        rb,rc: in STD_LOGIC_VECTOR (15 downto 0);
        ra: out STD_LOGIC_VECTOR (15 downto 0);
        overflow: out STD_LOGIC);
end multiplier;

architecture behavioral of multiplier is
    signal signed_rb, signed_rc, signed_output: STD_LOGIC_VECTOR(14 downto 0);
    --signal product_s: UNSIGNED(29 downto 0);
    
begin
    process (rb, rc, signed_rb, signed_rc, signed_output)
        variable s, product: UNSIGNED(29 downto 0);
        variable operand1, operand2: UNSIGNED(29 downto 0);
        variable temp1, temp2, temp3: UNSIGNED(14 downto 0);
    begin
        -- convert 2's complement input to signed (if negative)
        if rb(15) = '1' then        -- if -'ve, convert to signed
            temp1:= NOT UNSIGNED(rb(14 downto 0)) + "1";
            signed_rb <= STD_LOGIC_VECTOR(temp1);
        else
            signed_rb <= rb(14 downto 0);
        end if;
        
        if rc(15) = '1' then        -- if -'ve, convert to signed
            temp2:= NOT UNSIGNED(rc(14 downto 0)) + "1";
            signed_rc <= STD_LOGIC_VECTOR(temp2);
        else
            signed_rc <= rc(14 downto 0);
        end if;
    
        -- operate on signed values
        operand1(29 downto 15) := (others => '0');
        operand1(14 downto 0) := UNSIGNED(signed_rb); -- grab rb data
        operand2(29 downto 15) := (others => '0');
        operand2(14 downto 0) := UNSIGNED(signed_rc); -- grab rc data
        
        -- loop to multiply data (shift and sum algorithm)
        product := (others => '0');                         -- initial product = 0
        for i in 0 to 14 loop                               -- loop through each bit of Rc
            s := (others => operand2(i));                   -- temporary vector full of i'th bit of Rc
            product := product + (operand1 AND s);          -- add partial sums to current product
            operand1 := (operand1(28 downto 0) & "0");      -- shift left Rb by 1 bit for next iteration
        end loop; 
        
        if product (29 downto 15) = "000000000000000" then  -- check for product overflow
            overflow <= '0';
        else 
            overflow <= '1';
        end if;

        signed_output <= STD_LOGIC_VECTOR(product(14 downto 0));    -- out result magnitude (signed)
        ra(15) <= rb(15) XOR rc(15);                                -- output result sign
        
        -- convert signed output to 2's complement (if negative)
        if (rb(15) XOR rc(15)) = '1' then -- if 2's complement, convert to signed
            temp3:= NOT UNSIGNED(signed_output) + "1";
            ra(14 downto 0) <= STD_LOGIC_VECTOR(temp3);
        else                              -- otherwise just pass
            ra(14 downto 0) <= signed_output;
        end if;
    end process;
end behavioral;


------------------------------------- 16-bit adder --------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity adder is
    port(
        rb,rc: in STD_LOGIC_VECTOR (15 downto 0);
        ra: out STD_LOGIC_VECTOR (15 downto 0);
        overflow: out STD_LOGIC);
end adder;

architecture behavioral of adder is
    signal sum: SIGNED(16 downto 0);
begin
    process(rb, rc, sum)
    begin
        sum <= resize(SIGNED(rb), sum'length) + resize(SIGNED(rc), sum'length);

        if rb(15) = rc(15) then
            overflow <= rb(15) XOR sum(16);
        else
            overflow <= '0';
        end if;

        ra <= STD_LOGIC_VECTOR(sum(15 downto 0));
    end process;
end behavioral;

------------------------------------ 16-bit subtractor --------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity subtractor is
    port(
        rb,rc: in STD_LOGIC_VECTOR (15 downto 0);
        ra: out STD_LOGIC_VECTOR (15 downto 0);
        overflow: out STD_LOGIC);
end subtractor;

architecture behavioral of subtractor is
    signal difference: SIGNED(16 downto 0);
begin
    process (rb, rc, difference)
    begin
        difference <= resize(SIGNED(rb), difference'length) - resize(SIGNED(rc), difference'length);
        
        if (rb(15) /= rc(15)) AND (rc(15) = difference(16)) then
            overflow <= '1';
        else
            overflow <= '0';
        end if;
        ra <= STD_LOGIC_VECTOR(difference(15 downto 0));
    end process;
end behavioral;


------------------------------ 16-bit barrel shifter (left) -----------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity left_shifter is
    port(
        n: in STD_LOGIC_VECTOR (3 downto 0);
        rin: in STD_LOGIC_VECTOR (15 downto 0);
        rout: out STD_LOGIC_VECTOR (15 downto 0));
end left_shifter;

architecture behavioral of left_shifter is
    --signal shift1, shift2, shift3, shift4: STD_LOGIC_VECTOR(15 downto 0);
begin
    process (n, rin)
        variable shift1, shift2, shift3, shift4: STD_LOGIC_VECTOR(15 downto 0);
    begin
        -- 1 bit shift
        if n(0) = '1' then
            shift1 := (rin(14 downto 0) & "0");
        else
            shift1 := rin;
        end if;
        
        -- 2 bit shift
        if n(1) = '1' then
            shift2 := (shift1(13 downto 0) & "00");
        else
            shift2 := shift1;
        end if;
        
        -- 4 bit shift
        if n(2) = '1' then
            shift3 := (shift2(11 downto 0) & "0000");
        else
            shift3 := shift2;
        end if;
        
        -- 8 bit shift
        if n(3) = '1' then
            shift4 := (shift3(7 downto 0) & "00000000");
        else
            shift4 := shift3;
        end if;
        rout <= shift4;
    end process;
end behavioral;

----------------------------- 16-bit barrel shifter (right) -----------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity right_shifter is
    port(
        n: in STD_LOGIC_VECTOR (3 downto 0);
        rin: in STD_LOGIC_VECTOR (15 downto 0);
        rout: out STD_LOGIC_VECTOR (15 downto 0));
end right_shifter;

architecture behavioral of right_shifter is
    --signal shift1, shift2, shift3, shift4: STD_LOGIC_VECTOR(15 downto 0);
begin
    process (n, rin)
        variable shift1, shift2, shift3, shift4: STD_LOGIC_VECTOR(15 downto 0);
    begin
            -- 1 bit shift
        if n(0) = '1' then
            shift1 := ("0" & rin(15 downto 1));
        else
            shift1 := rin;
        end if;
        
        -- 2 bit shift
        if n(1) = '1' then
            shift2 := ("00" & shift1(15 downto 2));
        else
            shift2 := shift1;
        end if;
        
        -- 4 bit shift
        if n(2) = '1' then
            shift3 := ("0000" & shift2(15 downto 4));
        else
            shift3 := shift2;
        end if;
        
        -- 8 bit shift
        if n(3) = '1' then
            shift4 := ("00000000" & shift3(15 downto 8));
        else
            shift4 := shift3;
        end if;
        rout <= shift4;
    end process;
end behavioral;