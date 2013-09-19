library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ddr_wr_fifo is
	generic (
		std : positive;
		data_bytes : natural := 2;
		data_edges : natural := 2;
		data_phases : natural := 1;
		byte_bits  : natural := 8);
	port (
		sys_clk : in std_logic;
		sys_req : in std_logic;
		sys_dm  : in std_logic_vector(data_edges*data_bytes-1 downto 0) := (others => '-');
		sys_di  : in std_logic_vector(data_edges*data_bytes*byte_bits-1 downto 0);
		sys_rst : in std_logic;

		ddr_clk : in  std_logic_vector(data_phases-1 downto 0) := (others => '-');;
		ddr_ena : in  std_logic_vector(data_edges*data_phases*data_bytes-1 downto 0) := (others => '-');
		ddr_dm  : out std_logic_vector(data_edges*data_phases*data_bytes-1 downto 0) := (others => '-');
		ddr_dq  : out std_logic_vector(data_edges*data_phases*data_bytes*byte_bits-1 downto 0));

	constant data_bits : natural := byte_bits*data_bytes;
end;

library hdl4fpga;
use hdl4fpga.std.all;

architecture mix of ddr_wr_fifo is
	subtype addr_word is std_logic_vector(0 to 4-1);
	signal ddr_clks : std_logic_vector(data_edges*ddr_clk'length-1 downto 0);
	signal ddr_ena  : std_logic_vector(data_edges*ddr_clk'length-1 downto 0);

	type aw_vector is array (natural range <>) of addr_word;

	type dword_vector is array (natural range <>) of std_logic_vector(ddr_dq_r'range);
	signal ddr_dq : dword_vector(0 to 1);

	type dm_vector is array (natural range <>) of std_logic_vector(ddr_dm_r'range);
	signal ddr_dm : dm_vector(0 to data_edges-1);
	signal dmi : dm_vector(0 to data_edges-1);

	type byte_vector is array (natural range <>) of std_logic_vector(byte_bits-1 downto 0);

	function to_bytevector (
		arg : std_logic_vector) 
		return byte_vector is
		variable dat : unsigned(arg'length-1 downto 0);
		variable val : byte_vector(arg'length/byte_bits-1 downto 0);
	begin	
		dat := unsigned(arg);
		for i in val'reverse_range loop
			val(i) := std_logic_vector(dat(byte_bits-1 downto 0));
			dat := dat srl byte_bits;
		end loop;
		return val;
	end;

	function to_dmvector (
		arg : std_logic_vector)
		return dm_vector is
		variable dat : unsigned(arg'length-1 downto 0);
		variable val : dm_vector(data_bytes-1 downto 0);
	begin
		dat := unsigned(arg);
		for i in val'reverse_range loop
			val(i) := std_logic_vector(dat(data_bytes-1 downto 0));
			dat := dat srl 2;
		end loop;
		return val;
	end;

	signal di : byte_vector(data_edges*data_phases*data_bytes-1 downto 0);
	signal ddr_addr_q : aw_vector(data_edges*data_bytes-1 downto 0);
	signal sys_addr_q : aw_vector(data_bytes-1 downto 0);

begin

	ddr_clks <= (ddr_clk'length-1 downto 0) <= ddr_clk;
	ddr_clks <= (data_edges*ddr_clk'length-1 downto ddr_clk'length) <= not ddr_clk;

	ddr_ena <= (0 => ddr_ena_r(0), 1 => ddr_ena_f(0));
	ddr_dq_r <= ddr_dq(0);
	ddr_dq_f <= ddr_dq(1);

	ddr_dm_r <= ddr_dm(0);
	ddr_dm_f <= ddr_dm(1);

	dmi <= to_dmvector(sys_dm);
	dm_g: for i in data_edges*data_phases-1 downto 0 generate
		ram_i : entity hdl4fpga.dbram
		generic map (
			n => data_bytes)
		port map (
			clk => sys_clk,
			we => sys_req,
			wa => sys_addr_q(0),
			di => dmi(i),
			ra => ddr_addr_q(data_bytes*i),
			do => ddr_dm(i));
	end generate;

	di <= to_bytevector(sys_di);
	data_byte_g: for l in data_bytes-1 downto 0 generate
		signal sys_addr_d : addr_word;
	begin
		sys_addr_d <= inc(gray(sys_addr_q(l)));
		sys_cntr_g: for j in addr_word'range  generate
			signal addr_set : std_logic;
		begin
			addr_set <= not sys_req;
			ffd_i : entity hdl4fpga.sff
			port map (
				clk => sys_clk,
				sr  => addr_set,
				d   => sys_addr_d(j),
				q   => sys_addr_q(l)(j));
		end generate;

		ddr_data_g: for i in data_edges*data_phases-1 downto 0 generate
			signal dpo : std_logic_vector(byte_bits-1 downto 0);
			signal ddr_addr_d : addr_word;
		begin
			ddr_addr_d <= inc(gray(ddr_addr_q(data_bytes*i+l)));
			cntr_g: for j in addr_word'range generate
				signal addr_set : std_logic;
			begin
				addr_set <= not ddr_ena(i);
				ffd_i : entity hdl4fpga.sff
				port map (
					clk => ddr_clks(i),
					sr => addr_set,
					d  => ddr_addr_d(j),
					q  => ddr_addr_q(data_bytes*i+l)(j));
			end generate;

			ram_i : entity hdl4fpga.dbram
			generic map (
				n => byte_bits)
			port map (
				clk => sys_clk,
				we => sys_req,
				wa => sys_addr_q(l),
				di => di(data_bytes*i+l),
				ra => ddr_addr_q(data_bytes*i+l),
				do => dpo);

			ram_g: for j in byte_bits-1 downto 0 generate
				signal qpo : std_logic;
			begin
				ffd_i : entity hdl4fpga.ff
				port map (
					clk => ddr_clks(i),
					d   => dpo(j),
					q   => qpo);

				ddr_dq(i)(byte_bits*l+j) <= 
					dpo(j) when std=1 else
					qpo;
					
			end generate;
		end generate;
	end generate;
end;
