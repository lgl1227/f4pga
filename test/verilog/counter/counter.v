/*
* Copyright (C) 2020-2022 F4PGA Authors.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     https://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* SPDX-License-Identifier: Apache-2.0
*/

module top (
    input CLK,
    output [3:0] LEDs
);

  localparam BITS = 4;
  localparam LOG2DELAY = 22;

  wire bufg;
  BUFG bufgctrl (
      .I(CLK),
      .O(bufg)
  );

  reg [BITS+LOG2DELAY-1:0] counter = 0;

  always @(posedge bufg) begin
    counter <= counter + 1;
  end

  assign LEDs[3:0] = counter >> LOG2DELAY;
endmodule
