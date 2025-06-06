module controlUnit(
    INSTRUCTION,
    WRITE_ENABLE,         // RegWrite back
    MEMORY_ACCESS,        // Memory Access: Load/Store
    MEM_WRITE,            // Memory Write
    MEM_READ,             // Memory Read
    JUMP_AND_LINK,        // Enables JALR and JAL
    ALU_OPCODE,           // Specifies ALU operation
    IMMEDIATE_SELECT,     // Selects the source of immediate
    OFFSET_GENARATOR,     // Selects type of PC offset used in jumps/branches.
    BRANCH,JUMP,          // Control signals for branching and jumping.
    IMM_SEL        // Specifies the type of immediate value(I-type, S-type, B-type, U-type)
);

input[31:0] INSTRUCTION;
output reg[4:0] ALU_OPCODE;
output reg[2:0] IMM_SEL;
output reg WRITE_ENABLE,MEMORY_ACCESS,MEM_WRITE,MEM_READ,JUMP_AND_LINK,BRANCH,JUMP;
output reg[1:0]OFFSET_GENARATOR,IMMEDIATE_SELECT;
wire [6:0] OPCODE,FUNCT7;
wire [2:0] FUNCT3;


assign OPCODE = INSTRUCTION[6:0];
assign FUNCT3 = INSTRUCTION[14:12];
assign FUNCT7 = INSTRUCTION[31:25];


