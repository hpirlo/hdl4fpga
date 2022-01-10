#                                                                            #
# Author(s):                                                                 #
#   Miguel Angel Sagreras                                                    #
#                                                                            #
# Copyright (C) 2015                                                         #
#    Miguel Angel Sagreras                                                   #
#                                                                            #
# This source file may be used and distributed without restriction provided  #
# that this copyright statement is not removed from the file and that any    #
# derivative work contains  the original copyright notice and the associated #
# disclaimer.                                                                #
#                                                                            #
# This source file is free software; you can redistribute it and/or modify   #
# it under the terms of the GNU General Public License as published by the   #
# Free Software Foundation, either version 3 of the License, or (at your     #
# option) any later version.                                                 #
#                                                                            #
# This source is distributed in the hope that it will be useful, but WITHOUT #
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or      #
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for   #
# more details at http://www.gnu.org/licenses/.                              #
#                                                                            #

set_clock_groups -asynchronous -group { sys_clk     } -group { ddr_clk0div_mmce2   }
set_clock_groups -asynchronous -group { sys_clk     } -group { ddr_clk90div_mmce2   }
set_clock_groups -asynchronous -group { sys_clk     } -group { ioctrl_clk  }
set_clock_groups -asynchronous -group { dqso0       } -group { sys_clk     }
set_clock_groups -asynchronous -group { dqso1       } -group { sys_clk     }
set_clock_groups -asynchronous -group { dqso0       } -group { ddr_clk90_mmce2   }
set_clock_groups -asynchronous -group { dqso1       } -group { ddr_clk90_mmce2   }
set_clock_groups -asynchronous -group { eth_rx_clk  } -group { sys_clk     }
set_clock_groups -asynchronous -group { eth_rx_clk  } -group { ddr_clk0div_mmce2   }
set_clock_groups -asynchronous -group { eth_tx_clk  } -group { eth_rx_clk  }
set_clock_groups -asynchronous -group { ddr_clk0div_mmce2 } -group { sys_clk     }
set_clock_groups -asynchronous -group { ddr_clk0div_mmce2 } -group { eth_tx_clk  }
set_clock_groups -asynchronous -group { ddr_clk0div_mmce2 } -group { eth_rx_clk  }

create_clock -name dqso0   -period  1.667 -waveform { 0.0 0.833 } [ get_ports ddr3_dqs_p[0] ]
create_clock -name dqso1   -period  1.667 -waveform { 0.0 0.833 } [ get_ports ddr3_dqs_p[1] ]

set_false_path -from [ get_pins grahics_e/ddrctlr_b.ddrctlr_e/rdfifo_i/bytes_g[*].DATA_PHASES_g[*].inbyte_i/phases_g[*].ram_b/ram_g[*].ram_i/DP/CLK ] -to [ get_pins grahics_e/dmactlr_b.dmado_e/delay[*].q_reg[*]/D ]
