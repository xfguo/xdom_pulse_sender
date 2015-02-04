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
 *
 *
 * Send a pulse from one domain to another timing domain.
 *
 * NOTE: the pulse must be one cycle and cannot be set again when busy_o is
 *       high.
 */

module xdom_pulse_sender (
input		grst_i,

input		odom_clk_i,
input		odom_pulse_i,

input		xdom_clk_i,
output		xdom_pulse_o,

output		busy_o,
output		err_o
);

/* signals in origin domain */
reg		odom_pulse_delay_r;
reg		odom_pulse_keeper_r;
reg	[1:0]	odom_feedback_double_flips_r	;
reg		err_r;

/* cross-domain signals */
wire		xdom_pulse_en;
wire		odom_pulse_safe_cancel;

/* signals in cross domain */
reg	[1:0]	xdom_double_flips_r		;
reg		xdom_pulse_en_delay_r		;
reg		xdom_pulse_gen_r		;

/* latch input pulse for one cycle
 * this can avoid setup issue when o-clk is slower then x-clk.
 */
always @(posedge odom_clk_i or posedge grst_i)
	if (grst_i)
		odom_pulse_delay_r <= 1'b0;
	else
		odom_pulse_delay_r <= odom_pulse_i;

/* keep input pulse signal until feedback signal cancel it */
always @(posedge odom_clk_i or posedge grst_i)
	if (grst_i)
		odom_pulse_keeper_r <= 1'b0;
	else if (odom_pulse_keeper_r == 1'b0 && odom_pulse_delay_r == 1'b1)
		odom_pulse_keeper_r <= 1'b1;
	else if (odom_pulse_keeper_r == 1'b1 && odom_pulse_safe_cancel == 1'b1)
		odom_pulse_keeper_r <= 1'b0;
	else
		odom_pulse_keeper_r <= odom_pulse_keeper_r;

/* busy signal */
assign busy_o = odom_pulse_keeper_r | odom_pulse_i;

/* a new request must wait until last is finished */
always @(posedge odom_clk_i or posedge grst_i)
	if (grst_i)
		err_r = 1'b0;
	else 
		err_r = (odom_pulse_keeper_r == 1'b1) && (odom_pulse_i == 1'b1);

assign err_o = err_r;

/* double flips in cross-domain */
always @(posedge xdom_clk_i or posedge grst_i)
	if (grst_i)
		xdom_double_flips_r <= 2'b0;
	else
		xdom_double_flips_r <= {odom_pulse_keeper_r, xdom_double_flips_r[1]};

assign xdom_pulse_en = xdom_double_flips_r[0];

/* double flips in origin-domain */
always @(posedge odom_clk_i or posedge grst_i)
	if (grst_i)
		odom_feedback_double_flips_r <= 2'b0;
	else
		odom_feedback_double_flips_r <= {xdom_pulse_en, odom_feedback_double_flips_r[1]};

assign odom_pulse_safe_cancel = odom_feedback_double_flips_r[0];

/* latch cross domain pulse enable signal for one cycle. */
always @(posedge xdom_clk_i or posedge grst_i)
	if (grst_i)
		xdom_pulse_en_delay_r <= 1'b0;
	else
		xdom_pulse_en_delay_r <= xdom_pulse_en;

/* generate pulse in cross-domain */
always @(posedge xdom_clk_i or posedge grst_i)
	if (grst_i)
		xdom_pulse_gen_r <= 1'b0;
	else if (xdom_pulse_en == 1'b1 && xdom_pulse_en_delay_r == 1'b0)
		xdom_pulse_gen_r <= 1'b1;
	else
		xdom_pulse_gen_r <= 1'b0;

assign xdom_pulse_o = xdom_pulse_gen_r;

endmodule
