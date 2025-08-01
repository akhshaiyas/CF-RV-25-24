// See LICENSE.iitm for license details
/*

Author : IIT Madras
Details:

--------------------------------------------------------------------------------------------------
*/
package ccore_types;
`include "ccore_params.defines"
`include "csrbox.defines"
`include "trap.defines"

import csr_types      :: * ;
import csrbox_decoder :: * ;
import DefaultValue   :: * ;
import Vector         :: * ;

typedef 0 USERSPACE;
typedef 1 IDWIDTH ;  

`ifdef RV64
typedef 64 XLEN;
`else
typedef 32 XLEN;
`endif
`ifdef dpfpu
typedef 64 FLEN;
`elsif spfpu
typedef 32 FLEN;
`else
typedef `vaddr FLEN;
`endif

function String excause2str (Bit#(TSub#(`causesize,1)) cause);
  case (cause)
    `Inst_addr_misaligned  : return "Instruction-Address-Misaligned-Trap";
    `Inst_access_fault     : return "Instruction-Access-Fault-Trap";
    `Load_addr_misaligned  : return "Load-Address-Misaligned-Trap";
    `Load_access_fault     : return "Load-Access-Fault-Trap";
    `Store_addr_misaligned : return "Store-Address-Misaligned-Trap";
    `Store_access_fault    : return "Store-Access-Fault-Trap";  
    `Inst_pagefault        : return "Instruction-Page-Fault-Trap";  
    `Load_pagefault        : return "Load-Page-Fault-Trap";  
    `Store_pagefault       : return "Store-Page-Fault-Trap";  
    `Illegal_inst          : return "Illegal-Trap";
    `Ecall_from_machine    : return "ECALL-Machine-Trap";
    `Ecall_from_user       : return "ECALL-User-Trap";
    `Ecall_from_supervisor : return "ECALL-Supervisor-Trap";
    `Breakpoint            : return "Breakpoint-Trap";
  `ifdef arith_trap
    `Int_divide_by_zero    : return "Int_divide_by_zero";
    `FP_invalid            : return "FP_invalid";
    `FP_divide_by_zero     : return "FP_divide_by_zero";
    `FP_overflow           : return "FP_overflow";
    `FP_underflow          : return "FP_underflow";
    `FP_inexact            : return "FP_inexact";
  `endif
    default: return "UNKNOWN EXCEPTION VALUE";
  endcase
endfunction

