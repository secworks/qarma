//======================================================================
//
// qarma_core.v
// -------------
// QARMA block cipher core.
//
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

module qarma_core(
                   input wire            clk,
                   input wire            reset_n,

                   input wire            encdec,
                   input wire            next,
                   output wire           ready,

                   input wire [255 : 0]  key,
                   input wire [127 : 0]  tweak,

                   input wire [127 : 0]  block,
                   output wire [127 : 0] result
                  );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam CTRL_IDLE = 3'h0;
  localparam CTRL_DONE = 3'h1;

  localparam alpha = 128'h243f6a8885a308d3_13198a2e03707344;

  localparam c0    = 128'h0000000000000000_0000000000000000;
  localparam c1    = 128'ha4093822299f31d0_082efa98ec4e6c89;
  localparam c2    = 128'h452821e638d01377_be5466cf34e90c6c;
  localparam c3    = 128'hc0ac29b7c97c50dd_3f84d5b5b5470917;
  localparam c4    = 128'h9216d5d98979fb1b_d1310ba698dfb5ac;
  localparam c5    = 128'h2ffd72dbd01adfb7_b8e1afed6a267e96;
  localparam c6    = 128'hba7c9045f12c7f99_24a19947b3916cf7;
  localparam c7    = 128'h0801f2e2858efc16_636920d871574e69;
  localparam c8    = 128'ha458fea3f4933d7e_0d95748f728eb658;
  localparam c9    = 128'h718bcd5882154aee_7b54a41dc25a59b5;
  localparam c10   = 128'h9c30d5392af26013_c5d1b023286085f0;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;

  reg [2 : 0]  core_ctrl_reg;
  reg [2 : 0]  core_ctrl_new;
  reg          core_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign ready  = ready_reg;
  assign result = 128'h0;


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin: reg_update
      if (!reset_n)
        begin
          ready_reg     <= 1'h1;
          core_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (ready_we)
            ready_reg <= ready_new;

          if (core_ctrl_we)
            core_ctrl_reg <= core_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // qarma_core_dp
  //
  // Datapath with state update logic.
  //----------------------------------------------------------------
  always @*
    begin : qarma_core_dp
    end // qarma_core_dp


  //----------------------------------------------------------------
  // qarma_core_ctrl
  //
  // Control FSM for aes core.
  //----------------------------------------------------------------
  always @*
    begin : qarma_core_ctrl
      ready_new     = 1'h0;
      ready_we      = 1'h0;
      core_ctrl_new = CTRL_IDLE;
      core_ctrl_we  = 1'h0;

      case (core_ctrl_reg)
        CTRL_IDLE: begin
            if (next) begin
              ready_new     = 1'h0;
              ready_we      = 1'h1;
              core_ctrl_new = CTRL_DONE;
              core_ctrl_we  = 1'h1;
            end
        end


        CTRL_DONE: begin
          ready_new     = 1'h1;
          ready_we      = 1'h1;
          core_ctrl_new = CTRL_IDLE;
          core_ctrl_we  = 1'h1;
        end

        default: begin
        end
      endcase // case (core_ctrl_reg)
    end // qarma_core_ctrl

endmodule // qarma_core

//======================================================================
// EOF qarma_core.v
//======================================================================
