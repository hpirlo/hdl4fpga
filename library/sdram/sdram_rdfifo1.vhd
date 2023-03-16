--                                                                            --
-- Author(s):                                                                 --
--   Miguel Angel Sagreras                                                    --
--                                                                            --
-- Copyright (C) 2015                                                         --
--    Miguel Angel Sagreras                                                   --
--                                                                            --
-- This source file may be used and distributed without restriction provided  --
-- that this copyright statement is not removed from the file and that any    --
-- derivative work contains  the original copyright notice and the associated --
-- disclaimer.                                                                --
--                                                                            --
-- This source file is free software; you can redistribute it and/or modify   --
-- it under the terms of the GNU General Public License as published by the   --
-- Free Software Foundation, either version 3 of the License, or (at your     --
-- option) any later version.                                                 --
--                                                                            --
-- This source is distributed in the hope that it will be useful, but WITHOUT --
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or      --
-- FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for   --
-- more details at http://www.gnu.org/licenses/.                              --
--                                                                            --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_rdfifo1 is
	generic (
		data_delay    : natural := 1;
		data_gear     : natural := 64;
		word_size     : natural := 16;
		byte_size     : natural := 8);
	port (
		sys_clk       : in  std_logic;
		sys_rdy       : out std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
		sys_rea       : in  std_logic;
		sys_do        : out std_logic_vector(data_gear*word_size-1 downto 0);
		sys_win_dq    : out std_logic_vector(data_gear*word_size/byte_size-1 downto 0);

		sdram_win_dq  : in std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
		sdram_win_dqs : in std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
		sdram_dqsi    : in std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
		sdram_dqi     : in std_logic_vector(data_gear*word_size-1 downto 0));
end;

library hdl4fpga;
use hdl4fpga.base.all;

architecture struct of sdram_rdfifo1 is
	subtype byte is std_logic_vector(BYTE_SIZE-1 downto 0);
	type byte_vector is array (natural range <>) of byte;

	subtype word is std_logic_vector(DATA_GEAR*WORD_SIZE/sdram_dqsi'length-1 downto 0);
	type word_vector is array (natural range <>) of word;

	function to_stdlogicvector (
		constant arg : word_vector)
		return std_logic_vector is
		variable dat : word_vector(arg'length-1 downto 0);
		variable val : unsigned(arg'length*byte'length-1 downto 0);
	begin
		dat := arg;
		for i in dat'range loop
			val := val sll byte'length;
			val(byte'range) := unsigned(dat(i));
		end loop;
		return std_logic_vector(val);
	end;

	impure function to_wordvector (
		constant arg : std_logic_vector) 
		return word_vector is
		variable dat : unsigned(arg'length-1 downto 0);
		variable val : word_vector(arg'length/word'length-1 downto 0);
	begin	
		dat := unsigned(arg);
		for i in val'reverse_range loop
			val(i) := std_logic_vector(dat(word'length-1 downto 0));
			dat := dat srl word'length;
		end loop;
		return val;
	end;

	signal do : word_vector(sdram_dqsi'length-1 downto 0);
	signal di : word_vector(sdram_dqsi'length-1 downto 0);

	signal sys_do_win : std_logic;
begin

	process (sys_clk)
		variable acc_rea_dly : std_logic;
	begin
		if rising_edge(sys_clk) then
			sys_do_win  <= acc_rea_dly;
			acc_rea_dly := not sys_rea;
		end if;
	end process;

	di  <= to_wordvector(sdram_dqi);
	datadelay_g : if data_delay/=0 generate
		bytes_g : for i in word_size/byte_size-1 downto 0 generate
			data_phases_g : for j in 0 to data_gear-1 generate
				signal pll_req : std_logic;
			begin
	
				process (sys_clk)
					variable q : std_logic_vector(0 to data_delay);
				begin 
					if rising_edge(sys_clk) then
						q := q(1 to q'right) & sdram_win_dq(i*data_gear+j);
						if q=(q'range => '0') then
							sys_win_dq(i*data_gear+j) <= '0';
						else
							sys_win_dq(i*data_gear+j) <= '1';
						end if;
						pll_req <= q(0);
					end if;
				end process;
				sys_rdy(i*data_gear+j) <= pll_req;
	
				inbyte_i : entity hdl4fpga.iofifo1
				generic map (
					pll2ser    => false,
					data_gear  => 1,
					word_size  => word'length,
					byte_size  => byte'length)
				port map (
					pll_clk    => sys_clk,
					pll_req    => pll_req,
	
					ser_ar(0)  => sys_do_win,
					ser_ena(0) => sdram_win_dqs(i*data_gear+j),
					ser_clk(0) => sdram_dqsi(i*data_gear+j),
	
					di  => di(i*data_gear+j),
					do  => do(j*WORD_SIZE/BYTE_SIZE+i));
			end generate;
		end generate;
	end generate;

	no_datadelay_g : if data_delay=0 generate
		bytes_g : for i in word_size/byte_size-1 downto 0 generate
			data_phases_g : for j in 0 to data_gear-1 generate
				sys_rdy(i*data_gear+j) <= sdram_win_dqs(i*data_gear+j);
				do(j*word_size/byte_size+i) <= di(i*data_gear+j);
			end generate;
		end generate;
		sys_win_dq <= sdram_win_dq;
	end generate;

	
	sys_do <= to_stdlogicvector(do);

end;
