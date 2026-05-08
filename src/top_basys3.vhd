--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
    signal w_clk_div: std_logic;

    signal w_adv: std_logic;
    signal w_cycle: std_logic_vector(3 downto 0);
    
    signal w_result: std_logic_vector(7 downto 0);
    signal w_flags: std_logic_vector(3 downto 0);
    
        signal w_sign_twos: std_logic;
        signal w_sign_TDM4: std_logic_vector(3 downto 0);

    
    signal w_bin: std_logic_vector(7 downto 0);
    signal w_hund: std_logic_vector(3 downto 0);
    signal w_tens: std_logic_vector(3 downto 0);
    signal w_ones: std_logic_vector(3 downto 0);
    
    signal w_data_hex: std_logic_vector(3 downto 0);
    signal w_sel: std_logic_vector(3 downto 0);
    
    signal w_seg: std_logic_vector(6 downto 0);
  
	-- declare components and signals
	
    component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;

    component button_debounce is
        Port(	clk: in  STD_LOGIC;
                reset : in  STD_LOGIC;
                button: in STD_LOGIC;
                action: out STD_LOGIC);
    end component button_debounce;

    component controller_fsm is
        Port ( i_reset : in STD_LOGIC;
               i_adv : in STD_LOGIC;
               o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
 
     component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
               i_reset		: in  STD_LOGIC; -- asynchronous
               i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
        );
    end component TDM4;
        
    component ALU is
        Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
               i_B : in STD_LOGIC_VECTOR (7 downto 0);
               i_op : in STD_LOGIC_VECTOR (2 downto 0);
               o_result : out STD_LOGIC_VECTOR (7 downto 0);
               o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    end component ALU;

    component twos_comp is
        port (
            i_bin: in std_logic_vector(7 downto 0);
            o_sign: out std_logic;
            o_hund: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twos_comp;
    
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;

    
begin
	-- PORT MAPS ----------------------------------------
    	clock_divider_inst: clock_divider
    	   generic map ( k_DIV => 25000000 ) -- 2 Hz clock from 100 MHz
           port map (						  
               i_clk   => clk,
               i_reset => btnU,
               o_clk   => w_clk_div
    	   );
    	
    	button_debounce_inst: button_debounce
    	   port map(
    	      clk      => clk,
    	      reset    => btnU,
    	      button   => btnC,
    	      action   => w_adv
    	   );
    	   
    	   
    	controller_fsm_inst: controller_fsm
    	   port map(
    	       i_reset =>  btnU,
    	       i_adv   =>  w_adv,
    	       o_cycle =>  w_cycle
               );

        ALU_inst: ALU
            port map(
                i_A       => sw,
                i_B       => sw,
                i_op      => sw(2 downto 0),
                o_result  => w_result,
                o_flags   => w_flags
                );

        twos_comp_inst: twos_comp
            port map(
                i_bin  => w_result,
                o_sign => w_sign_twos,
                o_hund => w_hund,
                o_tens => w_tens,
                o_ones => w_ones
                );
                
    	TDM4_inst: TDM4
    	   generic map ( k_WIDTH => 4 )
    	   port map(
    	      i_clk        => w_clk_div,
    	      i_reset      => btnU,         -----------------could be clk or fsm reset, not sure----------------------------------------
    	      i_D3         => w_sign_TDM4,
    	      i_D2         => w_hund,
    	      i_D1         => w_tens,
    	      i_D0         => w_ones,
    	      o_data       => w_data_hex,
    	      o_sel        => an
    	   );
    	   
    	sevenseg_decoder_inst: sevenseg_decoder
    	   port map(
    	      i_Hex    => w_data_hex,
    	      o_seg_n  => w_seg
    	   );
	
	-- CONCURRENT STATEMENTS ----------------------------
	-- LED 15-12 show the flag results.
	-- LED 3-0 show which state the machine is in
    led(15 downto 12) <= w_flags;
	led(11 downto 4) <= (others => '0');
    led(3 downto 0) <= w_cycle;
    
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	
	-- Seg and Anode
	with w_sign_twos select            --Pass sign value to a 4 bit wire
	   w_sign_TDM4 <= "0001" when '1',
	                  "0000" when others;
	
	with w_sign_twos select            --negative sign when negative
	   seg <= "1111110" when '1',
	          w_seg when others;
	
	with w_cycle select                --clear display when in CLEAR
	   seg <= "1111111" when "0000",
	          w_seg when others;
	
	
end top_basys3_arch;
