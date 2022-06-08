# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import driver, itertools

# =============================================================================

def rv32( args ) :
  if ( args.prog ) :
    driver.program_fpga( args, 'grain', 'rv32', 'xalu' )
  if ( args.nist ) :
    CONF = [ 'DRIVER_BYPASS_TEST' ]

    driver.run( args, 'grain', CONF, 'rv32', 'nist', NIST_IMP = 'x64' )

  for TYPE in [ 'GRAIN_RV32_TYPE1', 'GRAIN_RV32_TYPE2'] :
    CONF = [ TYPE ]
    CONF += [ 'GRAIN_RV32_UNROLL' ]
    CONF += ['DRIVER_BYPASS_TEST']

    driver.run( args, 'grain', CONF, 'rv32', 'rv32', NIST_IMP = 'x64' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  pass

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
