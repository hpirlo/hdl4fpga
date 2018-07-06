library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hdl4fpga;

entity scopeio_mmap is
	port (
		in_clk       : in  std_logic;
		in_ena       : in  std_logic;
		in_data      : in  std_logic_vector;

		trigger_edge    : out std_logic;
		trigger_level   : out std_logic_vector;
		trigger_channel : out std_logic_vector;

		hzaxis_data  : out std_logic_vector;
		vtaxis_data  : out std_logic_vector);
end;

architecture beh of scopeio_downsampler is
	signal dev_ena :
begin

	process (in_clk)
	begin
		if rising_edge(in_clk) then
			if in_ena='1' then
				if ptr(0) /= '1' then
					data(in_data'range) := in_data;
					data := data rol in_data'length;
					ptr := ptr + 1;
				else
					dev_id <= data(devid'range);
					data   := data ror devid'length;
					reg_id <= data(regid'range);
				end if;
			else
				ptr := (others => '0');
			end if;
		end if;
	end process;
	dev_ena <= demux(dev_id, ptr(0));
	reg_ena <= demux(reg_id, ptr(0)); 

	regfile_b : block 
		constant max_rid : natural := rid_channel+1;

		type rgtr_param record
			devid  : natural;
			regid  : natural;
			offset : natural;
			size   : natural;
		end record;

		type regdev_vector array (natural range <>) of rgtr_param;

		constant rgtr_tgrlevel   : natural := 0;
		constant rgtr_tgrchannel : natural := 1;

		constant rgtr_map : regmap_vector := (		-- Map Descritpion
			(devid_tgr, rgtr_tgrlevel,   10),
			(devid_tgr, rgtr_tgrchannel,  5));

	begin
		rgtr_g : for rid in rgtr_map'range generate
			constant dev_base    : natural := dev_map(rgtr_map(i).devid).base;
			constant rgrt_offset : natural := rgtr_map(i).offset;
			constant rgrt_size   : natural := rgtr_map(i).offset;

			subtype rgtr_slice is natural dev_base+rgtr_offset to dev_base+rgtr_offset+rgtr_size;

			signal  rgtr : std_logic_vector(0 to rgtr_map(i).size-1);
		begin

			cp_p : process (in_clk)
				variable value : unsigned(0 to rgtr_map(i).size-1);
			begin
				if rising_edge(in_clk) then
					if in_ena='1' then
						if dev_ena(rgtr_map(i).devid)='1' then
							if reg_ena(rgtr_map(i).regid)='1' then
								if value'length >= in_data'length then
									value(in_data'range) := unsigned(in_data);
								else
									value := unsigned(in_data(value'range));
								end if;
								value := value ror in_data'length;
							end if;
						end if;
					else
						rgtr <= std_logic_vector(value);
					end if;
				end if;
			end process;

			(rgtr_slice'range) <= rgtr;

		end generate;
	end block;

			if pll_rdy='1' then
				for i in 0 to inputs-1 loop
					if i=to_integer(unsigned(scope_channel(channel_select'range))) then
						case scope_cmd(3 downto 0) is
						when "0000" =>
							channel_scale  <= byte2word(channel_scale, 
											  scope_data(vt_scale'range),
											  reverse(std_logic_vector(to_unsigned(2**i, inputs))));
							channel_decas  <= byte2word(channel_decas, 
											  vt_scales(to_integer(unsigned(scope_data(vt_scale'range)))).deca,
											  reverse(std_logic_vector(to_unsigned(2**i, inputs))));
							channel_select <= std_logic_vector(to_unsigned(i, channel_select'length));

							vt_scale       <= scope_data(vt_scale'range);
						when "0001" =>
							channel_offset <= byte2word(channel_offset, std_logic_vector(resize(signed(scope_data), vt_size)), reverse(std_logic_vector(to_unsigned(2**i, inputs))));
							vt_pos   <= std_logic_vector(resize(signed(scope_data), vt_pos'length));
						when others =>
						end case;
					end if;
				end loop;

				case scope_cmd(3 downto 0) is
				when "0010" =>
					trigger_level   <= std_logic_vector(resize(signed(scope_data), vt_size));
					trigger_channel <= std_logic_vector(resize(unsigned(scope_channel and x"7f"),trigger_channel'length));
					trigger_edge    <= scope_channel(scope_channel'left);
				when "0011" =>
					hz_scale        <= scope_data(hz_scale'range);
					time_deca       <= hz_scales(to_integer(unsigned(scope_data(hz_scale'range)))).deca;
					g_hzscale       <= hz_scales(to_integer(unsigned(scope_data(hz_scale'range)))).scale;
				when others =>
				end case;
			end if;
		end if;
	end process;
	process (input_clk)
	begin
		if rising_edge(input_clk) then
			output_ena <= cntr(cntr'left) and input_ena;
			if input_ena='1' then
				if cntr(cntr'left)='1' then
					cntr <= signed(factor_data);
				else
					cntr <= cntr - 1;
				end if;
			end if;
		end if;
	end process;

	lat_e : entity hdl4fpga.align
	generic map (
		n => input_data'length,
		d => (input_data'range => 1)
	port map (
		clk => clk,
		di  => input_data,
		do  => output_data);
end;
