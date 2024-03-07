/**
  Module name: axi_ohs_comm
  Author: P.Trujillo
  Date: March 2024
  Revision: 1.0
  History: 
    1.0: Model created
**/

`define C_AXI_DATA_WIDTH 32

module axi_ohs_comm #(
	parameter	C_AXI_ADDR_WIDTH = 4
)(
	input s_axi_aclk, 
	input s_axi_aresetn, 

  input wire [`C_AXI_ADDR_WIDTH - 1:0] s_axi_awaddr,
  input wire s_axi_awvalid,
	output wire s_axi_awready,
  
	input wire [`C_AXI_DATA_WIDTH-1:0] s_axi_wdata,
	input wire [`C_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
	input wire s_axi_wvalid,
  output wire s_axi_wready,
	
	output wire [1:0] s_axi_bresp,
	output wire s_axi_bvalid,
	input wire s_axi_bready,

	input wire [`C_AXI_ADDR_WIDTH - 1:0] s_axi_araddr,
  input  wire s_axi_arvalid,
  output wire s_axi_arready,

  output wire [`C_AXI_DATA_WIDTH-1:0] s_axi_rdata,	
  output wire [1:0] s_axi_rresp,
	output wire s_axi_rvalid,
	input wire s_axi_rready
);

	localparam ADDRLSB = 2; /* AXI lite is always 32 bits (32 = 4 bytes) */

	/**********************************************************************************
	*
	* Write strobe apply function (https://zipcpu.com/blog/2020/03/08/easyaxil.html)
	*
	**********************************************************************************/

	function [C_AXI_DATA_WIDTH-1:0]	apply_wstrb;
		input	[C_AXI_DATA_WIDTH-1:0] prior_data;
		input	[C_AXI_DATA_WIDTH-1:0] new_data;
		input	[C_AXI_DATA_WIDTH/8-1:0] wstrb;

		integer	k;
		for(k=0; k<C_AXI_DATA_WIDTH/8; k=k+1)
		begin
			apply_wstrb[k*8 +: 8]
				= wstrb[k] ? new_data[k*8 +: 8] : prior_data[k*8 +: 8];
		end
	endfunction

	/**********************************************************************************
	*
	* AXI Registers declaration
	*
	**********************************************************************************/

	reg	[C_AXI_DATA_WIDTH-1:0] r0;

	/**********************************************************************************
	*
	* AXI internal signals
	*
	**********************************************************************************/

	reg [1:0] axi_rresp; /* read response */
	reg [1 :0] axi_bresp; /* write response */
	reg axi_awready; /* write address acceptance */
	reg axi_bvalid; /* write response valid */
	reg [ADDR_MSB-1:0] axi_awaddr; /* write address */
	reg [ADDR_MSB-1:0] axi_araddr; /* read address valid */
	reg [`C_S_AXI_DATA_WIDTH-1:0] axi_rdata; /* read data */
	reg axi_arready; /* read address acceptance */

	wire	[C_AXI_DATA_WIDTH-1:0]	wskd_r0; /* reading register with strobo appplied */

	/**********************************************************************************
	*
	* Write acceptance.
	*
	**********************************************************************************/

  always @(posedge s_axi_aclk )
    if (!s_axi_aresetn)
      begin
        axi_awready <= 1'b0;
      end
    else
      axi_awready <= <= !axil_awready && (s_axi_awvalid && s_axi_wvalid) && (!s_axi_bvalid || s_axi_bready);
	
	/* Both ready signals are set at the same time */
	assign s_axi_awready = axi_awready;
	assign s_axi_wready = axi_awready;

	/**********************************************************************************
	*
	* Register write
	*
	**********************************************************************************/

	/* Apply write strobe to registers */
	assign	wskd_r0 = apply_wstrb(r0, wskd_data, wskd_strb);

	/* set address */
	assign axi_awaddr = s_axi_awaddr[C_AXI_ADDR_WIDTH-1:ADDRLSB];

	/* write registers */
	always @(s_axi_aclk)
	if (!s_axi_aresetn)
		r0 <= 0;
	else if (axi_awready && s_axi_awaddr == 2'b00)
		r0 <= wskd_r0;

	/**********************************************************************************
	*
	* Register read
	*
	**********************************************************************************/

	assign axil_read_ready = (s_axi_arvalid && s_axi_arready);
	assign axi_araddr = s_axi_araddr[C_AXI_ADDR_WIDTH-1:ADDRLSB];

	always @(posedge s_axi_aclk)
		if (!s_axi_aresetn) begin
			axi_rdata <= {C_AXI_DATA_WIDTH{1'b0}}
		end
		else 
			if (!s_axi_rvalid || s_axi_rready)
				case(axi_araddr)
					2'b00: axi_rdata	<= r0;
					default: axi_rdata <= {C_AXI_DATA_WIDTH{1'b0}};
				endcase

	/**********************************************************************************
	*
	* AXI information signals
	*
	**********************************************************************************/

	/* force no errors during AXI transactions */
	assign s_axi_bresp = 2'b00;
	assign s_axi_rresp = 2'b00;

	
endmodule