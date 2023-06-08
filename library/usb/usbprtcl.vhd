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
use hdl4fpga.base.all;

entity usbprtcl is
   	generic (
		oversampling : natural;
		watermark    : natural := 0;
		bit_stuffing : natural := 5);
	port (
		dp   : inout std_logic;
		dn   : inout std_logic;
		clk  : in  std_logic;
		cken : buffer std_logic;

		txen : in  std_logic;
		txbs : out std_logic;
		txd  : in  std_logic;

		rxdv : buffer std_logic;
		rxd  : buffer std_logic);
end;

architecture def of usbprtcl is
	signal frm : std_logic;
	signal dv  : std_logic;
begin

	usbphy_e : entity hdl4fpga.usbphy
   	generic map (
		oversampling => oversampling,
		watermark    => watermark,
		bit_stuffing => bit_stuffing);
	port map (
		dp   => dp,
		dn   => dn,
		clk  => clk,
		cken => cken,

		txen => txen,
		txbs => txbs,
		txd  => txd,

		rxdv => rxdv,
		rxd  => rxd);

	process (clk)
		type states is (s_pid, s_data);
		variable state : states;
		variable cntr  : natural range 0 to 7;
		variable pid   : unsigned(8-1 downto 0);
	begin
		if rising_edge(clk) then
			case state is
			when s_pid =>
				if frm='0' then
					cntr := 0;
				elsif dv='1' then
					if cntr < 7 then
						cntr := cntr + 1;
					else 
						state := s_data;
					end if;
					pid(0) := rxd(0);
					pid := pid ror 1;
				end if;
				crc_frm <= '0';
			when s_data =>
				if frm='0' then
					crc_frm <= '0';
					state := s_pid;
				else
					crc_frm <= '1';
				end if;
			end case;
		end if;
	end process;

	dv <= (rxdv or txen) and cken;
	usbcrc_e : entity hdl4fpga.usbcrc
	port map (
		clk   => clk,
		cken  => cken,
		frm   => frm,
		dv    => dv,
		data  => ,
		crc5  => crc5,
		crc16 => crc16);

end;