function String intcause2str (Bit#(TSub#(`causesize,1)) cause);
  case (cause)
    `User_soft_int            : return "User-Soft-Interrupt";
    `Supervisor_soft_int      : return "Supervisor-Soft-Interrupt";
    `Machine_soft_int         : return "Machine-Soft-Interrupt";
    `User_timer_int           : return "User-Timer-Interrupt";
    `Supervisor_timer_int     : return "Supervisor-Timer-Interrupt";
    `Machine_timer_int        : return "Machine-Timer-Interrupt";
    `User_external_int        : return "User-External-Interrupt";
    `Supervisor_external_int  : return "Supervisor-External-Interrupt";
    `Machine_external_int     : return "Machine-External-Interrupt";
    default: return "UNKNOWN INTERRUPT VALUE";
  endcase
endfunction

//------ Enums used across the pipeline -------------------------------------------------
/*doc:enum: This enum is used to identify the type of instruction. This is consumed by the EXE
 * stage to figue out which Functional unit will be used for execution. 
 * min size: 3 bits. max_size: 4*/
typedef enum {ALU, MEMORY, BRANCH, JAL, JALR, SYSTEM_INSTR, TRAP, WFI 
              `ifdef spfpu, FLOAT `endif
              `ifdef muldiv, MULDIV `endif } Instruction_type deriving(Bits, Eq, FShow);

/*doc:enum: indicates the different data memory accesses that can be generated by the core
 * min size: 3 bits. max_size: 3*/
typedef enum {Load = 0, Store = 1, Fence = 3, FenceI = 4
              `ifdef atomic,      Atomic = 2 `endif
              `ifdef supervisor,  SFence = 5 `endif 
              `ifdef hypervisor, HFence_VVMA = 6, HFence_GVMA = 7 `endif } Access_type deriving (Bits, Eq, FShow);

/*doc:enum: This enum indicates the type of the operand-1 used for execution 
 * min size: 1 max size: 2 */
typedef enum {IntegerRF = 0, PC = 1  `ifdef spfpu ,FloatingRF = 2,  Dummy1_Op1type = 3  `endif } Op1type deriving(Bits, Eq, FShow);

/*doc:enum: This enum indicates the type of the operand-2 used for execution 
 * min size: 2 max size: 3 */
typedef enum {IntegerRF = 0, Immediate = 1, Constant4 = 2, Constant2 = 3  `ifdef spfpu ,FloatingRF = 4, Dummy1_Op2type = 5, Dummy2_Op2type = 6, Dummy3_Op2type = 7  `endif }
                           Op2type deriving(Bits, Eq, FShow);

/*doc:enum: This enum indicates in which rf the destination register needs to be updated
 * min size: 1 max size: 1 */
typedef enum {FRF = 1, IRF = 0} RFType deriving(Bits, Eq, FShow);

typedef TMax#(XLEN, FLEN) ELEN;

/*doc:enum: This indicate which ISB after EXE should the result be captured in
 * min size: 2 max size: 3 */
typedef enum {BASE, SYSTEM, TRAP, MEMORY 
    `ifdef muldiv , MULDIV `endif
    `ifdef spfpu  , FLOAT  `endif } EXEType deriving (Bits, FShow, Eq);

/*doc:enum this indicates which ISB after MEM should the next instruction commit happen from
 * min size: 2 max size: 2 */
typedef enum {BASE, SYSTEM, TRAP, MEMORY} CommitType deriving (Bits, FShow, Eq);

// -------------------------------------------------------------------------------------


typedef struct{
`ifdef ifence
  Bool  fence;        // bits [XLEN+1] or [XLEN]
`endif
`ifdef supervisor
  Bool  sfence;       // bits [XLEN]
`endif
`ifdef hypervisor
  Bool  hfence;
`endif
  Bit#(`vaddr) pc;    // bits [XLEN-1:0]
} Stage0Flush deriving(Bits, Eq, FShow);

// ------------------ Structures used by the score-board mechanism --------------------------
/*doc:struct: struct indicates which entry of the scoreboard needs to be updated. Used for both
 * locking and releasing updates*/
typedef struct{
`ifdef no_wawstalls
  Bit#(`wawid) id;
`endif
`ifdef spfpu 
  RFType rdtype;  // bits [5]
`endif
  Bit#(5) rd;     // bits [4:0]
}SBDUpd deriving (Bits,  Eq);

instance FShow#(SBDUpd);
  function Fmt fshow(SBDUpd val);
    Fmt result;
  `ifdef spfpu
    if (val.rdtype == FRF)
      result = $format("F[%d]",val.rd);
    else
  `endif
      result = $format("X[%d]",val.rd);
    return result;
  endfunction
endinstance

typedef struct{
`ifdef no_wawstalls
  Bit#(`wawid) id;
`endif
  Bit#(1) lock;
} SBEntry deriving (Bits, FShow, Eq);

/*doc:struct: This struct is used to read the scoreboard values*/
typedef struct{
`ifdef spfpu
  Bit#(64) rf_lock;   // bits [63:32]
  `ifdef no_wawstalls
    Vector#(64, Bit#(`wawid)) v_id;
  `endif
`else
  Bit#(32) rf_lock;   // bits [31:0]
  `ifdef no_wawstalls
    Vector#(32, Bit#(`wawid)) v_id;
  `endif
`endif
}SBD deriving (Bits, Eq);

