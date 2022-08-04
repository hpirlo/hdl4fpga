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
use hdl4fpga.profiles.all;
use hdl4fpga.ddr_db.all;
use hdl4fpga.ipoepkg.all;
use hdl4fpga.videopkg.all;

library ecp5u;
use ecp5u.components.all;

architecture graphics of ulx4m_ld is

	--------------------------------------
	-- Set of profiles                  --
	type apps is (
	--	Interface_SdramSpeed_PixelFormat--

		uart_400MHz_480p24bpp,
		uart_425MHz_480p24bpp,
		uart_450MHz_480p24bpp,
		uart_475MHz_480p24bpp,
		uart_500MHz_480p24bpp,
		uart_400MHz_600p24bpp,


		mii_400MHz_480p24bpp,
		mii_425MHz_480p24bpp,
		mii_450MHz_480p24bpp,
		mii_475MHz_480p24bpp,
		mii_500MHz_480p24bpp);
	--------------------------------------

	---------------------------------------------
	-- Set your profile here                   --
	constant app : apps := uart_400MHz_480p24bpp;
	---------------------------------------------

	constant sys_freq    : real    := 25.0e6;

	constant sclk_phases : natural := 1;
	constant sclk_edges  : natural := 1;
	constant cmmd_gear   : natural := 2;
	constant data_edges  : natural := 1;
	constant data_gear   : natural := 4;

	constant bank_size   : natural := ddram_ba'length;
	constant addr_size   : natural := ddram_a'length;
	constant coln_size   : natural := 10;
	constant word_size   : natural := ddram_dq'length;
	constant byte_size   : natural := ddram_dq'length/ddram_dqs'length;

	signal sys_rst       : std_logic;

	signal ddrsys_rst    : std_logic;
	signal ddrphy_rst    : std_logic;
	signal physys_clk    : std_logic;

	signal dramclk_lck   : std_logic;

	signal ctlrphy_frm   : std_logic;
	signal ctlrphy_trdy  : std_logic;
	signal ctlrphy_ini   : std_logic;
	signal ctlrphy_rw    : std_logic;
	signal ctlrphy_wlreq : std_logic;
	signal ctlrphy_wlrdy : std_logic;
	signal ctlrphy_rlreq : std_logic;
	signal ctlrphy_rlrdy : std_logic;

	signal ctlrphy_rst   : std_logic_vector(0 to 2-1);
	signal ctlrphy_cke   : std_logic_vector(0 to 2-1);
	signal ctlrphy_cs    : std_logic_vector(0 to 2-1);
	signal ctlrphy_ras   : std_logic_vector(0 to 2-1);
	signal ctlrphy_cas   : std_logic_vector(0 to 2-1);
	signal ctlrphy_we    : std_logic_vector(0 to 2-1);
	signal ctlrphy_odt   : std_logic_vector(0 to 2-1);
	signal ctlrphy_cmd   : std_logic_vector(0 to 3-1);
	signal ctlrphy_ba    : std_logic_vector(cmmd_gear*ddram_ba'length-1 downto 0);
	signal ctlrphy_a     : std_logic_vector(cmmd_gear*ddram_a'length-1 downto 0);
	signal ctlrphy_dsi   : std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
	signal ctlrphy_dst   : std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
	signal ctlrphy_dso   : std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
	signal ctlrphy_dmi   : std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
	signal ctlrphy_dmt   : std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
	signal ctlrphy_dmo   : std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
	signal ctlrphy_dqi   : std_logic_vector(data_gear*word_size-1 downto 0);
	signal ctlrphy_dqt   : std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
	signal ctlrphy_dqo   : std_logic_vector(data_gear*word_size-1 downto 0);
	signal ctlrphy_sto   : std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
	signal ctlrphy_sti   : std_logic_vector(data_gear*word_size/byte_size-1 downto 0);
	signal ddr_ba        : std_logic_vector(ddram_ba'length-1 downto 0);
	signal ddr_a         : std_logic_vector(ddram_a'length-1 downto 0);

	type pll_params is record
		clkos_div  : natural;
		clkop_div  : natural;
		clkfb_div  : natural;
		clki_div   : natural;
		clkos2_div : natural;
		clkos3_div : natural;
	end record;

	type video_modes is (
		mode480p24,
		mode600p16,
		mode600p24,
		mode900p24,
		modedebug);

	type pixel_types is (
		rgb565,
		rgb888);

	type video_params is record
		pll   : pll_params;
		mode  : videotiming_ids;
		pixel : pixel_types;
	end record;

	type videoparams_vector is array (video_modes) of video_params;
	constant v_r : natural := 5; -- video ratio
	constant video_tab : videoparams_vector := (
		modedebug  => (pll => (clkos_div => 2, clkop_div => 16,  clkfb_div => 1, clki_div => 1, clkos2_div => 16,    clkos3_div => 10), pixel => rgb888, mode => pclk_debug),
		mode480p24 => (pll => (clkos_div => 5, clkop_div => 25,  clkfb_div => 1, clki_div => 1, clkos2_div => v_r*5, clkos3_div => 16), pixel => rgb888, mode => pclk25_00m640x480at60),
		mode600p16 => (pll => (clkos_div => 2, clkop_div => 16,  clkfb_div => 1, clki_div => 1, clkos2_div => v_r*2, clkos3_div => 10), pixel => rgb565, mode => pclk40_00m800x600at60),
		mode600p24 => (pll => (clkos_div => 2, clkop_div => 16,  clkfb_div => 1, clki_div => 1, clkos2_div => v_r*2, clkos3_div => 10), pixel => rgb888, mode => pclk40_00m800x600at60),
		mode900p24 => (pll => (clkos_div => 2, clkop_div => 22,  clkfb_div => 1, clki_div => 1, clkos2_div => v_r*2, clkos3_div => 14), pixel => rgb888, mode => pclk108_00m1600x900at60)); -- 30 Hz

	signal video_clk      : std_logic;
	signal videoio_clk    : std_logic;
	signal video_lck      : std_logic;
	signal video_shft_clk : std_logic;
	signal dvid_crgb      : std_logic_vector(8-1 downto 0);

	type ddram_speed is (
		ddram400MHz,
		ddram425MHz,
		ddram450MHz,
		ddram475MHz,
		ddram500MHz);

	type ddram_params is record
		pll : pll_params;
		cl  : std_logic_vector(0 to 3-1);
		cwl : std_logic_vector(0 to 3-1);
	end record;

	type ddramparams_vector is array (ddram_speed) of ddram_params;
	constant ddram_tab : ddramparams_vector := (
		ddram400MHz => (pll => (clkos_div => 1, clkop_div => 1, clkfb_div => 16, clki_div => 1, clkos2_div => 1, clkos3_div => 1), cl => "010", cwl => "000"),
		ddram425MHz => (pll => (clkos_div => 1, clkop_div => 1, clkfb_div => 17, clki_div => 1, clkos2_div => 1, clkos3_div => 1), cl => "011", cwl => "001"),
		ddram450MHz => (pll => (clkos_div => 1, clkop_div => 1, clkfb_div => 18, clki_div => 1, clkos2_div => 1, clkos3_div => 1), cl => "011", cwl => "001"),
		ddram475MHz => (pll => (clkos_div => 1, clkop_div => 1, clkfb_div => 19, clki_div => 1, clkos2_div => 1, clkos3_div => 1), cl => "011", cwl => "001"),
		ddram500MHz => (pll => (clkos_div => 1, clkop_div => 1, clkfb_div => 20, clki_div => 1, clkos2_div => 1, clkos3_div => 1), cl => "011", cwl => "001"));

	signal ctlr_clk   : std_logic;

	constant mem_size : natural := 8*(1024*8);
	signal so_frm     : std_logic;
	signal so_irdy    : std_logic;
	signal so_trdy    : std_logic;
	signal so_data    : std_logic_vector(0 to 8-1);
	signal si_frm     : std_logic;
	signal si_irdy    : std_logic;
	signal si_trdy    : std_logic;
	signal si_end     : std_logic;
	signal si_data    : std_logic_vector(0 to 8-1);

	signal sio_clk    : std_logic;
	alias uart_clk    : std_logic is sio_clk;

	type io_iface is (
		io_hdlc,
		io_ipoe);

	type app_record is record
		iface : io_iface;
		mode  : video_modes;
		speed : ddram_speed;
	end record;

	type app_vector is array (apps) of app_record;
	constant app_tab : app_vector := (
		uart_400MHz_480p24bpp => (iface => io_hdlc, mode => mode480p24, speed => ddram400MHz),
		uart_425MHz_480p24bpp => (iface => io_hdlc, mode => mode480p24, speed => ddram425MHz),
		uart_450MHz_480p24bpp => (iface => io_hdlc, mode => mode480p24, speed => ddram450MHz),
		uart_475MHz_480p24bpp => (iface => io_hdlc, mode => mode480p24, speed => ddram475MHz),
		uart_500MHz_480p24bpp => (iface => io_hdlc, mode => mode480p24, speed => ddram500MHz),
		uart_400MHz_600p24bpp => (iface => io_hdlc, mode => mode600p24, speed => ddram400MHz),

		mii_400MHz_480p24bpp  => (iface => io_ipoe, mode => mode480p24, speed => ddram400MHz),
		mii_425MHz_480p24bpp  => (iface => io_ipoe, mode => mode480p24, speed => ddram425MHz),
		mii_450MHz_480p24bpp  => (iface => io_ipoe, mode => mode480p24, speed => ddram450MHz),
		mii_475MHz_480p24bpp  => (iface => io_ipoe, mode => mode480p24, speed => ddram475MHz),
		mii_500MHz_480p24bpp  => (iface => io_ipoe, mode => mode480p24, speed => ddram500MHz));

	constant nodebug_videomode : video_modes := app_tab(app).mode;
	-- constant video_mode   : video_modes := video_modes'VAL(setif(debug,
		-- video_modes'POS(modedebug),
		-- video_modes'POS(nodebug_videomode)));
	constant video_mode   : video_modes := nodebug_videomode;

    signal video_pixel    : std_logic_vector(0 to setif(
		video_tab(app_tab(app).mode).pixel=rgb565, 16, setif(
		video_tab(app_tab(app).mode).pixel=rgb888, 32, 0))-1);

	constant ddram_mode : ddram_speed := ddram_speed'VAL(setif(not FALSE,
		ddram_speed'POS(app_tab(app).speed),
		ddram_speed'POS(ddram400Mhz)));

	constant ddr_tcp : real := 
		real(ddram_tab(ddram_mode).pll.clki_div)/
		(real(ddram_tab(ddram_mode).pll.clkos_div*ddram_tab(ddram_mode).pll.clkfb_div)*sys_freq);

	constant io_link : io_iface := app_tab(app).iface;

	constant hdplx   : std_logic := setif(debug, '0', '1');

	signal tp : std_logic_vector(1 to 32);
	signal tp_phy : std_logic_vector(1 to 32);
begin

	sys_rst <= '0';
	videopll_b : block

		attribute FREQUENCY_PIN_CLKOS  : string;
		attribute FREQUENCY_PIN_CLKOS2 : string;
		attribute FREQUENCY_PIN_CLKOS3 : string;
		attribute FREQUENCY_PIN_CLKI   : string;
		attribute FREQUENCY_PIN_CLKOP  : string;

		constant video_freq  : real :=
			(real(video_tab(video_mode).pll.clkfb_div*video_tab(video_mode).pll.clkop_div)*sys_freq)/
			(real(video_tab(video_mode).pll.clki_div*video_tab(video_mode).pll.clkos2_div*1e6));

		constant video_shift_freq  : real :=
			(real(video_tab(video_mode).pll.clkfb_div*video_tab(video_mode).pll.clkop_div)*sys_freq)/
			(real(video_tab(video_mode).pll.clki_div*video_tab(video_mode).pll.clkos_div*1e6));

		constant videoio_freq  : real :=
			(real(video_tab(video_mode).pll.clkfb_div*video_tab(video_mode).pll.clkop_div)*sys_freq)/
			(real(video_tab(video_mode).pll.clki_div*video_tab(video_mode).pll.clkos3_div*1e6));

		attribute FREQUENCY_PIN_CLKOS  of pll_i : label is ftoa(video_shift_freq, 10);
		attribute FREQUENCY_PIN_CLKOS2 of pll_i : label is ftoa(video_freq,       10);
		attribute FREQUENCY_PIN_CLKOS3 of pll_i : label is ftoa(videoio_freq,     10);
		attribute FREQUENCY_PIN_CLKI   of pll_i : label is ftoa(sys_freq/1.0e6,   10);
		attribute FREQUENCY_PIN_CLKOP  of pll_i : label is ftoa(sys_freq/1.0e6,   10);

		signal clkfb : std_logic;

	begin
		pll_i : EHXPLLL
        generic map (
			PLLRST_ENA       => "DISABLED",
			INTFB_WAKE       => "DISABLED",
			STDBY_ENABLE     => "DISABLED",
			DPHASE_SOURCE    => "DISABLED",
			PLL_LOCK_MODE    =>  0,
			FEEDBK_PATH      => "CLKOP",
			CLKOS_ENABLE     => "ENABLED",  CLKOS_FPHASE   => 0, CLKOS_CPHASE  => 0,
			CLKOS2_ENABLE    => "ENABLED",  CLKOS2_FPHASE  => 0, CLKOS2_CPHASE => 0,
			CLKOS3_ENABLE    => "ENABLED",  CLKOS3_FPHASE  => 0, CLKOS3_CPHASE => 0,
			CLKOP_ENABLE     => "ENABLED",  CLKOP_FPHASE   => 0, CLKOP_CPHASE  => video_tab(video_mode).pll.clkop_div-1,
			CLKOS_TRIM_DELAY =>  0,         CLKOS_TRIM_POL => "FALLING",
			CLKOP_TRIM_DELAY =>  0,         CLKOP_TRIM_POL => "FALLING",
			OUTDIVIDER_MUXD  => "DIVD",
			OUTDIVIDER_MUXC  => "DIVC",
			OUTDIVIDER_MUXB  => "DIVB",
			OUTDIVIDER_MUXA  => "DIVA",

			CLKOS_DIV        => video_tab(video_mode).pll.clkos_div,
			CLKOS2_DIV       => video_tab(video_mode).pll.clkos2_div,
			CLKOS3_DIV       => video_tab(video_mode).pll.clkos3_div,
			CLKOP_DIV        => video_tab(video_mode).pll.clkop_div,
			CLKFB_DIV        => video_tab(video_mode).pll.clkfb_div,
			CLKI_DIV         => video_tab(video_mode).pll.clki_div)
        port map (
			rst       => '0',
			clki      => clk_25mhz,
			CLKFB     => clkfb,
            PHASESEL0 => '0', PHASESEL1 => '0',
			PHASEDIR  => '0',
            PHASESTEP => '0', PHASELOADREG => '0',
            STDBY     => '0', PLLWAKESYNC  => '0',
            ENCLKOP   => '0',
			ENCLKOS   => '0',
			ENCLKOS2  => '0',
            ENCLKOS3  => '0',
			CLKOP     => clkfb,
			CLKOS     => video_shft_clk,
			CLKOS2    => video_clk,
            CLKOS3    => videoio_clk,
			LOCK      => video_lck,
            INTLOCK   => open,
			REFCLK    => open,
			CLKINTFB  => open);

	end block;

	ctlrpll_b : block

		attribute FREQUENCY_PIN_CLKOS  : string;
		attribute FREQUENCY_PIN_CLKOS2 : string;
		attribute FREQUENCY_PIN_CLKOS3 : string;
		attribute FREQUENCY_PIN_CLKI   : string;
		attribute FREQUENCY_PIN_CLKOP  : string;

		constant ddram_mhz : real := 1.0e-6/ddr_tcp;


		attribute FREQUENCY_PIN_CLKOP of pll_i : label is ftoa(ddram_mhz, 10);
		attribute FREQUENCY_PIN_CLKI  of pll_i : label is ftoa(sys_freq/1.0e6, 10);

		signal clkfb : std_logic;

	begin

		assert false
		report real'image(ddram_mhz)
		severity NOTE;

		pll_i : EHXPLLL
        generic map (
			PLLRST_ENA       => "DISABLED",
			INTFB_WAKE       => "DISABLED",
			STDBY_ENABLE     => "DISABLED",
			DPHASE_SOURCE    => "DISABLED",
			PLL_LOCK_MODE    =>  0,
			FEEDBK_PATH      => "CLKOP",
			CLKOS_ENABLE     => "DISABLED", CLKOS_FPHASE   => 0, CLKOS_CPHASE  => 0,
			CLKOS2_ENABLE    => "DISABLED", CLKOS2_FPHASE  => 0, CLKOS2_CPHASE => 0,
			CLKOS3_ENABLE    => "DISABLED", CLKOS3_FPHASE  => 0, CLKOS3_CPHASE => 0,
			CLKOP_ENABLE     => "ENABLED",  CLKOP_FPHASE   => 0, CLKOP_CPHASE  => ddram_tab(ddram_mode).pll.clkop_div-1,
			CLKOS_TRIM_DELAY =>  0,         CLKOS_TRIM_POL => "FALLING",
			CLKOP_TRIM_DELAY =>  0,         CLKOP_TRIM_POL => "FALLING",
			OUTDIVIDER_MUXD  => "DIVD",
			OUTDIVIDER_MUXC  => "DIVC",
			OUTDIVIDER_MUXB  => "DIVB",
			OUTDIVIDER_MUXA  => "DIVA",

--			CLKOS_DIV        => ddram_tab(ddram_mode).pll.clkos_div,
--			CLKOS2_DIV       => ddram_tab(ddram_mode).pll.clkos2_div,
--			CLKOS3_DIV       => ddram_tab(ddram_mode).pll.clkos3_div,
			CLKOP_DIV        => ddram_tab(ddram_mode).pll.clkop_div,
			CLKFB_DIV        => ddram_tab(ddram_mode).pll.clkfb_div,
			CLKI_DIV         => ddram_tab(ddram_mode).pll.clki_div)
        port map (
			rst       => '0',
			clki      => clk_25mhz,
			CLKFB     => physys_clk,
            PHASESEL0 => '0', PHASESEL1 => '0',
			PHASEDIR  => '0',
            PHASESTEP => '0', PHASELOADREG => '0',
            STDBY     => '0', PLLWAKESYNC  => '0',
            ENCLKOP   => '0',
			ENCLKOS   => '0',
			ENCLKOS2  => '0',
            ENCLKOS3  => '0',
			CLKOP     => physys_clk,
			CLKOS     => open,
			CLKOS2    => open,
			CLKOS3    => open,
			LOCK      => dramclk_lck,
            INTLOCK   => open,
			REFCLK    => open,
			CLKINTFB  => open);

	end block;

	hdlc_g : if io_link=io_hdlc generate

		constant uart_xtal : real := 
			real(video_tab(video_mode).pll.clkfb_div*video_tab(video_mode).pll.clkop_div)*sys_freq/
			real(video_tab(video_mode).pll.clki_div*video_tab(video_mode).pll.clkos3_div);

		constant baudrate : natural := setif(
			uart_xtal >= 32.0e6, 3000000, setif(
			uart_xtal >= 25.0e6, 2000000,
                                 115200));

		signal uart_rxdv  : std_logic;
		signal uart_rxd   : std_logic_vector(0 to 8-1);
		signal uarttx_frm : std_logic;
		signal uart_idle  : std_logic;
		signal uart_txen  : std_logic;
		signal uart_txd   : std_logic_vector(uart_rxd'range);

		signal tp         : std_logic_vector(1 to 32);

		alias ftdi_txd    : std_logic is gpio23;
		alias ftdi_txen   : std_logic is gpio13;
		alias ftdi_rxd    : std_logic is gpio24;

		signal dummy_txd  : std_logic_vector(uart_rxd'range);
	begin

		process (uart_clk)
			variable q0 : std_logic := '0';
			variable q1 : std_logic := '0';
		begin
			if rising_edge(uart_clk) then
				-- led(1) <= q1;
				-- led(7) <= q0;
				if tp(1)='1' then
					if tp(2)='1' then
						q1 := not q1;
					end if;
				end if;
				if uart_rxdv='1' then
					q0 := not q0;
				end if;
			end if;
		end process;

		process (dummy_txd ,uart_clk)
			variable q : std_logic := '0';
			variable e : std_logic := '1';
		begin
			if rising_edge(uart_clk) then
				-- led(5) <= q;
				if (so_frm and not e)='1' then
					q := not q;
				end if;
				-- led(4) <= so_frm;
				e := so_frm;
			end if;
		end process;

		ftdi_txen <= '1';
		nodebug_g : if not debug generate
			uart_clk <= videoio_clk;
		end generate;

		debug_g : if debug generate
			uart_clk <= not to_stdulogic(to_bit(uart_clk)) after 0.1 ns /2;
		end generate;

		assert FALSE
			report "BAUDRATE : " & " " & integer'image(baudrate)
			severity NOTE;

		uartrx_e : entity hdl4fpga.uart_rx
		generic map (
			baudrate => baudrate,
			clk_rate => uart_xtal)
		port map (
			uart_rxc  => uart_clk,
			uart_sin  => ftdi_txd,
			uart_irdy => uart_rxdv,
			uart_data => uart_rxd);

		uarttx_e : entity hdl4fpga.uart_tx
		generic map (
			baudrate => baudrate,
			clk_rate => uart_xtal)
		port map (
			uart_txc  => uart_clk,
			uart_frm  => video_lck,
			uart_irdy => uart_txen,
			uart_trdy => uart_idle,
			uart_data => uart_txd,
			uart_sout => ftdi_rxd);

		siodaahdlc_e : entity hdl4fpga.sio_dayhdlc
		generic map (
			mem_size    => mem_size)
		port map (
			uart_clk    => uart_clk,
			uartrx_irdy => uart_rxdv,
			uartrx_data => uart_rxd,
			uarttx_frm  => uarttx_frm,
			uarttx_trdy => uart_idle,
			uarttx_data => uart_txd,
			uarttx_irdy => uart_txen,
			sio_clk     => sio_clk,
			so_frm      => so_frm,
			so_irdy     => so_irdy,
			so_trdy     => so_trdy,
			so_data     => so_data,

			si_frm      => si_frm,
			si_irdy     => si_irdy,
			si_trdy     => si_trdy,
			si_end      => si_end,
			si_data     => si_data,
			tp          => tp);

	end generate;

	ipoe_e : if io_link=io_ipoe generate
		-- RMII pins as labeled on the board and connected to ULX3S with pins down and flat cable
		alias rmii_crs    : std_logic is gpio17;

		alias rmii_tx_en  : std_logic is gpio6;
		alias rmii_tx0    : std_logic is gpio7;
		alias rmii_tx1    : std_logic is gpio8;

		alias rmii_rx_dv  : std_logic is rmii_crs;
		alias rmii_rx0    : std_logic is gpio9;
		alias rmii_rx1    : std_logic is gpio11;

		alias rmii_nint   : std_logic is gpio19;
		alias rmii_mdio   : std_logic is gpio22;
		alias rmii_mdc    : std_logic is gpio25;
		signal mii_clk    : std_logic;

		signal mii_txen   : std_logic;
		signal mii_txd    : std_logic_vector(0 to 2-1);

		signal mii_rxdv   : std_logic;
		signal mii_rxd    : std_logic_vector(0 to 2-1);

		signal dhcpcd_req : std_logic := '0';
		signal dhcpcd_rdy : std_logic := '0';

		signal miitx_frm  : std_logic;
		signal miitx_irdy : std_logic;
		signal miitx_trdy : std_logic;
		signal miitx_end  : std_logic;
		signal miitx_data : std_logic_vector(si_data'range);

	begin

		sio_clk <= rmii_nint;
		mii_clk <= rmii_nint;

		process (mii_clk)
		begin
			if rising_edge(mii_clk) then
				rmii_tx_en <= mii_txen;
				(0 => rmii_tx0, 1 => rmii_tx1) <= mii_txd;
			end if;
		end process;

		process (mii_clk)
		begin
			if rising_edge(mii_clk) then
				mii_rxdv <= rmii_rx_dv;
				mii_rxd  <= rmii_rx0 & rmii_rx1;
			end if;
		end process;

		rmii_mdc  <= '0';
		rmii_mdio <= '0';

		dhcp_p : process(mii_clk)
		begin
			if rising_edge(mii_clk) then
				if to_bit(dhcpcd_req xor dhcpcd_rdy)='0' then
					dhcpcd_req <= dhcpcd_rdy xor ((btn(1) and dhcpcd_rdy) or (btn(2) and not dhcpcd_rdy));
				end if;
			end if;
		end process;
		-- led(0) <= dhcpcd_rdy;
		-- led(7) <= not dhcpcd_rdy;

		udpdaisy_e : entity hdl4fpga.sio_dayudp
		generic map (
			my_mac        => x"00_40_00_01_02_03",
			default_ipv4a => aton("192.168.1.1"))
		port map (
			hdplx      => hdplx,
			sio_clk    => mii_clk,
			dhcpcd_req => dhcpcd_req,
			dhcpcd_rdy => dhcpcd_rdy,
			miirx_frm  => mii_rxdv,
			miirx_data => mii_rxd,

			miitx_frm  => miitx_frm,
			miitx_irdy => miitx_irdy,
			miitx_trdy => miitx_trdy,
			miitx_end  => miitx_end,
			miitx_data => miitx_data,

			si_frm     => si_frm,
			si_irdy    => si_irdy,
			si_trdy    => si_trdy,
			si_end     => si_end,
			si_data    => si_data,

			so_frm     => so_frm,
			so_irdy    => so_irdy,
			so_trdy    => so_trdy,
			so_data    => so_data);

		desser_e: entity hdl4fpga.desser
		port map (
			desser_clk => mii_clk,

			des_frm    => miitx_frm,
			des_irdy   => miitx_irdy,
			des_trdy   => miitx_trdy,
			des_data   => miitx_data,

			ser_irdy   => open,
			ser_data   => mii_txd);

		mii_txen <= miitx_frm and not miitx_end;

	end generate;

	grahics_e : entity hdl4fpga.demo_graphics
	generic map (
		debug        => debug,
		profile      => 2,

		ddr_tcp      => 2.0*ddr_tcp,
		fpga         => ecp5,
		mark         => m4g107,
		sclk_phases  => sclk_phases,
		sclk_edges   => sclk_edges,
		burst_length => 8,
		data_phases  => data_gear,
		data_edges   => data_edges,
		data_gear    => data_gear,
		cmmd_gear    => cmmd_gear,
		bank_size    => bank_size,
		addr_size    => addr_size,
		coln_size    => coln_size,
		word_size    => word_size,
		byte_size    => byte_size,

		timing_id    => video_tab(video_mode).mode,
		red_length   => setif(video_tab(video_mode).pixel=rgb565, 5, setif(video_tab(video_mode).pixel=rgb888, 8, 0)),
		green_length => setif(video_tab(video_mode).pixel=rgb565, 6, setif(video_tab(video_mode).pixel=rgb888, 8, 0)),
		blue_length  => setif(video_tab(video_mode).pixel=rgb565, 5, setif(video_tab(video_mode).pixel=rgb888, 8, 0)),
		fifo_size    => mem_size)
	port map (
		sio_clk      => sio_clk,
		sin_frm      => so_frm,
		sin_irdy     => so_irdy,
		sin_trdy     => so_trdy,
		sin_data     => so_data,
		sout_frm     => si_frm,
		sout_irdy    => si_irdy,
		sout_trdy    => si_trdy,
		sout_end     => si_end,
		sout_data    => si_data,

		video_clk    => video_clk,
		video_shift_clk => video_shft_clk,
		video_pixel  => video_pixel,
		dvid_crgb    => dvid_crgb,

		ctlr_clks(0) => ctlr_clk,
		ctlr_rst     => ddrsys_rst,
		ctlr_bl      => "000",
		ctlr_cl      => ddram_tab(ddram_mode).cl,
		ctlr_cwl     => ddram_tab(ddram_mode).cwl,
		ctlr_wrl     => "010",
		ctlr_rtt     => "001",
		ctlr_cmd     => ctlrphy_cmd,
		ctlr_inirdy  => tp(1),

		ctlrphy_wlreq => ctlrphy_wlreq,
		ctlrphy_wlrdy => ctlrphy_wlrdy,
		ctlrphy_rlreq => ctlrphy_rlreq,
		ctlrphy_rlrdy => ctlrphy_rlrdy,

		ctlrphy_irdy => ctlrphy_frm,
		ctlrphy_trdy => ctlrphy_trdy,
		ctlrphy_ini  => ctlrphy_ini,
		ctlrphy_rw   => ctlrphy_rw,

		ctlrphy_rst  => ctlrphy_rst(0),
		ctlrphy_cke  => ctlrphy_cke(0),
		ctlrphy_cs   => ctlrphy_cs(0),
		ctlrphy_ras  => ctlrphy_ras(0),
		ctlrphy_cas  => ctlrphy_cas(0),
		ctlrphy_we   => ctlrphy_we(0),
		ctlrphy_odt  => ctlrphy_odt(0),
		ctlrphy_b    => ddr_ba,
		ctlrphy_a    => ddr_a,
		ctlrphy_dsi  => ctlrphy_dsi,
		ctlrphy_dst  => ctlrphy_dst,
		ctlrphy_dso  => ctlrphy_dso,
		ctlrphy_dmi  => ctlrphy_dmi,
		ctlrphy_dmt  => ctlrphy_dmt,
		ctlrphy_dmo  => ctlrphy_dmo,
		ctlrphy_dqi  => ctlrphy_dqi,
		ctlrphy_dqt  => ctlrphy_dqt,
		ctlrphy_dqo  => ctlrphy_dqo,
		ctlrphy_sto  => ctlrphy_sto,
		ctlrphy_sti  => ctlrphy_sti);

	tp(2) <= not (ctlrphy_wlreq xor ctlrphy_wlrdy);
	tp(3) <= not (ctlrphy_rlreq xor ctlrphy_rlrdy);
	tp(4) <= ctlrphy_ini;

	process (clk_25mhz)
	begin
		if rising_edge(clk_25mhz) then
			led(0) <= tp(1);
			led(7 downto 2) <= tp_phy(1 to 6);
		end if;
	end process;

	process (ddr_ba)
	begin
		for i in ddr_ba'range loop
			for j in 0 to cmmd_gear-1 loop
				ctlrphy_ba(i*cmmd_gear+j) <= ddr_ba(i);
			end loop;
		end loop;
	end process;

	process (ddr_a)
	begin
		for i in ddr_a'range loop
			for j in 0 to cmmd_gear-1 loop
				ctlrphy_a(i*cmmd_gear+j) <= ddr_a(i);
			end loop;
		end loop;
	end process;

	ctlrphy_rst(1) <= ctlrphy_rst(0);
	ctlrphy_cke(1) <= ctlrphy_cke(0);
	ctlrphy_cs(1)  <= ctlrphy_cs(0);
	ctlrphy_ras(1) <= '1';
	ctlrphy_cas(1) <= '1';
	ctlrphy_we(1)  <= '1';
	ctlrphy_odt(1) <= ctlrphy_odt(0);

	ddrphy_rst <= not dramclk_lck;
	process (dramclk_lck, ctlr_clk)
	begin
		if dramclk_lck='0' then
			ddrsys_rst <= '1';
		elsif rising_edge(ctlr_clk) then
			ddrsys_rst <= not dramclk_lck;
		end if;
	end process;
	
	tp_b : block
		signal tp_dv : std_logic;
	begin
		process (ctlr_clk)
			variable q : std_logic;
			variable q1 : std_logic := '0';
		begin
			if rising_edge(ctlr_clk) then
				if ctlrphy_sti(0)='1' then
					if q='0' then
						q1 := not q1;
					end if;
				end if;
				q := ctlrphy_sti(0);
			tp_dv <= q1;
			end if;
		end process;
		
		process (clk_25mhz)
		begin
			if rising_edge(clk_25mhz) then
				led(1) <= tp_dv;
			end if;
		end process;
		
	end block;

	ddrphy_e : entity hdl4fpga.ecp5_ddrphy
	generic map (
		ddr_tcp       => ddr_tcp,
		cmmd_gear     => cmmd_gear,
		data_gear     => data_gear,
		bank_size     => ddram_ba'length,
		addr_size     => ddram_a'length,
		word_size     => word_size,
		byte_size     => byte_size)
	port map (
		rst           => ddrphy_rst,
		sync_clk      => clk_25mhz,
		clkop         => physys_clk,
		sclk          => ctlr_clk,
		phy_frm       => ctlrphy_frm,
		phy_trdy      => ctlrphy_trdy,
		phy_cmd       => ctlrphy_cmd,
		phy_rw        => ctlrphy_rw,
		phy_ini       => ctlrphy_ini,

		phy_wlreq     => ctlrphy_wlreq,
		phy_wlrdy     => ctlrphy_wlrdy,

		phy_rlreq     => ctlrphy_rlreq,
		phy_rlrdy     => ctlrphy_rlrdy,

		phy_rst       => ctlrphy_rst,
		phy_cs        => ctlrphy_cs,
		phy_cke       => ctlrphy_cke,
		phy_ras       => ctlrphy_ras,
		phy_cas       => ctlrphy_cas,
		phy_we        => ctlrphy_we,
		phy_odt       => ctlrphy_odt,
		phy_b         => ctlrphy_ba,
		phy_a         => ctlrphy_a,
		phy_dqsi      => ctlrphy_dso,
		phy_dqst      => ctlrphy_dst,
		phy_dqso      => ctlrphy_dsi,
		phy_dmi       => ctlrphy_dmo,
		phy_dmt       => ctlrphy_dmt,
		phy_dmo       => ctlrphy_dmi,
		phy_dqi       => ctlrphy_dqo,
		phy_dqt       => ctlrphy_dqt,
		phy_dqo       => ctlrphy_dqi,
		phy_sti       => ctlrphy_sto,
		phy_sto       => ctlrphy_sti,

		ddr_rst       => ddram_reset_n,
		ddr_ck        => ddram_clk,
		ddr_cke       => ddram_cke,
		ddr_cs        => ddram_cs_n,
		ddr_ras       => ddram_ras_n,
		ddr_cas       => ddram_cas_n,
		ddr_we        => ddram_we_n,
		ddr_odt       => ddram_odt,
		ddr_b         => ddram_ba,
		ddr_a         => ddram_a,

		ddr_dm        => open,
		ddr_dq        => ddram_dq,
		ddr_dqs       => ddram_dqs,
		tp => tp_phy);
	ddram_dm <= (others => '0');

	-- VGA --
	---------

	debug_q : if debug generate
		signal q : bit;
	begin
		q <= not q after 1 ns;
		rgmii_tx_clk <= to_stdulogic(q);
	end generate;

	nodebug_g : if not debug generate
		rgmii_ref_clk_i : oddrx1f
		port map(
			sclk => rgmii_rx_clk,
			rst  => '0',
			d0   => '1',
			d1   => '0',
			q    => rgmii_tx_clk);
	end generate;

	fpdi_clk_i : oddrx1f
	port map(
		sclk => video_shft_clk,
		rst  => '0',
		d0   => dvid_crgb(2*0),
		d1   => dvid_crgb(2*0+1),
		q    => fpdi_clk);
 
	fpdi_d0_i : oddrx1f
	port map(
		sclk => video_shft_clk,
		rst  => '0',
		d0   => dvid_crgb(2*1),
		d1   => dvid_crgb(2*1+1),
		q    => fpdi_d0);
 
	fpdi_d1_i : oddrx1f
	port map(
		sclk => video_shft_clk,
		rst  => '0',
		d0   => dvid_crgb(2*2),
		d1   => dvid_crgb(2*2+1),
		q    => fpdi_d1);
 
	fpdi_d2_i : oddrx1f
	port map(
		sclk => video_shft_clk,
		rst  => '0',
		d0   => dvid_crgb(2*3),
		d1   => dvid_crgb(2*3+1),
		q    => fpdi_d2);
 
end;