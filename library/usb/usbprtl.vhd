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

entity usbprtl is
   	generic (
		oversampling : natural := 0;
		watermark    : natural := 0;
		bit_stuffing : natural := 6);
	port (
		tp   : out std_logic_vector(1 to 32);
		dp   : inout std_logic := 'Z';
		dn   : inout std_logic := 'Z';
		clk  : in  std_logic;
		cken : buffer std_logic;

		txen : in  std_logic;
		txbs : buffer std_logic;
		txd  : in  std_logic;

		rxdv : out std_logic;
		rxbs : buffer std_logic;
		rxd  : buffer std_logic);

	constant length_of_sync  : natural := 8;
	constant length_of_pid   : natural := 8;
	constant length_of_crc5  : natural := 5;
	constant length_of_crc16 : natural := 16;
end;

architecture def of usbprtl is
	signal phy_txen : std_logic;
	signal phy_txbs : std_logic;
	signal phy_txd  : std_logic;
	signal phy_rxbs : std_logic;
	signal phy_rxdv : std_logic;
	signal phy_rxd  : std_logic;

	signal dv       : std_logic;
	signal data     : std_logic;
	signal crcact   : std_logic;
	signal crcdv    : std_logic;
	signal crcen    : std_logic;
	signal crcd     : std_logic;
	signal crc5     : std_logic_vector(0 to 5-1);
	signal crc16    : std_logic_vector(0 to 16-1);
	signal bitstff  : std_logic;
	signal pktdat   : std_logic;
	signal pid      : std_logic_vector(8-1 downto 0);

	-- type tokens is (tk_out, tk_in, tk_sof, tksetup);
	constant tk_out   : std_logic_vector := b"0001";
	constant tk_in    : std_logic_vector := b"1001";
	constant tk_sof   : std_logic_vector := b"0101";
	constant tk_setup : std_logic_vector := b"1101";

	constant data0    : std_logic_vector := b"0011";
	constant data1    : std_logic_vector := b"1011";

begin

	tp(1 to 3) <= (phy_txen, phy_txbs, phy_txd);

	usbphy_e : entity hdl4fpga.usbphy
   	generic map (
		oversampling => oversampling,
		watermark    => watermark,
		bit_stuffing => bit_stuffing)
	port map (
		dp   => dp,
		dn   => dn,
		clk  => clk,
		cken => cken,

		txen => phy_txen,
		txbs => phy_txbs,
		txd  => phy_txd,

		rxdv => phy_rxdv,
		rxbs => phy_rxbs,
		rxd  => phy_rxd);

	usbcrc_e : entity hdl4fpga.usbcrc
	port map (
		clk   => clk,
		cken  => crcen,
		dv    => crcdv,
		data  => data,
		crc5  => crc5,
		crc16 => crc16);

	crcd <= crc16(0) when pktdat='1' else crc5(0);
	crcglue_e : entity hdl4fpga.usbcrcglue
	port map (
		clk      => clk,
		cken     => cken,
		dv       => dv,
		bitstff  => bitstff,
		data     => data,
           
		crcdv    => crcdv,
		crcact   => crcact,
		crcen    => crcen,
		crcd     => crcd,
           
		txen     => txen,
		txbs     => txbs,
		txd      => txd,
           
		phy_txen => phy_txen,
		phy_txbs => phy_txbs,
		phy_txd  => phy_txd,
           
		rxdv     => rxdv,
		rxbs     => rxbs,
		rxd      => rxd,
           
		phy_rxdv => phy_rxdv,
		phy_rxbs => phy_rxbs,
		phy_rxd  => phy_rxd);

	pid_and_crc_p : process (clk)
		type states is (s_pid, s_payload, s_crc);
		variable state : states;
		variable cntr  : natural range 0 to max(length_of_crc16,length_of_crc5)-1+length_of_pid-1;
		variable id    : unsigned(8-1 downto 0);
	begin
		if rising_edge(clk) then
			case state is
			when s_pid =>
				if dv='0' then
					cntr := length_of_pid-1;
					crcact <= '0';
				elsif cken='1' then
					if bitstff='0' then
						if cntr /= 0 then
							cntr  := cntr - 1;
							crcact <= '0';
						else 
							crcact <= txen or phy_rxdv;
							state := s_payload;
						end if;
						id(0) := data;
						id := id ror 1;
					end if;
				else
					crcact <= '0';
				end if;
				if id(2-1 downto 0)="11" then
					pktdat <= '1';
				else
					pktdat <= '0';
				end if;
				pid <= std_logic_vector(id);
			when s_payload =>
				if cken='1' then
					if dv='0' then
						if crcact='1' then
							state := s_crc;
						else
							state := s_pid;
						end if;
					end if;
				end if;
				-- crc plus tx serial register
				if pktdat='1' then
					cntr := (length_of_crc16-1)+length_of_sync-1;
				else
					cntr :=  (length_of_crc5-1)+length_of_sync-1;
				end if;
			when s_crc =>
				if cken='1' then
					if bitstff='0' then
						if cntr /= 0 then
							cntr := cntr - 1;
						else
							crcact <= '0';
							state := s_pid;
						end if;
					end if;
				end if;
			end case;
		end if;
	end process;

	process(clk)
		type states is (s_setup, s_data0, s_ack);
		variable state : states;

	begin
		if rising_edge(clk) then
			case pid(4-1 downto 0) is
			when tk_setup =>
			when data0 =>
				
			when others =>
			end case;
		end if;
	end process;
end;