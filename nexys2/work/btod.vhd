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

entity test is
	port (
		clk     : in  std_logic;
		bin_di  : in  std_logic_vector( 4-1 downto 0);
		bin_dv  : in  std_logic;
		bcd_ena : in  std_logic;
		bcd_cy  : out std_logic;
		bcd_di  : in  std_logic_vector( 4-1 downto 0);
		bcd_do  : out std_logic_vector(4-1 downto 0));
end;

architecture btod of test is
begin
	smult_e : entity hdl4fpga.btod
	port map (
		clk     => clk,
		bin_di  => bin_di,
		bin_dv  => bin_dv,
		bcd_ena => bcd_ena,
		bcd_cy  => bcd_cy,
		bcd_di  => bcd_di,
		bcd_do  => bcd_do);
end;
