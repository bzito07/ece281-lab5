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
        btnU    :   in std_logic; -- master reset
        btnL    :   in std_logic; -- clock reset
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
    signal w_reset_clk: std_logic;
    signal w_reset_master: std_logic;

    signal w_adv: std_logic;
    signal w_cycle: std_logic_vector(3 downto 0);
    
    signal w_A: std_logic_vector(7 downto 0);
    signal w_B: std_logic_vector(7 downto 0);
    
    signal w_result_new: std_logic_vector(7 downto 0);
    signal w_flags: std_logic_vector(3 downto 0);
    
        signal w_sign_twos: std_logic;
        signal w_sign_7SD: std_logic_vector(6 downto 0);

    
    signal w_bin: std_logic_vector(7 downto 0);
    signal w_hund: std_logic_vector(3 downto 0);
    signal w_tens: std_logic_vector(3 downto 0);
    signal w_ones: std_logic_vector(3 downto 0); 
    
    signal w_data_hex: std_logic_vector(3 downto 0);
    signal w_sel: std_logic_vector(3 downto 0);
    
    signal w_seg_7SD: std_logic_vector(6 downto 0);
    signal w_seg_mux: std_logic_vector(6 downto 0);
  
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
    	   generic map ( k_DIV => 50000 ) -- 1000 Hz clock from 100 MHz
           port map (						  
               i_clk   => clk,
               i_reset => w_reset_clk,
               o_clk   => w_clk_div
    	   );
    	
    	button_debounce_inst: button_debounce
    	   port map(
    	      clk      => clk,
    	      reset    => w_reset_master,
    	      button   => btnC,
    	      action   => w_adv
    	   );
    	   
    	   
    	controller_fsm_inst: controller_fsm
    	   port map(
    	       i_reset =>  w_reset_master,
    	       i_adv   =>  w_adv,
    	       o_cycle =>  w_cycle
               );

        ALU_inst: ALU
            port map(
                i_A       => w_A,
                i_B       => w_B,
                i_op      => sw(2 downto 0),
                o_result  => w_result_new,
                o_flags   => w_flags
                );

        twos_comp_inst: twos_comp
            port map(
                i_bin  => w_bin,
                o_sign => w_sign_twos,
                o_hund => w_hund,
                o_tens => w_tens,
                o_ones => w_ones
                );
                
    	TDM4_inst: TDM4
    	   generic map ( k_WIDTH => 4 )
    	   port map(
    	      i_clk        => w_clk_div,
    	      i_reset      => w_reset_master,         -----------------could be clk or fsm reset, not sure----------------------------------------
    	      i_D3         => "0000",      --hardcoded, not going to use this value, will pass the sign through a separate datapath
    	      i_D2         => w_hund,
    	      i_D1         => w_tens,
    	      i_D0         => w_ones,
    	      o_data       => w_data_hex,
    	      o_sel        => w_sel
    	   );
    	   
    	sevenseg_decoder_inst: sevenseg_decoder
    	   port map(
    	      i_Hex    => w_data_hex,
    	      o_seg_n  => w_seg_7SD
    	   );
	
	-- CONCURRENT STATEMENTS ----------------------------
	-- LED 15-12 show the flag results.
	-- LED 3-0 show which state the machine is in
    led(15 downto 12) <= w_flags;
	led(11 downto 4) <= (others => '0');
    led(3 downto 0) <= w_cycle;
    
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	-- registers before ALU
register_proc_1 : process(w_cycle(1))
	begin
        if rising_edge(w_cycle(1)) then    
           w_A <= sw;
        end if;
	end process register_proc_1;

register_proc_2 : process(w_cycle(2))
	begin
        if rising_edge(w_cycle(2)) then    
           w_B <= sw;
        end if;
	end process register_proc_2;


	-- MUX after ALU, passes to twos_comp
	
	with w_cycle select
	   w_bin   <=  w_A when "0010",
	               w_B when "0100",
	               w_result_new when "1000",
	               "11111111" when others;
	
	
	
	-- Seg and Anode
	
    -- MUX passes a negative sign or clear display to the next MUX
    with w_sign_twos select
        w_sign_7SD  <=  "0111111" when '1',
                        "1111111" when '0',
                        "1111111" when others;
    
    -- MUX displays 7SD output except for the last display, displays sign output
    with w_sel select
        w_seg_mux   <=  w_sign_7SD when "0111",
                        w_seg_7SD when others;                        
                        
    -- MUX clears all displays in state 1, displays results other times
    with w_cycle select
        seg <= "1111111" when "0001",   -- result passed directly to seg output
               w_seg_mux when others;    
    
    -- passes selector signal to anodes
    an  <=  w_sel;
    
    -- wire reset signals to buttons
    w_reset_clk <= btnL or btnU;
    w_reset_master <= btnU;
    
end top_basys3_arch;

