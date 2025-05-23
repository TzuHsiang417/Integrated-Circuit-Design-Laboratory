###################################################################

# Created by write_sdc on Thu Dec 29 20:18:26 2022

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -power mW -voltage V -current mA
set_load -pin_load 0.05 [get_ports out_valid]
set_load -pin_load 0.05 [get_ports {out_data[31]}]
set_load -pin_load 0.05 [get_ports {out_data[30]}]
set_load -pin_load 0.05 [get_ports {out_data[29]}]
set_load -pin_load 0.05 [get_ports {out_data[28]}]
set_load -pin_load 0.05 [get_ports {out_data[27]}]
set_load -pin_load 0.05 [get_ports {out_data[26]}]
set_load -pin_load 0.05 [get_ports {out_data[25]}]
set_load -pin_load 0.05 [get_ports {out_data[24]}]
set_load -pin_load 0.05 [get_ports {out_data[23]}]
set_load -pin_load 0.05 [get_ports {out_data[22]}]
set_load -pin_load 0.05 [get_ports {out_data[21]}]
set_load -pin_load 0.05 [get_ports {out_data[20]}]
set_load -pin_load 0.05 [get_ports {out_data[19]}]
set_load -pin_load 0.05 [get_ports {out_data[18]}]
set_load -pin_load 0.05 [get_ports {out_data[17]}]
set_load -pin_load 0.05 [get_ports {out_data[16]}]
set_load -pin_load 0.05 [get_ports {out_data[15]}]
set_load -pin_load 0.05 [get_ports {out_data[14]}]
set_load -pin_load 0.05 [get_ports {out_data[13]}]
set_load -pin_load 0.05 [get_ports {out_data[12]}]
set_load -pin_load 0.05 [get_ports {out_data[11]}]
set_load -pin_load 0.05 [get_ports {out_data[10]}]
set_load -pin_load 0.05 [get_ports {out_data[9]}]
set_load -pin_load 0.05 [get_ports {out_data[8]}]
set_load -pin_load 0.05 [get_ports {out_data[7]}]
set_load -pin_load 0.05 [get_ports {out_data[6]}]
set_load -pin_load 0.05 [get_ports {out_data[5]}]
set_load -pin_load 0.05 [get_ports {out_data[4]}]
set_load -pin_load 0.05 [get_ports {out_data[3]}]
set_load -pin_load 0.05 [get_ports {out_data[2]}]
set_load -pin_load 0.05 [get_ports {out_data[1]}]
set_load -pin_load 0.05 [get_ports {out_data[0]}]
create_clock [get_ports clk]  -period 20  -waveform {0 10}
create_clock [get_ports clk2]  -period 15  -waveform {0 7.5}
set_input_delay -clock clk  0  [get_ports clk]
set_input_delay -clock clk2  0  [get_ports clk2]
set_input_delay -clock clk  0  [get_ports rst_n]
set_input_delay -clock clk  10  [get_ports in_valid]
set_input_delay -clock clk  10  [get_ports op_valid]
set_input_delay -clock clk  10  [get_ports {pic_data[31]}]
set_input_delay -clock clk  10  [get_ports {pic_data[30]}]
set_input_delay -clock clk  10  [get_ports {pic_data[29]}]
set_input_delay -clock clk  10  [get_ports {pic_data[28]}]
set_input_delay -clock clk  10  [get_ports {pic_data[27]}]
set_input_delay -clock clk  10  [get_ports {pic_data[26]}]
set_input_delay -clock clk  10  [get_ports {pic_data[25]}]
set_input_delay -clock clk  10  [get_ports {pic_data[24]}]
set_input_delay -clock clk  10  [get_ports {pic_data[23]}]
set_input_delay -clock clk  10  [get_ports {pic_data[22]}]
set_input_delay -clock clk  10  [get_ports {pic_data[21]}]
set_input_delay -clock clk  10  [get_ports {pic_data[20]}]
set_input_delay -clock clk  10  [get_ports {pic_data[19]}]
set_input_delay -clock clk  10  [get_ports {pic_data[18]}]
set_input_delay -clock clk  10  [get_ports {pic_data[17]}]
set_input_delay -clock clk  10  [get_ports {pic_data[16]}]
set_input_delay -clock clk  10  [get_ports {pic_data[15]}]
set_input_delay -clock clk  10  [get_ports {pic_data[14]}]
set_input_delay -clock clk  10  [get_ports {pic_data[13]}]
set_input_delay -clock clk  10  [get_ports {pic_data[12]}]
set_input_delay -clock clk  10  [get_ports {pic_data[11]}]
set_input_delay -clock clk  10  [get_ports {pic_data[10]}]
set_input_delay -clock clk  10  [get_ports {pic_data[9]}]
set_input_delay -clock clk  10  [get_ports {pic_data[8]}]
set_input_delay -clock clk  10  [get_ports {pic_data[7]}]
set_input_delay -clock clk  10  [get_ports {pic_data[6]}]
set_input_delay -clock clk  10  [get_ports {pic_data[5]}]
set_input_delay -clock clk  10  [get_ports {pic_data[4]}]
set_input_delay -clock clk  10  [get_ports {pic_data[3]}]
set_input_delay -clock clk  10  [get_ports {pic_data[2]}]
set_input_delay -clock clk  10  [get_ports {pic_data[1]}]
set_input_delay -clock clk  10  [get_ports {pic_data[0]}]
set_input_delay -clock clk  10  [get_ports {se_data[7]}]
set_input_delay -clock clk  10  [get_ports {se_data[6]}]
set_input_delay -clock clk  10  [get_ports {se_data[5]}]
set_input_delay -clock clk  10  [get_ports {se_data[4]}]
set_input_delay -clock clk  10  [get_ports {se_data[3]}]
set_input_delay -clock clk  10  [get_ports {se_data[2]}]
set_input_delay -clock clk  10  [get_ports {se_data[1]}]
set_input_delay -clock clk  10  [get_ports {se_data[0]}]
set_input_delay -clock clk  10  [get_ports {op[2]}]
set_input_delay -clock clk  10  [get_ports {op[1]}]
set_input_delay -clock clk  10  [get_ports {op[0]}]
set_output_delay -clock clk  10  [get_ports out_valid]
set_output_delay -clock clk  10  [get_ports {out_data[31]}]
set_output_delay -clock clk  10  [get_ports {out_data[30]}]
set_output_delay -clock clk  10  [get_ports {out_data[29]}]
set_output_delay -clock clk  10  [get_ports {out_data[28]}]
set_output_delay -clock clk  10  [get_ports {out_data[27]}]
set_output_delay -clock clk  10  [get_ports {out_data[26]}]
set_output_delay -clock clk  10  [get_ports {out_data[25]}]
set_output_delay -clock clk  10  [get_ports {out_data[24]}]
set_output_delay -clock clk  10  [get_ports {out_data[23]}]
set_output_delay -clock clk  10  [get_ports {out_data[22]}]
set_output_delay -clock clk  10  [get_ports {out_data[21]}]
set_output_delay -clock clk  10  [get_ports {out_data[20]}]
set_output_delay -clock clk  10  [get_ports {out_data[19]}]
set_output_delay -clock clk  10  [get_ports {out_data[18]}]
set_output_delay -clock clk  10  [get_ports {out_data[17]}]
set_output_delay -clock clk  10  [get_ports {out_data[16]}]
set_output_delay -clock clk  10  [get_ports {out_data[15]}]
set_output_delay -clock clk  10  [get_ports {out_data[14]}]
set_output_delay -clock clk  10  [get_ports {out_data[13]}]
set_output_delay -clock clk  10  [get_ports {out_data[12]}]
set_output_delay -clock clk  10  [get_ports {out_data[11]}]
set_output_delay -clock clk  10  [get_ports {out_data[10]}]
set_output_delay -clock clk  10  [get_ports {out_data[9]}]
set_output_delay -clock clk  10  [get_ports {out_data[8]}]
set_output_delay -clock clk  10  [get_ports {out_data[7]}]
set_output_delay -clock clk  10  [get_ports {out_data[6]}]
set_output_delay -clock clk  10  [get_ports {out_data[5]}]
set_output_delay -clock clk  10  [get_ports {out_data[4]}]
set_output_delay -clock clk  10  [get_ports {out_data[3]}]
set_output_delay -clock clk  10  [get_ports {out_data[2]}]
set_output_delay -clock clk  10  [get_ports {out_data[1]}]
set_output_delay -clock clk  10  [get_ports {out_data[0]}]
