onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {New Divider}
add wave -noupdate /testbench/mii_req
add wave -noupdate /testbench/du_e/mii_rxc
add wave -noupdate /testbench/du_e/mii_rxdv
add wave -noupdate -radix hexadecimal /testbench/du_e/mii_rxd
add wave -noupdate -divider {New Divider}
add wave -noupdate /testbench/du_e/mii_txc
add wave -noupdate /testbench/du_e/mii_txen
add wave -noupdate -radix hexadecimal /testbench/du_e/mii_txd
add wave -noupdate -divider {New Divider}
add wave -noupdate /testbench/du_e/ddr_ckp
add wave -noupdate /testbench/du_e/ddr_ras
add wave -noupdate /testbench/du_e/ddr_cas
add wave -noupdate /testbench/du_e/ddr_we
add wave -noupdate /testbench/du_e/ddr_ba
add wave -noupdate -radix hexadecimal /testbench/du_e/ddr_a
add wave -noupdate -expand /testbench/du_e/ddr_dqs
add wave -noupdate -radix hexadecimal -childformat {{/testbench/du_e/ddr_dq(15) -radix hexadecimal} {/testbench/du_e/ddr_dq(14) -radix hexadecimal} {/testbench/du_e/ddr_dq(13) -radix hexadecimal} {/testbench/du_e/ddr_dq(12) -radix hexadecimal} {/testbench/du_e/ddr_dq(11) -radix hexadecimal} {/testbench/du_e/ddr_dq(10) -radix hexadecimal} {/testbench/du_e/ddr_dq(9) -radix hexadecimal} {/testbench/du_e/ddr_dq(8) -radix hexadecimal} {/testbench/du_e/ddr_dq(7) -radix hexadecimal} {/testbench/du_e/ddr_dq(6) -radix hexadecimal} {/testbench/du_e/ddr_dq(5) -radix hexadecimal} {/testbench/du_e/ddr_dq(4) -radix hexadecimal} {/testbench/du_e/ddr_dq(3) -radix hexadecimal} {/testbench/du_e/ddr_dq(2) -radix hexadecimal} {/testbench/du_e/ddr_dq(1) -radix hexadecimal} {/testbench/du_e/ddr_dq(0) -radix hexadecimal}} -subitemconfig {/testbench/du_e/ddr_dq(15) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(14) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(13) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(12) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(11) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(10) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(9) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(8) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(7) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(6) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(5) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(4) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(3) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(2) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(1) {-height 29 -radix hexadecimal} /testbench/du_e/ddr_dq(0) {-height 29 -radix hexadecimal}} /testbench/du_e/ddr_dq
add wave -noupdate /testbench/du_e/grahics_e/ctlrphy_sto(3)
add wave -noupdate /testbench/du_e/grahics_e/ctlrphy_sti(3)
add wave -noupdate -divider {New Divider}
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_frm
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_irdy
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_trdy
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_end
add wave -noupdate -radix hexadecimal -childformat {{/testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(0) -radix hexadecimal} {/testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(1) -radix hexadecimal} {/testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(2) -radix hexadecimal} {/testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(3) -radix hexadecimal} {/testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(4) -radix hexadecimal} {/testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(5) -radix hexadecimal} {/testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(6) -radix hexadecimal} {/testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(7) -radix hexadecimal}} -subitemconfig {/testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(0) {-height 29 -radix hexadecimal} /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(1) {-height 29 -radix hexadecimal} /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(2) {-height 29 -radix hexadecimal} /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(3) {-height 29 -radix hexadecimal} /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(4) {-height 29 -radix hexadecimal} /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(5) {-height 29 -radix hexadecimal} /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(6) {-height 29 -radix hexadecimal} /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data(7) {-height 29 -radix hexadecimal}} /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/mii_ipoe_e/pltx_data
add wave -noupdate -divider {New Divider}
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/sio_flow_e/rx_frm
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/sio_flow_e/rx_irdy
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/sio_flow_e/rx_trdy
add wave -noupdate -radix hexadecimal /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/sio_flow_e/rx_data
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/sio_flow_e/tx_frm
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/sio_flow_e/tx_irdy
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/sio_flow_e/tx_trdy
add wave -noupdate /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/sio_flow_e/tx_end
add wave -noupdate -radix hexadecimal /testbench/du_e/ipoe_b/udpdaisy_e/sio_udp_e/sio_flow_e/tx_data
add wave -noupdate -divider {New Divider}
add wave -noupdate /testbench/du_e/grahics_e/sio_b/dmaioaddr_irdy
add wave -noupdate /testbench/du_e/grahics_e/sio_b/dmaio_next
add wave -noupdate -radix hexadecimal /testbench/du_e/grahics_e/dmaio_len
add wave -noupdate -radix hexadecimal /testbench/du_e/grahics_e/dmaio_addr
add wave -noupdate /testbench/du_e/grahics_e/dmaio_we
add wave -noupdate -divider {New Divider}
add wave -noupdate /testbench/du_e/grahics_e/sio_b/status_rw
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/siodmaio_irdy
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/siodmaio_trdy
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/siodmaio_end
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/siodmaio_data
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/sodata_irdy
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/sodata_trdy
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/sodata_end
add wave -noupdate -radix hexadecimal /testbench/du_e/grahics_e/sio_b/tx_b/sodata_data
add wave -noupdate -divider {New Divider}
add wave -noupdate /testbench/du_e/grahics_e/sio_b/sout_req
add wave -noupdate /testbench/du_e/grahics_e/sio_b/sout_rdy
add wave -noupdate /testbench/du_e/grahics_e/sout_frm
add wave -noupdate /testbench/du_e/grahics_e/sout_irdy
add wave -noupdate /testbench/du_e/grahics_e/sout_trdy
add wave -noupdate /testbench/du_e/grahics_e/sout_end
add wave -noupdate -radix hexadecimal /testbench/du_e/grahics_e/sout_data
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned -childformat {{/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(10) -radix hexadecimal} {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(9) -radix hexadecimal} {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(8) -radix hexadecimal} {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(7) -radix hexadecimal} {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(6) -radix hexadecimal} {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(5) -radix hexadecimal} {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(4) -radix hexadecimal} {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(3) -radix hexadecimal} {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(2) -radix hexadecimal} {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(1) -radix hexadecimal} {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(0) -radix hexadecimal}} -subitemconfig {/testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(10) {-height 29 -radix hexadecimal} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(9) {-height 29 -radix hexadecimal} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(8) {-height 29 -radix hexadecimal} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(7) {-height 29 -radix hexadecimal} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(6) {-height 29 -radix hexadecimal} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(5) {-height 29 -radix hexadecimal} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(4) {-height 29 -radix hexadecimal} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(3) {-height 29 -radix hexadecimal} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(2) {-height 29 -radix hexadecimal} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(1) {-height 29 -radix hexadecimal} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length(0) {-height 29 -radix hexadecimal}} /testbench/du_e/grahics_e/sio_b/tx_b/line__473/data_length
add wave -noupdate -radix hexadecimal /testbench/du_e/grahics_e/sio_b/tx_b/line__473/hdr_length
add wave -noupdate -radix unsigned /testbench/du_e/grahics_e/sio_b/tx_b/line__473/pay_length
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/line__473/pfix_size
add wave -noupdate -radix unsigned /testbench/du_e/grahics_e/sio_b/tx_b/trans_length
add wave -noupdate -radix hexadecimal /testbench/du_e/grahics_e/sio_b/tx_b/sodata_b/fifo_length
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/sodata_b/trans_req
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/sodata_b/trans_rdy
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/sodata_b/len_rdy
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/sodata_b/len_req
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/sodata_b/fifo_req
add wave -noupdate /testbench/du_e/grahics_e/sio_b/tx_b/sodata_b/fifo_rdy
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {211345828 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 221
configure wave -valuecolwidth 135
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {211320245 ps} {211365019 ps}
