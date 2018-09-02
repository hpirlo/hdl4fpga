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

architecture scopeio_format of testbench is
	signal rst     : std_logic := '1';
	signal clk     : std_logic := '0';

	signal fill_ena : std_logic := '1';
	signal point    : std_logic_vector := "111";

	signal value    : std_logic_vector(16-1 downto 0);
	signal bcd_dv   : std_logic;
	signal bcd_dat  : std_logic_vector(0 to 4*8-1);

begin

	clk <= not clk  after  5 ns;

	linear_b : block
		signal wr_addr : std_logic_vector(0 to 6) := (others => '0');
		signal rd_addr : std_logic_vector(1 to 6) := (others => '0');
		signal rd_data : std_logic_vector(bcd_dat'range);
	begin
		process(clk)
			variable cntr : unsigned(value'range);
		begin
			if rising_edge(clk) then
				if fill_ena='0' then
					cntr := (others => '0');
				elsif bcd_dv='1' then
					if wr_addr(0)='0' then
						cntr    := cntr + unsigned(step);
						wr_addr <= std_logic_vector(unsigned(wr_addr) + 1);
					end if;
				end if;
				value <= std_logic_vector(cntr);
			end if;
		end process;
		binary_ena <= not wr_addr(0);

		ram_e : entity hdl4fpga.dpram
		port map (
			wr_clk  => clk,
			wr_ena  => bcd_dv,
			wr_addr => wr_addr(1 to 6),
			wr_data => bcd_dat,
			rd_addr => rd_addr,
			rd_data => rd_data);
	end block;

	du: entity hdl4fpga.scopeio_format
	port map (
		clk        => clk,
		binary_ena => binary_ena,
		binary     => value,
		point      => point,
		bcd_dv     => bcd_dv,
		bcd_dat    => bcd_dat);

end;