instance FShow#(SBD);
  function Fmt fshow(SBD val);
    Fmt result = $format("SBD: IRF:\n");
    for (Integer i = 0; i< `ifdef spfpu 64 `else 32 `endif ; i = i + 1) begin
      result = result + $format("%3d ",i);
    end
    result= result + $format("\n");
    for (Integer i = 0; i< `ifdef spfpu 64 `else 32 `endif ; i = i + 1) begin
      result = result + $format("%3d ",val.rf_lock[i]);
    end
  `ifdef no_wawstalls
    result= result + $format("\n");
    for (Integer i = 0; i< `ifdef spfpu 64 `else 32 `endif ; i = i + 1) begin
      result = result + $format("%3d ",val.v_id[i]);
    end
  `endif
    return result;
  endfunction
endinstance
// -------------------------------------------------------------------------------------

// ---------------------structures used for operand bypass scheme-----------------------
/*doc:struct: This struct is used by the EXE stage to indicate the operand required for execution*/
typedef struct{
`ifdef no_wawstalls
  Bit#(`wawid) id;
`endif
`ifdef spfpu
  RFType rdtype;      // bits [ELEN+8]
`endif
  Bit#(5) rd;         // bits [ELEN+7 : ELEN+3]
  Bit#(1) sb_lock;    // bits [1]
  Bit#(1) epochs;     // bits [0]
} BypassReq deriving (Bits, FShow, Eq);

/*doc:struct: This struct carries the bypassed operand available at various stages of the pipeline*/
typedef struct{
`ifdef no_wawstalls
  Bit#(`wawid) id;
`endif
`ifdef spfpu
  RFType rdtype;      // bits [ELEN+7]
`endif
  Bool valid;         // bits [ELEN+6]
  Bit#(5) addr;       // bits [ELEN+5: ELEN+1]
  Bit#(`elen) data;    // bits [ELEN:1]
  Bit#(1) epochs;     // bits [0]
} FwdType deriving(Bits, FShow, Eq);
// -------------------------------------------------------------------------------------

// this struct holds the meta decoded information of an instruction
typedef struct{
`ifdef hypervisor
  Bit#(1) hlvx;
  Bit#(1) hvm_loadstore;
`endif
  Instruction_type inst_type; // instruction type
  Access_type memaccess;      // memory access type
  Bit#(32) immediate;         // immediate fields
  Bit#(TMax#(`causesize, 7)) funct_cause;              // concatenation of f3 and fn fields
  Bool    microtrap;              // indicates if the current instruction needs to be rerun
} InstrMeta deriving(Bits, Eq, FShow);

// This struct captures the decoded addresses of the operands and destination registers.
// Max width : 20 bits
typedef struct{
`ifdef spfpu
  Bit#(5) rs3addr;
`endif
  Bit#(5) rs1addr;
  Bit#(5) rs2addr;
  Bit#(5) rd;
} OpAddr deriving(Bits, Eq);

instance FShow#(OpAddr);
  function Fmt fshow(OpAddr val);
    Fmt result = $format("Operands: RS1:%2d RS2:%2d RD:%2d",val.rs1addr, val.rs2addr, val.rd);
    return result;
  endfunction
endinstance

//// this struct captures the type of the operands based on the instruction being decoded.
//// Max width : 2+3 + 1+1 = 7 bits
typedef struct{
`ifdef spfpu
  RFType  rs3type;
  RFType  rdtype;
`endif
  Op1type rs1type;
  Op2type rs2type; 
} OpType deriving(Bits, Eq, FShow);

// the final structure of the response from the decoder
typedef struct{
`ifdef compressed
  Bool compressed;
`endif
  OpAddr    op_addr;
  OpType    op_type;
  InstrMeta meta;
} DecodeOut deriving(Bits, Eq, FShow);
// ------------------------------------------------------------------------------------------

typedef struct{
`ifdef non_m_traps
  Bit#(TAdd#(`max_int_cause,1)) csr_mideleg;
