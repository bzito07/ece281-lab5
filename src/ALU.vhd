----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

    component full_adder is
        port (
            A     : in std_logic;
            B     : in std_logic;
            Cin   : in std_logic;
            S     : out std_logic;
            Cout  : out std_logic
            );
        end component full_adder;    

    component ripple_adder is
        Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
               B : in STD_LOGIC_VECTOR (7 downto 0);
               Cin : in STD_LOGIC;
               S : out STD_LOGIC_VECTOR (7 downto 0);
               Cout : out STD_LOGIC);
    end component ripple_adder;

    signal w_carry: std_logic;
    signal w_b: std_logic_vector (7 downto 0);
    signal w_S: std_logic_vector (7 downto 0);


    
begin

    with i_op(0) select
        w_b <=  i_B when '0',
                not i_B when '1';

    ripple_adder_1: ripple_adder
    port map(
        A     => i_A,
        B     => w_b,
        Cin   => i_op(0),   -- Directly to input here
        S     => w_S,
        Cout  => w_carry
    );
    
    with i_op select
        o_result    <=  w_S when "000",
                        w_S when "001",
                        (i_A and i_B) when "010",
                        (i_A or i_B) when "011";
                        
        o_flags(0)  <=  '1' when (w_S(7) = '1')         else '0';    -- Negative flag
        o_flags(1)  <=  '1' when (w_S = "00000000")     else '0';     -- Zero flag
        o_flags(2)  <=  '1' when ((w_carry = '1') and (i_op(1) = '0'))        else '0';     -- Carry flag
        o_flags(3)  <=  '1' when (i_op(1) = '0') and (i_A(7) xor w_S(7)) and (i_A(7) xor i_B(7) xor i_op(0))       else '0';     -- Overflow flag
        
    
end Behavioral;
