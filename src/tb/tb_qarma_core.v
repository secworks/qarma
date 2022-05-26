//======================================================================
//
// tb_qarma_core.v
// --------------
// Testbench for the qarma block cipher core.
//
// Author: Joachim Strombergson
// Copyright (c) 2022, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

`default_nettype none

module tb_qarma_core();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 0;
  parameter DUMP_WAIT = 0;

  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [63 : 0]   cycle_ctr;
  reg [31 : 0]   error_ctr;
  reg [31 : 0]   tc_ctr;
  reg            display_cycle_ctr;
  reg            display_dut_state;

  reg            tb_clk;
  reg            tb_reset_n;
  reg            tb_encdec;
  reg            tb_next;
  wire           tb_ready;
  reg [255 : 0]  tb_key;
  reg [127 : 0]  tb_tweak;
  reg [127 : 0]  tb_block;
  wire [127 : 0] tb_result;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  qarma_core dut(
                .clk(tb_clk),
                .reset_n(tb_reset_n),

                .encdec(tb_encdec),
                .next(tb_next),
                .ready(tb_ready),

                .key(tb_key),
                .tweak(tb_tweak),

                .block(tb_block),
                .result(tb_result)
               );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD tb_clk = !tb_clk;
    end // clk_gen


  //--------------------------------------------------------------------
  // dut_monitor
  //
  // Monitor displaying information every cycle.
  // Includes the cycle counter.
  //--------------------------------------------------------------------
  always @ (posedge tb_clk)
    begin : dut_monitor
      cycle_ctr = cycle_ctr + 1;

      if (display_dut_state) begin
        dump_dut_state();
      end
    end // dut_monitor


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("-------------------------------------------------------------------------------------");
      $display("-------------------------------------------------------------------------------------");
      $display("DUT state at cycle: %08d", cycle_ctr);
      $display("--------------------------------");
      $display("Inputs and outputs:");
      $display("ready: 0x%1x, encdec: 0x%1x, next: 0x%1x", dut.ready, dut.encdec, dut.next);
      $display("");
      $display("key:    0x%064x", dut.key);
      $display("tweak:  0x%032x", dut.tweak);
      $display("block:  0x%032x", dut.block);
      $display("result: 0x%032x", dut.result);
      $display("");
      $display("Internal state:");
      $display("core_ctrl_reg: 0x%02x, core_ctrl_new: 0x%02x, core_ctrl_we: 0x%1x",
	       dut.core_ctrl_reg, dut.core_ctrl_new, dut.core_ctrl_we);
      $display("");
      $display("-------------------------------------------------------------------------------------");
      $display("-------------------------------------------------------------------------------------");
      $display("");
      $display("");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // inc_tc_ctr
  //----------------------------------------------------------------
  task inc_tc_ctr;
    tc_ctr = tc_ctr + 1;
  endtask // inc_tc_ctr


  //----------------------------------------------------------------
  // inc_error_ctr
  //----------------------------------------------------------------
  task inc_error_ctr;
    error_ctr = error_ctr + 1;
  endtask // inc_error_ctr


  //----------------------------------------------------------------
  // pause_finish()
  //
  // Pause for a given number of cycles and then finish sim.
  //----------------------------------------------------------------
  task pause_finish(input [31 : 0] num_cycles);
    begin
      $display("--- TB: Pausing for %04d cycles and then finishing hard.", num_cycles);
      #(num_cycles * CLK_PERIOD);
      $finish;
    end
  endtask // pause_finish


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for the ready flag to be set in dut.
  //----------------------------------------------------------------
  task wait_ready;
    begin : wready
      while (!tb_ready) begin
        #(CLK_PERIOD);
      end
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // display_test_result()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_result;
    begin
      $display("--- TB: %02d test cases executed.", tc_ctr);
      if (error_ctr == 0)
        begin
          $display("--- TB: All %02d test cases completed successfully.", tc_ctr);
        end
      else
        begin
          $display("--- TB: %02d test cases did not complete successfully.", error_ctr);
        end
    end
  endtask // display_test_result


  //----------------------------------------------------------------
  // init_sim()
  //
  // Set the input to the DUT to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr         = 0;
      error_ctr         = 0;
      tc_ctr            = 0;

      display_cycle_ctr = 1;
      display_dut_state = 0;

      tb_clk            = 0;
      tb_reset_n        = 1;
      tb_encdec         = 1'h0;
      tb_next           = 1'h0;
      tb_key            = 256'h0;
      tb_tweak          = 128'h0;
      tb_block          = 128'h0;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("--- TB: Resetting dut.");
      tb_reset_n = 1'h0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1'h1;
      #(2 * CLK_PERIOD);
      $display("--- TB: Reset done.");
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // qarma_core_test
  //
  // Test vectors from:
  //----------------------------------------------------------------
  initial
    begin : qarma_core_test
      $display("");
      $display("-----------------------------------");
      $display("--- Testbench for QARMA started ---");
      $display("-----------------------------------");
      $display("");

      init_sim();

      display_dut_state = 1;

      #(2 * CLK_PERIOD);

      reset_dut();

      #(2 * CLK_PERIOD);

      display_dut_state = 0;

      #(2 * CLK_PERIOD);

      display_test_result();

      $display("");
      $display("-------------------------------------");
      $display("--- Testbench for QARMA completed ---");
      $display("-------------------------------------");
      $display("");
      $finish_and_return(error_ctr);
    end // qarma_core_test
endmodule // tb_qarma_core

//======================================================================
// EOF tb_qarma_core.v
//======================================================================
