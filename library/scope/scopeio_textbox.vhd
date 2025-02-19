library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hdl4fpga;
use hdl4fpga.base.all;
use hdl4fpga.jso.all;
use hdl4fpga.scopeiopkg.all;
use hdl4fpga.textboxpkg.all;
use hdl4fpga.cgafonts.all;

entity scopeio_textbox is
	generic(
		layout        : string;
		latency       : natural;
		max_delay     : natural;
		font_bitrom   : std_logic_vector := psf1cp850x8x16;
		font_height   : natural := 16);
	port (
		rgtr_clk      : in  std_logic;
		rgtr_dv       : in  std_logic;
		rgtr_id       : in  std_logic_vector(8-1 downto 0);
		rgtr_data     : in  std_logic_vector;

		gain_ena      : in  std_logic;
		gain_dv       : in  std_logic;
		gain_cid      : in  std_logic_vector;
		gain_ids      : in  std_logic_vector;

		time_ena      : in  std_logic;
		time_scale    : in  std_logic_vector;
		time_offset   : in  std_logic_vector;

		video_clk     : in  std_logic;
		video_hcntr   : in  std_logic_vector;
		video_vcntr   : in  std_logic_vector;
		sgmntbox_ena  : in  std_logic_vector;
		text_on       : in  std_logic := '1';
		text_fg       : out std_logic_vector;
		text_bg       : out std_logic_vector;
		text_fgon     : out std_logic);

	constant inputs        : natural := jso(layout)**".inputs";
	constant hzoffset_bits : natural := unsigned_num_bits(max_delay-1);
	constant chanid_bits   : natural := unsigned_num_bits(inputs-1);
	constant font_width    : natural := jso(layout)**".textbox.font_width";

	constant hz_unit : real := jso(layout)**".axis.horizontal.unit";
	constant vt_unit : real := jso(layout)**".axis.vertical.unit";

   	function textalign (
   		constant text  : string;
   		constant width : natural;
   		constant align : string := "left")
   		return string is
   		variable retval : string(1 to width);
   	begin
		retval := (others => ' ');
		retval(1 to text'length) := text;
		if align="right" then
			retval := rotate_left(retval, text'length);
		elsif align="center" then
			retval := rotate_left(retval, (text'length+width)/2);
		end if; 

		return retval;
	end;

	impure function textbox_rom (
		constant width  : natural;
		constant size   : natural)
		return string is
		variable data   : string(1 to size);
		variable offset : positive;
		variable length : natural;
		variable i      : natural;
		variable j      : natural;
	begin
		i := 0;
		j := data'left;
		for i in 0 to inputs-1 loop
			resolve(layout&".vt["&natural'image(i)&"].text", offset, length);
			if length=0 then
				exit;
			else
				data(j to j+width-1) := textalign(layout(offset to offset+length-1), width);
				j := j + width;
			end if;
		end loop;
		return data;
	end;

	impure function textbox_field (
		constant width  : natural;
		constant size   : natural)
		return natural_vector is
		variable retval : natural_vector(0 to inputs-1);
	begin
		retval(0) := width;
		for i in 1 to inputs-1 loop
			retval(i) := retval(i-1) + width;
		end loop;
		return retval;
	end;

end;

architecture def of scopeio_textbox is
	subtype ascii is std_logic_vector(8-1 downto 0);
	constant cgaadapter_latency : natural := 4;
	subtype storage_word is std_logic_vector(unsigned_num_bits(grid_height(layout))-1 downto 0);

	constant fontwidth_bits  : natural := unsigned_num_bits(font_width-1);
	constant fontheight_bits : natural := unsigned_num_bits(font_height-1);
	constant textwidth_bits  : natural := unsigned_num_bits(textbox_width(layout)-1);
	constant cga_cols        : natural := textbox_width(layout)/font_width;
	constant cga_rows        : natural := textbox_height(layout)/font_height;
	constant cga_size        : natural := (textbox_width(layout)/font_width)*(textbox_height(layout)/font_height);
	constant cga_bitrom      : std_logic_vector := to_ascii(textbox_rom(cga_cols, cga_size));

	signal cga_we            : std_logic := '0';
	signal cga_addr          : unsigned(unsigned_num_bits(cga_size-1)-1 downto 0);
	signal cga_code          : ascii;

	signal textfg            : std_logic_vector(text_fg'range);
	signal textbg            : std_logic_vector(text_bg'range);
	signal video_on          : std_logic;
	signal video_addr        : std_logic_vector(cga_addr'range);
	signal video_dot         : std_logic;

	signal bcd_code          : ascii;
	signal xxx               : std_logic;
begin

	rgtr_b : block

		signal myip_ena       : std_logic;
		signal myip_dv        : std_logic;
		signal myip_num1      : std_logic_vector(8-1 downto 0);
		signal myip_num2      : std_logic_vector(8-1 downto 0);
		signal myip_num3      : std_logic_vector(8-1 downto 0);
		signal myip_num4      : std_logic_vector(8-1 downto 0);

		signal trigger_ena    : std_logic;
		signal trigger_freeze : std_logic;
		signal trigger_slope  : std_logic;
		signal trigger_chanid : std_logic_vector(chanid_bits-1 downto 0);
		signal trigger_level  : std_logic_vector(storage_word'range);

		signal chan_id        : std_logic_vector(chanid_maxsize-1 downto 0);
		signal vt_exp         : integer;
		signal vt_dv          : std_logic;
		signal vt_ena         : std_logic;
		signal vt_offset      : std_logic_vector((5+8)-1 downto 0);
		signal vt_offsets     : std_logic_vector(0 to inputs*vt_offset'length-1);
		signal vt_chanid      : std_logic_vector(chan_id'range);
		signal vt_scale       : std_logic_vector(4-1 downto 0);
		signal tgr_scale      : std_logic_vector(4-1 downto 0);

		constant bin_digits   : natural := 3;
		constant bcd_length   : natural := 4;
		constant bcd_digits   : natural := 1;
		signal bcd            : std_logic_vector(0 to bcd_length*bcd_digits*((5+bcd_digits-1)/bcd_digits)-1);
		signal bin            : std_logic_vector(0 to bin_digits*((vt_offset'length+bin_digits-1)/bin_digits)-1);
		signal load           : std_logic;
		signal last           : std_logic;
	begin

		myip4_e : entity hdl4fpga.scopeio_rgtrmyip
		port map (
			rgtr_clk  => rgtr_clk,
			rgtr_dv   => rgtr_dv,
			rgtr_id   => rgtr_id,
			rgtr_data => rgtr_data,

			ip4_ena   => myip_ena,
			ip4_dv    => myip_dv,
			ip4_num1  => myip_num1,
			ip4_num2  => myip_num2,
			ip4_num3  => myip_num3,
			ip4_num4  => myip_num4);

		trigger_e : entity hdl4fpga.scopeio_rgtrtrigger
		port map (
			rgtr_clk       => rgtr_clk,
			rgtr_dv        => rgtr_dv,
			rgtr_id        => rgtr_id,
			rgtr_data      => rgtr_data,

			trigger_ena    => trigger_ena,
			trigger_slope  => trigger_slope,
			trigger_freeze => trigger_freeze,
			trigger_chanid => trigger_chanid,
			trigger_level  => trigger_level);

		rgtrvtaxis_b : block
			signal offset : std_logic_vector(vt_offset'range);
			signal chanid : std_logic_vector(vt_chanid'range);
		begin
			vtaxis_e : entity hdl4fpga.scopeio_rgtrvtaxis
			generic map (
				rgtr      => false)
			port map (
				rgtr_clk  => rgtr_clk,
				rgtr_dv   => rgtr_dv,
				rgtr_id   => rgtr_id,
				rgtr_data => rgtr_data,
				vt_dv     => vt_dv,
				vt_ena    => vt_ena,
				vt_chanid => chanid,
				vt_offset => offset);

			vtoffsets_p : process(rgtr_clk)
			begin
				if rising_edge(rgtr_clk) then
					if vt_ena='1' then
						vt_chanid  <= chanid;
						vt_offsets <= byte2word(vt_offsets, chanid, offset);
					end if;
				end if;
			end process;
		end block;

		chainid_p : process (rgtr_clk)
		begin
			if rising_edge(rgtr_clk) then
				if vt_dv='1' then
					chan_id <= vt_chanid;
				elsif gain_dv='1' then
					chan_id <= std_logic_vector(resize(unsigned(gain_cid),chan_id'length));
				end if;
			end if;
		end process;
		vt_offset <= multiplex(vt_offsets, chan_id,        vt_offset'length);
		vt_scale  <= multiplex(gain_ids,   chan_id,        vt_scale'length);
		tgr_scale <= multiplex(gain_ids,   trigger_chanid, tgr_scale'length);

		process (rgtr_clk)
		begin
			if rising_edge(rgtr_clk) then
				if vt_dv='1' then
					load <= '1';
				elsif gain_dv='1' then
					load <= '1';
				else
					load <= '0';
				end if;
			end if;
		end process;

		xxx_b : block
			constant a : std_logic_vector := b"000";
			signal   b : std_logic_vector(a'range);
			signal   s : std_logic_vector(a'range);
		begin
			process (rgtr_clk)
			begin
			end process;

			resize(unsigned(vt_offset), bin'length));
			adder_ser_e : entity hdl4fpga.adder_ser
			port map (
				clk => rgtr_clk,
				ena => '1',
				a   => b"000",
				b   => b,
				s   => s);
		end block;

		bin <= std_logic_vector(resize(unsigned(vt_offset), bin'length));
		bin2bcd_e : entity hdl4fpga.dbdbbl_seq
		generic map (
			bcd_digits => bcd_digits)
		port map (
			clk  => rgtr_clk,
			load => load,
			last => last,
			bin  => bin,
			bcd  => bcd);

		process (rgtr_clk)
		begin
			if rising_edge(rgtr_clk) then
				if last='1' then
					bcd_code <= x"3" & bcd(0 to 4-1);
				end if;
			end if;
		end process;

		xxx <= last;
	end block;

	video_addr <= std_logic_vector(resize(
		mul(unsigned(video_vcntr) srl fontheight_bits, textbox_width(layout)/font_width) +
		(unsigned(video_hcntr(textwidth_bits-1 downto 0)) srl fontwidth_bits),
		video_addr'length));
	video_on <= text_on and sgmntbox_ena(0);

	process (rgtr_clk)
		constant dn : std_logic := '1';
		type states is (s_init, s_convert);
		variable state : states;
	begin
		if rising_edge(rgtr_clk) then
			if cga_we='1' then
				if dn='0' then
					cga_addr <= cga_addr + 1;
				else
					cga_addr <= cga_addr - 1;
				end if;
			end if;
			if xxx='1' then
				cga_we   <= '1';
			else
				cga_addr <= to_unsigned(5-1, cga_addr'length);
				cga_we   <= '0';
			end if;
		end if;
	end process;
	cga_code <= bcd_code;

	cgaram_e : entity hdl4fpga.cgaram
	generic map (
		cga_bitrom   => cga_bitrom,
		font_bitrom  => font_bitrom,
		font_height  => font_height,
		font_width   => font_width)
	port map (
		cga_clk      => rgtr_clk,
		cga_we       => cga_we,
		cga_addr     => std_logic_vector(cga_addr),
		cga_data     => cga_code,

		video_clk    => video_clk,
		video_addr   => video_addr,
		font_hcntr   => video_hcntr(unsigned_num_bits(font_width-1)-1 downto 0),
		font_vcntr   => video_vcntr(unsigned_num_bits(font_height-1)-1 downto 0),
		video_on     => video_on,
		video_dot    => video_dot);

	lat_e : entity hdl4fpga.latency
	generic map (
		n => 1,
		d => (0 => latency-cgaadapter_latency))
	port map (
		clk => video_clk,
		di(0) => video_dot,
		do(0) => text_fgon);

	process (video_clk)
		constant field_addr : natural_vector := textbox_field(cga_cols, cga_size);
		variable field_id   : unsigned(0 to unsigned_num_bits(field_addr'length-1)-1);
		variable addr       : std_logic_vector(video_addr'range);
	begin
		if rising_edge(video_clk) then
			textfg <= std_logic_vector(resize(field_id, textfg'length)+pltid_order'length);
			if unsigned(addr)=field_addr(to_integer(field_id)) then
				if video_on='1' then
					if field_id /= field_addr'length-1 then
						field_id := field_id + 1;
					else
						field_id := (others => '0');
					end if;
				end if;
			end if;
			addr := video_addr;
		end if;
	end process;

	textbg <= std_logic_vector(to_unsigned(pltid_textbg, textbg'length));

	latfg_e : entity hdl4fpga.latency
	generic map (
		n =>  text_fg'length,
		d => (0 to text_fg'length-1 => latency-cgaadapter_latency+2))
	port map (
		clk => video_clk,
		di => textfg,
		do => text_fg);
	latbg_e : entity hdl4fpga.latency
	generic map (
		n => text_bg'length,
		d => (0 to text_bg'length-1 => latency-cgaadapter_latency+2))
	port map (
		clk => video_clk,
		di => textbg,
		do => text_bg);
end;
