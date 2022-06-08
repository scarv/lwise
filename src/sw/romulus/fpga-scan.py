# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import driver, itertools

# =============================================================================

def rv32( args ) :
  if ( args.prog ) :
    driver.program_fpga( args, 'romulus', 'rv32', 'xalu' )

  if ( args.nist ) :
    CONF  = [ 'DRIVER_BYPASS_TEST'  ]
    driver.run( args, 'romulus', CONF, 'rv32', 'nist', NIST_IMP = 'ref'            )
    driver.run( args, 'romulus', CONF, 'rv32', 'nist', NIST_IMP = 'fixslice_opt32' )

  for TYPE in [ 'ROMULUS_RV32_TYPE1', 'ROMULUS_RV32_TYPE2' ] :
    CONF = [ TYPE ]
    # this flag will not be used in code but will be used in kernel measurement
    CONF += [ 'ROMULUS_LUT' ]
    CONF += [ 'ROMULUS_RV32_UNROLL' ]
    CONF += [ 'DRIVER_BYPASS_TEST'  ]
    driver.run( args, 'romulus', CONF, 'rv32', 'rv32', NIST_IMP = 'ref'            )

#  if ( args.nist ) :
#    CONF = [ 'DRIVER_BYPASS_TEST'   ]
#    driver.run( args, 'romulus', CONF, 'rv32', 'nist', NIST_IMP = 'fixslice_opt32' )

  for TYPE in [ 'ROMULUS_RV32_TYPE1', 'ROMULUS_RV32_TYPE3' ] :
    CONF = [ TYPE ]
    # this flag will not be used in code but will be used in kernel measurement
    CONF += [ 'ROMULUS_FIXSLICING'  ]
    CONF += [ 'ROMULUS_RV32_UNROLL' ]
    CONF += [ 'DRIVER_BYPASS_TEST'  ]
    driver.run( args, 'romulus', CONF, 'rv32', 'rv32', NIST_IMP = 'fixslice_opt32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  pass

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
