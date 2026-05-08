----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    type sm_state is (CLEAR, Load_op_1, Load_op_2, RESULT);
    
    signal current_state, next_state: sm_state;
    
begin

    next_state  <=  Load_op_1       when (current_state = CLEAR)        else
                    Load_op_2       when (current_state = Load_op_1)    else
                    RESULT          when (current_state = Load_op_2)    else
                    CLEAR           when (current_state = RESULT)       else
                    CLEAR;

    with current_state select
        o_cycle <=  "0001" when CLEAR,
                    "0010" when Load_op_1,
                    "0100" when Load_op_2,
                    "1000" when RESULT,
                    "0001" when others;
                    
register_proc : process(i_adv)

	begin
        if i_reset = '1' then
            current_state <= CLEAR;
            else if rising_edge(i_adv) then
                current_state <= next_state;
            end if;
        end if;
	end process register_proc;

                   
end FSM;