`endif
`ifdef usertraps
  `ifdef supervisor
  Bit#(TAdd#(`max_int_cause,1)) csr_sideleg;
  `endif
`endif
`ifdef debug
  Bit#(32)  csr_dcsr;
`endif 
`ifdef spfpu
  Bit#(3) frm;
`endif
`ifdef hypervisor
    Bit#(12) csr_hideleg;
    Bit#(`xlen) csr_hstatus;   
    Bit #(1) csr_vs_bit;
`endif
  Privilege_mode prv;
  Bit#(TAdd#(`max_int_cause,1)) csr_mip;
  Bit#(TAdd#(`max_int_cause,1)) csr_mie;
  Bit#(26) csr_misa;
  Bit#(`xlen) csr_mstatus;
  Bit#(`xlen) csr_sstatus;
} CSRtoDecode deriving(Bits, Eq, FShow);

typedef struct {
  Bool debugger_available;
  Bool debug_mode;
  Bool step_set;
  Bool step_ie;
  Bool core_debugenable;
} DebugStatus deriving(Bits, Eq, FShow);

// ----------------------------structures required for commit logging --------------------------
typedef struct{
  Bit#(`xlen) address;
  Bit#(`xlen) data;
  Bit#(`xlen) commit_data;
  Access_type access;
  Bit#(5) rd;
  Bool irf;
  Bit#(3) size;
  Bit#(5) atomic_op;
} CommitLogMem deriving(Bits, FShow, Eq);

typedef struct{
  Bit#(12) csr_address;
  Bit#(`xlen) wdata;
  Bit#(5) rd;
  Bit#(`xlen) rdata;
  Bit#(2) op;
} CommitLogCSR deriving(Bits, FShow, Eq);

typedef struct{
  Bit#(`xlen) wdata;
  Bit#(5) rd;
  Bool irf;
  `ifdef spfpu
  Bit#(5) fflags;
`endif
} CommitLogReg deriving(Bits, FShow, Eq);

typedef union tagged {
  void None;
  CommitLogMem MEM;
  CommitLogCSR CSR;
  CommitLogReg REG;
} CommitLogType deriving(Bits, FShow, Eq);

typedef struct{
`ifdef hypervisor
  Bit#(1) v;
`endif
  Privilege_mode mode;
  Bit#(`xlen) pc;
  Bit#(32) instruction;
  CommitLogType inst_type;
} CommitLogPacket deriving(Bits, FShow, Eq);
// ------------------------------------------------------------------------------------------

// ---- structure of the zeroth pipeline stage ----------------//
typedef struct{
`ifdef compressed
  Bool discard;
`endif
`ifdef bpu
  BTBResponse btbresponse;
`endif
  Bit#(addr)  address;      // XLEN:0
} Stage0PC#(numeric type addr) deriving(Bits, Eq, FShow);

// -- structure of the first pipeline stage -----------------//
typedef struct{
`ifdef compressed
  Bool upper_err;
  Bool compressed;
`endif
`ifdef bpu
  BTBResponse btbresponse;
`endif
	Bit#(`vaddr) program_counter;
	Bit#(32) instruction;
	Bit#(`iesize) epochs;
  Bool trap ;
  Bit#(`causesize) cause;
}PIPE1 deriving (Bits, Eq, FShow);

typedef struct{
`ifdef hypervisor
  Bit#(1) hlvx;
  Bit#(1) hvm_loadstore;
`endif
`ifdef spfpu
  RFType rdtype;
`endif
`ifdef RV64
  Bool word32;
`elsif dpfpu
  Bool word32;
`endif
`ifdef bpu
  `ifdef compressed
    Bool compressed;
  `endif
  BTBResponse btbresponse;
`endif
  Bool is_microtrap;
  Bit#(TMax#(`causesize, 7)) funct;
  Access_type memaccess;
  Bit#(`vaddr) pc;
  Bit#(2) epochs;
  Bit#(5) rd;
} Stage3Meta deriving(Bits, Eq);

