/*
 * Copyright (C) 2015  Xiongfei Guo <xfguo@credosemi.com>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License, version 3
 * as published by the Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

`timescale 1ns/1ps

module tb_xdom_pulse_sender;

reg		grst_i		;
reg		odom_clk_i	;
reg		odom_pulse_i	;
reg		xdom_clk_i	;
wire		xdom_pulse_o	;
wire		busy_o		;

xdom_pulse_sender uut (
	.grst_i		(	grst_i		),
	.odom_clk_i	(	odom_clk_i	),
	.odom_pulse_i	(	odom_pulse_i	),
	.xdom_clk_i	(	xdom_clk_i	),
	.xdom_pulse_o	(	xdom_pulse_o	),
	.busy_o		(	busy_o		)
);

parameter ODOM_PERIOD = 10;
parameter XDOM_PERIOD = 100;

initial begin
	$dumpfile("db_tb_xdom_pulse_sender.vcd");
	$dumpvars(0, tb_xdom_pulse_sender);
end

initial begin
	odom_clk_i = 1'b0;
	#(ODOM_PERIOD/2);
	forever
		#(ODOM_PERIOD/2) odom_clk_i = ~odom_clk_i;
end

initial begin
	xdom_clk_i = 1'b0;
	#(XDOM_PERIOD/2);
	forever
		#(XDOM_PERIOD/2) xdom_clk_i = ~xdom_clk_i;
end

initial begin
	#10;
	odom_pulse_i = 1'b0;
	grst_i = 1'b1;
	#5;
	grst_i = 1'b0;

	/* generate a pulse */
	@(posedge odom_clk_i);
	odom_pulse_i = 1'b1;
	@(posedge odom_clk_i);
	odom_pulse_i = 1'b0;

	repeat (1000) @(posedge odom_clk_i);
	$finish(0);
end

endmodule
