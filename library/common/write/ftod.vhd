library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hdl4fpga;
use hdl4fpga.std.all;

entity ftod is
	generic (
		size    : natural := 4);
	port (
		clk      : in  std_logic;
		bin_frm  : in  std_logic;
		bin_irdy : in  std_logic := '1';
		bin_trdy : out std_logic;
		bin_flt  : in  std_logic;
		bin_exp  : in  std_logic_vector;
		bin_di   : in  std_logic_vector;

		bcd_do   : out std_logic_vector);
end;

architecture def of ftod is

	signal vector_rst     : std_logic;
	signal vector_ena     : std_logic;
	signal vector_full    : std_logic;
	signal vector_left    : std_logic_vector(size-1 downto 0);
	signal vector_right   : std_logic_vector(size-1 downto 0);
	signal vector_addr    : std_logic_vector(size-1 downto 0);
	signal vector_do      : std_logic_vector(bcd_do'range);
	signal vector_di      : std_logic_vector(vector_do'range);
	signal left_up      : std_logic;
	signal left_ena       : std_logic;
	signal right_up     : std_logic;
	signal right_ena      : std_logic;

	signal btod_left_up   : std_logic;
	signal btod_left_ena  : std_logic;
	signal btod_right_up  : std_logic;
	signal btod_right_ena : std_logic;
	signal btod_frm      : std_logic;
	signal btod_trdy      : std_logic;
	signal btod_irdy      : std_logic;
	signal btod_addr      : std_logic_vector(vector_addr'range);
	signal btod_do      : std_logic_vector(bcd_do'range);

	signal dtof_left_up   : std_logic;
	signal dtof_left_ena  : std_logic;
	signal dtof_right_up  : std_logic;
	signal dtof_right_ena : std_logic;
	signal dtof_frm      : std_logic;
	signal dtof_trdy      : std_logic;
	signal dtof_irdy      : std_logic;
	signal dtof_addr      : std_logic_vector(vector_addr'range);
	signal dtof_do      : std_logic_vector(bcd_do'range);

	signal dev_trdy       : std_logic_vector(1 to 2);
	signal dev_irdy       : std_logic_vector(1 to 2);
	signal dev_gnt        : std_logic_vector(0 to dev_trdy'length);
begin

	process (clk, dev_trdy, dev_irdy)
		variable id : unsigned(0 to 1);
	begin
		if rising_edge(clk) then
			if id=(id'range => '0') then
				for i in dev_irdy'range loop
					if dev_irdy(i)/='0' then
						id := to_unsigned(i, id'length);
						exit;
					end if;
				end loop;
			else
				if dev_trdy(to_integer(id))='0' then
					id := (others => '0');
				end if;
			end if;
		end if;
	end process;

	gnt_p : process (clk, bin_flt, btod_trdy)
		variable sel : std_logic;
	begin
		if rising_edge(clk) then
				if bin_irdy='1' then
					sel := bin_flt;
				end if;
		end if;
		dev_gnt(1) <= not (btod_trdy and bin_flt) or (not btod_trdy and sel);
		dev_gnt(2) <=     (btod_trdy and bin_flt) or (not btod_trdy and sel);
	end process;

	btod_e : entity hdl4fpga.btod
	port map (
		clk          => clk,
		bin_frm      => btod_frm,
		bin_irdy     => btod_irdy,
		bin_trdy     => btod_trdy,
		bin_di       => bin_di,

		mem_full     => vector_full,

		mem_left     => vector_left,
		mem_left_up  => btod_left_up,
		mem_left_ena => btod_left_ena,

		mem_right    => vector_right,
		mem_right_up  => btod_right_up,
		mem_right_ena => btod_right_ena,

		mem_addr     => btod_addr,
		mem_di       => btod_do,
		mem_do       => vector_do);

	dtof_e : entity hdl4fpga.dtof
	port map (
		clk          => clk,
		bcd_frm      => dtof_frm,
		bcd_irdy     => dtof_irdy,
		bcd_trdy     => dtof_trdy,
		bcd_di       => bin_di,

		mem_full     => vector_full,

		mem_left     => vector_left,
		mem_left_up  => dtof_left_up,
		mem_left_ena => dtof_left_ena,

		mem_right    => vector_right,
		mem_right_up  => dtof_right_up,
		mem_right_ena => dtof_right_ena,

		mem_addr     => dtof_addr,
		mem_di       => dtof_do,
		mem_do       => vector_do);

	vector_addr_p : process(clk)
	begin
		if rising_edge(clk) then
			vector_addr <= wirebus((vector_addr'range => '-') & btod_addr & dtof_addr, dev_gnt);
		end if;
	end process;

	left_up    <= wirebus('-' & btod_left_up  & dtof_left_up,  dev_gnt)(0);
	left_ena   <= wirebus('-' & btod_left_ena & dtof_left_ena, dev_gnt)(0);

	right_up <= wirebus('-' & btod_left_up  & dtof_right_up,  dev_gnt)(0);
	right_ena  <= wirebus('-' & btod_left_ena & dtof_right_ena, dev_gnt)(0);

	vector_di  <= wirebus((vector_di'range => '-') & btod_do & dtof_do, dev_gnt);

	vector_rst <= not bin_frm;

	vector_e : entity hdl4fpga.vector
	port map (
		vector_clk   => clk,
		vector_rst   => vector_rst,
		vector_ena   => vector_ena,
		vector_addr  => std_logic_vector(vector_addr),
		vector_full  => vector_full,
		vector_di    => vector_di,
		vector_do    => vector_do,
		left_ena     => left_ena,
		left_up    => left_up,
		vector_left  => vector_left,
		right_ena    => right_ena,
		right_up   => right_up,
		vector_right => vector_right);

	bcd_do   <= btod_do;
	bin_trdy <= btod_trdy;
end;
