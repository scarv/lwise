// See LICENSE.SiFive for license details.
// See LICENSE.Berkeley for license details.

package freechips.rocketchip.system

import Chisel._
import freechips.rocketchip.config._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.tile._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.groundtest.WithTraceGen

class WithISERoCC extends Config((site, here, up) => {
  case BuildRoCC => List(
    (p: Parameters) => {
        val CoP_ISE = LazyModule(new RoCC_ISE(OpcodeSet.custom0)(p))
        CoP_ISE
    })
})

class WithXLEN64 extends Config((site, here, up) => {
  case XLen => 64
})

class SCARVRocketCoPConfig extends Config(
    new WithNBreakpoints(2)	++
	new WithJtagDTM  ++
	new WithISERoCC ++
    new WithXLEN64 ++
	new TinyConfig ++
	new BaseConfig)




