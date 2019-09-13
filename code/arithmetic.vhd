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
        
        if rb(15) /= rc(15) then
            overflow <= rc(15);
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