instance FShow#(Stage3Meta);
  function Fmt fshow(Stage3Meta val);
    Fmt result = $format("Stage3Meta: rd:%d epochs:%b funct:%h",val.rd, val.epochs, val.funct);
  `ifdef spfpu
    result = result + $format(" rdtype:",fshow(val.rdtype));
  `endif
  `ifdef compressed
    result = result + $format(" compressed:",fshow(val.compressed));
  `endif
  return result;
  endfunction
endinstance

typedef struct {
`ifdef spfpu
  RFType  rs3type;
  Bit#(5) rs3addr;
`endif
  Op1type rs1type;
  Op2type rs2type;
  Bit#(5) rs1addr;
  Bit#(5) rs2addr;
} OpMeta deriving(Bits, FShow, Eq);

// ----------------- structures of operand fetch from decode stage ------------------------------
typedef struct{
  Bit#(5)     addr;
  Bit#(`elen)  data;
  Op1type     optype;
} RFOp1 deriving(Bits, Eq, FShow);

typedef struct{
  Bit#(5)     addr;
  Bit#(`elen)  data;
  Op2type     optype;
} RFOp2 deriving(Bits, Eq, FShow);

typedef struct{
  Bit#(`elen)  data;
`ifdef spfpu
  Bit#(5)     addr;
  RFType      optype;
`endif
} RFOp3 deriving(Bits, Eq, FShow);
// ------------------------------------------------------------------------------------------


// ---------------------------------------Output types from stage3 --------------------------
typedef struct{
`ifdef no_wawstalls
  Bit#(`wawid) id;
`endif
`ifdef spfpu
  Bit#(5)       fflags;
  RFType        rdtype;
`endif
  Bit#(`elen)    rdvalue;
  Bit#(5)       rd;
  Bit#(1)       epochs;
} BaseOut deriving(Bits, Eq);

instance FShow#(BaseOut);
  function Fmt fshow(BaseOut value);
    Fmt result = $format("rd:%2d rdval:%h",value.rd, value.rdvalue);
  `ifdef spfpu
    result = result + $format(" rdtype: ",fshow(value.rdtype));
  `endif
  `ifdef no_wawstalls
    result = result + $format(" id:%2d", value.id);
  `endif
    return result;
  endfunction
endinstance

typedef struct {
`ifdef microtrap_support
  Bool is_microtrap;
`endif
  Bit#(`causesize)        cause;
  Bit#(`vaddr)            mtval;
`ifdef hypervisor 
  Bit#(`vaddr)            mtval2;
`endif
} TrapOut deriving(Bits, Eq);

instance FShow#(TrapOut);
  /*doc:func: */
  function Fmt fshow (TrapOut value);
    Fmt result ;
  `ifdef microtrap_support
    if (value.is_microtrap) begin
      result =$format("MICRO-TRAP. Cause:%d MTVAL:%h",value.cause,value.mtval);
    end
    else
  `endif
    if (truncateLSB(value.cause) == 1'b1)
      result = $format(intcause2str(truncate(value.cause)));
    else 
      result = $format(excause2str(truncate(value.cause)));
    result = result + $format(" mtval:%h",value.mtval);
    return result;
  endfunction
endinstance

typedef struct{
  Bit#(`xlen)    rs1_imm;
  Bit#(2)       lpc;
  Bit#(12)      csr_address;
  Bit#(3)       funct3;
} SystemOut deriving(Bits, Eq);

instance FShow#(SystemOut);
  /*doc:func: */
  function Fmt fshow (SystemOut value);
    String csrop = case(value.funct3)
      'b001: "csrrw";
      'b010: "csrrs";
      'b011: "csrrc";
      'b101: "csrrwi";
      'b110: "csrrsi";
      'b111: "csrrci";
      default: "UNKOWN OP";
    endcase;

    Fmt result; 
    if (value.funct3 !=0)
      result = $format(csrop , " %s",fn_csr_to_str(value.csr_address), " rs1:%h",value.rs1_imm);
    else 
      result = $format("NON-CSR System Op %h",value.csr_address);
    return result;
  endfunction
