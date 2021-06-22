// See LICENSE for license details.

package freechips.rocketchip.tile

import Chisel._
import freechips.rocketchip.config._
import freechips.rocketchip.rocket._

class cop_ise extends BlackBox {
	val io = new Bundle() {
		val cop_clk   = Clock(INPUT)
		val cop_rst   = Bool(INPUT)
		val cop_valid = Bool(INPUT)
		val cop_ready = Bool(OUTPUT)
		val cop_wait  = Bool(OUTPUT)
		val cop_wr    = Bool(OUTPUT)
        val cop_rdywr = Bool(INPUT)		
		val cop_insn = Bits(INPUT ,width= 32)
		val cop_rs1  = Bits(INPUT ,width= 64)
		val cop_rs2  = Bits(INPUT ,width= 64)
		val cop_rd   = Bits(OUTPUT,width= 64)	}
}
 
//RoCC Black box which will then be defined in Verilog after generating RC system.
class RoCC_ISE(opcodes: OpcodeSet)(implicit p: Parameters) extends LazyRoCC(opcodes) {
  override lazy val module = new RoCC_ISE_Imp(this)
}

class RoCC_ISE_Imp(outer: RoCC_ISE)(implicit p: Parameters) extends LazyRoCCModuleImp(outer)
    with HasCoreParameters {
	
//  val cmd = Queue(io.cmd)
  val insn= Cat(io.cmd.bits.inst.funct,
				io.cmd.bits.inst.rs2,
				io.cmd.bits.inst.rs1,
				io.cmd.bits.inst.xd,
				io.cmd.bits.inst.xs1,
				io.cmd.bits.inst.xs2,
				io.cmd.bits.inst.rd,
				io.cmd.bits.inst.opcode)

  val rdreg = Reg(UInt(width = 5))

  val CoP_BB = Module(new cop_ise())
  CoP_BB.io.cop_clk   := clock
  CoP_BB.io.cop_rst   := reset
  CoP_BB.io.cop_insn  <> insn
  CoP_BB.io.cop_rs1   <> io.cmd.bits.rs1
  CoP_BB.io.cop_rs2   <> io.cmd.bits.rs2
  CoP_BB.io.cop_valid <> io.cmd.valid
  io.cmd.ready        := CoP_BB.io.cop_ready  
	
  io.busy             := CoP_BB.io.cop_wait
  CoP_BB.io.cop_rdywr := io.resp.ready
  io.resp.valid	      := CoP_BB.io.cop_wr
  io.resp.bits.data   := CoP_BB.io.cop_rd
  io.resp.bits.rd     := io.cmd.bits.inst.rd


  // PROC RESPONSE INTERFACE
  io.interrupt := Bool(false)
    // Set this true to trigger an interrupt on the processor (please refer to supervisor documentation)

  // MEMORY REQUEST INTERFACE
  io.mem.req.valid := Bool(false) // we're not performing any memory request ...
  io.mem.req.bits.addr := io.cmd.bits.rs1
  io.mem.req.bits.tag := Bits(0)
  io.mem.req.bits.size := log2Ceil(8).U
  io.mem.req.bits.signed := Bool(false)
  io.mem.req.bits.cmd := M_XRD // perform a load (M_XWR for stores)
  io.mem.req.bits.data := Bits(0) // we're not performing any stores...
  io.mem.req.bits.phys := Bool(false)
}

