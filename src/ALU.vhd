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
                        (i_A or i_B) when "011",
                        
        
    
    
process(i_A, i_B, i_op)
begin
    if i_op = "000" then
        o_result <= i_A + i_B;
    else if i_op = "001" then
        o_result <= i_A - i_B;
    else if i_op = "010" then
        o_result <= i_A and i_B;
    else if i_op = "011" then
        o_result <= i_A or i_B;
    end if;
end Behavioral;
