`include ".//PC/pc.v"
`include ".//IMEM/instruction_memory.v"
`include ".//ImmGenerator/imm_generator.v"
`include ".//ControlUnit/control_unit.v"
`include ".//RegisterFile/register_file.v"
`include ".//ALUControlUnit/alu_control_unit.v"
`include ".//ALU/alu_core.v"
`include ".//ALU/alu_m_extension.v"
`include ".//BranchCompare/branch_compare.v"
`include ".//DataMemory/data_memory.v"
`timescale 1ns / 1ps

module cpu (
    input wire clk,
    input wire reset
);

// ----------- PC -----------
wire [31:0] PC;
wire [31:0] PC_next;

// Branch predictor result
wire [31:0] branch_target;
wire pc_src;

assign PC_next = pc_src ? branch_target : PC + 4;

pc pc (
    .clk(clk),
    .reset(reset),
    .pc_write(1'b1),
    .next_pc(PC_next),
    .pc_out(PC)
);

// ----------- IF Stage -----------
wire [31:0] instr;
instruction_memory imem (
    .addr(PC),
    .instr(instr)
);

// ----------- IF/ID Pipeline Register -----------
reg [31:0] IF_ID_PC, IF_ID_instr;

always @(posedge clk) begin
    IF_ID_PC <= PC;
    IF_ID_instr <= instr;
end

// ----------- ID Stage -----------
wire [4:0] rs1 = IF_ID_instr[19:15];
wire [4:0] rs2 = IF_ID_instr[24:20];
wire [4:0] rd  = IF_ID_instr[11:7];
wire [6:0] opcode = IF_ID_instr[6:0];
wire [2:0] funct3 = IF_ID_instr[14:12];
wire [6:0] funct7 = IF_ID_instr[31:25];

wire [31:0] rd1, rd2;
register_file rf (
    .clk(clk),
    .rs1_addr(rs1),
    .rs2_addr(rs2),
    .rd_addr(MEM_WB_rd),
    .rd_data(WB_result),
    .we(MEM_WB_reg_write),
    .rs1_data(rd1),
    .rs2_data(rd2)
);

wire [31:0] imm;
imm_generator imm_gen (
    .instr(IF_ID_instr),
    .imm_out(imm)
);

// Control Signals
wire reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch;
wire [1:0] alu_op;
control_unit cu (
    .opcode(opcode),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .alu_src(alu_src),
    .alu_op(alu_op),
    .branch(branch)
);

// ----------- ID/EX Pipeline Register -----------
reg [31:0] ID_EX_PC, ID_EX_imm, ID_EX_rd1, ID_EX_rd2;
reg [4:0] ID_EX_rd;
reg [2:0] ID_EX_funct3;
reg [6:0] ID_EX_funct7;
reg ID_EX_reg_write, ID_EX_mem_read, ID_EX_mem_write, ID_EX_mem_to_reg, ID_EX_alu_src, ID_EX_branch;
reg [1:0] ID_EX_alu_op;

always @(posedge clk) begin
    ID_EX_PC <= IF_ID_PC;
    ID_EX_rd1 <= rd1;
    ID_EX_rd2 <= rd2;
    ID_EX_imm <= imm;
    ID_EX_rd <= rd;
    ID_EX_funct3 <= funct3;
    ID_EX_funct7 <= funct7;
    ID_EX_reg_write <= reg_write;
    ID_EX_mem_read <= mem_read;
    ID_EX_mem_write <= mem_write;
    ID_EX_mem_to_reg <= mem_to_reg;
    ID_EX_alu_src <= alu_src;
    ID_EX_alu_op <= alu_op;
    ID_EX_branch <= branch;
end

// ----------- EX Stage -----------
wire [4:0] alu_control;

alu_control_unit alu_cu (
    .alu_op(ID_EX_alu_op),
    .funct3(ID_EX_funct3),
    .funct7(ID_EX_funct7),
    .alu_control(alu_control)
);

wire [31:0] alu_input_b = (ID_EX_alu_src) ? ID_EX_imm : ID_EX_rd2;

wire [31:0] alu_out_standard;
wire [31:0] alu_out_mext;

alu_core alu_core (
    .data1(ID_EX_rd1),
    .data2(alu_input_b),
    .alu_control(alu_control),
    .result(alu_out_standard)
);

alu_m_extension alu_mext_core (
    .data1(ID_EX_rd1),
    .data2(alu_input_b),
    .alu_control(alu_control),
    .result(alu_out_mext)
);

wire [31:0] alu_out = (alu_control[4:3] == 2'b01) ? alu_out_mext : alu_out_standard;

// ----------- Branch Comparator -----------
wire branch_taken;
branch_compare branch_cmp (
    .reg1(ID_EX_rd1),
    .reg2(ID_EX_rd2),
    .funct3(ID_EX_funct3),
    .branch_taken(branch_taken)
);

assign branch_target = ID_EX_PC + ID_EX_imm;
assign pc_src = ID_EX_branch && branch_taken;

// ----------- EX/MEM Pipeline Register -----------
reg [31:0] EX_MEM_alu_out, EX_MEM_rd2;
reg [4:0] EX_MEM_rd;
reg [2:0] EX_MEM_funct3;
reg EX_MEM_reg_write, EX_MEM_mem_read, EX_MEM_mem_write, EX_MEM_mem_to_reg;

always @(posedge clk) begin
    EX_MEM_alu_out <= alu_out;
    EX_MEM_rd2 <= ID_EX_rd2;
    EX_MEM_rd <= ID_EX_rd;
    EX_MEM_funct3 <= ID_EX_funct3;
    EX_MEM_reg_write <= ID_EX_reg_write;
    EX_MEM_mem_read <= ID_EX_mem_read;
    EX_MEM_mem_write <= ID_EX_mem_write;
    EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
end

// ----------- MEM Stage -----------
wire [1:0] mem_data_type = EX_MEM_funct3[1:0];
wire [1:0] mem_write_type = EX_MEM_mem_write ? EX_MEM_funct3[1:0] : 2'b00;
wire [31:0] mem_data_out;

data_memory dmem (
    .clk(clk),
    .address(EX_MEM_alu_out),
    .data_in(EX_MEM_rd2),
    .write(mem_write_type),
    .data(mem_data_type),
    .data_out(mem_data_out)
);

// ----------- MEM/WB Pipeline Register -----------
reg [31:0] MEM_WB_mem_data, MEM_WB_alu_out;
reg [4:0] MEM_WB_rd;
reg MEM_WB_reg_write, MEM_WB_mem_to_reg;

always @(posedge clk) begin
    MEM_WB_mem_data <= mem_data_out;
    MEM_WB_alu_out <= EX_MEM_alu_out;
    MEM_WB_rd <= EX_MEM_rd;
    MEM_WB_reg_write <= EX_MEM_reg_write;
    MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
end

// ----------- WB Stage -----------
wire [31:0] WB_result = MEM_WB_mem_to_reg ? MEM_WB_mem_data : MEM_WB_alu_out;

endmodule
