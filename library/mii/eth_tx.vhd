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

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hdl4fpga;
use hdl4fpga.std.all;
use hdl4fpga.ethpkg.all;

entity eth_tx is
	generic (
		hwsa       : in  std_logic_vector(0 to 6*8-1) := x"00_40_00_01_02_03");
	port (
		mii_txc    : in  std_logic;
		proto_txen : in  std_logic;
		proto_txd  : in  std_logic_vector;
		eth_txen   : out std_logic;
		eth_txd    : out std_logic_vector);

end;

architecture def of eth_tx is

	signal hwda_trdy : std_logic;
	signal hwda_txen : std_logic;
	signal hwda_txd  : std_logic_vector(eth_txd'range);

	signal hwsa_trdy : std_logic;
	signal hwsa_txen : std_logic;
	signal hwsa_txd  : std_logic_vector(eth_txd'range);

	signal lat_txen  : std_logic;
	signal lat_txd   : std_logic_vector(eth_txd'range);

	signal dll_txen  : std_logic;
	signal dll_txd   : std_logic_vector(eth_txd'range);

begin

	hwda_e : entity hdl4fpga.mii_rom
	generic map (
		mem_data => reverse(hwsa, 8))
	port map (
		mii_txc  => mii_txc,
		mii_treq => proto_txen,
		mii_trdy => hwda_trdy,
		mii_txd  => hwda_txd);

	hwsa_e : entity hdl4fpga.mii_rom
	generic map (
		mem_data => reverse(hwsa, 8))
	port map (
		mii_txc  => mii_txc,
		mii_treq => hwda_trdy,
		mii_trdy => hwsa_trdy,
		mii_txd  => hwsa_txd);

	lattxd_e : entity hdl4fpga.align
	generic map (
		n => eth_txd'length,
		d => (0 to eth_txd'length-1 => (eth_frame(eth_hwda)+eth_frame(eth_hwsa/eth_txd'length))))
	port map (
		clk => mii_txc,
		di  => proto_txd, 
		do  => lat_txd);

	lattxdv_e : entity hdl4fpga.align
	generic map (
		n => 1,
		d => (0 to eth_txd'length-1 => (eth_frame(eth_hwda)+eth_frame(eth_hwsa/eth_txd'length))))
	port map (
		clk   => mii_txc,
		di(0) => proto_txen,
		do(0) => lat_txen);

	dll_txd  <= primux (hwda_txd & hwsa_txd & lat_txd, not hwsa_trdy & not hwsa_trdy & lat_txen);
	dll_txen <= hwda_txen or hwsa_txen or lat_txen;

	dll_e : entity hdl4fpga.eth_dll
	port map (
		mii_txc  => mii_txc,
		dll_txen => dll_txen,
		dll_txd  => dll_txd,
		mii_txen => eth_txen,
		mii_txd  => eth_txd);

end;

