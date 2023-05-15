\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/1d1023ccf8e7b0a8cf8e8fc4f0a823ebb61008e3/risc-v_defs.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])

   m4_test_prog()

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   
   $reset = *reset;
   
   
   $pc[31:0] = >>1$next_pc;
   $next_pc[31:0] = $reset ? 0 :
                    $taken_br ? $br_tgt_pc :
                    $pc + 4;
   
   `READONLY_MEM($pc, $$instr[31:0]);
   
   /*==========
   Decode instruction type
   ==========*/
   $instr_spec[4:0] = $instr[6:2];
   $is_u_instr = $instr_spec ==? 5'b0x_101;
   // This is equivalent to $intr[6:2] == 5'b00101 || $instr[6:2] == 5'b01101;
   
   $is_i_instr = $instr_spec ==? 5'b00_00x ||
                 $instr_spec ==? 5'b00_1x0 ||
                 $instr_spec ==? 5'b11_001;
   
   $is_r_instr = $instr_spec ==? 5'b01_011 ||
                 $instr_spec ==? 5'b01_1x0 ||
                 $instr_spec ==? 5'b10_100;
   
   $is_s_instr = $instr_spec ==? 5'b01_00x;
   
   $is_b_instr = $instr_spec ==? 5'b11_000;
   
   $is_j_instr = $instr_spec ==? 5'b11_011;
   
   /*==========
   Extract Fields
   ==========*/
   $funct7[6:0] = $instr[31:25];
   $funct3[2:0] = $instr[14:12];
   $rs1[4:0]    = $instr[19:15]; // Source 1 register
   $rs2[4:0]    = $instr[24:20]; // Source 2 register
   $rd[4:0]     = $instr[11:7];  // Destination register
   $opcode[6:0] = $instr[6:0];
   
   $imm[31:0]   = $is_i_instr ? { {21{$instr[31]}}, $instr[30:20] } :
                  $is_s_instr ? { {21{$instr[31]}}, $instr[30:25], $instr[11:7] } :
                  $is_b_instr ? { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0 } :
                  $is_u_instr ? { $instr[31:12], 12'b0 } :
                  $is_j_instr ? { {12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0}:
                                 32'b0 ;
   
   // Signal whether the field is in use.
   $funct7_valid = $is_r_instr;
   $funct3_valid = $is_r_instr ||
                   $is_s_instr ||
                   $is_b_instr ||
                   $is_i_instr;
   $rs1_valid    = $is_r_instr ||
                   $is_s_instr ||
                   $is_b_instr ||
                   $is_i_instr;
   $rs2_valid    = $is_r_instr ||
                   $is_s_instr ||
                   $is_b_instr;
   $rd_valid     = $rd != 0 && ($is_r_instr ||
                   $is_u_instr ||
                   $is_j_instr ||
                   $is_i_instr);
   $imm_valid    = ~$is_r_instr;
   
   /*==========
   Decode instructions
   ==========*/
   $dec_bits[10:0] = {$instr[30],$funct3,$opcode};
   $is_lui  = $dec_bits ==? 11'bx_xxx_0110111;
   $is_auipc = $dec_bits ==? 11'bx_xxx_0010111;
   $is_jal  = $dec_bits ==? 11'bx_xxx_1101111;
   $is_jalr = $dec_bits ==? 11'bx_000_1100111;
   $is_beq  = $dec_bits ==? 11'bx_000_1100011;
   $is_bne  = $dec_bits ==? 11'bx_001_1100011;
   $is_blt  = $dec_bits ==? 11'bx_100_1100011;
   $is_bge  = $dec_bits ==? 11'bx_101_1100011;
   $is_bltu = $dec_bits ==? 11'bx_110_1100011;
   $is_bgeu = $dec_bits ==? 11'bx_111_1100011;
   $is_addi = $dec_bits ==? 11'bx_000_0010011;
   $is_slti = $dec_bits ==? 11'bx_010_0010011;
   $is_sltiu = $dec_bits ==? 11'bx_011_0010011;
   $is_xori = $dec_bits ==? 11'bx_100_0010011;
   $is_ori  = $dec_bits ==? 11'bx_110_0010011;
   $is_andi = $dec_bits ==? 11'bx_111_0010011;
   $is_slli = $dec_bits ==? 11'b0_001_0010011;
   $is_srli = $dec_bits ==? 11'b0_101_0010011;
   $is_srai = $dec_bits ==? 11'b1_101_0010011;
   $is_add  = $dec_bits ==? 11'b0_000_0110011;
   $is_sub  = $dec_bits ==? 11'b1_000_0110011;
   $is_sll  = $dec_bits ==? 11'b0_001_0110011;
   $is_slt  = $dec_bits ==? 11'b0_010_0110011;
   $is_sltu = $dec_bits ==? 11'b0_011_0110011;
   $is_xor  = $dec_bits ==? 11'b0_100_0110011;
   $is_srl  = $dec_bits ==? 11'b0_101_0110011;
   $is_sra  = $dec_bits ==? 11'b1_101_0110011;
   $is_or   = $dec_bits ==? 11'b0_110_0110011;
   $is_and  = $dec_bits ==? 11'b0_111_0110011;
   
   $is_load = $dec_bits ==? 11'bx_xxx_0000011; // All load instructions
   // Store instructions are covered by $is_s_instr above.
   
   
   /*==========
   ALU
   ==========*/

   // Common results

   // Set if less than result
   $sltu_rslt[31:0] = {31'b0, $src1_value < $src2_value};
   $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};

   // Arithmatic shift right
   $sign_extend_src1[63:0] = { {32{$src1_value[31]}}, $src1_value };
   $sra_rslt[63:0] = $sign_extend_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sign_extend_src1 >> $imm[4:0];

   // Actual results
   $alu_result[31:0] =
      $is_lui ? {$imm[31:12], 12'b0} : // Load immediate value to upper
      $is_auipc ? $pc + $imm : // Add unsigned to program counter
      $is_jal ? $pc + 32'd4 : // Jump and link
      $is_jalr ? $pc + 32'd4 : // Jump and link register
      $is_addi ? $src1_value + $imm : // Add immediate
      $is_slti ? ( ($src1_value[31] == $imm[31]) ?
         $sltiu_rslt :
         {31'b0, $src1_value[31]} ) : // Set if less than immediate
      $is_sltiu ? $sltiu_rslt :
      $is_xori ? $src1_value ^ $imm : // Xor with immediate
      $is_ori ? $src1_value | $imm : // Or with immediate
      $is_andi ? $src1_value & $imm : // And with immediate
      $is_slli ? $src1_value << $imm[4:0] : // Shift left by immediate
      $is_srli ? $src1_value >> $imm[4:0] : // Shift right byy immediate
      $is_srai ? $srai_rslt[31:0] : // Arimatic shift right
      $is_add  ? $src1_value + $src2_value : // Add
      $is_sub ? $src1_value - $src2_value : // Subtract
      $is_sll ? $src1_value << $src2_value[4:0] : // Shift left
      $is_slt ? ( ($src1_value[31] == $src2_value[31]) ?
         $sltu_rslt :
         {31'b0, $src1_value[31]} ) : // Set if less than
      $is_sltu ? $sltu_rslt : // Unsigned set if less than
      $is_xor ? $src1_value ^ $src2_value : // Xor
      $is_srl ? $src1_value >> $src2_value[4:0] : // Shift right
      $is_sra ? $sra_rslt[31:0] : // Arithmatic shift right
      $is_or ? $src1_value | $src2_value : // Or
      $is_and ? $src1_value & $src2_value : // And
      0;
   
   /*==========
   Branch Logic
   ==========*/
   $taken_br =
      $is_beq  ? $src1_value == $src2_value :
      $is_bne  ? $src1_value != $src2_value :
      $is_blt  ? ($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31]) :
      $is_bge  ? ($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31]) :
      $is_bltu ? $src1_value < $src2_value :
      $is_bgeu ? $src1_value >= $src2_value :
      $is_jal  ? 1'b1 : // Branch always taken
      $is_jalr ? 1'b1 : // Branch always taken
      0;
   
   $br_tgt_pc[31:0] =
      $taken_br && $is_jalr ? $src1_value + $imm :
      $taken_br ? $pc + $imm :
      0;

   /*==========
   Load & Store
   ==========*/
   $addr[31:0] = $src1_value + $imm;

   $result[31:0] = $is_load ? $ld_data : $alu_result;
   
   // `BOGUS_USE($rs1 $rs1_valid $rs2 $rs2_valid $funct3 $funct3_valid $funct7 $funct7_valid $imm $imm_valid $rd $rd_valid $opcode)
   // `BOGUS_USE($is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi $is_add) 
   
   // Assert these to end simulation (before Makerchip cycle limit).
   // *passed = 1'b0;
   // *failed = *cyc_cnt > M4_MAX_CYC;
   
   m4+rf(32, 32, $reset, $rd_valid, $rd[4:0], $result[31:0], $rs1_valid, $rs1[4:0], $src1_value, $rs2_valid, $rs2[4:0], $src2_value)
   m4+dmem(32, 32, $reset, $addr[4:0], $is_s_instr, $src2_value[31:0], $is_load, $$ld_data)
   m4+cpu_viz()
\SV
   endmodule