endinstance

typedef struct{
`ifdef rtldump `ifdef atomic
  Bit#(5) atomicop;
`endif `endif
`ifdef dpfpu
  Bit#(1)       nanboxing;
`endif
  Access_type   memaccess;
} MemoryOut deriving(Bits, Eq);

instance FShow#(MemoryOut);
  /*doc:func: */
  function Fmt fshow (MemoryOut value);
    Fmt result = $format("type: ",fshow(value.memaccess));
    `ifdef dpfpu
      result = result + $format("nanboxing: %d", value.nanboxing);
    `endif
    return result;
  endfunction
endinstance
// ------------------------------------------------------------------------------------------

typedef struct{
`ifdef atomic
  Bit#(`elen) atomic_rd_data;
`endif
`ifdef dpfpu
  Bool       nanboxing;
`endif
  Bit#(TLog#(`dsbsize)) sb_id;
  Bool io;
  Access_type memaccess;
} WBMemop deriving (Bits, Eq, FShow);

typedef struct{
`ifdef hypervisor
  Bool hfence;
`endif
`ifdef supervisor
  Bool sfence;
`endif
  Bool flush;
  Bit#(`xlen) newpc;
  Bool fencei;
} WBFlush deriving (Bits, Eq, FShow);

instance DefaultValue #(WBFlush);
  defaultValue = WBFlush { `ifdef supervisor sfence: False, `endif
                            flush: False,
                            newpc: ?,
                            fencei: False };
endinstance


typedef struct{
`ifdef no_wawstalls
  Bit#(`wawid) id;
`endif
`ifdef spfpu
  RFType        rdtype;
`endif
  Bit#(`vaddr) pc;
  Bit#(5)      rd;
  Bit#(1)      epochs;
  EXEType     insttype;
} FUid deriving(Bits, Eq);

instance FShow#(FUid);
  /*doc:func: */
  function Fmt fshow (FUid value);
    Fmt result = $format("pc:%h rd:%2d inst:",value.pc, value.rd,fshow(value.insttype));
  `ifdef spfpu
    result = result + $format(" rdtype: ",fshow(value.rdtype));
  `endif
  `ifdef no_wawstalls
    result = result + $format(" id:%2s",value.id);
  `endif
    return result;
  endfunction
endinstance

typedef struct{
`ifdef no_wawstalls
  Bit#(`wawid) id;
`endif
`ifdef spfpu
  RFType        rdtype;
`endif
  Bit#(`vaddr) pc;
  Bit#(5)      rd;
  Bit#(1)      epochs;
  CommitType   insttype;
} CUid deriving(Bits, Eq);

instance FShow#(CUid);
  /*doc:func: */
  function Fmt fshow (CUid value);
    Fmt result = $format("pc:%h rd:%2d inst:",value.pc, value.rd,fshow(value.insttype));
  `ifdef spfpu
    result = result + $format(" rdtype: ",fshow(value.rdtype));
  `endif
  `ifdef no_wawstalls
    result = result + $format(" id:%2s",value.id);
  `endif
    return result;
  endfunction
endinstance

function CUid fn_fu2cu(FUid f);
  let c =  CUid{pc: f.pc, rd: f.rd, epochs: f.epochs, insttype : ?
          `ifdef no_wawstalls ,id: f.id `endif 
          `ifdef spfpu ,rdtype: f.rdtype `endif };
  c.insttype = case (f.insttype) matches
    BASE: BASE;
    SYSTEM: SYSTEM;
    TRAP: TRAP;
    MEMORY: MEMORY;
  `ifdef muldiv MULDIV: BASE; `endif 
  `ifdef spfpu FLOAT: BASE; `endif
  endcase;
  return c;
endfunction:fn_fu2cu

// ----------------------------------------------------------//

