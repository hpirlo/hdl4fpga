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

library hdl4fpga;
use hdl4fpga.std.all;
use hdl4fpga.scopeiopkg.all;

entity scopeio_capture is
	port (
		input_clk      : in  std_logic;
		downsampler_on : in  std_logic := '0';
		capture_shot   : in  std_logic;
		capture_end    : out std_logic;

		input_dv       : in  std_logic := '1';
		input_data     : in  std_logic_vector;
		input_delay    : in  std_logic_vector;

		capture_clk    : in  std_logic;
		capture_addr   : in  std_logic_vector;
		capture_data   : out std_logic_vector;
		capture_dv     : out std_logic);
end;

architecture beh of scopeio_capture is

	constant bram_latency : natural := 2;

	constant capture_size : natural := 2**capture_addr'length;
	constant delay_size   : natural := 2**input_delay'length;

	signal index   : signed(input_delay'length-1  downto 0);
	signal bound   : signed(input_delay'length-1  downto 0);
	signal base    : signed(capture_addr'length-1 downto 0);
	signal rd_addr : signed(capture_addr'length-1 downto 0);
	signal wr_addr : signed(capture_addr'length-1 downto 1) := (others => '0'); -- Debug purpose
	signal wr_ena  : std_logic;
	signal no_data : std_logic_vector(input_data'range);

	signal running : std_logic;
	signal delay   : signed(input_delay'range);
	signal valid   : std_logic;


begin
 
	capture_addr_p : process (input_clk)
		variable full : std_logic;
		variable pre  : std_logic;
		variable cntr : signed(0 to input_delay'length) := (others => '1'); -- Debug purpose
	begin
		if rising_edge(input_clk) then
			if input_dv='1' then
				if signed(input_delay) < 0 then
					-- Pre-trigger
					if capture_shot='1' then
						if full='0' then
							pre  := '0';
							cntr := to_signed(-capture_size, cntr'length);
							base <= (others => '-');
						else
							pre  := '1';
							cntr := resize(-signed(input_delay)-capture_size+1, cntr'length);
							base <= shift_left(resize(wr_addr,base'length),1);
						end if;
						delay   <= signed(input_delay);
						bound   <= signed(resize(cntr, bound'length));
						running <= cntr(0);
					elsif full='0' then
						cntr    := cntr + 1;
						full    := setif(cntr+delay > 0);
						bound   <= to_signed(-capture_size, bound'length);
						running <= '1';
					elsif pre='0' then
						cntr    := cntr + 1;
						full    := '1';
						bound   <= to_signed(-capture_size, bound'length);
						running <= '1';
					elsif cntr(0)='1' then
						cntr    := cntr + 1;
						full    := '1';
						bound   <= signed(resize(cntr, bound'length));
						running <= cntr(0);
					end if;
				else
					-- Delayed trigger
					if capture_shot='1' then
						cntr  := resize(-signed(input_delay)-capture_size+1, cntr'length);
						base  <= shift_left(resize(wr_addr, base'length), 1);
						delay <= signed(input_delay);
					elsif cntr(0)='1' then
						cntr := cntr + 1;
					end if;
					bound   <= signed(resize(cntr, bound'length));
					running <= cntr(0);
				end if;
			end if;
		end if;
	end process;

	index <= signed(input_delay)+signed(resize(unsigned(capture_addr), input_delay'length));

	capture_valid_p : valid <=
		setif(index > -capture_size and delay <= index and -capture_size < delay-index) when not running='1' else
		setif(index > -capture_size and delay <= index and -capture_size < delay-index+bound);

	valid_e : entity hdl4fpga.align
	generic map (
		n => 1,
		d => (0 to 0 => bram_latency))
	port map (
		clk   => capture_clk,
		di(0) => '1', --valid,
		do(0) => capture_dv);

	capture_end <= not running;

	storage_b : block
		signal addrb   : std_logic_vector(capture_addr'length-1 downto 1);
		signal rd_data : std_logic_Vector(capture_data'range);
		signal y0      : std_logic_Vector(0 to capture_data'length/2-1);
	begin

		rd_addr <= base + index(rd_addr'range);
		wr_addr_p : process (input_clk)
		begin
			if rising_edge(input_clk) then
				if input_dv='1' then
					wr_addr <= wr_addr + 1;
				end if;
			end if;
		end process;
		wr_ena  <= (running or capture_shot) and input_dv;

		addrb <= std_logic_vector(word2byte(rd_addr(rd_addr'left downto 1) & rd_addr(rd_addr'left-1 downto 0), downsampler_on));
		mem_e : entity hdl4fpga.bram(inference)
		port map (
			clka  => input_clk,
			addra => std_logic_vector(wr_addr),
			wea   => wr_ena,
			dia   => input_data,
			doa   => no_data,

			clkb  => capture_clk,
			addrb => addrb, --std_logic_vector(rd_addr(rd_addr'left downto 1)),
			dib   => no_data,
			dob   => rd_data);


		process (capture_clk)
		begin
			if rising_edge(capture_clk) then
				y0 <= word2byte(rd_data, rd_addr(0));
			end if;
		end process;
		capture_data <= word2byte(y0 & word2byte(rd_data, rd_addr(0)) & rd_data, downsampler_on);
--		capture_data <= b"0_00_0000" & b"0_11_1111";

	end block;

end;
