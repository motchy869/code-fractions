// Verible directive
// verilog_lint: waive-start line-length

//! AXI4-Lite interface.
//! Statements in modport's descriptions are quoted from AXI4 Slave template generated from Vivado 2023.2.
interface aix4_lite_if #(
    parameter int ADDR_BIT_WIDTH = 4, //! address bit width
    parameter int DATA_BIT_WIDTH = 32 //! data bit width
);
    logic [ADDR_BIT_WIDTH-1:0] awaddr;
    logic [2:0] awprot;
    logic awvalid;
    logic awready;
    logic [DATA_BIT_WIDTH-1:0] wdata;
    logic [(DATA_BIT_WIDTH/8)-1:0] wstrb;
    logic wvalid;
    logic wready;
    logic [1:0] bresp;
    logic bvalid;
    logic bready;
    logic [ADDR_BIT_WIDTH-1:0] araddr;
    logic [2:0] arprot;
    logic arvalid;
    logic arready;
    logic [DATA_BIT_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rvalid;
    logic rready;

    modport mst_port(
        //! write address (issued by master, accepted by slave)
        output awaddr,
        //! Write channel Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
        output awprot,
        //! Write address valid. This signal indicates that the master signaling valid write address and control information.
        output awvalid,
        //! Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
        input awready,
        //! Write data (issued by master, accepted by Slave)
        output wdata,
        //! Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
        output wstrb,
        //! Write valid. This signal indicates that valid write data and strobes are available.
        output wvalid,
        //! Write ready. This signal indicates that the slave can accept the write data.
        input wready,
        //! Write response. This signal indicates the status of the write transaction.
        input bresp,
        //! Write response valid. This signal indicates that the channel is signaling a valid write response.
        input bvalid,
        //! Response ready. This signal indicates that the master can accept a write response.
        output bready,
        //! read address (issued by master, accepted by Slave)
        output araddr,
        //! Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
        output arprot,
        //! Read address valid. This signal indicates that the channel is signaling valid read address and control information.
        output arvalid,
        //! Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
        input arready,
        //! read data (issued by slave)
        input rdata,
        //! Read response. This signal indicates the status of the read transfer.
        input rresp,
        //! Read valid. This signal indicates that the channel is signaling the required read data.
        input rvalid,
        //! Read ready. This signal indicates that the master can accept the read data and response information.
        output rready
    );

    modport slv_port(
        //! write address (issued by master, accepted by slave)
        input awaddr,
        //! Write channel Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
        input awprot,
        //! Write address valid. This signal indicates that the master signaling valid write address and control information.
        input awvalid,
        //! Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
        output awready,
        //! Write data (issued by master, accepted by Slave)
        input wdata,
        //! Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
        input wstrb,
        //! Write valid. This signal indicates that valid write data and strobes are available.
        input wvalid,
        //! Write ready. This signal indicates that the slave can accept the write data.
        output wready,
        //! Write response. This signal indicates the status of the write transaction.
        output bresp,
        //! Write response valid. This signal indicates that the channel is signaling a valid write response.
        output bvalid,
        //! Response ready. This signal indicates that the master can accept a write response.
        input bready,
        //! read address (issued by master, accepted by Slave)
        input araddr,
        //! Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
        input arprot,
        //! Read address valid. This signal indicates that the channel is signaling valid read address and control information.
        input arvalid,
        //! Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
        output arready,
        //! read data (issued by slave)
        output rdata,
        //! Read response. This signal indicates the status of the read transfer.
        output rresp,
        //! Read valid. This signal indicates that the channel is signaling the required read data.
        output rvalid,
        //! Read ready. This signal indicates that the master can accept the read data and response information.
        input rready
    );
endinterface