typedef struct {
	Bit#(1)			mprv;
	Bit#(1)			sum;
	Bit#(1)			mxr;
	Privilege_mode mpp;
	Privilege_mode prv;
} Chmod deriving(Bits, Eq);

typedef struct{
`ifdef no_wawstalls
  Bit#(`wawid) id;
`endif
`ifdef spfpu
  RFType      rdtype ;
`endif
  Bool        unlock_only;
  Bit#(5)     addr;
  Bit#(`elen)  data;
} CommitData deriving(Bits, Eq);

instance FShow#(CommitData);
  function Fmt fshow(CommitData val);
    Fmt result = $format("Committing :");
    Fmt optype = $format("X");
  `ifdef spfpu
    if (val.rdtype == FRF)
      optype = $format("F");
  `endif
    result = result + optype + $format("[%d] = %h unlock:%b",val.addr,val.data,val.unlock_only);
  `ifdef no_wawstalls
    result = result + $format(" id:%2d",val.id);
  `endif
    return result;
  endfunction:fshow
endinstance

typedef struct{
        Bit#(ELEN) operand1;
        Bit#(ELEN) operand2;
        Bit#(ELEN) operand3;
        Bit#(4) opcode;
        Bit#(7) funct7;
        Bit#(3) funct3;
        Bit#(2) imm;
        Bool    issp;
        Bit#(3) fsr;
}Input_Packet deriving (Bits,Eq);

typedef struct{
  Bit#(ELEN)  data;
  Bool        valid;
  `ifdef arith_trap
    Bit#(1) arith_trap_en;
  `endif
`ifdef spfpu
  Bit#(5) fflags;
`endif
} XBoxOutput deriving(Bits, Eq, FShow);

typedef struct{
	Bit#(width) final_result;					// the final result for the operation
	Bit#(5) fflags; 					// indicates if any exception is generated.
}Floating_output#(numeric type width) deriving(Bits, Eq);				// data structure of the output FIFO.
// ------------------------------------------------------------- //

`ifdef triggers
  typedef struct{
    Bit#(1) load;
    Bit#(1) store;
    Bit#(1) execute;
  `ifdef user
    Bit#(1) user;
  `endif
  `ifdef supervisor
    Bit#(1) supervisor;
  `endif
    Bit#(1) machine;
    Bit#(4) matched;
    Bit#(1) chain;
    Bit#(4) action_;
  `ifdef RV64
    Bit#(4) size;
  `else
    Bit#(2) size;
  `endif
    Bit#(1) select;
    Bit#(1) dmode;
  } MControl deriving(Bits, Eq, FShow);

  typedef struct {
    Bit#(6) action_;
  `ifdef user
    Bit#(1) user;
  `endif
  `ifdef supervisor
    Bit#(1) supervisor;
  `endif
    Bit#(1) machine;
    Bit#(14) count;
    Bit#(1) dmode;
  } ICount deriving(Bits, Eq, FShow);

  typedef struct{
    Bit#(6) action_;
  `ifdef user
    Bit#(1) user;
  `endif
  `ifdef supervisor
    Bit#(1) supervisor;
  `endif
    Bit#(1) machine;
    Bit#(1) dmode;
  } ITrigger deriving(Bits, Eq, FShow);

  typedef struct{
    Bit#(6) action_;
  `ifdef user
    Bit#(1) user;
  `endif
  `ifdef supervisor
    Bit#(1) supervisor;
  `endif
    Bit#(1) machine;
    Bit#(1) dmode;
  } ETrigger deriving(Bits, Eq, FShow);

  typedef union tagged {
    MControl MCONTROL;
    ICount   ICOUNT;
    ITrigger ITRIGGER;
    ETrigger ETRIGGER;
    void NONE;
  } TriggerData deriving(Bits, Eq, FShow);

  typedef struct{
      Bool trap;
      Bit#(`causesize) cause;
    } TriggerStatus deriving(Bits, Eq, FShow);

