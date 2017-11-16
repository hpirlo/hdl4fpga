library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hdl4fpga;
use hdl4fpga.std.all;

entity scopeio_gpannel is
	generic (
		inputs         : natural;
		gauge_labels   : std_logic_vector;
		unit_symbols   : std_logic_vector;
		time_scales    : std_logic_vector;
		hz_scales      : scale_vector;
		vt_scales      : scale_vector);
	port (
		pannel_clk     : in  std_logic;
		time_scale     : in  std_logic_vector;
		time_value     : in  std_logic_vector;
		trigger_scale  : in  std_logic_vector;
		trigger_value  : in  std_logic_vector;
		channel_scale  : in  std_logic_vector;
		channel_level  : in  std_logic_vector;
		video_clk      : in  std_logic;
		gpannel_row    : in  std_logic_vector;
		gpannel_col    : in  std_logic_vector;
		gpannel_on     : in  std_logic_vector;
		gauge_on       : out std_logic_vector;
		gauge_code     : out std_logic_vector);
end;

architecture beh of scopeio_gpannel is

	constant label_size : natural := gauge_labels'length/((2*inputs+2)*ascii'length);
	signal   reading    : std_logic_vector(5*4-1 downto 0);

	function init_rom 
		return std_logic_vector is
		variable aux    : std_logic_vector(gauge_labels'length-1 downto 0);
		variable aux1   : std_logic_vector(unit_symbols'length-1 downto 0);
		variable retval : std_logic_vector(0 to ascii'length*2**gpannel_col'length*(2*inputs+2)-1);
		constant ssize  : natural := aux'length/(2+2*inputs);
		constant ssize1 : natural := aux1'length/(2+2*inputs);
	begin 
		aux  := std_logic_vector(gauge_labels);
		aux1 := std_logic_vector(unit_symbols);
		for i in 0 to 2*inputs+2-1 loop
			retval := std_logic_vector(unsigned(retval) ror (ascii'length*2**gpannel_col'length));
			retval(0 to retval'length/(2+2*inputs)-1) := fill(
				aux(ssize-1 downto 0)    & 
				fill("", ascii'length*reading'length/4) &
				to_ascii(string'("  "))  &
				aux1(ssize1-1 downto 0),
				ascii'length*2**gpannel_col'length, value => '0');
			aux  := std_logic_vector(unsigned(aux)  srl ssize);
			aux1 := std_logic_vector(unsigned(aux1) srl ssize1);
		end loop;
		return retval;
	end;

	function init_deca (
		constant arg : scale_vector)
		return std_logic_vector is
		variable retval : unsigned(arg'length*ascii'length-1 downto 0);
	begin
		for i in arg'range loop
			retval(ascii'range) := unsigned(std_logic_vector'(to_ascii(string'((1 => arg(i).deca)))));
			retval := retval rol ascii'length;
		end loop;
		return std_logic_vector(retval);
	end;

	constant hz_decas  : std_logic_vector(0 to ascii'length*hz_scales'length-1) := init_deca(hz_scales);
	constant vt_decas  : std_logic_vector(0 to ascii'length*vt_scales'length-1) := init_deca(vt_scales);

	signal   mem       : byte_vector(0 to (2*inputs+2)*2**gpannel_col'length-1) := to_bytevector(init_rom);
	signal   scale     : std_logic_vector(0 to channel_scale'length/inputs-1) := b"0011";
	signal   value     : std_logic_vector(0 to channel_level'length/inputs-1) := b"0_0010_0000";
	signal   reading1  : std_logic_vector(reading'range):= (others => '0');

	signal   ut_deca   : std_logic_vector(ascii'range);
	signal   chan_dot  : std_logic_vector(0 to 2+inputs-1);
	signal   meter_fld : std_logic_vector(0 to 2+inputs-1);


	function fmt_reading (
		constant arg1 : std_logic_vector;
		constant arg2 : natural)
		return std_logic_vector is
	begin
		return std_logic_vector(unsigned(fill(arg1, 2**gpannel_col'length*ascii'length)) ror arg2 );
	end;

	signal text_col  : std_logic_vector(gpannel_col'left downto gpannel_col'right);
	signal text_row  : std_logic_vector(gpannel_row'left downto gpannel_row'right);
	signal text_addr : std_logic_vector(text_row'length+text_col'length-1 downto 0);
	signal text_data : std_logic_vector(ascii'range);

	signal we : std_logic;
	signal mult  : std_logic_vector(0 to 2-1);
	signal order : std_logic_vector(0 to 2-1);
begin

	process (pannel_clk)
		constant start  : natural := label_size;
		constant finish : natural := start+reading'length/4+2;
	begin
		if rising_edge(pannel_clk) then
			if unsigned(text_col) < (finish-1) then
				text_col <= std_logic_vector(unsigned(text_col) + 1);
			else
				text_col <= std_logic_vector(to_unsigned(start, text_col'length));
				we <= '1';
				if unsigned(text_row) < (4-1) then
					text_row <= std_logic_vector(unsigned(text_row) + 1);
				else
					text_row <= (others => '0');
				end if;
			end if;
		end if;
	end process;

	textcol_align_e : entity hdl4fpga.align
	generic map (
		n => text_col'length,
		d => (text_col'range => 2))
	port map (
		clk => pannel_clk,
		di  => text_col,
		do  => text_addr(text_col'length-1 downto 0));

	textrow_align_e : entity hdl4fpga.align
	generic map (
		n => text_row'length,
		d => (text_row'range => 0))
	port map (
		clk => pannel_clk,
		di  => text_row,
		do  => text_addr(text_row'length+text_col'length-1 downto text_col'length));


	process(pannel_clk)
		variable addr : std_logic_vector(text_addr'range);
		variable data : std_logic_vector(ascii'range);
	begin
		if rising_edge(pannel_clk) then
			if we='1' then
				mem(to_integer(unsigned(addr))) <= data;
			end if;
			addr := text_addr;
			data := word2byte(fmt_reading(bcd2ascii(reading1) & to_ascii(string'(" ")) & ut_deca, label_size*ascii'length), text_addr(text_col'length-1 downto 0), ascii'length);
		end if;
	end process;

	process (pannel_clk)
		function dup (
			constant arg : std_logic_vector)
			return std_logic_vector is
			constant size   : natural := arg'length/inputs;
			variable aux    : unsigned(0 to arg'length-1);
			variable retval : unsigned(0 to 2*arg'length-1);
		begin
			retval := (others => '-');
			aux    := unsigned(arg);
			for i in 0 to inputs-1 loop
				for j in 0 to 2-1 loop
					retval(0 to size-1) := aux(0 to size-1);
					retval := retval rol size;
				end loop;
				aux := aux srl size;
			end loop;
			return std_logic_vector(retval);
		end;

		variable vt_value : std_logic_vector(0 to 2*inputs*9-1);
		variable hz_deca  : std_logic_vector(0 to ascii'length-1);
		variable vt_deca  : std_logic_vector(0 to ascii'length*inputs-1);
		variable tg_deca  : std_logic_vector(0 to ascii'length-1);

		variable aux      : std_logic_vector(channel_scale'range);
		variable aux1     : std_logic_vector(channel_level'range);

		variable aux_mult  : std_logic_vector(0 to mult'length*inputs-1);
		variable aux_order : std_logic_vector(0 to order'length*inputs-1);
	begin

		if rising_edge(pannel_clk) then
			mult <= word2byte(
				dup(aux_mult) &
				hz_scales(to_integer(unsigned(time_scale))).mult &
				hz_scales(to_integer(unsigned(trigger_scale))).mult,
				text_row, mult'length);

			order <= word2byte(
				dup(aux_order) &
				hz_scales(to_integer(unsigned(time_scale))).order &
				hz_scales(to_integer(unsigned(trigger_scale))).order,
				text_row, order'length);

			aux_mult  := (others => '0');
			aux_order := (others => '0');
			for i in 0 to inputs-1 loop
				aux_mult := std_logic_vector(unsigned(aux_mult) srl mult'length);
				aux_mult(0 to 2-1) := vt_scales(to_integer(unsigned(word2byte(channel_scale, i, channel_scale'length/inputs)))).mult;

				aux_order := std_logic_vector(unsigned(aux_order) srl order'length);
				aux_order(0 to 2-1) := vt_scales(to_integer(unsigned(word2byte(channel_scale, i, channel_scale'length/inputs)))).order;
			end loop;

			value <= word2byte(
				vt_value      &
				time_value    &
				trigger_value,
				text_row, value'length);

			ut_deca <= word2byte(
				dup(vt_deca) & 
				hz_deca      & 
				tg_deca,
				text_row, ascii'length);

			aux  := channel_scale;
			aux1 := channel_level;
			vt_deca := (others => '0');
			for i in 0 to inputs-1 loop
				vt_value := std_logic_vector(unsigned(vt_value) srl value'length);
				vt_value(0 to 9-1) := aux1(0 to 9-1);
				vt_value := std_logic_vector(unsigned(vt_value) srl value'length);
				vt_value(0 to 9-1) := b"0001_00000";
				vt_deca  := std_logic_vector(unsigned(vt_deca)  srl scale'length);
				vt_deca(0 to ascii'length-1) := word2byte(vt_decas, aux(0 to scale'length-1));
				aux  := std_logic_vector(unsigned(aux)  sll scale'length);
				aux1 := std_logic_vector(unsigned(aux1) sll 9);
			end loop;
			hz_deca := word2byte(hz_decas,  time_scale);
			tg_deca := word2byte(vt_decas, trigger_scale);
			reading1 <= reading;

		end if;
	end process;

	display_e : entity hdl4fpga.scopeio_gauge
	generic map (
		frac => 6,
		dec  => 3)
	port map (
		value => b"000_100000", --value,
		mult  => mult,
		order => order,
		fmtds => reading);	

	process(video_clk)
	begin
		if rising_edge(video_clk) then
			gauge_code <= mem(to_integer(unsigned(std_logic_vector'(gpannel_row & gpannel_col))));
		end if;
	end process;

	process(video_clk)
		variable row : unsigned(0 to 2**gpannel_row'length-1);
	begin
		row := unsigned(demux(gpannel_row));
		for i in 0 to inputs+2-1 loop
			if i < inputs then
				gauge_on(i) <= setif(row(0 to 2-1) /= (0 to 2-1 => '0')) and setif(gpannel_on/=(gpannel_on'range => '0'));
				row         := row sll 2;
			else
				gauge_on(i) <= row(0) and setif(gpannel_on/=(gpannel_on'range => '0'));
				row         := row sll 1;
			end if;
		end loop;
	end process;

end;