always @(OPCODE,FUNCT3,FUNCT7) begin
    #1 
    case(OPCODE)
    7'b0110011:begin //R type istruction
        IMM_SEL = 3'bxxx;
        WRITE_ENABLE = 1'b1;
        MEMORY_ACCESS = 1'b0;
        MEM_WRITE = 1'b0;
        MEM_READ = 1'b0;
        JUMP_AND_LINK = 1'b0;
        IMMEDIATE_SELECT = 2'b00;
        OFFSET_GENARATOR = 2'b00;
        BRANCH = 1'b0;
        JUMP = 1'b0 ;
        
        case({FUNCT7,FUNCT3})
        10'b0000000000:ALU_OPCODE = 5'b00000; // ADD
        10'b0100000000:ALU_OPCODE = 5'b00001; // SUB
        10'b0000000110:ALU_OPCODE = 5'b00010; // OR
        10'b0000000100:ALU_OPCODE = 5'b00011; // XOR
        10'b0000000111:ALU_OPCODE = 5'b00100; // AND 
        10'b0000000101:ALU_OPCODE = 5'b00101; // SRL
        10'b0000000001:ALU_OPCODE = 5'b00110; // SLL
        10'b0100000101:ALU_OPCODE = 5'b00111; // SRA
        10'b0000001000:ALU_OPCODE = 5'b01000; // MUL
        10'b0000001001:ALU_OPCODE = 5'b01001; // MULH
        10'b0000001011:ALU_OPCODE = 5'b01010; // MULHU
        10'b0000001010:ALU_OPCODE = 5'b01011; // MULHSU
        10'b0000001100:ALU_OPCODE = 5'b01100; // DIV
        10'b0000001101:ALU_OPCODE = 5'b01101; // DIVH
        10'b0000001110:ALU_OPCODE = 5'b01110; // REM
        10'b0000001111:ALU_OPCODE = 5'b01111; // REMU
        10'b0000000010:ALU_OPCODE = 5'b10000; // SLT 
        endcase
    end

    7'b0010011:begin //I type istruction
        IMM_SEL = 3'b000;
        WRITE_ENABLE = 1'b1;
        MEMORY_ACCESS = 1'b0;
        MEM_WRITE = 1'b0;
        MEM_READ = 1'b0;
        JUMP_AND_LINK = 1'b0;
        IMMEDIATE_SELECT = 2'b10;
        OFFSET_GENARATOR = 2'b00;
        BRANCH = 1'b0;
        JUMP = 1'b0 ;

        case(FUNCT3)
        3'b000:ALU_OPCODE = 5'b00000; // ADDI
        3'b010:ALU_OPCODE = 5'b10000; // SLTI
        3'b111:ALU_OPCODE = 5'b00100; // ANDI
        3'b110:ALU_OPCODE = 5'b00010; // ORI
        3'b100:ALU_OPCODE = 5'b00011; // XORI
        endcase

        case(FUNCT7)
        7'b0000000:begin
            case (FUNCT3)
                3'b001: ALU_OPCODE = 5'b00110; //SLLI
                3'b101: ALU_OPCODE = 5'b00101; //SRLI 
            endcase
        end
        7'b0100000:begin
            case (FUNCT3)
                3'b101: ALU_OPCODE = 5'b00111; //SRAI
                endcase
        end
        endcase
    
    end

    7'b0000011:begin //LW istruction
        IMM_SEL = 3'b000;
        WRITE_ENABLE = 1'b1;
        MEMORY_ACCESS = 1'b1;
        MEM_WRITE = 1'b0;
        MEM_READ = 1'b1;
        JUMP_AND_LINK = 1'b0;
        IMMEDIATE_SELECT = 2'b10;
        OFFSET_GENARATOR = 2'b00;
        BRANCH = 1'b0;
        JUMP = 1'b0 ;
        ALU_OPCODE = 5'b00000;
        end 

    7'b0100011:begin //S type istruction
        IMM_SEL = 3'b001;
        WRITE_ENABLE = 1'b0;
        MEMORY_ACCESS = 1'b1;
        MEM_WRITE = 1'b1;    
        MEM_READ = 1'b0;
        JUMP_AND_LINK = 1'b0;    
        IMMEDIATE_SELECT = 2'b10;
        OFFSET_GENARATOR = 2'b00;
        BRANCH = 1'b0;
        JUMP = 1'b0 ;
        ALU_OPCODE = 5'b00000; 
    end

    7'b1101111:begin //J type istruction
        IMM_SEL = 3'b010;
        WRITE_ENABLE = 1'b1;
        MEMORY_ACCESS = 1'b0;
        MEM_WRITE = 1'b0;
        MEM_READ = 1'b0;
        JUMP_AND_LINK = 1'b1;
        IMMEDIATE_SELECT = 2'b10;
        OFFSET_GENARATOR = 2'b10;
        BRANCH = 1'b0;
        JUMP = 1'b1 ;
        ALU_OPCODE = 5'b00000;
    end

    7'b1100111:begin //JALR istruction
        IMM_SEL = 3'b000;
        WRITE_ENABLE = 1'b1;
        MEMORY_ACCESS = 1'b0;
        MEM_WRITE = 1'b0;
        MEM_READ = 1'b0;
        JUMP_AND_LINK = 1'b1;
        IMMEDIATE_SELECT = 2'b10;
        OFFSET_GENARATOR = 2'b00;
        BRANCH = 1'b0;
        JUMP = 1'b1;
        ALU_OPCODE = 5'b00000;
    end

    7'b0110111:begin // LUI
        IMM_SEL = 3'b011;
        WRITE_ENABLE = 1'b1;
        MEMORY_ACCESS = 1'b0;
        MEM_WRITE = 1'b0;
        MEM_READ = 1'b0;
        JUMP_AND_LINK = 1'b0;
        IMMEDIATE_SELECT = 2'b10;
        OFFSET_GENARATOR = 2'b00;
        BRANCH = 1'b0;
        JUMP = 1'b0;
        ALU_OPCODE = 5'b10001;
    end

     7'b0010111:begin // AUIPC
        IMM_SEL = 3'b011;
        WRITE_ENABLE = 1'b1;
        MEMORY_ACCESS = 1'b0;
        MEM_WRITE = 1'b0;
        MEM_READ = 1'b0;
        JUMP_AND_LINK = 1'b0;
        IMMEDIATE_SELECT = 2'b10;
        OFFSET_GENARATOR = 2'b10;
        BRANCH = 1'b0;
        JUMP = 1'b0;
        ALU_OPCODE = 5'b00000;
    end
    
    7'b1100011:begin // B type instruction
        IMM_SEL = 3'b100;
        WRITE_ENABLE = 1'b0;
        MEMORY_ACCESS = 1'b0;
        MEM_WRITE = 1'b0;
        MEM_READ = 1'b0;
        JUMP_AND_LINK = 1'b0;
        IMMEDIATE_SELECT = 2'b10;
        OFFSET_GENARATOR = 2'b10;
        BRANCH = 1'b1;
        JUMP = 1'b0;
        ALU_OPCODE = 5'b00000;
    end
    

    endcase
end

endmodule