`endif

  // ------------------------------ types for predictor ------------------------------------------//
  typedef enum {Branch = 0, JAL = 1, Call = 2, Ret = 3} ControlInsn deriving(Bits, Eq, FShow);

  typedef struct{
  `ifdef compressed
    Bool hi;                          // bits [histlen+statesize+1]
  `endif
  `ifdef gshare
    Bit#(`histlen) history;           // bits [histlen+statesize: statesize+1]
  `endif
    Bit#(`statesize) prediction;      // bits [statesize:1]
    Bool btbhit ;                     // bits [0]
  } BTBResponse deriving(Bits, Eq, FShow);

  typedef struct {
  `ifdef compressed
    Bool instr16;
  `endif
    Bit#(`vaddr) nextpc;
    BTBResponse btbresponse;
  }PredictionResponse deriving (Bits, Eq, FShow);

  typedef struct {
  `ifdef compressed
    Bool          instr16;
  `endif
  `ifdef gshare
    Bit#(`histlen) history;
  `endif
    Bit#(`vaddr)  pc;
    Bit#(`vaddr)  target;
    Bit#(2)       state;
    ControlInsn   ci;
    Bool          btbhit;
  } Training_data deriving (Bits, Eq, FShow);

  typedef struct{
  `ifdef ifence
    Bool         fence;
  `endif
  `ifdef compressed
    Bool         discard;
  `endif
    Bit#(`vaddr) pc;
  } PredictionRequest deriving(Bits, Eq, FShow);
  // --------------------------------------------------------------------------------------------//

`ifdef perfmonitors
		typedef struct{
      Bit#(1) misprediction            ;
      Bit#(1) exceptions               ;
      Bit#(1) interrupts               ;
      Bit#(1) csrops                   ;
      Bit#(1) jumps                    ;
      Bit#(1) branches                 ;
      Bit#(1) floats                   ;
      Bit#(1) muldiv                   ;
      Bit#(1) rawstalls                ;
      Bit#(1) exetalls                 ;
      Bit#(1) icache_access            ;
      Bit#(1) icache_hits              ;
      Bit#(1) icache_fbhit             ;
      Bit#(1) icache_ncaccess          ;
      Bit#(1) icache_fbrelease         ;
      Bit#(1) dcache_read_access		    ;
      Bit#(1) dcache_write_access		  ;
      Bit#(1) dcache_atomic_access		  ;
      Bit#(1) dcache_nc_read_access		;
      Bit#(1) dcache_nc_write_access   ;
      Bit#(1) dcache_read_hits		      ;
      Bit#(1) dcache_write_hits		    ;
      Bit#(1) dcache_atomic_hits		    ;
      Bit#(1) dcache_read_fb_hits		  ;
      Bit#(1) dcache_write_fb_hits		  ;
      Bit#(1) dcache_atomic_fb_hits		;
      Bit#(1) dcache_fb_releases		    ;
      Bit#(1) dcache_line_evictions		;
      Bit#(1) itlb_misses              ;
      Bit#(1) dtlb_misses              ;
  	} Events deriving(Bits, Eq, FShow);
	// types for events
	`ifdef csr_grp4
  	typedef Events Events_grp4;
  `endif
  `ifdef csr_grp5
  	typedef Events Events_grp5;
	`endif
	`ifdef csr_grp6
  	typedef Events Events_grp6;
  `endif
  `ifdef csr_grp7
  	typedef Events Events_grp7;
  `endif
  function String event_to_string(Bit#(`xlen) event_count);
    case (event_count)
      'd1:  return "Exceptions";
      'd2:  return "Interrupts";
      'd3:  return "Branches Taken";
      'd4:  return "Branches Not Taken";
      'd5:  return "MulDiv Inst";
      'd6:  return "CSR Inst";
      'd7:  return "Jumps";
      'd8:  return "Loads";
      'd9:  return "Stores";
      'd10: return "Control Redirections";
      'd11: return "RAW Stalls";
      default: return "Unknown Event";
    endcase
  endfunction
`endif
endpackage
