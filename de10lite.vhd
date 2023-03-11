LIBRARY 	ieee;
USE		ieee.std_logic_1164.all, ieee.numeric_std.all;

ENTITY de10lite IS
	PORT(	
		CLOCK_50	: 	IN			std_logic;
		KEY		: 	IN 		std_logic_vector( 1 DOWNTO 0 );
		SW			: 	IN 		std_logic_vector( 9 DOWNTO 0 );
		hex0     : out 		std_logic_vector( 6 downto 0 );
		LEDR		: 	OUT		std_logic_vector( 9 DOWNTO 0 )
	);
END de10lite;

ARCHITECTURE Structural OF de10lite IS	
	
	component gumnut_with_mem IS
		generic ( 
			IMem_file_name : string := "gasm_text.dat";
			DMem_file_name : string := "gasm_data.dat";
         debug : boolean := false );
		port ( clk_i : in std_logic;
         rst_i : in std_logic;
         -- I/O port bus
         port_cyc_o : out std_logic;
         port_stb_o : out std_logic;
         port_we_o : out std_logic;
         port_ack_i : in std_logic;
         port_adr_o : out unsigned(7 downto 0);
         port_dat_o : out std_logic_vector(7 downto 0);
         port_dat_i : in std_logic_vector(7 downto 0);
         -- Interrupts
         int_req : in std_logic;
         int_ack : out std_logic );
	end component gumnut_with_mem;
	
	component DECODER_DAC_when is 
		port(
			x : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			hex : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
	end component DECODER_DAC_when;
	
	
	SIGNAL clk_i, rst_i: std_logic; 
	SIGNAL port_cyc_o, port_stb_o, port_we_o, port_ack_i:	std_logic;
	SIGNAL port_adr_o:	unsigned(7 downto 0);
	SIGNAL port_dat_o, port_dat_i:	std_logic_vector(7 downto 0);
	SIGNAL int_req, int_ack: std_logic;
	signal s_bcd : std_logic_vector(3 downto 0);
	
	
BEGIN
	
	clk_i 		<= CLOCK_50;
	rst_i 		<= not KEY( 0 );
	port_ack_i	<= '1';	
	
	gumnut : 		COMPONENT gumnut_with_mem 
							PORT MAP(
								clk_i,
								rst_i,
								port_cyc_o,
								port_stb_o,
								port_we_o,
								port_ack_i,
								port_adr_o( 7 DOWNTO 0 ),
								port_dat_o( 7 DOWNTO 0 ),
								port_dat_i( 7 DOWNTO 0 ),
								int_req,
								int_ack
								);		

								
	
	--OUTPUT => HEX0 -> 0x01
	process(clk_i)
	begin
		if rst_i = '1' then
			s_bcd <= (others => '0');
		elsif rising_edge (clk_i) then
			if port_adr_o(1) = '0' and port_adr_o(0) = '1' and 
				port_cyc_o = '1' and port_stb_o = '1' and port_we_o = '1' then
				s_bcd <= port_dat_o(3 downto 0);
			end if;
		end if;
	end process;
	
--	--INPUT => pushbutton -> 0x10, switches -> 11
--	process(clk_i)
--	begin
--		if rising_edge (clk_i) then
--			if port_adr_o(1) = '1' and port_adr_o(0) = '0' and 
--				port_cyc_o = '1' and port_stb_o = '1' and port_we_o = '0' then
--				 port_dat_i(0) <= KEY(1);
--				 
--			elsif port_adr_o(1) = '1' and port_adr_o(0) = '1' and 
--				port_cyc_o = '1' and port_stb_o = '1' and port_we_o = '0' then
--				port_dat_i(3 downto 0) <= sw(3 downto 0);
--			end if;
--		end if;
--	end process;
	
	--INPUT => pushbutton -> 0x10, switches -> 11
	process(clk_i)
	begin
		if rising_edge (clk_i) then
			if port_cyc_o = '1' and port_stb_o = '1' and port_we_o = '0' then
			
				if port_adr_o(1) = '1' and port_adr_o(0) = '0' then
					port_dat_i(0) <= KEY(1);
				elsif port_adr_o(1) = '1' and port_adr_o(0) = '1'then
					port_dat_i(3 downto 0) <= sw(3 downto 0);
				end if;
			end if;
		end if;
	end process;

	
	display : DECODER_DAC_when port map(s_bcd, hex0);
		
END Structural;