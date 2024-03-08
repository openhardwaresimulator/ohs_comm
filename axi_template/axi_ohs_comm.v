/**
  Module name: axi_ohs_comm
  Author: P.Trujillo
  Date: March 2024
  Revision: 1.0
  History: 
    1.0: Model created
**/

`default_nettype none

`define S_AXI_DATA_WIDTH 32

module axi_ohs_comm #(
	parameter	S_AXI_ADDR_WIDTH = 4
)(
	input wire s_axi_aclk, 
	input wire s_axi_aresetn, 

  input wire [S_AXI_ADDR_WIDTH - 1:0] s_axi_awaddr,
  input wire s_axi_awvalid,
	output wire s_axi_awready,
  
	input wire [`S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
	input wire [`S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
	input wire s_axi_wvalid,
  output wire s_axi_wready,
	
	output wire [1:0] s_axi_bresp,
	output reg s_axi_bvalid,
	input wire s_axi_bready,

	input wire [S_AXI_ADDR_WIDTH - 1:0] s_axi_araddr,
  input  wire s_axi_arvalid,
  output wire s_axi_arready,

  output wire [`S_AXI_DATA_WIDTH-1:0] s_axi_rdata,	
  output wire [1:0] s_axi_rresp,
	output reg s_axi_rvalid,
	input wire s_axi_rready
);

	localparam ADDR_LSB = 2; /* AXI lite is always 32 bits (32 = 4 bytes) */
	localparam ADDR_MSB = S_AXI_ADDR_WIDTH-ADDR_LSB; /* AXI lite is always 32 bits (32 = 4 bytes) */

	/**********************************************************************************
	*
	* Write strobe apply function (https://zipcpu.com/blog/2020/03/08/easyaxil.html)
	*
	**********************************************************************************/

	function [`S_AXI_DATA_WIDTH-1:0]	apply_wstrb;
		input	[`S_AXI_DATA_WIDTH-1:0] prior_data;
		input	[`S_AXI_DATA_WIDTH-1:0] new_data;
		input	[`S_AXI_DATA_WIDTH/8-1:0] wstrb;

		integer	k;
		for(k=0; k<`S_AXI_DATA_WIDTH/8; k=k+1)
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

	reg	[`S_AXI_DATA_WIDTH-1:0] r0;
	reg	[`S_AXI_DATA_WIDTH-1:0] r1;
	reg	[`S_AXI_DATA_WIDTH-1:0] r2;
	reg	[`S_AXI_DATA_WIDTH-1:0] r3;

	/**********************************************************************************
	*
	* AXI internal signals
	*
	**********************************************************************************/

	reg [1:0] axi_rresp; /* read response */
	reg [1 :0] axi_bresp; /* write response */
	reg axi_awready; /* write address acceptance */
	reg axi_bvalid; /* write response valid */
	wire [ADDR_MSB-1:0] axi_awaddr; /* write address */
	wire [ADDR_MSB-1:0] axi_araddr; /* read address valid */
	reg [`S_AXI_DATA_WIDTH-1:0] axi_rdata; /* read data */
	reg axi_arready; /* read address acceptance */
	wire axi_read_ready; /* read ready */

	wire [`S_AXI_DATA_WIDTH-1:0] wskd_r0; /* reading register with strobo appplied */
	wire [`S_AXI_DATA_WIDTH-1:0] wskd_r1; /* reading register with strobo appplied */
	wire [`S_AXI_DATA_WIDTH-1:0] wskd_r2; /* reading register with strobo appplied */
	wire [`S_AXI_DATA_WIDTH-1:0] wskd_r3; /* reading register with strobo appplied */

	/**********************************************************************************
	*
	* Write acceptance.
	*
	**********************************************************************************/

  always @(posedge s_axi_aclk )
    if (!s_axi_aresetn)
        axi_awready <= 1'b0;
    else
      axi_awready <= !axi_awready && (s_axi_awvalid && s_axi_wvalid) && (!s_axi_bvalid || s_axi_bready);
	
	/* Both ready signals are set at the same time */
	assign s_axi_awready = axi_awready;
	assign s_axi_wready = axi_awready;

	/**********************************************************************************
	*
	* Register write
	*
	**********************************************************************************/

	/* Apply write strobe to registers */
	assign	wskd_r0 = apply_wstrb(r0, s_axi_wdata, s_axi_wstrb);

	/* set address */
	assign axi_awaddr = s_axi_awaddr[S_AXI_ADDR_WIDTH-1:ADDR_LSB];

	/* write registers */
	always @(s_axi_aclk)
	if (!s_axi_aresetn) begin
		r0 <= 0;
		r1 <= 0;
		r2 <= 0;
		r3 <= 0;
	end
	else 
		if (axi_awready)
			case(s_axi_awaddr)
				2'b00: r0 <= wskd_r0;
				2'b01: r1 <= wskd_r1;
				2'b10: r2 <= wskd_r2;
				2'b11: r3 <= wskd_r3;
			endcase


	/**********************************************************************************
	*
	* Register read
	*
	**********************************************************************************/

	assign axi_read_ready = (s_axi_arvalid && s_axi_arready);
	assign axi_araddr = s_axi_araddr[S_AXI_ADDR_WIDTH-1:ADDR_LSB];

	always @(posedge s_axi_aclk)
		if (!s_axi_aresetn)
			axi_rdata <= {`S_AXI_DATA_WIDTH{1'b0}};
		else 
			if (!s_axi_rvalid || s_axi_rready)
				case(axi_araddr)
					2'b00: axi_rdata	<= r0;
					default: axi_rdata <= {`S_AXI_DATA_WIDTH{1'b0}};
				endcase

	assign s_axi_rdata = axi_rdata;

	/**********************************************************************************
	*
	* AXI information signals
	*
	**********************************************************************************/

	/* force no errors during AXI transactions */
	assign s_axi_bresp = 2'b00;
	assign s_axi_rresp = 2'b00;

	/* s_axi_bvalid is set following any succesful write transaction */
	always @(posedge s_axi_aclk)
		if (!s_axi_aresetn)
			s_axi_bvalid <= 1'b0;
		else 
			if (axi_awready)
				s_axi_bvalid <= 1'b1;
			else if (s_axi_bready)
				s_axi_bvalid <= 1'b0;
	
	/* s_axi_bvalid is set following any succesful read transaction */
	always @(posedge s_axi_aclk)
		if (!s_axi_aresetn)
			s_axi_rvalid <= 1'b0;
		else 
			if (axi_read_ready)
				s_axi_rvalid <= 1'b1;
			else if (s_axi_rready)
				s_axi_rvalid <= 1'b0;

	assign s_axi_arready = !s_axi_rvalid;
	
endmodule